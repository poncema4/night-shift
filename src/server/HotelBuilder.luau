--!strict
-- Builds the hotel from the pure layout in Shared/Game/Hotel and Shared/Game/Dressing.
-- Blender meshes replace the part-built props once they are imported (see art/README.md).
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dressing = require(ReplicatedStorage.Shared.Game.Dressing)
local Hotel = require(ReplicatedStorage.Shared.Game.Hotel)
local Props = require(script.Parent.Props)

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

-- A fresh Studio place ships a Baseplate whose top is at y = 0 (the same plane as our floor tiles, so the
-- floor shimmers) and a large SpawnLocation. The hotel owns the floor and the spawn, so remove both.
local function clearTemplate()
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
	clearTemplate()
	local folder = Instance.new("Folder")
	folder.Name = "Hotel"
	folder.Parent = workspace
	local c = Hotel.CORRIDOR
	local width, depth = c.x2 - c.x1 + Hotel.WALL, 50 + Hotel.WALL

	local WALL_COLOR = Color3.fromRGB(70, 52, 62)
	local TRIM_COLORS: { [string]: { Color3 } } = {
		skirting = { Color3.fromRGB(34, 22, 16), Enum.Material.Wood :: any },
		wainscot = { Color3.fromRGB(62, 38, 28), Enum.Material.WoodPlanks :: any },
		rail = { Color3.fromRGB(150, 108, 58), Enum.Material.Wood :: any },
		cornice = { Color3.fromRGB(170, 152, 120), Enum.Material.SmoothPlastic :: any },
		frame = { Color3.fromRGB(120, 82, 46), Enum.Material.Wood :: any },
		header = { WALL_COLOR, Enum.Material.SmoothPlastic :: any },
	}
	local FLOORS: { [string]: { Color3 } } = {
		Lobby = { Color3.fromRGB(78, 72, 74), Enum.Material.Marble :: any },
		Office = { Color3.fromRGB(44, 62, 52), Enum.Material.Fabric :: any },
		Ballroom = { Color3.fromRGB(96, 62, 40), Enum.Material.WoodPlanks :: any },
		["Pool Room"] = { Color3.fromRGB(40, 92, 118), Enum.Material.Slate :: any },
		Kitchen = { Color3.fromRGB(150, 150, 146), Enum.Material.Slate :: any },
		Pantry = { Color3.fromRGB(110, 100, 86), Enum.Material.Slate :: any },
		["Boiler Room"] = { Color3.fromRGB(62, 62, 66), Enum.Material.Concrete :: any },
		Laundry = { Color3.fromRGB(98, 104, 112), Enum.Material.Slate :: any },
		Storage = { Color3.fromRGB(72, 64, 56), Enum.Material.WoodPlanks :: any },
		Security = { Color3.fromRGB(46, 52, 68), Enum.Material.Fabric :: any },
	}

	-- Floor: one dark base slab under flush tiles. Tiles share edges but never overlap, so nothing z-fights.
	block(
		folder,
		"Base",
		Vector3.new(width, 1, depth),
		Vector3.new(0, -1.5, 0),
		Color3.fromRGB(20, 16, 16),
		Enum.Material.Concrete
	)
	for _, room in Hotel.rooms do
		local rx, rz = Hotel.centre(room)
		local style = FLOORS[room.name]
		block(
			folder,
			"Floor_" .. room.name,
			Vector3.new(room.x2 - room.x1, 1, room.z2 - room.z1),
			Vector3.new(rx, -0.5, rz),
			style[1],
			style[2] :: any
		)
	end
	block(
		folder,
		"Floor_Corridor",
		Vector3.new(c.x2 - c.x1, 1, c.z2 - c.z1),
		Vector3.new(0, -0.5, 0),
		Color3.fromRGB(104, 22, 36),
		Enum.Material.Fabric
	)
	block(
		folder,
		"Runner",
		Vector3.new(c.x2 - c.x1 - 4, 0.04, 4),
		Vector3.new(0, 0.02, 0),
		Color3.fromRGB(74, 14, 26),
		Enum.Material.Fabric
	)
	for _, side in { -1, 1 } do
		block(
			folder,
			"RunnerEdge",
			Vector3.new(c.x2 - c.x1 - 4, 0.02, 0.25),
			Vector3.new(0, 0.05, side * 1.9),
			Color3.fromRGB(190, 150, 70),
			Enum.Material.Fabric
		)
	end

	block(
		folder,
		"Ceiling",
		Vector3.new(width, 1, depth),
		Vector3.new(0, Hotel.CEILING + 0.5, 0),
		Color3.fromRGB(34, 30, 38),
		Enum.Material.SmoothPlastic
	)
	for _, box in Hotel.wallBoxes() do
		block(
			folder,
			"Wall",
			Vector3.new(box.w, Hotel.CEILING, box.d),
			Vector3.new(box.x, Hotel.CEILING / 2, box.z),
			WALL_COLOR,
			Enum.Material.SmoothPlastic
		)
	end
	local function slab(s: Dressing.Slab)
		local style = TRIM_COLORS[s.kind]
		block(
			folder,
			s.kind,
			Vector3.new(s.w, s.h, s.d),
			Vector3.new(s.x, s.y + s.h / 2, s.z),
			style[1],
			style[2] :: any
		)
	end
	for _, list in { Dressing.headers(), Dressing.frames(), Dressing.trim() } do
		for _, s in list do
			slab(s)
		end
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
	Props.desk(folder, Vector3.new(lx, 0, -22))
	Props.armchair(folder, Vector3.new(lx - 9, 0, -10), math.rad(20))
	Props.armchair(folder, Vector3.new(lx + 9, 0, -10), math.rad(-20))
	Props.chandelier(folder, lx, -15, Hotel.CEILING)
	local px, pz = Hotel.centre(Hotel.room("Pool Room"))
	pz = -13
	local water = block(
		folder,
		"Pool",
		Vector3.new(20, 0.1, 10),
		Vector3.new(px, 0.05, pz),
		Color3.fromRGB(52, 150, 200),
		Enum.Material.SmoothPlastic
	)
	water.Transparency = 0.35
	water.CanCollide = false
	local coping = Color3.fromRGB(215, 210, 200)
	for _, side in { -1, 1 } do
		block(
			folder,
			"Coping",
			Vector3.new(21.2, 0.25, 0.6),
			Vector3.new(px, 0.125, pz + side * 5.3),
			coping,
			Enum.Material.Marble
		)
		block(
			folder,
			"Coping",
			Vector3.new(0.6, 0.25, 10),
			Vector3.new(px + side * 10.3, 0.125, pz),
			coping,
			Enum.Material.Marble
		)
	end
	local bx, bz = Hotel.centre(Hotel.room("Ballroom"))
	block(
		folder,
		"BallroomTable",
		Vector3.new(13, 2.6, 5),
		Vector3.new(bx, 1.3, bz + 2),
		Color3.fromRGB(70, 42, 28),
		Enum.Material.Wood
	)
	block(
		folder,
		"BallroomTableTop",
		Vector3.new(14, 0.4, 6),
		Vector3.new(bx, 2.8, bz + 2),
		Color3.fromRGB(96, 60, 38),
		Enum.Material.Wood
	)
	Props.chandelier(folder, bx - 8, bz + 2, Hotel.CEILING)
	Props.chandelier(folder, bx + 8, bz + 2, Hotel.CEILING)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(4, 0.2, 4)
	spawn.Position = Vector3.new(lx, 0.1, -14)
	spawn.Transparency = 1
	spawn.CanCollide = false
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
	reportStrays(folder)
	return { spawn = spawn, stations = stations }
end

return HotelBuilder
