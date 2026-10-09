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
local darkened: { PointLight } = {}

local function restoreLights()
	for _, light in darkened do
		if light.Parent then
			light.Enabled = true
		end
	end
	darkened = {}
end

local function blackout(level: number, seconds: number)
	for _, lamp in CollectionService:GetTagged("Bulb") do
		local light = lamp:FindFirstChildOfClass("PointLight")
		if lamp:IsA("BasePart") and light and light.Enabled and Floors.levelAt(lamp.Position.Y) == level then
			light.Enabled = false
			table.insert(darkened, light)
		end
	end
	task.delay(seconds, restoreLights)
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

function ScareDirector.setActive(on: boolean, nightSeconds: number)
	if connection then
		connection:Disconnect()
		connection = nil
	end
	restoreLights()
	if not on then
		return
	end
	local director = Scares.new(math.random, nightSeconds)
	connection = RunService.Heartbeat:Connect(function(dt)
		local event = director:tick(dt)
		if event and remote then
			print(`[Scare] {event.kind}`)
			remote:FireAllClients(event.kind, event.seconds)
			if event.kind == "blackout" then
				blackout(levelOfSomeone(), event.seconds)
			end
		end
	end)
end

return ScareDirector
