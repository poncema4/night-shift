--!strict
-- Hotel furniture assembled from parts, modelled on the Blender previews in art/renders. Each kind is centred on its
-- footprint (see Shared/Game/Furnishing) with the front toward +Z. Pieces touch their neighbours instead of
-- overlapping them, so no two faces share a plane.
local CollectionService = game:GetService("CollectionService")

local Furnishing = require(game:GetService("ReplicatedStorage").Shared.Game.Furnishing)

local Props = {}

local WOOD = Color3.fromRGB(58, 34, 20)
local WOOD_LIGHT = Color3.fromRGB(96, 60, 38)
local BRASS = Color3.fromRGB(190, 140, 62)
local VELVET = Color3.fromRGB(70, 10, 20)
local MARBLE = Color3.fromRGB(205, 200, 192)
local LINEN = Color3.fromRGB(196, 186, 164)
local STEEL = Color3.fromRGB(88, 96, 98)
local RUST = Color3.fromRGB(110, 62, 40)

type Make = (model: Model, at: (number, number, number) -> CFrame, item: Furnishing.Item) -> ()

local function piece(
	model: Model,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanTouch = false
	part.Parent = model
	return part
end

local function soft(part: Part)
	part.CanCollide = false
	part.CanQuery = false
end

local function glow(
	model: Model,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	range: number,
	strength: number
)
	local lamp = piece(model, name, size, cf, color, Enum.Material.Neon)
	soft(lamp)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = strength
	light.Shadows = false
	light.Parent = lamp
	CollectionService:AddTag(lamp, "Bulb") -- flickers with the hotel lights
	return lamp
end

local makers: { [string]: Make } = {}

makers.armchair = function(model, at)
	-- the footprint is 5.6 x 4.4 and the model is drawn off-centre in z, so shift it back
	local function s(x: number, y: number, z: number): CFrame
		return at(x, y, z + 0.4)
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			piece(model, "Leg", Vector3.new(0.5, 1.3, 0.5), s(sx * 1.6, 0.65, sz * 1.4), WOOD, Enum.Material.Wood)
			piece(model, "Cap", Vector3.new(0.6, 0.1, 0.6), s(sx * 1.6, 0.05, sz * 1.4), BRASS, Enum.Material.Metal)
		end
		piece(model, "Arm", Vector3.new(0.8, 2.4, 3.6), s(sx * 2.4, 2.5, 0), VELVET, Enum.Material.Fabric)
	end
	piece(model, "Seat", Vector3.new(4, 1, 3.6), s(0, 1.8, 0), VELVET, Enum.Material.Fabric)
	piece(model, "Back", Vector3.new(5.6, 3.4, 0.8), s(0, 3.0, -2.2), VELVET, Enum.Material.Fabric)
end

makers.desk = function(model, at)
	piece(model, "Plinth", Vector3.new(14.2, 0.4, 3.2), at(0, 0.2, 0), Color3.fromRGB(20, 12, 8), Enum.Material.Wood)
	piece(model, "Body", Vector3.new(14, 3.2, 3), at(0, 2.0, 0), WOOD, Enum.Material.Wood)
	piece(model, "Top", Vector3.new(14.8, 0.3, 3.8), at(0, 3.75, 0), MARBLE, Enum.Material.Marble)
	for i = 0, 5 do
		local x = -5.5 + i * 2.2
		piece(model, "PanelFrame", Vector3.new(1.9, 2.5, 0.1), at(x, 2.0, 1.55), BRASS, Enum.Material.Metal)
		piece(
			model,
			"Panel",
			Vector3.new(1.6, 2.2, 0.15),
			at(x, 2.0, 1.675),
			Color3.fromRGB(86, 52, 34),
			Enum.Material.Wood
		)
	end
	piece(model, "KickRail", Vector3.new(14, 0.2, 0.2), at(0, 0.7, 1.8), BRASS, Enum.Material.Metal)
	piece(model, "Bell", Vector3.new(0.7, 0.4, 0.7), at(-5, 4.05, 0.4), BRASS, Enum.Material.Metal)
end

makers.bed = function(model, at)
	piece(model, "Base", Vector3.new(5.8, 1.2, 6), at(0, 0.6, 0), WOOD, Enum.Material.Wood)
	piece(model, "Headboard", Vector3.new(6.2, 4.8, 0.5), at(0, 2.4, -3.25), WOOD, Enum.Material.Wood)
	piece(model, "Footboard", Vector3.new(5.8, 2.0, 0.5), at(0, 1.0, 3.25), WOOD, Enum.Material.Wood)
	piece(model, "Mattress", Vector3.new(5.4, 0.9, 5.6), at(0, 1.65, 0), LINEN, Enum.Material.Fabric)
	piece(model, "Blanket", Vector3.new(5.6, 0.4, 3.6), at(0, 2.3, 0.9), VELVET, Enum.Material.Fabric)
	for _, x in { -1.4, 1.4 } do
		piece(model, "Pillow", Vector3.new(2.2, 0.6, 1.4), at(x, 2.4, -2.2), LINEN, Enum.Material.Fabric)
	end
	for _, x in { -1.6, 0, 1.6 } do
		piece(model, "Tuft", Vector3.new(0.3, 0.3, 0.1), at(x, 3.4, -2.95), BRASS, Enum.Material.Metal)
	end
end

makers.lamp = function(model, at)
	piece(model, "Table", Vector3.new(1.6, 1.4, 1.6), at(0, 0.7, 0), WOOD, Enum.Material.Wood)
	piece(model, "Foot", Vector3.new(0.9, 0.15, 0.9), at(0, 1.475, 0), BRASS, Enum.Material.Metal)
	piece(model, "Stem", Vector3.new(0.18, 0.7, 0.18), at(0, 1.9, 0), BRASS, Enum.Material.Metal)
	glow(model, "Shade", Vector3.new(1.4, 0.9, 1.4), at(0, 2.55, 0), Color3.fromRGB(255, 200, 130), 14, 0.7)
end

makers.shelf = function(model, at)
	for _, x in { -2.9, 2.9 } do
		piece(model, "Side", Vector3.new(0.2, 8, 1.6), at(x, 4, 0), WOOD, Enum.Material.Wood)
	end
	piece(model, "Back", Vector3.new(5.6, 8, 0.15), at(0, 4, -0.725), WOOD, Enum.Material.Wood)
	local palette = {
		Color3.fromRGB(110, 30, 34),
		Color3.fromRGB(34, 62, 92),
		Color3.fromRGB(86, 70, 34),
		Color3.fromRGB(44, 74, 52),
		Color3.fromRGB(120, 100, 76),
	}
	for row = 0, 4 do
		local y = 0.3 + row * 1.7
		piece(model, "Board", Vector3.new(5.6, 0.15, 1.4), at(0, y, 0.075), WOOD_LIGHT, Enum.Material.Wood)
		if row < 4 then
			local x = -2.5
			local i = 0
			while x < 2.3 do
				local w = 0.25 + (i * 7 % 4) * 0.08
				local h = 1.0 + (i * 5 % 3) * 0.2
				piece(
					model,
					"Book",
					Vector3.new(w, h, 1.0),
					at(x + w / 2, y + 0.075 + h / 2, 0.1),
					palette[(i + row) % #palette + 1],
					Enum.Material.SmoothPlastic
				)
				x += w + 0.04
				i += 1
			end
		end
	end
end

makers.crate = function(model, at)
	piece(model, "Box", Vector3.new(3, 3, 3), at(0, 1.5, 0), Color3.fromRGB(104, 72, 44), Enum.Material.WoodPlanks)
	for _, y in { 0.45, 2.55 } do
		piece(model, "Strap", Vector3.new(3.1, 0.3, 3.1), at(0, y, 0), WOOD, Enum.Material.Wood)
	end
end

makers.locker = function(model, at)
	piece(model, "Body", Vector3.new(2, 7, 2), at(0, 3.5, 0), STEEL, Enum.Material.Metal)
	for i = 0, 2 do
		piece(
			model,
			"Vent",
			Vector3.new(1.4, 0.15, 0.06),
			at(0, 5.6 + i * 0.4, 1.03),
			Color3.fromRGB(30, 34, 36),
			Enum.Material.Metal
		)
	end
	piece(model, "Handle", Vector3.new(0.15, 0.7, 0.15), at(0.6, 3.2, 1.075), BRASS, Enum.Material.Metal)
end

makers.wardrobe = function(model, at)
	piece(model, "Body", Vector3.new(4, 7.5, 2), at(0, 3.75, 0), WOOD, Enum.Material.Wood)
	piece(model, "Crown", Vector3.new(4.3, 0.4, 2.2), at(0, 7.7, 0), WOOD_LIGHT, Enum.Material.Wood)
	for _, x in { -1, 1 } do
		piece(model, "Door", Vector3.new(1.8, 6.4, 0.1), at(x, 3.7, 1.05), WOOD_LIGHT, Enum.Material.WoodPlanks)
		piece(model, "Handle", Vector3.new(0.15, 0.8, 0.15), at(x * 0.25, 3.7, 1.15), BRASS, Enum.Material.Metal)
	end
end

makers.rack = function(model, at)
	for _, x in { -3.8, 3.8 } do
		piece(model, "Post", Vector3.new(0.3, 6, 2), at(x, 3, 0), WOOD, Enum.Material.Wood)
	end
	for row = 0, 3 do
		local y = 0.4 + row * 1.6
		piece(model, "Slat", Vector3.new(7.3, 0.15, 1.8), at(0, y, 0), WOOD_LIGHT, Enum.Material.Wood)
		for i = 0, 7 do
			piece(
				model,
				"Bottle",
				Vector3.new(0.5, 0.5, 1.5),
				at(-3.15 + i * 0.9, y + 0.325, 0),
				Color3.fromRGB(30, 60, 36),
				Enum.Material.Glass
			)
		end
	end
end

makers.furnace = function(model, at)
	piece(model, "Base", Vector3.new(6, 1, 6), at(0, 0.5, 0), STEEL, Enum.Material.Concrete)
	local drum = piece(
		model,
		"Drum",
		Vector3.new(6, 5, 5),
		at(0, 3.5, 0) * CFrame.Angles(0, 0, math.pi / 2),
		RUST,
		Enum.Material.CorrodedMetal
	)
	drum.Shape = Enum.PartType.Cylinder
	piece(model, "Pipe", Vector3.new(1, 2, 1), at(0, 7, 0), STEEL, Enum.Material.Metal)
	piece(model, "Door", Vector3.new(2.2, 2.2, 0.2), at(0, 2.4, 2.6), Color3.fromRGB(40, 36, 34), Enum.Material.Metal)
	glow(model, "Fire", Vector3.new(1.6, 1.4, 0.1), at(0, 2.4, 2.75), Color3.fromRGB(255, 120, 40), 22, 1.4)
end

makers.generator = function(model, at)
	piece(model, "Frame", Vector3.new(7, 0.5, 4), at(0, 0.25, 0), Color3.fromRGB(30, 32, 34), Enum.Material.Metal)
	piece(model, "Body", Vector3.new(6.4, 3.4, 3.4), at(0, 2.2, 0), Color3.fromRGB(52, 78, 60), Enum.Material.Metal)
	piece(model, "Exhaust", Vector3.new(0.6, 1.2, 0.6), at(2.4, 4.5, 0), STEEL, Enum.Material.Metal)
	piece(
		model,
		"Panel",
		Vector3.new(2.4, 1.4, 0.1),
		at(-1.2, 2.4, 1.75),
		Color3.fromRGB(20, 22, 24),
		Enum.Material.Metal
	)
	glow(model, "Light", Vector3.new(0.4, 0.4, 0.1), at(-2.0, 2.9, 1.85), Color3.fromRGB(80, 255, 120), 10, 0.5)
end

makers.table = function(model, at)
	piece(model, "Top", Vector3.new(14, 0.4, 6), at(0, 2.6, 0), WOOD_LIGHT, Enum.Material.Wood)
	for _, x in { -6.4, 6.4 } do
		for _, z in { -2.4, 2.4 } do
			piece(model, "Leg", Vector3.new(0.6, 2.4, 0.6), at(x, 1.2, z), WOOD, Enum.Material.Wood)
		end
	end
	piece(model, "Runner", Vector3.new(12, 0.05, 1.6), at(0, 2.825, 0), VELVET, Enum.Material.Fabric)
	for _, x in { -3.5, 0, 3.5 } do
		piece(model, "Stick", Vector3.new(0.3, 0.9, 0.3), at(x, 3.3, 0), BRASS, Enum.Material.Metal)
		local flame = piece(
			model,
			"Flame",
			Vector3.new(0.2, 0.35, 0.2),
			at(x, 3.95, 0),
			Color3.fromRGB(255, 190, 90),
			Enum.Material.Neon
		)
		soft(flame)
	end
end

makers.tub = function(model, at)
	for _, z in { -2.75, 2.75 } do
		piece(model, "Rim", Vector3.new(10, 2.5, 0.5), at(0, 1.25, z), MARBLE, Enum.Material.Marble)
	end
	for _, x in { -4.75, 4.75 } do
		piece(model, "Rim", Vector3.new(0.5, 2.5, 5), at(x, 1.25, 0), MARBLE, Enum.Material.Marble)
	end
	local water =
		piece(model, "Water", Vector3.new(9, 0.2, 5), at(0, 1.9, 0), Color3.fromRGB(70, 160, 200), Enum.Material.Glass)
	water.Transparency = 0.4
	soft(water)
end

makers.pool = function(model, at)
	local coping = Color3.fromRGB(215, 210, 200)
	for _, z in { -6.7, 6.7 } do
		piece(model, "Coping", Vector3.new(10, 0.25, 0.6), at(0, 0.125, z), coping, Enum.Material.Marble)
	end
	for _, x in { -4.7, 4.7 } do
		piece(model, "Coping", Vector3.new(0.6, 0.25, 12.8), at(x, 0.125, 0), coping, Enum.Material.Marble)
	end
	local water = piece(
		model,
		"Water",
		Vector3.new(8.8, 0.1, 12.8),
		at(0, 0.05, 0),
		Color3.fromRGB(52, 150, 200),
		Enum.Material.SmoothPlastic
	)
	water.Transparency = 0.35
	soft(water)
end

makers.water = function(model, at)
	local water =
		piece(model, "Flood", Vector3.new(20, 0.3, 10), at(0, 0.15, 0), Color3.fromRGB(26, 60, 62), Enum.Material.Glass)
	water.Transparency = 0.45
	soft(water)
end

makers.car = function(model, at)
	piece(model, "Chassis", Vector3.new(6.4, 1.4, 13.2), at(0, 1.1, 0), Color3.fromRGB(46, 22, 24), Enum.Material.Metal)
	piece(model, "Hood", Vector3.new(6, 0.4, 4), at(0, 2.0, 4.4), Color3.fromRGB(52, 26, 28), Enum.Material.Metal)
	local cabin = piece(
		model,
		"Cabin",
		Vector3.new(5.4, 1.5, 6),
		at(0, 2.55, -1),
		Color3.fromRGB(28, 38, 46),
		Enum.Material.Glass
	)
	cabin.Transparency = 0.3
	piece(model, "Roof", Vector3.new(5.4, 0.2, 6), at(0, 3.4, -1), Color3.fromRGB(46, 22, 24), Enum.Material.Metal)
	for _, x in { -3.3, 3.3 } do
		for _, z in { -4.2, 4.2 } do
			local wheel = piece(
				model,
				"Wheel",
				Vector3.new(0.8, 1.6, 1.6),
				at(x, 0.8, z),
				Color3.fromRGB(14, 14, 16),
				Enum.Material.SmoothPlastic
			)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	for _, x in { -2, 2 } do
		local light = piece(
			model,
			"Headlight",
			Vector3.new(1, 0.5, 0.1),
			at(x, 1.5, 6.65),
			Color3.fromRGB(255, 240, 200),
			Enum.Material.Neon
		)
		soft(light)
	end
end

-- Hanging chandelier: stem, brass hub, eight arms each ending in a candle with a glowing flame.
makers.chandelier = function(model, at, item)
	local top = Furnishing.ceiling :: number
	local hubY = top - 5
	local function hung(x: number, y: number, z: number): CFrame
		return at(x, y, z)
	end
	piece(model, "Stem", Vector3.new(0.3, 3.6, 0.3), hung(0, top - 1.8, 0), BRASS, Enum.Material.Metal)
	local hub = piece(model, "Hub", Vector3.new(1.2, 1.2, 1.2), hung(0, hubY, 0), BRASS, Enum.Material.Metal)
	hub.Shape = Enum.PartType.Ball
	for i = 0, 7 do
		local spin = hung(0, hubY, 0) * CFrame.Angles(0, i * math.pi / 4, 0)
		piece(model, "Arm", Vector3.new(0.2, 0.2, 3), spin * CFrame.new(0, 0, -2.1), BRASS, Enum.Material.Metal)
		piece(
			model,
			"Candle",
			Vector3.new(0.35, 0.9, 0.35),
			spin * CFrame.new(0, 0.55, -3.6),
			Color3.fromRGB(230, 222, 196),
			Enum.Material.SmoothPlastic
		)
		local flame = piece(
			model,
			"Flame",
			Vector3.new(0.25, 0.4, 0.25),
			spin * CFrame.new(0, 1.2, -3.6),
			Color3.fromRGB(255, 190, 90),
			Enum.Material.Neon
		)
		soft(flame)
		piece(
			model,
			"Drop",
			Vector3.new(0.3, 0.8, 0.3),
			spin * CFrame.new(0, -0.4, -3.6),
			Color3.fromRGB(210, 230, 255),
			Enum.Material.Glass
		)
	end
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
	local _ = item
end

-- Builds one item standing on a floor at world height `floorY`.
function Props.make(parent: Instance, item: Furnishing.Item, floorY: number): Model
	local model = Instance.new("Model")
	model.Name = item.kind
	local base = CFrame.new(item.x, floorY, item.z) * CFrame.Angles(0, math.rad(item.yaw), 0)
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z)
	end
	local make = makers[item.kind]
	if make then
		make(model, at, item)
	else
		warn(`[Props] no model for {item.kind}`)
	end
	model.Parent = parent
	return model
end

return Props
