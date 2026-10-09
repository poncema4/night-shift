--!strict
-- "The Night Manager": a tall figure that patrols the hotel and hunts what it hears.
-- Movement rules live in Shared/Game/Patrol (tested); this file only moves a model and applies the kill.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Hotel = require(ReplicatedStorage.Shared.Game.Hotel)
local Patrol = require(ReplicatedStorage.Shared.Game.Patrol)

local ThreatService = {}

local connection: RBXScriptConnection? = nil

-- The server only publishes where he is; every client draws and smooths its own copy (client/ThreatView).
local state = Instance.new("Folder")
state.Name = "ThreatState"
state:SetAttribute("Active", false)
state.Parent = ReplicatedStorage

local PUBLISH_INTERVAL = 1 / 20

local function livingPlayers(): { { player: Player, humanoid: Humanoid, x: number, z: number } }
	local list = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			table.insert(list, { player = player, humanoid = humanoid, x = root.Position.X, z = root.Position.Z })
		end
	end
	return list
end

function ThreatService.activate()
	ThreatService.deactivate()
	local settings = Config.Threat
	local patrol = Patrol.new(Hotel.graph(), settings.StartRoom, math.random)
	local lastX, lastZ = patrol.x, patrol.z
	local facing = Vector3.new(0, 0, -1)
	local sincePublish = PUBLISH_INTERVAL
	state:SetAttribute("Active", true)

	connection = RunService.Heartbeat:Connect(function(dt)
		local living = livingPlayers()
		local nearest, nearestDistance = nil, settings.HearRange
		for _, entry in living do
			local d = math.sqrt((entry.x - patrol.x) ^ 2 + (entry.z - patrol.z) ^ 2)
			if d <= nearestDistance then
				nearest, nearestDistance = entry, d
			end
		end
		patrol:tick(
			dt,
			settings.PatrolSpeed,
			settings.ChaseSpeed,
			if nearest then { x = nearest.x, z = nearest.z } else nil
		)

		local dx, dz = patrol.x - lastX, patrol.z - lastZ
		if dx * dx + dz * dz > 1e-6 then
			facing = Vector3.new(dx, 0, dz).Unit
		end
		lastX, lastZ = patrol.x, patrol.z
		sincePublish += dt
		if sincePublish >= PUBLISH_INTERVAL then
			sincePublish = 0
			state:SetAttribute("X", patrol.x)
			state:SetAttribute("Z", patrol.z)
			state:SetAttribute("Yaw", math.atan2(-facing.X, -facing.Z))
			state:SetAttribute("Mode", patrol.mode)
		end

		for _, entry in living do
			if math.sqrt((entry.x - patrol.x) ^ 2 + (entry.z - patrol.z) ^ 2) <= settings.KillRadius then
				print(`[Threat] the Night Manager caught {entry.player.Name}`)
				entry.humanoid.Health = 0
			end
		end
	end)
end

function ThreatService.deactivate()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	state:SetAttribute("Active", false)
end

return ThreatService
