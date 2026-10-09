--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local ServerMode = require(ReplicatedStorage.Shared.Game.ServerMode)
local LobbyBuilder = require(script.Parent.LobbyBuilder)
local LobbyService = require(script.Parent.LobbyService)
local ProfileService = require(script.Parent.ProfileService)
local PurchaseService = require(script.Parent.PurchaseService)
local RoundService = require(script.Parent.RoundService)

local mode =
	ServerMode.detect(game.PrivateServerId, game.PrivateServerOwnerId, RunService:IsStudio(), Config.Server.StudioMode)
ReplicatedStorage:SetAttribute("ServerMode", mode)
print(`{Config.GameName} server v{Config.Version} started as {mode}`)

if mode == "Lobby" then
	local _, podViews = LobbyBuilder.build()
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	Players.CharacterAutoLoads = true
	ProfileService.start(remotes) -- the shop and cosmetics work in the lobby too
	PurchaseService.start(remotes)
	LobbyService.start(remotes, podViews)
else
	RoundService.start()
	PurchaseService.start(ReplicatedStorage:WaitForChild("Remotes"))
end
