--!strict
-- "The Night Manager": a tall figure that patrols the hotel and hunts what it hears.
-- Movement rules live in Shared/Game/Patrol (tested); this file only moves a model and applies the kill.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Floors = require(ReplicatedStorage.Shared.Game.Floors)
local Patrol = require(ReplicatedStorage.Shared.Game.Patrol)
local Stealth = require(ReplicatedStorage.Shared.Game.Stealth)
local StealthService = require(script.Parent.StealthService)

local ThreatService = {}

local connection: RBXScriptConnection? = nil
local patrolState: Patrol.Patrol? = nil
local lureTarget: { x: number, y: number, z: number, expires: number }? = nil

-- The server only publishes where he is; every client draws and smooths its own copy (client/ThreatView).
local state = Instance.new("Folder")
state.Name = "ThreatState"
state:SetAttribute("Active", false)
state.Parent = ReplicatedStorage

local PUBLISH_INTERVAL = 1 / 20

local function livingPlayers(): { { player: Player, humanoid: Humanoid, x: number, y: number, z: number } }
	local list = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			-- feet height: the root sits about three studs above the floor
			table.insert(list, {
				player = player,
				humanoid = humanoid,
				x = root.Position.X,
				y = root.Position.Y - 3,
				z = root.Position.Z,
			})
		end
	end
	return list
end

local function run(patrol: Patrol.Patrol)
	local settings = Config.Threat
	local lastX, lastZ = patrol.x, patrol.z
	local facing = Vector3.new(0, 0, -1)
	local sincePublish = PUBLISH_INTERVAL
	local searching: { [Player]: number } = {}
	state:SetAttribute("Active", true)

	connection = RunService.Heartbeat:Connect(function(dt)
		local living = livingPlayers()
		-- he hears the closest person: sprinting and flashlights carry farther, standing still is quiet, a hidden
		-- player is not heard at all, and someone on another floor is heard from half as far
		local nearest, nearestScore = nil, math.huge
		for _, entry in living do
			local d = math.sqrt((entry.x - patrol.x) ^ 2 + (entry.z - patrol.z) ^ 2)
			local floorsApart = math.abs(Floors.levelAt(entry.y) - Floors.levelAt(patrol.y))
			local base = settings.HearRange * (if floorsApart > 0 then settings.FloorHearFactor else 1)
			local range = Stealth.hearingRange(base, StealthService.stateOf(entry.player))
			local score = d + floorsApart * settings.FloorPenalty
			if d <= range and score < nearestScore then
				nearest, nearestScore = entry, score
			end
		end
		local target: Patrol.Target? = if nearest then { x = nearest.x, y = nearest.y, z = nearest.z } else nil
		if not target and lureTarget then
			-- a saboteur made a noise: he goes to investigate it (unless someone nearer is heard)
			if os.clock() < lureTarget.expires then
				target = { x = lureTarget.x, y = lureTarget.y, z = lureTarget.z }
			else
				lureTarget = nil
			end
		end
		patrol:tick(dt, settings.PatrolSpeed, settings.ChaseSpeed, target)

		local dx, dz = patrol.x - lastX, patrol.z - lastZ
		if dx * dx + dz * dz > 1e-6 then
			facing = Vector3.new(dx, 0, dz).Unit
		end
		lastX, lastZ = patrol.x, patrol.z

		sincePublish += dt
		if sincePublish >= PUBLISH_INTERVAL then
			sincePublish = 0
			state:SetAttribute("X", patrol.x)
			state:SetAttribute("Y", patrol.y)
			state:SetAttribute("Z", patrol.z)
			state:SetAttribute("Yaw", math.atan2(-facing.X, -facing.Z))
			state:SetAttribute("Mode", patrol.mode)
		end

		-- he searches hiding places he lingers beside; found players are pulled out right in front of him
		for _, entry in living do
			local place = StealthService.hidingPlace(entry.player)
			if place then
				local away = (Vector3.new(patrol.x, patrol.y, patrol.z) - Vector3.new(place.X, place.Y, place.Z)).Magnitude
				local timer, found = Stealth.search(searching[entry.player] or 0, dt, away)
				searching[entry.player] = timer
				if found then
					searching[entry.player] = 0
					StealthService.eject(entry.player)
				end
			else
				searching[entry.player] = nil
			end
		end

		for _, entry in living do
			-- someone inside a locker cannot be grabbed in passing: he has to search it (above) and pull them out first
			if StealthService.hidingPlace(entry.player) then
				continue
			end
			local flat = math.sqrt((entry.x - patrol.x) ^ 2 + (entry.z - patrol.z) ^ 2)
			if flat <= settings.KillRadius and math.abs(entry.y - patrol.y) <= settings.KillHeight then
				print(`[Threat] the Night Manager caught {entry.player.Name}`)
				entry.humanoid.Health = 0
			end
		end
	end)
end

function ThreatService.activate()
	ThreatService.deactivate()
	local fresh = Patrol.new(Floors.graph(), Config.Threat.StartRoom, math.random)
	patrolState = fresh
	lureTarget = nil
	run(fresh)
end

-- A meeting freezes him in place; resume() carries on from the same spot.
function ThreatService.pause()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	state:SetAttribute("Active", false)
end

function ThreatService.resume()
	local current = patrolState
	if current and not connection then
		run(current)
	end
end

-- The saboteur's noise: for `seconds` he heads for this spot if he hears nothing closer.
function ThreatService.lure(position: Vector3, seconds: number)
	lureTarget = { x = position.X, y = position.Y - 3, z = position.Z, expires = os.clock() + seconds }
end

function ThreatService.deactivate()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	patrolState = nil
	lureTarget = nil
	state:SetAttribute("Active", false)
end

return ThreatService
