--!strict
-- Meetings: a player reports a body or rings the bell, everyone alive gathers in the lobby, talks (normal chat),
-- votes, and the most-voted player is ejected. The counting is pure and tested (Shared/Game/Meeting); the round
-- clock belongs to RoundService. Everything a client sends is checked here.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Meeting = require(ReplicatedStorage.Shared.Game.Meeting)

export type Hooks = {
	request: (caller: Player, reason: string, victim: Player?) -> boolean,
	isNight: () -> boolean,
	isMeeting: () -> boolean,
	roleOf: (userId: number) -> string?,
	shorten: (seconds: number) -> (),
}

local MeetingService = {}

local RESULT_SECONDS = 9 -- the end of every meeting shows who was ejected
local GATHER = Vector3.new(-45, 3.1, -12) -- the lobby, in front of the desk
local GATHER_RADIUS = 5.5
local REPORT_DISTANCE = 10

local hooks: Hooks
local remotes: Folder
local votes: { [number]: number | boolean } = {}
local aliveIds: { number } = {}
local names: { [number]: string } = {}
local returns: { [Player]: CFrame } = {}
local ejected: { [number]: boolean } = {}
local bellUsed: { [number]: boolean } = {}
local bodyPrompts: { ProximityPrompt } = {}
local tallied = false

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function alive(player: Player): boolean
	local humanoid = humanoidOf(player)
	return humanoid ~= nil and humanoid.Health > 0
end

local function clearBodyPrompts()
	for _, prompt in bodyPrompts do
		prompt:Destroy()
	end
	bodyPrompts = {}
end

local function watchBody(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		if not hooks.isNight() then
			return -- an ejection or a death between rounds leaves no body to report
		end
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Report body"
		prompt.ObjectText = player.Name
		prompt.HoldDuration = 0.8
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
		table.insert(bodyPrompts, prompt)
		prompt.Triggered:Connect(function(reporter)
			local mine = rootOf(reporter)
			if
				hooks.isNight()
				and alive(reporter)
				and mine
				and (mine.Position - root.Position).Magnitude <= REPORT_DISTANCE
			then
				hooks.request(reporter, "body", player)
			end
		end)
	end)
end

local function onVote(player: Player, payload: unknown)
	if not hooks.isMeeting() or tallied or votes[player.UserId] ~= nil then
		return
	end
	if not table.find(aliveIds, player.UserId) then
		return
	end
	local choice: number | boolean
	if payload == "skip" then
		choice = false
	elseif typeof(payload) == "number" and table.find(aliveIds, payload) then
		choice = payload
	else
		return
	end
	votes[player.UserId] = choice
	local voted = remotes:FindFirstChild("MeetingVoted") :: RemoteEvent
	voted:FireAllClients(player.UserId)
	if Meeting.complete(votes, aliveIds) then
		hooks.shorten(RESULT_SECONDS)
	end
end

function MeetingService.start(folder: Folder, wiring: Hooks, bell: BasePart?)
	hooks = wiring
	remotes = folder
	for _, name in { "MeetingStart", "MeetingVoted", "MeetingResult" } do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	local vote = Instance.new("RemoteEvent")
	vote.Name = "Vote"
	vote.Parent = folder
	vote.OnServerEvent:Connect(onVote)

	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(character)
			watchBody(player, character)
		end)
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			watchBody(player, character)
		end)
	end)

	if bell then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Ring the bell"
		prompt.ObjectText = "Emergency meeting"
		prompt.HoldDuration = 1.2
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = bell
		prompt.Triggered:Connect(function(player)
			if hooks.isNight() and alive(player) and not bellUsed[player.UserId] then
				if hooks.request(player, "bell", nil) then
					bellUsed[player.UserId] = true
				end
			end
		end)
	end
end

-- A new night: everyone may ring the bell once again.
function MeetingService.resetNight()
	bellUsed = {}
	ejected = {}
	clearBodyPrompts()
end

function MeetingService.wasEjected(userId: number): boolean
	return ejected[userId] == true
end

-- The meeting starts: gather and freeze everyone alive, then tell the clients to open the vote.
function MeetingService.begin(reason: string, caller: Player, victim: Player?)
	clearBodyPrompts()
	votes = {}
	tallied = false
	aliveIds = {}
	names = {}
	returns = {}
	local list = {}
	local living: { Player } = {}
	for _, player in Players:GetPlayers() do
		if alive(player) then
			table.insert(living, player)
			table.insert(aliveIds, player.UserId)
			names[player.UserId] = player.Name
			table.insert(list, { userId = player.UserId, name = player.Name })
		end
	end
	for i, player in living do
		local root, humanoid = rootOf(player), humanoidOf(player)
		if root and humanoid then
			returns[player] = root.CFrame
			local angle = i / #living * math.pi * 2
			local spot = GATHER + Vector3.new(math.cos(angle), 0, math.sin(angle)) * GATHER_RADIUS
			root.CFrame = CFrame.lookAt(spot, Vector3.new(GATHER.X, spot.Y, GATHER.Z))
			root.Anchored = true
			humanoid.WalkSpeed = 0
			humanoid.JumpHeight = 0
		end
	end
	local open = remotes:FindFirstChild("MeetingStart") :: RemoteEvent
	open:FireAllClients({
		reason = reason,
		caller = caller.Name,
		victim = if victim then victim.Name else nil,
		players = list,
	})
end

local function tally()
	tallied = true
	local result = Meeting.tally(votes, aliveIds)
	local ejectedName: string? = nil
	local ejectedRole: string? = nil
	if result.ejected then
		ejected[result.ejected] = true
		ejectedName = names[result.ejected]
		ejectedRole = hooks.roleOf(result.ejected)
		local player = Players:GetPlayerByUserId(result.ejected)
		local humanoid = player and humanoidOf(player)
		if humanoid then
			humanoid.Health = 0
		end
	end
	local counts = {}
	for userId, n in result.counts do
		table.insert(counts, { name = names[userId] or "?", votes = n })
	end
	table.sort(counts, function(a, b)
		return a.votes > b.votes
	end)
	print(`[Meeting] result: {ejectedName or "no one"} ejected ({result.voted} voted)`)
	local announce = remotes:FindFirstChild("MeetingResult") :: RemoteEvent
	announce:FireAllClients({
		ejected = ejectedName,
		role = ejectedRole,
		tie = result.tie,
		skips = result.skips,
		counts = counts,
	})
end

-- Called every round step while the meeting is on: when the vote window closes, count it.
function MeetingService.tick(timeLeft: number)
	if not tallied and timeLeft <= RESULT_SECONDS then
		tally()
	end
end

-- The meeting is over: put everyone still alive back where they were and let them move.
function MeetingService.release()
	for player, cf in returns do
		local root, humanoid = rootOf(player), humanoidOf(player)
		if root and humanoid and humanoid.Health > 0 then
			root.CFrame = cf
			root.Anchored = false
			humanoid.WalkSpeed = Config.Move.Walk
			humanoid.JumpHeight = 7.2
		end
	end
	returns = {}
end

return MeetingService
