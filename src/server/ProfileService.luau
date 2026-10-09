--!strict
-- Loads, saves and applies each player's progress. The rules are pure and tested (Shared/Game/Progress and
-- Cosmetics); this file only talks to the DataStore and puts cosmetics on characters.
-- Saving never overwrites progress: each save merges with what is already stored, and a failed load or save
-- warns and carries on in memory (Studio needs "Enable Studio Access to API Services" for the DataStore).
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cosmetics = require(ReplicatedStorage.Shared.Game.Cosmetics)
local Progress = require(ReplicatedStorage.Shared.Game.Progress)

local ProfileService = {}

local STORE_NAME = "NightShiftProfiles"
local AUTOSAVE_SECONDS = 60
local RETRIES = 3

local store: DataStore? = nil
local profiles: { [Player]: Progress.Profile } = {}
local dirty: { [Player]: boolean } = {}
local loaded: { [Player]: boolean } = {}
local snapshotRemote: RemoteEvent
local awardRemote: RemoteEvent

local function key(player: Player): string
	return `u{player.UserId}`
end

-- Retry a DataStore call a few times with a growing pause; returns ok and the result.
local function attempt(label: string, fn: () -> any): (boolean, any)
	local lastError: any = nil
	for i = 1, RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = result
		task.wait(i * 1.5)
	end
	warn(`[Profile] {label} failed: {lastError}`)
	return false, nil
end

local function snapshot(profile: Progress.Profile): { [string]: any }
	local level = Progress.levelFor(profile.xp)
	local owned = {}
	for id in profile.owned do
		table.insert(owned, id)
	end
	return {
		xp = profile.xp,
		level = level,
		levelStart = Progress.xpForLevel(level),
		levelEnd = Progress.xpForLevel(level + 1),
		tips = Progress.tips(profile),
		owned = owned,
		equipped = profile.equipped,
		nights = profile.nights,
		wins = profile.wins,
		survived = profile.survived,
		bestStreak = profile.bestStreak,
	}
end

local function send(player: Player)
	local profile = profiles[player]
	if profile then
		snapshotRemote:FireClient(player, snapshot(profile))
	end
end

local function save(player: Player)
	local profile = profiles[player]
	local data = store
	if not profile or not data or not loaded[player] then
		return
	end
	local ok = attempt(`save {player.Name}`, function()
		return data:UpdateAsync(key(player), function(old)
			return Progress.merge(Progress.repair(old), profile)
		end)
	end)
	if ok then
		dirty[player] = nil
	end
end

local function hatParts(character: Model, id: string)
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local old = character:FindFirstChild("NightShiftHat")
	if old then
		old:Destroy()
	end
	if id == "hat_none" then
		return
	end
	local model = Instance.new("Model")
	model.Name = "NightShiftHat"
	local function part(name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.CFrame = head.CFrame * CFrame.new(offset)
		p.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = p
		weld.Parent = p
	end
	local red, brass = Color3.fromRGB(110, 20, 32), Color3.fromRGB(190, 140, 62)
	if id == "hat_bellhop" then
		part("Band", Vector3.new(1.35, 0.15, 1.35), Vector3.new(0, 0.62, 0), brass, Enum.Material.Metal)
		part("Cap", Vector3.new(1.3, 0.55, 1.3), Vector3.new(0, 0.97, 0), red, Enum.Material.Fabric)
	elseif id == "hat_top" then
		part(
			"Brim",
			Vector3.new(1.9, 0.12, 1.9),
			Vector3.new(0, 0.6, 0),
			Color3.fromRGB(12, 10, 16),
			Enum.Material.Fabric
		)
		part(
			"Crown",
			Vector3.new(1.2, 1.3, 1.2),
			Vector3.new(0, 1.3, 0),
			Color3.fromRGB(12, 10, 16),
			Enum.Material.Fabric
		)
		part("Ribbon", Vector3.new(1.24, 0.22, 1.24), Vector3.new(0, 0.82, 0), red, Enum.Material.Fabric)
	elseif id == "hat_crown" then
		part(
			"Ring",
			Vector3.new(1.25, 0.35, 1.25),
			Vector3.new(0, 0.78, 0),
			Color3.fromRGB(240, 200, 80),
			Enum.Material.Neon
		)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			part(
				"Point",
				Vector3.new(0.22, 0.4, 0.22),
				Vector3.new(math.cos(a) * 0.5, 1.1, math.sin(a) * 0.5),
				Color3.fromRGB(240, 200, 80),
				Enum.Material.Neon
			)
		end
	end
	model.Parent = character
end

-- Puts the player's equipped cosmetics on a freshly spawned character.
local function dress(player: Player, character: Model)
	local profile = profiles[player]
	if not profile then
		return
	end
	hatParts(character, Cosmetics.worn(profile, "hat").id)
	local dust = Cosmetics.worn(profile, "dust")
	local root = character:FindFirstChild("HumanoidRootPart")
	local old = root and root:FindFirstChild("NightShiftDust")
	if old then
		old:Destroy()
	end
	if root and dust.rgb then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "NightShiftDust"
		emitter.Color = ColorSequence.new(Color3.fromRGB(dust.rgb[1], dust.rgb[2], dust.rgb[3]))
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.6, 1.1)
		emitter.Speed = NumberRange.new(0.5, 1.5)
		emitter.Size = NumberSequence.new(0.35, 0)
		emitter.Transparency = NumberSequence.new(0.2, 1)
		emitter.Parent = root
	end
end

-- The beam colour for a player's flashlight.
function ProfileService.flashlightColor(player: Player): Color3
	local profile = profiles[player]
	local item = if profile then Cosmetics.worn(profile, "flashlight") else Cosmetics.get("light_warm")
	local rgb = item and item.rgb or { 255, 244, 214 }
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

-- Reward a player for a night. Returns nothing; the client is told what they earned.
-- The loaded profile (nil until it has loaded). Only the purchase code changes it directly.
function ProfileService.profileOf(player: Player): Progress.Profile?
	return profiles[player]
end

-- Call after changing the profile outside a night (a purchase): tells the client, re-dresses the player and SAVES NOW.
-- Returns whether it is safe to say the purchase went through (saved, or there is no DataStore to save to in Studio).
function ProfileService.commit(player: Player): boolean
	if not profiles[player] then
		return false
	end
	dirty[player] = true
	send(player)
	if player.Character then
		dress(player, player.Character)
	end
	if not store then
		return RunService:IsStudio()
	end
	save(player)
	return dirty[player] == nil
end

function ProfileService.award(player: Player, report: Progress.Report)
	local profile = profiles[player]
	if not profile then
		return
	end
	local before = Progress.levelFor(profile.xp)
	local earned = Progress.apply(profile, report)
	dirty[player] = true
	awardRemote:FireClient(
		player,
		{ xp = earned.xp, tips = earned.tips, levelUp = Progress.levelFor(profile.xp) > before }
	)
	send(player)
	task.spawn(save, player)
end

local function onShop(player: Player, payload: unknown)
	local profile = profiles[player]
	if not profile or typeof(payload) ~= "table" then
		return
	end
	local data = payload :: { [string]: unknown }
	local id = data.id
	if typeof(id) ~= "string" then
		return
	end
	if data.action == "buy" then
		local outcome = Cosmetics.buy(profile, id)
		if outcome == "ok" then
			Cosmetics.equip(profile, id)
		end
	elseif data.action == "equip" then
		Cosmetics.equip(profile, id)
	else
		return
	end
	dirty[player] = true
	send(player)
	if player.Character then
		dress(player, player.Character)
	end
	task.spawn(save, player)
end

local function onJoin(player: Player)
	local data = store
	local profile = Progress.new()
	if data then
		local ok, raw = attempt(`load {player.Name}`, function()
			return data:GetAsync(key(player))
		end)
		if ok then
			profile = Progress.repair(raw)
			loaded[player] = true
		else
			warn(`[Profile] {player.Name} plays without saving this session (could not load)`)
		end
	end
	profiles[player] = profile
	send(player)
	player.CharacterAdded:Connect(function(character)
		dress(player, character)
	end)
	if player.Character then
		dress(player, player.Character)
	end
end

function ProfileService.start(remotes: Folder)
	snapshotRemote = Instance.new("RemoteEvent")
	snapshotRemote.Name = "Profile"
	snapshotRemote.Parent = remotes
	awardRemote = Instance.new("RemoteEvent")
	awardRemote.Name = "Award"
	awardRemote.Parent = remotes
	local shop = Instance.new("RemoteEvent")
	shop.Name = "Shop"
	shop.Parent = remotes
	shop.OnServerEvent:Connect(onShop)

	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result :: DataStore
	else
		warn(`[Profile] DataStore unavailable ({result}): progress will not be saved`)
	end
	if RunService:IsStudio() then
		print(
			"[Profile] in Studio, turn on Game Settings > Security > Enable Studio Access to API Services to test saving"
		)
	end

	Players.PlayerAdded:Connect(function(player)
		task.spawn(onJoin, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onJoin, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player] = nil
		dirty[player] = nil
		loaded[player] = nil
	end)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			save(player)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player in dirty do
				save(player)
			end
		end
	end)
	-- footstep dust only while moving
	RunService.Heartbeat:Connect(function()
		for player in profiles do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local emitter = root and root:FindFirstChild("NightShiftDust") :: ParticleEmitter?
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if emitter and humanoid then
				emitter.Rate = if humanoid.MoveDirection.Magnitude > 0.1 then 8 else 0
			end
		end
	end)
end

return ProfileService
