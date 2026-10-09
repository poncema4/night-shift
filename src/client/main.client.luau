--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Fx = require(script.Parent.Fx)
local Hud = require(script.Parent.Hud)
local ThreatView = require(script.Parent.ThreatView)

print(`{Config.GameName} client v{Config.Version} started`)
Hud.start()
Fx.start()
ThreatView.start()
