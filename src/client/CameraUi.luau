--!strict
-- The security monitor (crew only): a map of the three floors with the Night Manager as a red blip, available while
-- you are "watching" (the server decides when: charges and cooldown). Press C or the CAMERAS button.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Floors = require(ReplicatedStorage.Shared.Game.Floors)

local CameraUi = {}

local X_MIN, X_MAX, Z_MIN, Z_MAX = -83, 83, -27, 27
local STRIPS = { 1, 0, -1 } -- top to bottom
local NAMES = { [1] = "FLOOR 2", [0] = "GROUND", [-1] = "BASEMENT" }

function CameraUi.start()
	local me = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local request = remotes:WaitForChild("Camera") :: RemoteEvent
	local roleAssigned = remotes:WaitForChild("RoleAssigned") :: RemoteEvent
	local state = ReplicatedStorage:WaitForChild("ThreatState")
	local myRole = ""
	roleAssigned.OnClientEvent:Connect(function(role: string)
		myRole = role
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "NightShiftCameras"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 8
	gui.Parent = me:WaitForChild("PlayerGui")

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0, 1)
	button.Position = UDim2.fromScale(0.02, 0.88)
	button.Size = UDim2.fromScale(0.16, 0.05)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.TextColor3 = Color3.fromRGB(190, 255, 235)
	button.BackgroundColor3 = Color3.fromRGB(14, 40, 40)
	button.Visible = false
	button.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.fromScale(0.5, 0.1)
	panel.Size = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(4, 14, 14)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromScale(0.02, 0.01)
	title.Size = UDim2.fromScale(0.96, 0.07)
	title.Font = Enum.Font.Code
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(100, 255, 210)
	title.Text = "SECURITY"
	title.Parent = panel

	-- three floor strips, drawn from the same room data the game is built from
	local strips: { [number]: Frame } = {}
	for i, level in STRIPS do
		local strip = Instance.new("Frame")
		strip.Position = UDim2.fromScale(0.02, 0.1 + (i - 1) * 0.3)
		strip.Size = UDim2.fromScale(0.96, 0.27)
		strip.BackgroundColor3 = Color3.fromRGB(8, 30, 30)
		strip.BorderSizePixel = 0
		strip.Parent = panel
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(0.15, 0.2)
		label.Font = Enum.Font.Code
		label.TextScaled = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Color3.fromRGB(70, 180, 150)
		label.Text = NAMES[level]
		label.ZIndex = 3
		label.Parent = strip
		for _, room in Floors.rooms(level) do
			local r = Instance.new("Frame")
			r.Position = UDim2.fromScale((room.x1 - X_MIN) / (X_MAX - X_MIN), (Z_MAX - room.z2) / (Z_MAX - Z_MIN))
			r.Size = UDim2.fromScale((room.x2 - room.x1) / (X_MAX - X_MIN), (room.z2 - room.z1) / (Z_MAX - Z_MIN))
			r.BackgroundColor3 = Color3.fromRGB(14, 50, 46)
			r.BorderSizePixel = 0
			r.Parent = strip
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(40, 120, 104)
			stroke.Thickness = 1
			stroke.Parent = r
		end
		strips[level] = strip
	end
	local blip = Instance.new("Frame")
	blip.AnchorPoint = Vector2.new(0.5, 0.5)
	blip.Size = UDim2.fromOffset(14, 14)
	blip.BackgroundColor3 = Color3.fromRGB(255, 60, 70)
	blip.BorderSizePixel = 0
	blip.ZIndex = 5
	blip.Visible = false
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = blip
	blip.Parent = gui

	local function ask()
		request:FireServer()
	end
	button.Activated:Connect(ask)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.C then
			ask()
		end
	end)

	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()
		local phase = ReplicatedStorage:GetAttribute("Phase")
		local charges = ReplicatedStorage:GetAttribute("CameraCharges") or 0
		local wait = math.max(0, math.ceil((ReplicatedStorage:GetAttribute("CameraReadyAt") or 0) - now))
		button.Visible = myRole == "Crew" and phase == "Night" and charges > 0
		button.Text = if wait > 0 then `CAMERAS (C)  {wait}s` else `CAMERAS (C)  x{charges}`
		button.BackgroundTransparency = if wait > 0 then 0.6 else 0.15

		local left = (me:GetAttribute("CamerasUntil") or 0) - now
		local watching = left > 0 and phase == "Night"
		panel.Visible = watching
		if not watching then
			blip.Visible = false
			return
		end
		title.Text = `SECURITY  REC  {math.ceil(left)}s`
		if state:GetAttribute("Active") then
			local level = math.clamp(Floors.levelAt(state:GetAttribute("Y") or 0), -1, 1)
			local strip = strips[level]
			local x, z = state:GetAttribute("X") or 0, state:GetAttribute("Z") or 0
			blip.Parent = strip
			blip.Position = UDim2.fromScale(
				math.clamp((x - X_MIN) / (X_MAX - X_MIN), 0, 1),
				math.clamp((Z_MAX - z) / (Z_MAX - Z_MIN), 0, 1)
			)
			blip.Visible = true
		else
			blip.Visible = false
			title.Text = "SECURITY  NO SIGNAL"
		end
	end)
end

return CameraUi
