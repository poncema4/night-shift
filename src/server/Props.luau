--!strict
-- Hotel furniture assembled from parts, modelled on the Blender previews in art/renders.
-- Every piece touches its neighbours instead of overlapping them, so no two faces share a plane.
local Props = {}

local WOOD = Color3.fromRGB(58, 34, 20)
local BRASS = Color3.fromRGB(190, 140, 62)
local VELVET = Color3.fromRGB(70, 10, 20)
local MARBLE = Color3.fromRGB(205, 200, 192)

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
	part.Parent = model
	return part
end

-- Faces +Z at the given position (floor level).
function Props.armchair(parent: Instance, position: Vector3, yaw: number)
	local model = Instance.new("Model")
	model.Name = "Armchair"
	local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z)
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			piece(model, "Leg", Vector3.new(0.5, 1.3, 0.5), at(sx * 1.6, 0.65, sz * 1.4), WOOD, Enum.Material.Wood)
			piece(model, "Cap", Vector3.new(0.6, 0.1, 0.6), at(sx * 1.6, 0.05, sz * 1.4), BRASS, Enum.Material.Metal)
		end
		piece(model, "Arm", Vector3.new(0.8, 2.4, 3.6), at(sx * 2.4, 2.5, 0), VELVET, Enum.Material.Fabric)
	end
	piece(model, "Seat", Vector3.new(4, 1, 3.6), at(0, 1.8, 0), VELVET, Enum.Material.Fabric)
	piece(model, "Back", Vector3.new(5.6, 3.4, 0.8), at(0, 3.0, -2.2), VELVET, Enum.Material.Fabric)
	model.Parent = parent
	return model
end

-- Long reception counter: panelled front, marble top, brass kick rail. Front faces +Z.
function Props.desk(parent: Instance, position: Vector3)
	local model = Instance.new("Model")
	model.Name = "ReceptionDesk"
	local function at(x: number, y: number, z: number): CFrame
		return CFrame.new(position + Vector3.new(x, y, z))
	end
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
	model.Parent = parent
	return model
end

-- Hanging chandelier: stem, brass hub, eight arms each ending in a candle with a glowing flame.
function Props.chandelier(parent: Instance, x: number, z: number, ceiling: number)
	local model = Instance.new("Model")
	model.Name = "Chandelier"
	local hubY = ceiling - 5
	piece(model, "Stem", Vector3.new(0.3, 3.6, 0.3), CFrame.new(x, ceiling - 1.8, z), BRASS, Enum.Material.Metal)
	local hub = piece(model, "Hub", Vector3.new(1.2, 1.2, 1.2), CFrame.new(x, hubY, z), BRASS, Enum.Material.Metal)
	hub.Shape = Enum.PartType.Ball
	for i = 0, 7 do
		local angle = i * math.pi / 4
		local spin = CFrame.new(x, hubY, z) * CFrame.Angles(0, angle, 0)
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
		flame.CanCollide = false
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
		if part:IsA("BasePart") and part.Name ~= "Stem" then
			part.CanCollide = false
		end
	end
	model.Parent = parent
	return model
end

return Props
