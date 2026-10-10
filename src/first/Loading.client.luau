--!strict
-- Runs from ReplicatedFirst, before the world arrives: a dark loading screen with the studio name, a progress bar and a
-- tip, removed once the game has loaded. Deliberately self-contained (the shared modules may not have replicated yet).
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local me = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "NightShiftLoading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = me:WaitForChild("PlayerGui")

local cover = Instance.new("Frame")
cover.Size = UDim2.fromScale(1, 1)
cover.BackgroundColor3 = Color3.fromRGB(8, 7, 12)
cover.BorderSizePixel = 0
cover.Parent = gui

local function text(value: string, y: number, font: Enum.Font, color: Color3, height: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.fromScale(0.7, height)
	l.Font = font
	l.TextScaled = true
	l.TextColor3 = color
	l.Text = value
	l.Parent = cover
	return l
end
text("NEXUS HOLLOW STUDIOS", 0.46, Enum.Font.GothamMedium, Color3.fromRGB(150, 144, 164), 0.03)
text("THE NIGHT MANAGER", 0.54, Enum.Font.GothamBlack, Color3.fromRGB(236, 232, 242), 0.07)
local tip = text("", 0.84, Enum.Font.GothamMedium, Color3.fromRGB(255, 190, 90), 0.035)

local track = Instance.new("Frame")
track.AnchorPoint = Vector2.new(0.5, 0.5)
track.Position = UDim2.fromScale(0.5, 0.74)
track.Size = UDim2.fromScale(0.3, 0.008)
track.BackgroundColor3 = Color3.fromRGB(34, 29, 46)
track.BorderSizePixel = 0
track.Parent = cover
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(255, 190, 90)
fill.BorderSizePixel = 0
fill.Parent = track

-- a tip from the shared config once it has replicated (it usually has by then; otherwise a plain line)
task.spawn(function()
	local shared = ReplicatedStorage:WaitForChild("Shared", 10)
	local config = shared and shared:FindFirstChild("Config")
	if config and config:IsA("ModuleScript") then
		local ok, value = pcall(require, config)
		if ok and type(value) == "table" and value.Tips then
			tip.Text = "TIP: " .. value.Tips[math.random(#value.Tips)]
			return
		end
	end
	tip.Text = "Keep quiet. He is listening."
end)

if not game:IsLoaded() then
	local total = math.max(#game:GetDescendants(), 1)
	local conn = ContentProvider:GetPropertyChangedSignal("RequestQueueSize"):Connect(function()
		local left = ContentProvider.RequestQueueSize
		fill.Size = UDim2.fromScale(math.clamp(1 - left / total, 0, 1), 1)
	end)
	game.Loaded:Wait()
	conn:Disconnect()
end
fill.Size = UDim2.fromScale(1, 1)
task.wait(0.8) -- a beat on the full bar, so the screen never just flashes
TweenService:Create(cover, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
for _, child in cover:GetDescendants() do
	if child:IsA("TextLabel") then
		TweenService:Create(child, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
	elseif child:IsA("ImageLabel") then
		TweenService:Create(child, TweenInfo.new(0.6), { ImageTransparency = 1 }):Play()
	elseif child:IsA("Frame") then
		TweenService:Create(child, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	end
end
task.wait(0.7)
gui:Destroy()
