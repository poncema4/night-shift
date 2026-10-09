--!strict
-- Builds the three-level hotel from the pure data in Shared/Game: Building (every solid box), Furnishing (props)
-- and Floors (levels, stairs, tasks). The geometry is proven by tests (no overlaps, headroom, clear routes),
-- so this file only turns boxes into Parts and styles them.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Building = require(ReplicatedStorage.Shared.Game.Building)
local Config = require(ReplicatedStorage.Shared.Config)
local Floors = require(ReplicatedStorage.Shared.Game.Floors)
local Furnishing = require(ReplicatedStorage.Shared.Game.Furnishing)
local Hotel = require(ReplicatedStorage.Shared.Game.Hotel)
local Props = require(script.Parent.Props)
local StationProps = require(script.Parent.StationProps)

local HotelBuilder = {}

export type Result = {
	spawn: SpawnLocation,
	stations: { [string]: Part },
	hiding: { { model: Model, position: Vector3 } },
	bell: BasePart?,
}

type Style = { Color3 | Enum.Material }

local function style(color: Color3, material: Enum.Material): Style
	return { color, material }
end

-- Walls and dressing per level: ground wallpaper, upstairs warmer, basement bare concrete.
local WALL: { [number]: Style } = {
	[0] = style(Color3.fromRGB(70, 52, 62), Enum.Material.SmoothPlastic),
	[1] = style(Color3.fromRGB(82, 70, 58), Enum.Material.SmoothPlastic),
	[-1] = style(Color3.fromRGB(62, 64, 68), Enum.Material.Concrete),
}
local TRIM: { [string]: Style } = {
	skirting = style(Color3.fromRGB(34, 22, 16), Enum.Material.Wood),
	wainscot = style(Color3.fromRGB(62, 38, 28), Enum.Material.WoodPlanks),
	rail = style(Color3.fromRGB(150, 108, 58), Enum.Material.Wood),
	cornice = style(Color3.fromRGB(170, 152, 120), Enum.Material.SmoothPlastic),
	frame = style(Color3.fromRGB(120, 82, 46), Enum.Material.Wood),
	tread = style(Color3.fromRGB(58, 38, 28), Enum.Material.Wood),
	landing = style(Color3.fromRGB(58, 38, 28), Enum.Material.Wood),
	guardrail = style(Color3.fromRGB(170, 124, 60), Enum.Material.Metal),
	roof = style(Color3.fromRGB(34, 30, 38), Enum.Material.SmoothPlastic),
}
local FLOORS: { [string]: Style } = {
	Lobby = style(Color3.fromRGB(78, 72, 74), Enum.Material.Marble),
	Office = style(Color3.fromRGB(44, 62, 52), Enum.Material.Fabric),
	Ballroom = style(Color3.fromRGB(96, 62, 40), Enum.Material.WoodPlanks),
	["Pool Room"] = style(Color3.fromRGB(40, 92, 118), Enum.Material.Slate),
	Kitchen = style(Color3.fromRGB(150, 150, 146), Enum.Material.Slate),
	Pantry = style(Color3.fromRGB(110, 100, 86), Enum.Material.Slate),
	["Boiler Room"] = style(Color3.fromRGB(62, 62, 66), Enum.Material.Concrete),
	Laundry = style(Color3.fromRGB(98, 104, 112), Enum.Material.Slate),
	Storage = style(Color3.fromRGB(72, 64, 56), Enum.Material.WoodPlanks),
	Security = style(Color3.fromRGB(46, 52, 68), Enum.Material.Fabric),
	Mezzanine = style(Color3.fromRGB(88, 82, 78), Enum.Material.Marble),
	Library = style(Color3.fromRGB(70, 46, 30), Enum.Material.WoodPlanks),
	["Grand Suite"] = style(Color3.fromRGB(76, 24, 36), Enum.Material.Fabric),
	["Rooftop Spa"] = style(Color3.fromRGB(86, 120, 130), Enum.Material.Slate),
	["Flooded Hall"] = style(Color3.fromRGB(34, 44, 46), Enum.Material.Concrete),
	["Parking Garage"] = style(Color3.fromRGB(52, 52, 54), Enum.Material.Concrete),
	["West stairs"] = style(Color3.fromRGB(60, 40, 30), Enum.Material.WoodPlanks),
	["East stairs"] = style(Color3.fromRGB(60, 40, 30), Enum.Material.WoodPlanks),
}
local CORRIDOR: { [number]: Style } = {
	[0] = style(Color3.fromRGB(104, 22, 36), Enum.Material.Fabric),
	[1] = style(Color3.fromRGB(34, 74, 60), Enum.Material.Fabric),
	[-1] = style(Color3.fromRGB(48, 48, 50), Enum.Material.Concrete),
}
local GUEST_ROOM = style(Color3.fromRGB(40, 58, 66), Enum.Material.Fabric)
local CELLAR_ROOM = style(Color3.fromRGB(56, 56, 60), Enum.Material.Concrete)

-- Wall dressing that never needs physics.
local DECORATION: { [string]: boolean } =
	{ skirting = true, wainscot = true, rail = true, cornice = true, frame = true }

local function styleOf(s: Building.Slab): (Color3, Enum.Material)
	local level = s.level or 0
	local chosen: Style
	if s.kind == "wall" or s.kind == "header" then
		chosen = WALL[level]
	elseif s.kind == "tile" then
		local name = s.name or ""
		if name == "Corridor" then
			chosen = CORRIDOR[level]
		else
			chosen = FLOORS[name] or if level > 0 then GUEST_ROOM elseif level < 0 then CELLAR_ROOM else FLOORS.Pantry
		end
	else
		chosen = TRIM[s.kind] or WALL[level]
	end
	return chosen[1] :: Color3, chosen[2] :: Enum.Material
end

local function block(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanTouch = false
	part.Parent = parent
	return part
end

-- Shared with the lobby room (LobbyBuilder): one way to make an anchored, styled box.
HotelBuilder.block = block

local function bulb(parent: Instance, x: number, y: number, z: number, level: number)
	local lamp = block(
		parent,
		"Bulb",
		Vector3.new(3, 0.4, 3),
		Vector3.new(x, y + Hotel.CEILING - 0.3, z),
		Color3.fromRGB(255, 214, 150),
		Enum.Material.Neon
	)
	lamp.CanCollide = false
	local light = Instance.new("PointLight")
	light.Range = Config.Look.BulbRange
	light.Brightness = if level < 0 then Config.Look.BasementBulbBrightness else Config.Look.BulbBrightness
	light.Color = if level < 0 then Color3.fromRGB(190, 220, 170) else Color3.fromRGB(255, 205, 140)
	light.Shadows = false
	light.Parent = lamp
	lamp:SetAttribute("Level", level)
	CollectionService:AddTag(lamp, "Bulb")
end

function HotelBuilder.atmosphere()
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	local look = Config.Look
	Lighting.Ambient = Color3.fromRGB(look.Ambient[1], look.Ambient[2], look.Ambient[3])
	Lighting.OutdoorAmbient = Color3.fromRGB(look.OutdoorAmbient[1], look.OutdoorAmbient[2], look.OutdoorAmbient[3])
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.FogColor = Color3.fromRGB(6, 6, 12)
	Lighting.FogStart = look.FogStart
	Lighting.FogEnd = look.FogEnd
	local effects = Instance.new("Folder")
	effects.Name = "NightShiftEffects"
	effects.Parent = Lighting
	local air = Instance.new("Atmosphere")
	air.Density = look.AtmosphereDensity
	air.Color = Color3.fromRGB(40, 40, 60)
	air.Parent = effects
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Contrast = look.Contrast
	grade.Saturation = look.Saturation
	grade.Brightness = look.GradeBrightness
	grade.TintColor = Color3.fromRGB(235, 235, 255)
	grade.Parent = effects
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 20
	bloom.Threshold = 1.6
	bloom.Parent = effects
end

-- A fresh Studio place ships a Baseplate whose top is at y = 0 (the same plane as our floor tiles, so the
-- floor shimmers) and a large SpawnLocation. The hotel owns the floor and the spawn, so remove both.
function HotelBuilder.clearTemplate()
	for _, child in workspace:GetChildren() do
		local isBaseplate = child.Name == "Baseplate" and child:IsA("BasePart")
		if isBaseplate or child:IsA("SpawnLocation") then
			print(`[Hotel] removed template {child.ClassName} "{child.Name}"`)
			child:Destroy()
		end
	end
end

-- Anything else loose in the workspace can overlap the hotel and flicker; name it in the log so it is easy to find.
local function reportStrays(hotel: Instance)
	local strays = {}
	for _, child in workspace:GetChildren() do
		local known = child == hotel
			or child:IsA("Terrain")
			or child:IsA("Camera")
			or child.Name == "NightManager"
			or Players:GetPlayerFromCharacter(child) ~= nil
		if not known and (child:IsA("BasePart") or child:IsA("Model")) then
			table.insert(strays, child.Name)
		end
	end
	if #strays > 0 then
		print(`[Hotel] other things in the workspace that may overlap the hotel: {table.concat(strays, ", ")}`)
	end
end

function HotelBuilder.build(): Result
	HotelBuilder.clearTemplate()
	local folder = Instance.new("Folder")
	folder.Name = "Hotel"
	folder.Parent = workspace

	-- every wall, floor slab, trim piece, stair, rail and roof: one pass over the tested list
	local shell = Instance.new("Folder")
	shell.Name = "Shell"
	shell.Parent = folder
	for _, s in Building.solids() do
		local color, material = styleOf(s)
		local part =
			block(shell, s.kind, Vector3.new(s.w, s.h, s.d), Vector3.new(s.x, s.y + s.h / 2, s.z), color, material)
		if DECORATION[s.kind] then
			-- skirting, panelling and frames are only to look at: nothing to collide with, snag on, or cast shadows
			part.CanCollide = false
			part.CanQuery = false
			part.CastShadow = false
		end
	end

	-- ceiling lights: one per room, and along each corridor
	local lights = Instance.new("Folder")
	lights.Name = "Lights"
	lights.Parent = folder
	for _, level in Floors.levels do
		local y = Floors.y(level)
		for _, room in Floors.rooms(level) do
			local x, z = Hotel.centre(room)
			bulb(lights, x, y, z, level)
		end
		for x = -70, 70, 20 do
			bulb(lights, x, y, 0, level)
		end
	end
	for _, a in Floors.annexes do
		local x = (a.x1 + a.x2) / 2
		bulb(lights, x, 0, 0, 0)
		bulb(lights, x, if a.side < 0 then Floors.y(1) else Floors.y(-1), 0, if a.side < 0 then 1 else -1)
	end

	-- furniture
	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = folder
	local hiding: { { model: Model, position: Vector3 } } = {}
	local bell: BasePart? = nil
	for _, item in Furnishing.items() do
		local model = Props.make(props, item, Floors.y(item.level))
		if item.kind == "desk" and not bell then
			bell = model:FindFirstChild("Bell") :: BasePart? -- the reception bell: ring it to call a meeting
		end
		if Furnishing.hideable[item.kind] then
			table.insert(hiding, { model = model, position = Vector3.new(item.x, Floors.y(item.level), item.z) })
		end
	end

	local lx, lz = Hotel.spawnPoint()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(4, 0.2, 4)
	spawn.Position = Vector3.new(lx, 0.1, lz)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = folder

	local stations: { [string]: Part } = {}
	for _, task in Floors.tasks() do
		local station = block(
			folder,
			"Task_" .. task.id,
			Vector3.new(4, 5, 2.5),
			Vector3.new(task.x, Floors.y(task.level) + 2.5, task.z),
			Color3.fromRGB(230, 160, 40),
			Enum.Material.Metal
		)
		station:SetAttribute("TaskName", task.name)
		station:SetAttribute("Level", task.level)
		StationProps.dress(station, task.id, if task.z > 0 then -1 else 1)
		stations[task.id] = station
	end

	HotelBuilder.atmosphere()
	reportStrays(folder)
	return { spawn = spawn, stations = stations, hiding = hiding, bell = bell }
end

return HotelBuilder
