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

type PodView = { status: TextLabel, ring: Part }

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

	-- Queue pods: stepping onto a pad puts you in that pad's party (the first one makes it), stepping off takes you out.
	local pods = Pods.layout(0, Config.Lobby.PodZ, Config.Lobby.PodSpacing)
	local podParty: { [number]: number } = {} -- pod id -> the party that pad is currently queueing
	local memberPod: { [number]: number } = {} -- userId -> the pod that put them in their party

	local function syncPods()
		for _, player in Players:GetPlayers() do
			local userId = player.UserId
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local pod = if root then Pods.at(pods, root.Position.X, root.Position.Z) else nil
			local was: number? = memberPod[userId]
			if was and lobby:partyOf(userId) == nil then
				memberPod[userId] = nil -- their party launched or was disbanded
				was = nil
			end
			if was and (not pod or pod.id ~= was) then
				lobby:leave(userId)
				memberPod[userId] = nil
			end
			if pod and not memberPod[userId] and lobby:partyOf(userId) == nil then
				local existing = podParty[pod.id]
				local joined = false
				if existing and lobby.parties[existing] then
					joined = lobby:join(userId, existing)
				end
				if not joined then
					local created = lobby:create(userId, pod.size)
					if created then
						podParty[pod.id] = created.id
						joined = true
					end
				end
				if joined then
					memberPod[userId] = pod.id
				end
			end
		end
		if podViews then
			for _, pod in pods do
				local view = podViews[pod.id]
				local party = lobby.parties[podParty[pod.id] or -1]
				if view then
					if party then
						local line = Pods.status(#party.members, party.size)
						view.status.Text = `{line}  {math.ceil(party.timeLeft)}s`
						view.ring.Color = if party.timeLeft <= Config.Lobby.FullSeconds
							then Color3.fromRGB(210, 40, 50)
							else Color3.fromRGB(110, 220, 130)
					else
						view.status.Text = Pods.status(0, pod.size)
						view.ring.Color = Color3.fromRGB(255, 190, 90)
					end
				end
			end
		end
	end

	local function broadcast()
		state:FireAllClients(lobby:view())
	end

	action.OnServerEvent:Connect(function(player: Player, kind: any, value: any)
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
		elseif kind == "leave" then
			lobby:leave(userId)
		else
			return
		end
		broadcast()
	end)

	Players.PlayerRemoving:Connect(function(player)
		lobby:leave(player.UserId)
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
