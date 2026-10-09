--!strict
-- The public lobby server: players form parties, the queue clock runs (Shared/Game/Party), and a party that is
-- ready is teleported to its own reserved server (a Match). All rules live in Party; this only moves people.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local Party = require(ReplicatedStorage.Shared.Game.Party)

local LobbyService = {}

local STEP = 0.5
local TELEPORT_TRIES = 3

local function makeRemote(parent: Instance, name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

-- Sends the players to a fresh reserved server; returns whether Roblox accepted it.
local function teleport(players: { Player }): boolean
	for attempt = 1, TELEPORT_TRIES do
		local ok, err = pcall(function()
			local code = TeleportService:ReserveServer(game.PlaceId)
			local options = Instance.new("TeleportOptions")
			options.ReservedServerAccessCode = code
			options:SetTeleportData({ size = #players })
			TeleportService:TeleportAsync(game.PlaceId, players, options)
		end)
		if ok then
			return true
		end
		warn(`[Lobby] teleport attempt {attempt} failed: {err}`)
		task.wait(1)
	end
	return false
end

function LobbyService.start(remotes: Folder)
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
		if not teleport(people) then
			for _, player in people do
				notice:FireClient(player, "Could not start your game. Please try again.")
			end
		end
	end

	task.spawn(function()
		while true do
			task.wait(STEP)
			for _, ready in lobby:tick(STEP) do
				launch(ready.members)
			end
			broadcast()
		end
	end)
end

return LobbyService
