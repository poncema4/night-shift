--!strict
-- What each task station looks like. The station Part itself stays an invisible, solid hit box (the prompt and the
-- task rules live on it); everything here is decoration inside that 4 x 5 x 2.5 box, with a status lamp that
-- turns green when TaskService marks the task done (it changes the hit box's Color).
local StationProps = {}

local STEEL = Color3.fromRGB(70, 76, 80)
local WOOD = Color3.fromRGB(70, 42, 26)
local BRASS = Color3.fromRGB(190, 140, 62)
local AMBER = Color3.fromRGB(255, 170, 40)
local DONE = Color3.fromRGB(70, 200, 110)

type Builder = (
	put: (name: string, size: Vector3, x: number, y: number, z: number, color: Color3, material: Enum.Material) -> Part
) -> ()

-- x across the front, y up from the floor, z toward the room (positive = front).
local builders: { [string]: Builder } = {
	breaker = function(put)
		put("Cabinet", Vector3.new(3.4, 4.2, 1.6), 0, 2.1, -0.3, STEEL, Enum.Material.Metal)
		put("Door", Vector3.new(3.0, 3.6, 0.1), 0, 2.4, 0.55, Color3.fromRGB(52, 58, 62), Enum.Material.Metal)
		for i = -1, 1 do
			put(
				"Switch",
				Vector3.new(0.35, 0.9, 0.3),
				i * 0.9,
				2.9,
				0.7,
				Color3.fromRGB(230, 230, 230),
				Enum.Material.SmoothPlastic
			)
		end
		put(
			"Lever",
			Vector3.new(0.3, 1.6, 0.3),
			0.9,
			1.4,
			0.75,
			Color3.fromRGB(190, 40, 40),
			Enum.Material.SmoothPlastic
		)
	end,
	minibar = function(put)
		put("Cabinet", Vector3.new(3.4, 3.4, 2.0), 0, 1.7, 0, WOOD, Enum.Material.Wood)
		put("Glass", Vector3.new(2.6, 2.2, 0.1), 0, 1.9, 1.05, Color3.fromRGB(120, 190, 220), Enum.Material.Glass)
		put("Strip", Vector3.new(2.6, 0.12, 0.1), 0, 3.05, 1.08, Color3.fromRGB(120, 220, 255), Enum.Material.Neon)
		put("Top", Vector3.new(3.6, 0.25, 2.2), 0, 3.5, 0, BRASS, Enum.Material.Metal)
	end,
	linens = function(put)
		put("Basket", Vector3.new(3.2, 2.2, 2.0), 0, 1.9, 0, Color3.fromRGB(150, 140, 120), Enum.Material.Fabric)
		put("Pile", Vector3.new(2.8, 0.9, 1.6), 0, 3.4, 0, Color3.fromRGB(225, 220, 205), Enum.Material.Fabric)
		for _, x in { -1.4, 1.4 } do
			put(
				"Wheel",
				Vector3.new(0.5, 0.5, 0.5),
				x,
				0.35,
				0,
				Color3.fromRGB(20, 20, 22),
				Enum.Material.SmoothPlastic
			)
		end
	end,
	cameras = function(put)
		put("Desk", Vector3.new(3.6, 0.3, 2.0), 0, 2.4, 0, WOOD, Enum.Material.Wood)
		for _, x in { -1.4, 1.4 } do
			put("Leg", Vector3.new(0.4, 2.25, 1.6), x, 1.1, 0, STEEL, Enum.Material.Metal)
		end
		for i = -1, 1 do
			put(
				"Monitor",
				Vector3.new(1.0, 0.8, 0.15),
				i * 1.1,
				3.4,
				0.2,
				Color3.fromRGB(14, 18, 20),
				Enum.Material.SmoothPlastic
			)
			put(
				"Screen",
				Vector3.new(0.85, 0.65, 0.05),
				i * 1.1,
				3.4,
				0.3,
				Color3.fromRGB(80, 220, 200),
				Enum.Material.Neon
			)
		end
	end,
	clock = function(put)
		put("Case", Vector3.new(2.4, 4.8, 1.6), 0, 2.4, -0.3, WOOD, Enum.Material.Wood)
		put("Face", Vector3.new(1.5, 1.5, 0.1), 0, 3.8, 0.55, Color3.fromRGB(235, 225, 195), Enum.Material.Neon)
		put("Pendulum", Vector3.new(0.2, 1.6, 0.1), 0, 1.6, 0.55, BRASS, Enum.Material.Metal)
		put("Weight", Vector3.new(0.7, 0.7, 0.1), 0, 0.9, 0.55, BRASS, Enum.Material.Metal)
	end,
	chlorine = function(put)
		for _, x in { -0.9, 0.9 } do
			local barrel =
				put("Barrel", Vector3.new(2.8, 1.9, 1.9), x, 1.4, 0, Color3.fromRGB(215, 190, 40), Enum.Material.Metal)
			barrel.Shape = Enum.PartType.Cylinder
			barrel.CFrame = barrel.CFrame * CFrame.Angles(0, 0, math.pi / 2)
			put(
				"Label",
				Vector3.new(0.9, 0.6, 0.05),
				x,
				1.6,
				0.97,
				Color3.fromRGB(30, 30, 30),
				Enum.Material.SmoothPlastic
			)
		end
	end,
	elevator = function(put)
		put("Plate", Vector3.new(2.2, 3.6, 0.3), 0, 2.4, -0.4, BRASS, Enum.Material.Metal)
		put("Panel", Vector3.new(1.6, 2.6, 0.1), 0, 2.4, -0.2, Color3.fromRGB(24, 22, 26), Enum.Material.SmoothPlastic)
		for i = 0, 2 do
			put(
				"Button",
				Vector3.new(0.45, 0.45, 0.1),
				0,
				3.2 - i * 0.7,
				-0.1,
				Color3.fromRGB(255, 220, 140),
				Enum.Material.Neon
			)
		end
	end,
	bed204 = function(put)
		put("Cart", Vector3.new(3.2, 0.3, 1.8), 0, 2.2, 0, BRASS, Enum.Material.Metal)
		for _, x in { -1.4, 1.4 } do
			put("Leg", Vector3.new(0.25, 2.1, 0.25), x, 1.05, 0, BRASS, Enum.Material.Metal)
		end
		put("Linen", Vector3.new(2.2, 0.5, 1.2), -0.4, 2.65, 0, Color3.fromRGB(225, 220, 205), Enum.Material.Fabric)
		put(
			"Chocolate",
			Vector3.new(0.5, 0.15, 0.3),
			1.0,
			2.5,
			0.1,
			Color3.fromRGB(70, 36, 20),
			Enum.Material.SmoothPlastic
		)
	end,
	spa = function(put)
		put("Pipe", Vector3.new(0.5, 3.4, 0.5), -1.2, 1.7, 0, Color3.fromRGB(150, 110, 60), Enum.Material.Metal)
		put("Pipe", Vector3.new(3.0, 0.5, 0.5), 0, 3.2, 0, Color3.fromRGB(150, 110, 60), Enum.Material.Metal)
		local wheel =
			put("Wheel", Vector3.new(0.3, 1.8, 1.8), 0.8, 3.2, 0.5, Color3.fromRGB(190, 50, 50), Enum.Material.Metal)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.CFrame = wheel.CFrame * CFrame.Angles(0, math.pi / 2, 0)
	end,
	generator = function(put)
		put("Box", Vector3.new(3.4, 2.4, 1.8), 0, 1.2, 0, Color3.fromRGB(52, 78, 60), Enum.Material.Metal)
		put("Crank", Vector3.new(0.3, 0.3, 1.4), 1.2, 2.4, 1.0, STEEL, Enum.Material.Metal)
		put(
			"Handle",
			Vector3.new(0.3, 1.0, 0.3),
			1.2,
			2.9,
			1.7,
			Color3.fromRGB(190, 40, 40),
			Enum.Material.SmoothPlastic
		)
	end,
	valve = function(put)
		put("Pipe", Vector3.new(0.6, 4.2, 0.6), 0, 2.1, -0.2, Color3.fromRGB(150, 150, 154), Enum.Material.Metal)
		local wheel =
			put("Wheel", Vector3.new(0.3, 2.2, 2.2), 0, 2.6, 0.6, Color3.fromRGB(200, 40, 40), Enum.Material.Metal)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.CFrame = wheel.CFrame * CFrame.Angles(0, math.pi / 2, 0)
	end,
	fuse = function(put)
		put("Box", Vector3.new(3.0, 3.4, 1.0), 0, 2.4, -0.5, STEEL, Enum.Material.Metal)
		put("Door", Vector3.new(2.8, 3.2, 0.1), 0, 2.4, 0.05, Color3.fromRGB(44, 48, 52), Enum.Material.Metal)
		for i = -1, 1 do
			put("Fuse", Vector3.new(0.4, 1.2, 0.2), i * 0.8, 2.4, 0.2, Color3.fromRGB(255, 130, 30), Enum.Material.Neon)
		end
	end,
}

-- Dresses `station` (the invisible hit box) for the task `id`. `faceZ` is +1 when the room is toward +z, else -1.
function StationProps.dress(station: Part, id: string, faceZ: number)
	local build = builders[id]
	if not build then
		return -- unknown task: keep the plain box visible
	end
	station.Transparency = 1
	local model = Instance.new("Model")
	model.Name = "Station_" .. id
	local base = CFrame.new(station.Position.X, station.Position.Y - 2.5, station.Position.Z)
		* CFrame.Angles(0, if faceZ > 0 then 0 else math.pi, 0)
	local function put(
		name: string,
		size: Vector3,
		x: number,
		y: number,
		z: number,
		color: Color3,
		material: Enum.Material
	): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Size = size
		p.CFrame = base * CFrame.new(x, y, z)
		p.Color = color
		p.Material = material
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	build(put)
	local status = put("Status", Vector3.new(0.6, 0.6, 0.3), 0, 4.7, 1.0, AMBER, Enum.Material.Neon)
	status.Shape = Enum.PartType.Ball
	model.Parent = station
	-- TaskService recolours the hit box when the task is done; mirror that on the status lamp
	local function refresh()
		local done = station.Color == DONE
		status.Color = if done then DONE else AMBER
	end
	station:GetPropertyChangedSignal("Color"):Connect(refresh)
	refresh()
end

return StationProps
