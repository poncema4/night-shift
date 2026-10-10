--!strict
-- The lobby room: a dim waiting hall with flickering lamps, a reception desk and bell, and a row of queue pods (round pads).
-- Plain geometry; the pods' behaviour is in LobbyService and the party screen is client UI.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Pods = require(ReplicatedStorage.Shared.Game.Pods)
local HotelBuilder = require(script.Parent.HotelBuilder)

local LobbyBuilder = {}

export type PodView = { status: TextLabel, ring: Part, gate: Part }

local WIDTH, DEPTH, HEIGHT = 130, 60, 18

function LobbyBuilder.layout(): { Pods.Pod }
	return Pods.layout(0, Config.Lobby.PodZ, Config.Lobby.PodSpacing)
end

-- A square cell: a dark pad with a glowing frame, glass walls on three sides, and a gate across the front that shuts when
-- the party inside is full. (Players who are queued cannot walk out: LobbyService puts them back until they press Leave.)
local function buildPod(folder: Folder, pod: Pods.Pod): PodView
	local model = Instance.new("Model")
	model.Name = `Pod_{pod.id}`
	model.Parent = folder
	local block = HotelBuilder.block
	local side = pod.half * 2
	block(
		model,
		"Pad",
		Vector3.new(side, 0.4, side),
		Vector3.new(pod.x, 0.2, pod.z),
		Color3.fromRGB(24, 22, 30),
		Enum.Material.Metal
	)
	local ring = block(
		model,
		"Ring",
		Vector3.new(side - 0.6, 0.1, side - 0.6),
		Vector3.new(pod.x, 0.45, pod.z),
		Color3.fromRGB(255, 190, 90),
		Enum.Material.Neon
	)
	ring.CanCollide = false
	block(
		model,
		"Inner",
		Vector3.new(side - 1.4, 0.12, side - 1.4),
		Vector3.new(pod.x, 0.5, pod.z),
		Color3.fromRGB(12, 11, 16),
		Enum.Material.SmoothPlastic
	).CanCollide =
		false
	local glass = Color3.fromRGB(120, 150, 190)
	local function wall(name: string, size: Vector3, position: Vector3): Part
		local part = block(model, name, size, position, glass, Enum.Material.Glass)
		part.Transparency = 0.65
		return part
	end
	local wallHeight = 9
	wall("WallBack", Vector3.new(side, wallHeight, 0.4), Vector3.new(pod.x, wallHeight / 2, pod.z + pod.half))
	wall("WallLeft", Vector3.new(0.4, wallHeight, side), Vector3.new(pod.x - pod.half, wallHeight / 2, pod.z))
	wall("WallRight", Vector3.new(0.4, wallHeight, side), Vector3.new(pod.x + pod.half, wallHeight / 2, pod.z))
	-- the front (toward the spawn, -z) is the doorway; its gate only blocks when the cell is full
	local gate = wall("Gate", Vector3.new(side, wallHeight, 0.4), Vector3.new(pod.x, wallHeight / 2, pod.z - pod.half))
	gate.CanCollide = false
	gate.Transparency = 1
	-- the sign hangs over the back wall, facing the doorway
	local sign = block(
		model,
		"Sign",
		Vector3.new(side, 3.2, 0.3),
		Vector3.new(pod.x, wallHeight + 2.2, pod.z + pod.half),
		Color3.fromRGB(10, 9, 14),
		Enum.Material.SmoothPlastic
	)
	sign.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = sign
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.45)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(236, 232, 242)
	title.Text = pod.label
	title.Parent = gui
	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Position = UDim2.fromScale(0, 0.45)
	status.Size = UDim2.fromScale(1, 0.5)
	status.Font = Enum.Font.GothamMedium
	status.TextScaled = true
	status.TextColor3 = Color3.fromRGB(255, 190, 90)
	status.Text = "STEP IN TO START A PARTY"
	status.Parent = gui
	for _, label in { title, status } do
		local constraint = Instance.new("UITextSizeConstraint")
		constraint.MaxTextSize = 120
		constraint.Parent = label
	end
	return { status = status, ring = ring, gate = gate }
end

function LobbyBuilder.build(): (SpawnLocation, { [number]: PodView })
	HotelBuilder.clearTemplate()
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	folder.Parent = workspace
	local block = HotelBuilder.block
	local wall = Color3.fromRGB(46, 36, 44)
	local wood = Color3.fromRGB(70, 44, 30)

	block(
		folder,
		"Floor",
		Vector3.new(WIDTH, 1, DEPTH),
		Vector3.new(0, -0.5, 0),
		Color3.fromRGB(40, 36, 40),
		Enum.Material.Marble
	)
	block(
		folder,
		"Ceiling",
		Vector3.new(WIDTH, 1, DEPTH),
		Vector3.new(0, HEIGHT + 0.5, 0),
		Color3.fromRGB(22, 19, 26),
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
	-- ceiling lamps: the client flickers these (client/LobbyFx), each on its own broken rhythm
	for _, x in { -52, -26, 0, 26, 52 } do
		for _, z in { -14, 6, 24 } do
			local lamp = block(
				folder,
				"Lamp",
				Vector3.new(3, 0.4, 3),
				Vector3.new(x, HEIGHT - 0.3, z),
				Color3.fromRGB(255, 214, 150),
				Enum.Material.Neon
			)
			lamp.CanCollide = false
			local light = Instance.new("PointLight")
			light.Range = 26
			light.Brightness = 0.7
			light.Color = Color3.fromRGB(255, 205, 140)
			light.Shadows = false
			light.Parent = lamp
			CollectionService:AddTag(lamp, "LobbyLamp")
		end
	end

	local views: { [number]: PodView } = {}
	for _, pod in LobbyBuilder.layout() do
		views[pod.id] = buildPod(folder, pod)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(12, 0.2, 8)
	spawn.Position = Vector3.new(0, 0.1, -4)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = folder

	HotelBuilder.atmosphere()
	return spawn, views
end

return LobbyBuilder
