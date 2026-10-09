--!strict
-- "The Night Manager": a tall figure that patrols the hotel and hunts what it hears.
-- Movement rules live in Shared/Game/Patrol (tested); this file only moves a model and applies the kill.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Escalation = require(ReplicatedStorage.Shared.Game.Escalation)
local Flash = require(ReplicatedStorage.Shared.Game.Flash)
local Floors = require(ReplicatedStorage.Shared.Game.Floors)
local Hotel = require(ReplicatedStorage.Shared.Game.Hotel)
local Patrol = require(ReplicatedStorage.Shared.Game.Patrol)
local Stealth = require(ReplicatedStorage.Shared.Game.Stealth)
local StealthService = require(script.Parent.StealthService)
local TaskService = require(script.Parent.TaskService)

local ThreatService = {}

local connection: RBXScriptConnection? = nil
local patrolState: Patrol.Patrol? = nil
local lureTarget: { x: number, y: number, z: number, expires: number }? = nil
local holdLeft = 0 -- seconds until he is released from the holding cell
local searchOnRelease = true -- ...and whether he then goes to search the lobby

-- The server only publishes where he is; every client draws and smooths its own copy (client/ThreatView).
local state = Instance.new("Folder")
state.Name = "ThreatState"
state:SetAttribute("Active", false)
state.Parent = ReplicatedStorage

local PUBLISH_INTERVAL = 1 / 20

type Living = { player: Player, humanoid: Humanoid, root: BasePart, x: number, y: number, z: number }

local function livingPlayers(): { Living }
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
				root = root,
				x = root.Position.X,
				y = root.Position.Y - 3,
				z = root.Position.Z,
			})
		end
	end
	return list
end

-- Is there nothing solid between two points? (player characters do not block the beam)
local function clearLine(from: Vector3, to: Vector3, living: { Living }): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	for _, entry in living do
		local character = entry.player.Character
		if character then
			table.insert(ignore, character)
		end
	end
	params.FilterDescendantsInstances = ignore
	return workspace:Raycast(from, to - from, params) == nil
end

local function run(patrol: Patrol.Patrol)
	local settings = Config.Threat
	local lastX, lastZ = patrol.x, patrol.z
	local facing = Vector3.new(0, 0, -1)
	local flash = Flash.new()
	local sincePublish = PUBLISH_INTERVAL
	local searching: { [Player]: number } = {}
	local lastHeard: { [Player]: number } = {} -- when he last heard each player
	local investigating: { [Player]: boolean } = {}
	state:SetAttribute("Active", true)

	connection = RunService.Heartbeat:Connect(function(dt)
		local living = livingPlayers()
		local now = os.clock()

		-- locked in the holding cell: he stands there (the crew can see the countdown) and hears and grabs no one
		if holdLeft > 0 then
			holdLeft -= dt
			state:SetAttribute("Hold", math.max(0, math.ceil(holdLeft)))
			state:SetAttribute("X", patrol.x)
			state:SetAttribute("Y", patrol.y)
			state:SetAttribute("Z", patrol.z)
			if holdLeft <= 0 then
				print("[Threat] the Night Manager is released")
				if searchOnRelease then
					local sx, sz = Hotel.spawnPoint()
					lureTarget = { x = sx, y = 0, z = sz, expires = os.clock() + settings.SearchSeconds }
				end
			end
			return
		end

		-- a flashlight held on him blinds him: in the cone, in range, and nothing solid in the way
		local lit = false
		if not Flash.stunned(flash, now) then
			local target = { patrol.x, patrol.y + 5, patrol.z }
			for _, entry in living do
				if StealthService.stateOf(entry.player).flashlight then
					local head = entry.root.Position + Vector3.new(0, 1.5, 0)
					local look = entry.root.CFrame.LookVector
					if
						Flash.inBeam(
							{ head.X, head.Y, head.Z },
							{ look.X, look.Y, look.Z },
							target,
							Flash.RANGE,
							Flash.HALF_ANGLE
						) and clearLine(head, Vector3.new(target[1], target[2], target[3]), living)
					then
						lit = true
						break
					end
				end
			end
		end
		if Flash.step(flash, dt, lit, now) then
			print("[Threat] the Night Manager is blinded by a flashlight")
		end
		local blinded = Flash.stunned(flash, now)
		state:SetAttribute("Stunned", blinded)
		-- every task the crew finishes makes him faster ("how did it get faster"): see Shared/Game/Escalation
		local done, total = TaskService.counts()
		local rage = Escalation.rage(done, total)
		local speedUp = Escalation.factor(rage)
		state:SetAttribute("Rage", rage)
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
			if d <= range then
				lastHeard[entry.player] = os.clock()
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
		if not blinded then
			patrol:tick(dt, settings.PatrolSpeed * speedUp, settings.ChaseSpeed * speedUp, target)
		end

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
				-- someone he was just hunting slipped into a locker: he heads there and waits (a player he never heard is safe)
				local heard = lastHeard[entry.player]
				if not investigating[entry.player] and heard and os.clock() - heard < settings.HideGrace then
					investigating[entry.player] = true
					lureTarget = {
						x = entry.x,
						y = entry.y,
						z = entry.z,
						expires = os.clock() + settings.InvestigateSeconds,
					}
				end
				-- he only opens a locker he has a reason to: he heard this player duck into it. Otherwise it is safe.
				local away = if investigating[entry.player]
					then (Vector3.new(patrol.x, patrol.y, patrol.z) - Vector3.new(place.X, place.Y, place.Z)).Magnitude
					else math.huge
				local timer, found = Stealth.search(searching[entry.player] or 0, dt, away)
				searching[entry.player] = timer
				if found then
					searching[entry.player] = 0
					StealthService.eject(entry.player)
				end
			else
				searching[entry.player] = nil
				investigating[entry.player] = nil
			end
		end

		for _, entry in living do
			if blinded then
				continue -- he cannot grab anyone while he cannot see
			end
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
	holdLeft = Config.Threat.ReleaseSeconds
	searchOnRelease = true
	state:SetAttribute("Hold", holdLeft)
	run(fresh)
end

-- His current movement state (tests place him with this; nothing else should).
function ThreatService.current(): Patrol.Patrol?
	return patrolState
end

-- Lets him out of the holding cell now (what the countdown does when it reaches zero; tests use it to skip the wait).
function ThreatService.release(search: boolean?)
	holdLeft = math.min(holdLeft, 0.001)
	searchOnRelease = search ~= false
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
	holdLeft = 0
	state:SetAttribute("Hold", 0)
	state:SetAttribute("Active", false)
end

return ThreatService
