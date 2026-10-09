--!strict
-- Thin Roblox wrapper around the pure Round state machine.
-- The server owns phase, roles, deaths, meetings and the winner. Clients only receive what they may see:
-- their OWN role (and fellow saboteurs) during the night, and every role once dawn arrives.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Roles = require(ReplicatedStorage.Shared.Game.Roles)
local Round = require(ReplicatedStorage.Shared.Game.Round)
local AbilityService = require(script.Parent.AbilityService)
local CameraService = require(script.Parent.CameraService)
local HotelBuilder = require(script.Parent.HotelBuilder)
local MeetingService = require(script.Parent.MeetingService)
local ProfileService = require(script.Parent.ProfileService)
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

	local function roleOf(userId: number): string?
		return roles[userId]
	end
	local function isNight(): boolean
		return round.phase == "Night"
	end

	local onChange: (Round.Event) -> ()
	local meeting: { reason: string, caller: Player, victim: Player? }? = nil

	local hotel = HotelBuilder.build()
	ProfileService.start(remotes)
	StealthService.start(remotes, hotel.hiding)
	ScareDirector.start(remotes)
	TaskService.start(hotel.stations, roleOf)
	AbilityService.start(remotes, roleOf, isNight)
	CameraService.start(remotes, roleOf, isNight)
	TaskService.onDone(function(id)
		if id == "cameras" and round.phase == "Night" then
			CameraService.unlock()
		end
	end)
	MeetingService.start(remotes, {
		request = function(caller: Player, reason: string, victim: Player?): boolean
			if round.phase ~= "Night" or not isAlive(caller) then
				return false
			end
			local event = round:callMeeting()
			if not event then
				return false
			end
			meeting = { reason = reason, caller = caller, victim = victim }
			onChange(event)
			return true
		end,
		isNight = isNight,
		isMeeting = function()
			return round.phase == "Meeting"
		end,
		roleOf = roleOf,
		shorten = function(seconds: number)
			round:shortenMeeting(seconds)
		end,
	}, hotel.bell)

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
		if round.phase ~= "Night" and round.phase ~= "Meeting" then
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
		-- Co-op (too few players for a saboteur): a phantom saboteur is counted, so only a wiped-out crew loses
		local coop = #Players:GetPlayers() < Roles.COOP_BELOW
		if coop then
			saboteurs += 1
		end
		local done, total = TaskService.counts()
		return {
			crewAlive = crew,
			saboteursAlive = saboteurs,
			tasksDone = done,
			tasksTotal = total,
			coop = coop,
		}
	end

	local function publish()
		ReplicatedStorage:SetAttribute("Phase", round.phase)
		ReplicatedStorage:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + round.timeLeft)
		ReplicatedStorage:SetAttribute("RoundNumber", round.roundNumber)
		ReplicatedStorage:SetAttribute("MinPlayers", settings.MinPlayers)
	end

	local function startNight()
		local ids = {}
		for _, player in Players:GetPlayers() do
			table.insert(ids, player.UserId)
		end
		roles = Roles.assign(ids, math.random)
		MeetingService.resetNight()
		AbilityService.reset()
		CameraService.reset()
		for _, player in Players:GetPlayers() do
			local allies = {}
			if roles[player.UserId] == "Saboteur" then
				for _, other in Players:GetPlayers() do
					if other ~= player and roles[other.UserId] == "Saboteur" then
						table.insert(allies, other.Name)
					end
				end
			end
			print(`[Round] {player.Name} is {roles[player.UserId]}`)
			roleAssigned:FireClient(player, roles[player.UserId], allies)
		end
		TaskService.setActive(true)
		StealthService.setActive(true)
		ScareDirector.setActive(true, settings.NightSeconds)
		ThreatService.activate()
	end

	local function dawnReport(winner: string?)
		local list = {}
		local reports: { { player: Player, report: any } } = {}
		for _, player in Players:GetPlayers() do
			local role = roles[player.UserId]
			if role then
				local fate = if MeetingService.wasEjected(player.UserId)
					then "ejected"
					elseif isAlive(player) then "survived"
					else "caught"
				table.insert(list, { name = player.Name, role = role, fate = fate })
				local crewSide = role ~= "Saboteur"
				table.insert(reports, {
					player = player,
					report = {
						role = role,
						won = (winner == "Crew") == crewSide and winner ~= nil,
						survived = fate == "survived",
						tasks = TaskService.completedBy(player.UserId),
					},
				})
			end
		end
		table.sort(list, function(a, b)
			return a.name < b.name
		end)
		local done, total = TaskService.counts()
		roundResult:FireAllClients({ winner = winner, players = list, tasksDone = done, tasksTotal = total })
		-- rewards after the result, so each player's "+XP" line lands on a screen that is already showing
		for _, entry in reports do
			ProfileService.award(entry.player, entry.report)
		end
	end

	onChange = function(event: Round.Event)
		publish() -- clients read the phase from these attributes: they must be current before any remote below arrives
		print(`[Round] {event.from} -> {event.to}{if event.winner then " (winner: " .. event.winner .. ")" else ""}`)
		if event.to == "Intermission" then
			loadEveryone()
			TaskService.reset()
		elseif event.to == "Night" and event.from == "Meeting" then
			-- the meeting is over: everyone goes back where they were and the hunt resumes
			MeetingService.release()
			TaskService.setActive(true)
			StealthService.setActive(true)
			ThreatService.resume()
			ScareDirector.pause(false)
		elseif event.to == "Night" then
			startNight()
		elseif event.to == "Meeting" then
			TaskService.setActive(false)
			StealthService.setActive(false)
			ThreatService.pause()
			ScareDirector.pause(true)
			local info = meeting
			if info then
				MeetingService.begin(info.reason, info.caller, info.victim)
			end
		elseif event.to == "Dawn" then
			TaskService.setActive(false)
			StealthService.setActive(false)
			ScareDirector.setActive(false, 0)
			ThreatService.deactivate()
			CameraService.reset()
			dawnReport(event.winner)
		elseif event.to == "Lobby" then
			TaskService.setActive(false)
			StealthService.setActive(false)
			ScareDirector.setActive(false, 0)
			ThreatService.deactivate()
			loadEveryone()
			TaskService.reset()
			MeetingService.resetNight()
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
			if round.phase == "Meeting" then
				MeetingService.tick(round.timeLeft)
			end
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
