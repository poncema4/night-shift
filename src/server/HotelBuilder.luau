--!strict
-- Builds the hotel from the pure layout in Shared/Game/Hotel. Greybox now; Blender models replace props later.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hotel = require(ReplicatedStorage.Shared.Game.Hotel)

local HotelBuilder = {}

export type Result = { spawn: SpawnLocation, stations: { [string]: Part } }

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
	part.Parent = parent
	return part
end

local function bulb(parent: Instance, x: number, z: number)
	local lamp = block(
		parent,
		"Bulb",
		Vector3.new(3, 0.4, 3),
		Vector3.new(x, Hotel.CEILING - 0.3, z),
		Color3.fromRGB(255, 214, 150),
		Enum.Material.Neon
	)
	lamp.CanCollide = false
	local light = Instance.new("PointLight")
	light.Range = 30
	light.Brightness = 1.1
	light.Color = Color3.fromRGB(255, 205, 140)
	light.Shadows = false
	light.Parent = lamp
	CollectionService:AddTag(lamp, "Bulb")
end

local function atmosphere()
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	Lighting.Ambient = Color3.fromRGB(26, 26, 38)
	Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 30)
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.FogColor = Color3.fromRGB(6, 6, 12)
	Lighting.FogStart = 20
	Lighting.FogEnd = 160
	local effects = Instance.new("Folder")
	effects.Name = "NightShiftEffects"
	effects.Parent = Lighting
	local air = Instance.new("Atmosphere")
	air.Density = 0.3
	air.Color = Color3.fromRGB(40, 40, 60)
	air.Parent = effects
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Contrast = 0.12
	grade.Saturation = -0.15
	grade.TintColor = Color3.fromRGB(235, 235, 255)
	grade.Parent = effects
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 20
	bloom.Threshold = 1.6
	bloom.Parent = effects
end

function HotelBuilder.build(): Result
	local folder = Instance.new("Folder")
	folder.Name = "Hotel"
	folder.Parent = workspace
	local c = Hotel.CORRIDOR
	local width, depth = c.x2 - c.x1 + Hotel.WALL, 50 + Hotel.WALL

	block(
		folder,
		"Floor",
		Vector3.new(width, 1, depth),
		Vector3.new(0, -0.5, 0),
		Color3.fromRGB(58, 40, 34),
		Enum.Material.WoodPlanks
	)
	block(
		folder,
		"Carpet",
		Vector3.new(c.x2 - c.x1, 0.1, c.z2 - c.z1),
		Vector3.new(0, 0.05, 0),
		Color3.fromRGB(110, 24, 38),
		Enum.Material.Fabric
	)
	block(
		folder,
		"Ceiling",
		Vector3.new(width, 1, depth),
		Vector3.new(0, Hotel.CEILING + 0.5, 0),
		Color3.fromRGB(34, 32, 40),
		Enum.Material.Concrete
	)
	for _, box in Hotel.wallBoxes() do
		block(
			folder,
			"Wall",
			Vector3.new(box.w, Hotel.CEILING, box.d),
			Vector3.new(box.x, Hotel.CEILING / 2, box.z),
			Color3.fromRGB(78, 74, 88),
			Enum.Material.Concrete
		)
	end

	for _, room in Hotel.rooms do
		local x, z = Hotel.centre(room)
		bulb(folder, x, z)
	end
	for x = -50, 50, 20 do
		bulb(folder, x, 0)
	end

	-- props
	local lx = Hotel.centre(Hotel.room("Lobby"))
	block(
		folder,
		"ReceptionDesk",
		Vector3.new(14, 4, 3),
		Vector3.new(lx, 2, -22),
		Color3.fromRGB(70, 46, 30),
		Enum.Material.Wood
	)
	local px, pz = Hotel.centre(Hotel.room("Pool Room"))
	local water = block(
		folder,
		"Pool",
		Vector3.new(20, 0.3, 12),
		Vector3.new(px, 0.2, pz),
		Color3.fromRGB(40, 150, 220),
		Enum.Material.Neon
	)
	water.Transparency = 0.45
	water.CanCollide = false
	local bx, bz = Hotel.centre(Hotel.room("Ballroom"))
	block(
		folder,
		"BallroomTable",
		Vector3.new(14, 3, 6),
		Vector3.new(bx, 1.5, bz + 2),
		Color3.fromRGB(92, 60, 40),
		Enum.Material.Wood
	)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(lx, 0.5, -14)
	spawn.Transparency = 1
	spawn.Parent = folder

	local stations: { [string]: Part } = {}
	for _, task in Hotel.tasks do
		local station = block(
			folder,
			"Task_" .. task.id,
			Vector3.new(4, 5, 2.5),
			Vector3.new(task.x, 2.5, task.z),
			Color3.fromRGB(230, 160, 40),
			Enum.Material.Metal
		)
		station:SetAttribute("TaskName", task.name)
		stations[task.id] = station
	end

	atmosphere()
	return { spawn = spawn, stations = stations }
end

return HotelBuilder
