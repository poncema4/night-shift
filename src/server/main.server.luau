--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local LogForwarder = require(script.Parent.LogForwarder)
local RoundService = require(script.Parent.RoundService)

LogForwarder.start()
print(`{Config.GameName} server v{Config.Version} started`)
RoundService.start()
