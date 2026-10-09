--!strict
-- The lobby room: a small, dim waiting hall where parties form. Plain geometry (a floor, four walls, a ceiling, a few
-- warm lamps, a reception desk and a bell); the party screen itself is client UI.
local HotelBuilder = require(script.Parent.HotelBuilder)

local LobbyBuilder = {}

local WIDTH, DEPTH, HEIGHT = 60, 44, 16

function LobbyBuilder.build(): SpawnLocation
	HotelBuilder.clearTemplate()
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	folder.Parent = workspace
	local block = HotelBuilder.block
	local wall = Color3.fromRGB(58, 44, 52)
	local wood = Color3.fromRGB(70, 44, 30)

	block(
		folder,
		"Floor",
		Vector3.new(WIDTH, 1, DEPTH),
		Vector3.new(0, -0.5, 0),
		Color3.fromRGB(54, 48, 50),
		Enum.Material.Marble
	)
	block(
		folder,
		"Ceiling",
		Vector3.new(WIDTH, 1, DEPTH),
		Vector3.new(0, HEIGHT + 0.5, 0),
		Color3.fromRGB(30, 26, 32),
		Enum.Material.SmoothPlastic
	)
	for _, z in { -DEPTH / 2, DEPTH / 2 } do
		block(
			folder,
			"Wall",
			Vector3.new(WIDTH, HEIGHT, 1),
			Vector3.new(0, HEIGHT / 2, z),
			wall,
			Enum.Material.SmoothPlastic
		)
	end
	for _, x in { -WIDTH / 2, WIDTH / 2 } do
		block(
			folder,
			"Wall",
			Vector3.new(1, HEIGHT, DEPTH),
			Vector3.new(x, HEIGHT / 2, 0),
			wall,
			Enum.Material.SmoothPlastic
		)
	end
	-- reception desk with a brass bell: the only thing in the room that is not dark
	block(folder, "Desk", Vector3.new(14, 3.6, 4), Vector3.new(0, 1.8, -DEPTH / 2 + 5), wood, Enum.Material.Wood)
	local bell = block(
		folder,
		"Bell",
		Vector3.new(1.2, 0.8, 1.2),
		Vector3.new(0, 4, -DEPTH / 2 + 5),
		Color3.fromRGB(214, 170, 80),
		Enum.Material.Metal
	)
	bell.CanCollide = false
	for _, x in { -20, 0, 20 } do
		local lamp = block(
			folder,
			"Lamp",
			Vector3.new(3, 0.4, 3),
			Vector3.new(x, HEIGHT - 0.3, 0),
			Color3.fromRGB(255, 214, 150),
			Enum.Material.Neon
		)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 28
		light.Brightness = 0.7
		light.Color = Color3.fromRGB(255, 205, 140)
		light.Shadows = false
		light.Parent = lamp
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(12, 0.2, 8)
	spawn.Position = Vector3.new(0, 0.1, 8)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = folder

	HotelBuilder.atmosphere()
	return spawn
end

return LobbyBuilder
