--!strict
-- Thin Roblox wrapper around the pure Round state machine.
-- The server owns phase, roles and winner. Clients only receive what they are allowed to see:
-- their OWN role during the night, and every role once dawn arrives.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Roles = require(ReplicatedStorage.Shared.Game.Roles)
local Round = require(ReplicatedStorage.Shared.Game.Round)

local STEP = 0.5

local RoundService = {}

local function makeRemote(parent: Instance, name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

function RoundService.start()
	local settings = if RunService:IsStudio() then Config.StudioRound else Config.Round
	local round = Round.new(settings)

	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	local roleAssigned = makeRemote(remotes, "RoleAssigned")
	local roundResult = makeRemote(remotes, "RoundResult")

	local roles: { [number]: Roles.Role } = {}

	local function publish()
		ReplicatedStorage:SetAttribute("Phase", round.phase)
		ReplicatedStorage:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + round.timeLeft)
		ReplicatedStorage:SetAttribute("RoundNumber", round.roundNumber)
	end

	local function onChange(event: Round.Event)
		print(`[Round] {event.from} -> {event.to}{if event.winner then " (winner: " .. event.winner .. ")" else ""}`)
		if event.to == "Night" then
			local ids = {}
			for _, player in Players:GetPlayers() do
				table.insert(ids, player.UserId)
			end
			roles = Roles.assign(ids, math.random)
			for _, player in Players:GetPlayers() do
				local role = roles[player.UserId]
				print(`[Round] {player.Name} is {role}`)
				roleAssigned:FireClient(player, role)
			end
		elseif event.to == "Dawn" then
			local reveal: { [string]: string } = {}
			for _, player in Players:GetPlayers() do
				reveal[player.Name] = roles[player.UserId] or "Crew"
			end
			roundResult:FireAllClients(event.winner, reveal)
		end
	end

	publish()
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(STEP)
			local now = os.clock()
			local dt = now - last
			last = now
			-- No tasks or kills exist yet (later milestones), so the night ends on the timer.
			local event = round:tick(dt, #Players:GetPlayers(), nil)
			if event then
				onChange(event)
			end
			publish()
		end
	end)
end

return RoundService
