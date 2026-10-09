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

local model: Model? = nil
local connection: RBXScriptConnection? = nil

local function part(parent: Instance, name: string, size: Vector3, offset: CFrame, color: Color3, neon: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = offset
	p.Color = color
	p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Parent = parent
	return p
end

local function build(): Model
	local m = Instance.new("Model")
	m.Name = "NightManager"
	local dark = Color3.fromRGB(8, 8, 12)
	local torso = part(m, "Torso", Vector3.new(3, 6, 1.6), CFrame.new(0, 4.5, 0), dark)
	part(m, "Head", Vector3.new(2, 2.4, 2), CFrame.new(0, 8.6, 0), dark)
	part(m, "EyeL", Vector3.new(0.45, 0.25, 0.2), CFrame.new(-0.5, 8.9, -1.05), Color3.fromRGB(255, 40, 60), true)
	part(m, "EyeR", Vector3.new(0.45, 0.25, 0.2), CFrame.new(0.5, 8.9, -1.05), Color3.fromRGB(255, 40, 60), true)
	part(m, "ArmL", Vector3.new(0.6, 6.5, 0.6), CFrame.new(-2.1, 4.2, 0) * CFrame.Angles(0, 0, math.rad(6)), dark)
	part(m, "ArmR", Vector3.new(0.6, 6.5, 0.6), CFrame.new(2.1, 4.2, 0) * CFrame.Angles(0, 0, math.rad(-6)), dark)
	part(m, "LegL", Vector3.new(0.9, 3, 0.9), CFrame.new(-0.8, 1.5, 0), dark)
	part(m, "LegR", Vector3.new(0.9, 3, 0.9), CFrame.new(0.8, 1.5, 0), dark)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 40, 60)
	glow.Range = 16
	glow.Brightness = 1.6
	glow.Parent = torso
	m.PrimaryPart = torso
	return m
end

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
	model = model or build()
	local m = model :: Model
	local patrol = Patrol.new(Hotel.graph(), settings.StartRoom, math.random)
	local lastX, lastZ = patrol.x, patrol.z
	local facing = Vector3.new(0, 0, -1)
	m.Parent = workspace

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
		local bob = math.sin(os.clock() * (if patrol.mode == "Chase" then 11 else 4)) * 0.25
		local position = Vector3.new(patrol.x, bob, patrol.z)
		m:PivotTo(CFrame.lookAt(position, position + facing))
		m:SetAttribute("Mode", patrol.mode)

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
	if model then
		model.Parent = nil
	end
end

return ThreatService
