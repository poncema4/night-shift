--!strict
-- Saboteur abilities. A client only asks ("lure" or "lights"); the server checks who they are, that it is night,
-- and the cooldown (pure rules in Shared/Game/Abilities) before anything happens.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Abilities = require(ReplicatedStorage.Shared.Game.Abilities)
local Floors = require(ReplicatedStorage.Shared.Game.Floors)
local ScareDirector = require(script.Parent.ScareDirector)
local ThreatService = require(script.Parent.ThreatService)

local AbilityService = {}

local tracker = Abilities.new()
local roleOf: (number) -> string? = function(_userId: number)
	return nil
end
local isNight: () -> boolean = function()
	return false
end

local ATTRIBUTE = { lure = "LureReadyAt", lights = "LightsReadyAt" }

local function onAbility(player: Player, kind: unknown)
	if typeof(kind) ~= "string" or Abilities.specs[kind] == nil then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not isNight() or roleOf(player.UserId) ~= "Saboteur" or not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	if not Abilities.use(tracker, player.UserId, kind, os.clock()) then
		return
	end
	local spec = Abilities.specs[kind]
	player:SetAttribute(ATTRIBUTE[kind], workspace:GetServerTimeNow() + spec.cooldown)
	print(`[Ability] {player.Name} used {kind}`)
	if kind == "lure" then
		ThreatService.lure(root.Position, spec.seconds)
	else
		ScareDirector.blackout(Floors.levelAt(root.Position.Y - 3), spec.seconds)
	end
end

function AbilityService.start(remotes: Folder, getRole: (number) -> string?, night: () -> boolean)
	roleOf = getRole
	isNight = night
	local remote = Instance.new("RemoteEvent")
	remote.Name = "Ability"
	remote.Parent = remotes
	remote.OnServerEvent:Connect(onAbility)
end

-- A new night: every cooldown starts fresh.
function AbilityService.reset()
	tracker = Abilities.new()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("LureReadyAt", 0)
		player:SetAttribute("LightsReadyAt", 0)
	end
end

return AbilityService
