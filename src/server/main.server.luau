--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local LogForwarder = require(script.Parent.LogForwarder)

LogForwarder.start()
print(`{Config.GameName} server v{Config.Version} started`)
