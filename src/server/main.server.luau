--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RoundService = require(script.Parent.RoundService)

print(`{Config.GameName} server v{Config.Version} started`)
RoundService.start()
