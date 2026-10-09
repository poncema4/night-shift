--!strict
-- The lobby room: a dim waiting hall with flickering lamps, a reception desk and bell, and a row of queue pods (round pads).
-- Plain geometry; the pods' behaviour is in LobbyService and the party screen is client UI.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Pods = require(ReplicatedStorage.Shared.Game.Pods)
local HotelBuilder = require(script.Parent.HotelBuilder)

local LobbyBuilder = {}

export type PodView = { status: TextLabel, ring: Part }

local WIDTH, DEPTH, HEIGHT = 80, 48, 16

function LobbyBuilder.layout(): { Pods.Pod }
	return Pods.layout(0, Config.Lobby.PodZ, Config.Lobby.PodSpacing)
end

local function buildPod(folder: Folder, pod: Pods.Pod): PodView
	local model = Instance.new("Model")
	model.Name = `Pod_{pod.id}`
	model.Parent = folder
	local block = HotelBuilder.block
	local pad = block(
		model,
		"Pad",
		Vector3.new(pod.radius * 2, 0.4, pod.radius * 2),
		Vector3.new(pod.x, 0.2, pod.z),
		Color3.fromRGB(26, 24, 32),
		Enum.Material.Metal
	)
	pad.Shape = Enum.PartType.Cylinder
	pad.CFrame = CFrame.new(pad.Position) * CFrame.Angles(0, 0, math.pi / 2)
	pad.Size = Vector3.new(0.4, pod.radius * 2, pod.radius * 2)
	local ring = block(
		model,
		"Ring",
		Vector3.new(0.1, pod.radius * 2 - 0.4, pod.radius * 2 - 0.4),
		Vector3.new(pod.x, 0.43, pod.z),
		Color3.fromRGB(255, 190, 90),
		Enum.Material.Neon
	)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(ring.Position) * CFrame.Angles(0, 0, math.pi / 2)
	ring.CanCollide = false
	local inner = block(
		model,
		"Floor",
		Vector3.new(0.1, pod.radius * 2 - 1, pod.radius * 2 - 1),
		Vector3.new(pod.x, 0.47, pod.z),
		Color3.fromRGB(14, 12, 18),
		Enum.Material.SmoothPlastic
	)
	inner.Shape = Enum.PartType.Cylinder
	inner.CFrame = CFrame.new(inner.Position) * CFrame.Angles(0, 0, math.pi / 2)
	inner.CanCollide = false
	-- the sign floats above the pad
	local sign = block(
		model,
		"Sign",
		Vector3.new(7, 3, 0.2),
		Vector3.new(pod.x, 9, pod.z + pod.radius + 0.5),
		Color3.fromRGB(10, 9, 14),
		Enum.Material.SmoothPlastic
	)
	sign.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.Parent = sign
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.5)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(236, 232, 242)
	title.Text = pod.label
	title.Parent = gui
	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Position = UDim2.fromScale(0, 0.5)
	status.Size = UDim2.fromScale(1, 0.4)
	status.Font = Enum.Font.GothamMedium
	status.TextScaled = true
	status.TextColor3 = Color3.fromRGB(255, 190, 90)
	status.Text = Pods.status(0, pod.size)
	status.Parent = gui
	return { status = status, ring = ring }
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
	for _, x in { -30, -15, 0, 15, 30 } do
		for _, z in { -8, 8 } do
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
