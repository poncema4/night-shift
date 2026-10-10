--!strict
-- The public lobby server: players form parties, the queue clock runs (Shared/Game/Party), and a party that is
-- ready is teleported to its own reserved server (a Match). All rules live in Party; this only moves people.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Party = require(ReplicatedStorage.Shared.Game.Party)
local Pods = require(ReplicatedStorage.Shared.Game.Pods)
local Teleport = require(script.Parent.Teleport)

type PodView = { status: TextLabel, ring: Part, gate: Part }

local LobbyService = {}

local STEP = 0.5

local function makeRemote(parent: Instance, name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

function LobbyService.start(remotes: Folder, podViews: { [number]: PodView }?)
	local lobby = Party.new({
		MaxSize = Config.Lobby.MaxParty,
		QueueSeconds = Config.Lobby.QueueSeconds,
		FullSeconds = Config.Lobby.FullSeconds,
	})
	local action = makeRemote(remotes, "PartyAction") -- client -> server
	local state = makeRemote(remotes, "PartyState") -- server -> clients: every open party
	local launching = makeRemote(remotes, "PartyLaunching") -- server -> the party's members
	local notice = makeRemote(remotes, "PartyNotice") -- server -> one player: why something did not work

	local lastAction: { [Player]: number } = {}

	-- Queue pods: square cells. The first player to step into an EMPTY cell is asked how big the party is (1 to 8) and
	-- the cell follows that answer; later players step in until it is full. Once queued you cannot walk out: you are put
	-- back until you press LEAVE QUEUE, so a party is never half-wandered-off.
	local pods = Pods.layout(0, Config.Lobby.PodZ, Config.Lobby.PodSpacing)
	local podParty: { [number]: number } = {} -- pod id -> the party that cell is currently queueing
	local memberPod: { [number]: number } = {} -- userId -> the pod they are queued in
	local choosing: { [number]: number } = {} -- userId -> the pod they are choosing a size for
	local prompt = makeRemote(remotes, "PodPrompt") -- server -> one player: pod id to choose a size for (0 closes it)

	local function rootOf(player: Player): BasePart?
		return player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	end
	local function placeAt(player: Player, x: number, z: number)
		local root = rootOf(player)
		if root then
			root.CFrame = CFrame.new(x, root.Position.Y, z)
		end
	end
	local function putBack(player: Player, pod: Pods.Pod) -- into the middle of the cell
		placeAt(player, pod.x, pod.z)
	end
	local function putOut(player: Player, pod: Pods.Pod) -- just outside the doorway
		placeAt(player, pod.x, pod.z - pod.half - 4)
	end
	local function podById(id: number): Pods.Pod
		return pods[id]
	end

	local function partyInPod(podId: number): Party.Party?
		local id = podParty[podId]
		local party = if id then lobby.parties[id] else nil
		if not party then
			podParty[podId] = nil
		end
		return party
	end

	local function syncPods()
		for _, player in Players:GetPlayers() do
			local userId = player.UserId
			local root = rootOf(player)
			if not root then
				continue
			end
			local x, z = root.Position.X, root.Position.Z
			local mine: number? = memberPod[userId]
			if mine and lobby:partyOf(userId) == nil then
				memberPod[userId] = nil -- their party launched or was disbanded
				mine = nil
			end
			if mine then
				local pod = podById(mine)
				if not Pods.inside(pod, x, z, 1) then
					putBack(player, pod)
					notice:FireClient(player, "You are queued. Press LEAVE QUEUE to go back out.")
				end
				continue
			end
			local inPod = Pods.at(pods, x, z)
			local picking: number? = choosing[userId]
			if picking and (not inPod or inPod.id ~= picking) then
				choosing[userId] = nil -- walked out before choosing
				prompt:FireClient(player, 0)
				picking = nil
			end
			if inPod and not picking and lobby:partyOf(userId) == nil then
				local party = partyInPod(inPod.id)
				if party then
					if lobby:join(userId, party.id) then
						memberPod[userId] = inPod.id
					else
						putOut(player, inPod)
						notice:FireClient(player, "That pod is full.")
					end
				else
					choosing[userId] = inPod.id
					prompt:FireClient(player, inPod.id)
				end
			end
		end
		for _, pod in pods do
			local party = partyInPod(pod.id)
			local anyChoosing = false
			for _, podId in choosing do
				if podId == pod.id then
					anyChoosing = true
				end
			end
			local view = if podViews then podViews[pod.id] else nil
			if view then
				if party then
					local full = #party.members >= party.size
					view.status.Text = `{Pods.status(#party.members, party.size)}  {math.ceil(party.timeLeft)}s`
					view.ring.Color = if party.timeLeft <= Config.Lobby.FullSeconds
						then Color3.fromRGB(210, 40, 50)
						else Color3.fromRGB(110, 220, 130)
					view.gate.CanCollide = full
					view.gate.Transparency = if full then 0.5 else 1
				else
					view.status.Text = if anyChoosing then "CHOOSING PARTY SIZE..." else "STEP IN TO START A PARTY"
					view.ring.Color = Color3.fromRGB(255, 190, 90)
					view.gate.CanCollide = false
					view.gate.Transparency = 1
				end
			end
		end
	end

	-- Leaving a queue (or backing out of the size question) puts you outside the doorway.
	local function leaveQueue(player: Player)
		local userId = player.UserId
		local podId = memberPod[userId] or choosing[userId]
		if memberPod[userId] then
			lobby:leave(userId)
			memberPod[userId] = nil
		end
		if choosing[userId] then
			choosing[userId] = nil
			prompt:FireClient(player, 0)
		end
		if podId then
			putOut(player, podById(podId))
		else
			lobby:leave(userId)
		end
	end

	local function broadcast()
		state:FireAllClients(lobby:view())
	end

	action.OnServerEvent:Connect(function(player: Player, kind: any, value: any, extra: any)
		local now = os.clock()
		if now - (lastAction[player] or 0) < Config.Lobby.ActionCooldown then
			return
		end
		lastAction[player] = now
		local userId = player.UserId
		if kind == "create" and type(value) == "number" then
			local _, why = lobby:create(userId, value)
			if why then
				notice:FireClient(player, why)
			end
		elseif kind == "quick" then
			local _, why = lobby:quickPlay(userId, Config.Lobby.DefaultParty)
			if why then
				notice:FireClient(player, why)
			end
		elseif kind == "join" and type(value) == "number" then
			local ok, why = lobby:join(userId, value)
			if not ok and why then
				notice:FireClient(player, why)
			end
		elseif kind == "podsize" and type(value) == "number" and type(extra) == "number" then
			-- the answer to the size question: only the player who was asked, only for an empty cell
			if choosing[userId] == value and not partyInPod(value) and extra == math.floor(extra) then
				local party = lobby:create(userId, extra)
				if party then
					podParty[value] = party.id
					memberPod[userId] = value
					choosing[userId] = nil
					prompt:FireClient(player, 0)
				end
			end
		elseif kind == "leave" then
			leaveQueue(player)
		else
			return
		end
		broadcast()
	end)

	Players.PlayerRemoving:Connect(function(player)
		lobby:leave(player.UserId)
		memberPod[player.UserId] = nil
		choosing[player.UserId] = nil
		lastAction[player] = nil
		broadcast()
	end)

	local function launch(members: { number })
		local people: { Player } = {}
		for _, userId in members do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				table.insert(people, player)
			end
		end
		if #people == 0 then
			return
		end
		for _, player in people do
			launching:FireClient(player, #people)
		end
		print(`[Lobby] launching a party of {#people}`)
		if RunService:IsStudio() then
			print("[Lobby] Studio cannot teleport: publish the place to test the real hand-off")
			return
		end
		if not Teleport.toMatch(people) then
			for _, player in people do
				notice:FireClient(player, "Could not start your game. Please try again.")
			end
		end
	end

	task.spawn(function()
		while true do
			task.wait(STEP)
			syncPods()
			for _, ready in lobby:tick(STEP) do
				launch(ready.members)
			end
			broadcast()
		end
	end)
end

return LobbyService
