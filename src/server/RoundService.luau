--!strict
-- Thin Roblox wrapper around the pure Round state machine.
-- The server owns phase, roles, deaths and the winner. Clients only receive what they may see:
-- their OWN role during the night, and every role once dawn arrives.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Roles = require(ReplicatedStorage.Shared.Game.Roles)
local Round = require(ReplicatedStorage.Shared.Game.Round)
local HotelBuilder = require(script.Parent.HotelBuilder)
local ScareDirector = require(script.Parent.ScareDirector)
local StealthService = require(script.Parent.StealthService)
local TaskService = require(script.Parent.TaskService)
local ThreatService = require(script.Parent.ThreatService)

local STEP = 0.5

local RoundService = {}

local function makeRemote(parent: Instance, name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local function isAlive(player: Player): boolean
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

function RoundService.start()
	local settings = if RunService:IsStudio() then Config.StudioRound else Config.Round
	local round = Round.new(settings)
	local roles: { [number]: Roles.Role } = {}

	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	local roleAssigned = makeRemote(remotes, "RoleAssigned")
	local roundResult = makeRemote(remotes, "RoundResult")

	local hotel = HotelBuilder.build()
	StealthService.start(remotes, hotel.hiding)
	ScareDirector.start(remotes)
	TaskService.start(hotel.stations, function(userId)
		return roles[userId]
	end)

	-- We place characters ourselves so people who die stay dead until the next round.
	Players.CharacterAutoLoads = false
	local function load(player: Player)
		task.spawn(function()
			local ok, err = pcall(player.LoadCharacter, player)
			if not ok then
				warn(`[Round] could not load {player.Name}: {err}`)
			end
		end)
	end
	local function loadEveryone()
		for _, player in Players:GetPlayers() do
			if not isAlive(player) then
				load(player)
			end
		end
	end
	Players.PlayerAdded:Connect(function(player)
		if round.phase ~= "Night" then
			load(player) -- latecomers during a night watch from the lobby until dawn
		end
	end)
	loadEveryone()

	local function stats(): Round.Stats
		local crew, saboteurs = 0, 0
		for _, player in Players:GetPlayers() do
			local role = roles[player.UserId]
			if role and isAlive(player) then
				if role == "Saboteur" then
					saboteurs += 1
				else
					crew += 1
				end
			end
		end
		-- Alone in Studio there is no real saboteur, so a phantom one stops the crew winning instantly.
		local sandbox = RunService:IsStudio() and #Players:GetPlayers() < 2
		if sandbox then
			saboteurs += 1
		end
		local done, total = TaskService.counts()
		return {
			crewAlive = crew,
			saboteursAlive = saboteurs,
			tasksDone = done,
			tasksTotal = total,
			sandbox = sandbox,
		}
	end

	local function publish()
		ReplicatedStorage:SetAttribute("Phase", round.phase)
		ReplicatedStorage:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + round.timeLeft)
		ReplicatedStorage:SetAttribute("RoundNumber", round.roundNumber)
	end

	local function onChange(event: Round.Event)
		print(`[Round] {event.from} -> {event.to}{if event.winner then " (winner: " .. event.winner .. ")" else ""}`)
		if event.to == "Intermission" then
			loadEveryone()
			TaskService.reset()
		elseif event.to == "Night" then
			local ids = {}
			for _, player in Players:GetPlayers() do
				table.insert(ids, player.UserId)
			end
			roles = Roles.assign(ids, math.random)
			for _, player in Players:GetPlayers() do
				print(`[Round] {player.Name} is {roles[player.UserId]}`)
				roleAssigned:FireClient(player, roles[player.UserId])
			end
			TaskService.setActive(true)
			StealthService.setActive(true)
			ScareDirector.setActive(true, settings.NightSeconds)
			ThreatService.activate()
		elseif event.to == "Dawn" then
			TaskService.setActive(false)
			StealthService.setActive(false)
			ScareDirector.setActive(false, 0)
			ThreatService.deactivate()
			local reveal: { [string]: string } = {}
			for _, player in Players:GetPlayers() do
				reveal[player.Name] = roles[player.UserId] or "Crew"
			end
			roundResult:FireAllClients(event.winner, reveal)
		elseif event.to == "Lobby" then
			TaskService.setActive(false)
			StealthService.setActive(false)
			ScareDirector.setActive(false, 0)
			ThreatService.deactivate()
			loadEveryone()
			TaskService.reset()
			roles = {}
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
			local current = if round.phase == "Night" then stats() else nil
			local event = round:tick(dt, #Players:GetPlayers(), current)
			if event then
				onChange(event)
			end
			publish()
		end
	end)
end

return RoundService
