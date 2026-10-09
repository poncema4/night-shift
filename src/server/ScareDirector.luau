--!strict
-- Plays the scare schedule (Shared/Game/Scares) during the Night: tells every client what to show, and turns a
-- level's lights off for a blackout. The schedule is tested; this file only applies it.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Floors = require(ReplicatedStorage.Shared.Game.Floors)
local Scares = require(ReplicatedStorage.Shared.Game.Scares)

local ScareDirector = {}

local remote: RemoteEvent? = nil
local connection: RBXScriptConnection? = nil
local paused = false
local restorers: { () -> () } = {}

-- Undo every blackout still running (used when the night ends).
local function restoreAll()
	for _, restore in restorers do
		restore()
	end
	restorers = {}
end

-- Turns the lights on one level off for a while (also used by the saboteur's ability). Each blackout remembers and
-- restores only its own lights, so two overlapping ones do not end each other early.
function ScareDirector.blackout(level: number, seconds: number)
	local lights: { PointLight } = {}
	local dims: { { part: BasePart, color: Color3, material: Enum.Material } } = {}
	for _, lamp in CollectionService:GetTagged("Bulb") do
		local light = lamp:FindFirstChildOfClass("PointLight")
		if
			lamp:IsA("BasePart")
			and light
			and light.Enabled
			and (lamp:GetAttribute("Level") or Floors.levelAt(lamp.Position.Y - 10)) == level
		then
			light.Enabled = false
			table.insert(lights, light)
			-- the glowing bulb itself goes dark too, otherwise a blackout still looks lit
			table.insert(dims, { part = lamp, color = lamp.Color, material = lamp.Material })
			lamp.Color = Color3.fromRGB(30, 28, 26)
			lamp.Material = Enum.Material.SmoothPlastic
		end
	end
	local restored = false
	local function restore()
		if restored then
			return
		end
		restored = true
		for _, light in lights do
			if light.Parent then
				light.Enabled = true
			end
		end
		for _, d in dims do
			if d.part.Parent then
				d.part.Color = d.color
				d.part.Material = d.material
			end
		end
	end
	table.insert(restorers, restore)
	task.delay(seconds, function()
		restore()
		local at = table.find(restorers, restore)
		if at then
			table.remove(restorers, at)
		end
	end)
end

local function levelOfSomeone(): number
	local levels = {}
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			table.insert(levels, Floors.levelAt(root.Position.Y - 3))
		end
	end
	return if #levels > 0 then levels[math.random(#levels)] else 0
end

function ScareDirector.start(remotes: Folder)
	local scare = Instance.new("RemoteEvent")
	scare.Name = "Scare"
	scare.Parent = remotes
	remote = scare
end

-- During a meeting the schedule stands still.
function ScareDirector.pause(on: boolean)
	paused = on
end

function ScareDirector.setActive(on: boolean, nightSeconds: number)
	paused = false
	if connection then
		connection:Disconnect()
		connection = nil
	end
	restoreAll()
	if not on then
		return
	end
	local director = Scares.new(math.random, nightSeconds)
	connection = RunService.Heartbeat:Connect(function(dt)
		if paused then
			return
		end
		local event = director:tick(dt)
		if event and remote then
			print(`[Scare] {event.kind}`)
			remote:FireAllClients(event.kind, event.seconds)
			if event.kind == "blackout" then
				ScareDirector.blackout(levelOfSomeone(), event.seconds)
			end
		end
	end)
end

return ScareDirector
