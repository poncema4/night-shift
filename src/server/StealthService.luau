--!strict
-- Sprint, flashlight and hiding. The server decides everything: clients only say what they WANT (hold sprint,
-- flashlight on, leave the hiding place), and the pure rules in Shared/Game (Stamina, Battery, Stealth) decide
-- what actually happens. Other systems (the Night Manager) read the results from here.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Battery = require(ReplicatedStorage.Shared.Game.Battery)
local Config = require(ReplicatedStorage.Shared.Config)
local Stamina = require(ReplicatedStorage.Shared.Game.Stamina)
local ProfileService = require(script.Parent.ProfileService)
local Stealth = require(ReplicatedStorage.Shared.Game.Stealth)

type Entry = {
	stamina: Stamina.Stamina,
	battery: Battery.Battery,
	wantsSprint: boolean,
	wantsLight: boolean,
	sprinting: boolean,
	lightOn: boolean,
	hiddenIn: Model?,
	exit: CFrame?,
	saved: { [Instance]: number },
	lastIntent: number,
	tokens: number,
}

export type HidingSpot = { model: Model, position: Vector3 }

local StealthService = {}

local HIDE_DISTANCE = 10
-- Clients cannot flood the server with intents: a short burst is fine (RUN and LIGHT pressed together), a stream is not.
local INTENT_BURST = 8
local INTENT_RATE = 20 -- allowed per second on average

local entries: { [Player]: Entry } = {}
local prompts: { [Model]: ProximityPrompt } = {}
local occupant: { [Model]: Player } = {}
local active = false

local function entryOf(player: Player): Entry
	local entry: Entry? = entries[player]
	if not entry then
		entry = {
			stamina = Stamina.new(),
			battery = Battery.new(),
			wantsSprint = false,
			wantsLight = false,
			sprinting = false,
			lightOn = false,
			hiddenIn = nil,
			exit = nil,
			saved = {},
			lastIntent = 0,
			tokens = INTENT_BURST,
		}
		entries[player] = entry
	end
	return entry :: Entry
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function flashlightOf(player: Player): SpotLight?
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then
		return nil
	end
	local existing = head:FindFirstChild("Flashlight")
	if existing and existing:IsA("SpotLight") then
		existing.Color = ProfileService.flashlightColor(player)
		return existing
	end
	local light = Instance.new("SpotLight")
	light.Name = "Flashlight"
	light.Angle = Config.Beam.Angle
	light.Range = Config.Beam.Range
	light.Brightness = Config.Beam.Brightness
	light.Color = ProfileService.flashlightColor(player)
	light.Face = Enum.NormalId.Front
	light.Shadows = false
	light.Enabled = false
	light.Parent = head
	return light
end

local TOOL_NAME = "Flashlight"

local function toolOf(player: Player): Tool?
	local backpack = player:FindFirstChildOfClass("Backpack")
	local held = player.Character and player.Character:FindFirstChild(TOOL_NAME)
	local found = held or (backpack and backpack:FindFirstChild(TOOL_NAME))
	return if found and found:IsA("Tool") then found else nil
end

-- The flashlight is a real item in the hotbar: equip it and the beam is on, put it away and it is off.
local function giveFlashlight(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then
		return
	end
	local old = toolOf(player)
	if old then
		old:Destroy()
	end
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.ToolTip = "Blinds him for a moment. Drains the battery."
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 0.5, 1.6)
	handle.Color = Color3.fromRGB(38, 38, 44)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = tool
	local lens = Instance.new("Part")
	lens.Name = "Lens"
	lens.Size = Vector3.new(0.6, 0.6, 0.2)
	lens.Color = ProfileService.flashlightColor(player)
	lens.Material = Enum.Material.Neon
	lens.CanCollide = false
	lens.Massless = true
	lens.CFrame = handle.CFrame * CFrame.new(0, 0, -0.9)
	lens.Parent = tool
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = lens
	weld.Parent = tool
	tool.Equipped:Connect(function()
		local entry = entryOf(player)
		entry.wantsLight = entry.hiddenIn == nil
	end)
	tool.Unequipped:Connect(function()
		entryOf(player).wantsLight = false
	end)
	tool.Parent = backpack
end

local function setVisible(player: Player, entry: Entry, visible: boolean)
	local character = player.Character
	if not character then
		return
	end
	if visible then
		for part, transparency in entry.saved do
			if part.Parent then
				local target = part :: any
				target.Transparency = transparency
			end
		end
		entry.saved = {}
	else
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				local target = d :: any
				entry.saved[d] = target.Transparency
				target.Transparency = 1
			end
		end
	end
end

local function leave(player: Player)
	local entry = entries[player]
	if not entry or not entry.hiddenIn then
		return
	end
	local spot = entry.hiddenIn
	entry.hiddenIn = nil
	occupant[spot] = nil
	spot:SetAttribute("Occupant", nil)
	if prompts[spot] then
		prompts[spot].Enabled = active
	end
	local root = rootOf(player)
	if root and entry.exit then
		root.CFrame = entry.exit
		root.Anchored = false
	end
	setVisible(player, entry, true)
	player:SetAttribute("Hidden", false)
end

local function enter(player: Player, spot: Model, body: BasePart)
	local entry = entryOf(player)
	local root = rootOf(player)
	local humanoid = humanoidOf(player)
	if not root or not humanoid or humanoid.Health <= 0 or entry.hiddenIn or occupant[spot] then
		return
	end
	entry.hiddenIn = spot
	entry.exit = body.CFrame * CFrame.new(0, 3 - body.Size.Y / 2, body.Size.Z / 2 + 2.5)
	occupant[spot] = player
	prompts[spot].Enabled = false
	setVisible(player, entry, false)
	root.CFrame = body.CFrame
	root.Anchored = true
	humanoid.WalkSpeed = 0 -- frozen at once, not on the next frame
	entry.wantsLight = false
	humanoid:UnequipTools()
	spot:SetAttribute("Occupant", player.UserId)
	player:SetAttribute("Hidden", true)
end

-- Used by the Night Manager when he searches a hiding place long enough: you are pulled out in front of him.
function StealthService.eject(player: Player)
	leave(player)
end

-- Where a hidden player is hiding (nil when not hidden).
function StealthService.hidingPlace(player: Player): Vector3?
	local entry = entries[player]
	local spot = entry and entry.hiddenIn
	local body = spot and spot:FindFirstChild("Body") :: BasePart?
	return body and body.Position
end

-- What the Night Manager needs to decide how far he hears this player.
function StealthService.stateOf(player: Player): Stealth.State
	local entry = entries[player]
	local humanoid = humanoidOf(player)
	return {
		moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1,
		sprinting = entry ~= nil and entry.sprinting,
		flashlight = entry ~= nil and entry.lightOn,
		hidden = entry ~= nil and entry.hiddenIn ~= nil,
	}
end

local function reset(player: Player)
	local entry = entries[player]
	if entry then
		leave(player)
		entry.stamina = Stamina.new()
		entry.battery = Battery.new()
		entry.wantsSprint = false
		entry.wantsLight = false
		entry.sprinting = false
		entry.lightOn = false
	end
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.WalkSpeed = Config.Move.Walk
	end
	local light = flashlightOf(player)
	if light then
		light.Enabled = false
	end
	player:SetAttribute("Stamina", 100)
	player:SetAttribute("Battery", 100)
	player:SetAttribute("LightOn", false)
	player:SetAttribute("Sprinting", false)
	player:SetAttribute("Hidden", false)
end

function StealthService.setActive(on: boolean)
	active = on
	for _, prompt in prompts do
		prompt.Enabled = on
	end
	if not on then
		for _, player in Players:GetPlayers() do
			reset(player)
		end
	end
end

local function onIntent(player: Player, payload: unknown)
	local now = os.clock()
	local entry = entryOf(player)
	entry.tokens = math.min(INTENT_BURST, entry.tokens + (now - entry.lastIntent) * INTENT_RATE)
	entry.lastIntent = now
	if entry.tokens < 1 then
		return
	end
	entry.tokens -= 1
	if typeof(payload) ~= "table" then
		return
	end
	local data = payload :: { [string]: unknown }
	if typeof(data.sprint) == "boolean" then
		entry.wantsSprint = data.sprint :: boolean
	end
	if typeof(data.light) == "boolean" then
		entry.wantsLight = (data.light :: boolean) and entry.hiddenIn == nil
		-- the key is a shortcut for the hotbar: it equips or puts away the flashlight item
		local humanoid = humanoidOf(player)
		local tool = toolOf(player)
		if humanoid and tool then
			if entry.wantsLight and tool.Parent ~= player.Character then
				humanoid:EquipTool(tool)
			elseif not entry.wantsLight and tool.Parent == player.Character then
				humanoid:UnequipTools()
			end
		end
	end
	if data.leave == true then
		leave(player)
	end
end

local function step(dt: number)
	for player, entry in entries do
		local humanoid = humanoidOf(player)
		if not humanoid or humanoid.Health <= 0 then
			continue
		end
		local hidden = entry.hiddenIn ~= nil
		local moving = humanoid.MoveDirection.Magnitude > 0.1
		entry.sprinting = entry.stamina:step(dt, entry.wantsSprint and not hidden, moving)
		entry.lightOn = entry.battery:step(dt, entry.wantsLight and not hidden)
		if entry.battery.dead then
			entry.wantsLight = false -- a dead light does not come back on by itself
		end
		humanoid.WalkSpeed = if hidden then 0 elseif entry.sprinting then Config.Move.Sprint else Config.Move.Walk
		local light = flashlightOf(player)
		if light then
			light.Enabled = entry.lightOn
		end
		player:SetAttribute("Stamina", math.floor(entry.stamina.value))
		player:SetAttribute("Battery", math.floor(entry.battery.charge))
		player:SetAttribute("Sprinting", entry.sprinting)
		player:SetAttribute("LightOn", entry.lightOn)
	end
end

function StealthService.start(remotes: Folder, spots: { HidingSpot })
	local intent = Instance.new("RemoteEvent")
	intent.Name = "Intent"
	intent.Parent = remotes
	intent.OnServerEvent:Connect(onIntent)

	for _, spot in spots do
		CollectionService:AddTag(spot.model, "HidingSpot")
		local body = spot.model:FindFirstChild("Body") :: BasePart?
		if body then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Hide"
			prompt.ObjectText = spot.model.Name
			prompt.HoldDuration = 0 -- one tap of E
			prompt.MaxActivationDistance = 7
			prompt.RequiresLineOfSight = false
			prompt.Enabled = false
			prompt.Parent = body
			prompts[spot.model] = prompt
			prompt.Triggered:Connect(function(player)
				local root = rootOf(player)
				if active and root and (root.Position - body.Position).Magnitude <= HIDE_DISTANCE then
					enter(player, spot.model, body)
				end
			end)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			local entry = entries[player]
			if entry then
				entry.hiddenIn = nil
				entry.saved = {}
			end
			reset(player)
			giveFlashlight(player)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		leave(player)
		entries[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		entryOf(player)
	end
	RunService.Heartbeat:Connect(function(dt)
		if active then
			for _, player in Players:GetPlayers() do
				entryOf(player)
			end
			step(dt)
		end
	end)
end

return StealthService
