--!strict
-- Screen and light effects that make the night feel alive. Cheap on purpose (phones count):
-- a red pulse + camera tremble when the Night Manager is near, and flickering bulbs.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Fx = {}

local NEAR = 45 -- studs at which the dread starts

function Fx.start()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "NightShiftFx"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = -1
	gui.Parent = player:WaitForChild("PlayerGui")

	local dread = Instance.new("Frame")
	dread.Size = UDim2.fromScale(1, 1)
	dread.BackgroundColor3 = Color3.fromRGB(150, 0, 20)
	dread.BackgroundTransparency = 1
	dread.BorderSizePixel = 0
	dread.Active = false
	dread.Parent = gui

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		local threat = workspace:FindFirstChild("NightManager") :: Model?
		local intensity = 0
		if threat and root then
			local d = (threat:GetPivot().Position - root.Position).Magnitude
			intensity = math.clamp(1 - d / NEAR, 0, 1)
		end

		local pulse = 0.5 + 0.5 * math.sin(now * (2 + intensity * 8))
		dread.BackgroundTransparency = 1 - intensity * 0.4 * (0.5 + 0.5 * pulse)
		if humanoid then
			local shake = intensity * intensity * 0.5
			humanoid.CameraOffset =
				Vector3.new((math.noise(now * 9, 1) - 0) * shake, (math.noise(now * 9, 7) - 0) * shake, 0)
		end

		-- bulbs near us flicker; much more when something is hunting close by
		if root then
			for _, lamp in CollectionService:GetTagged("Bulb") do
				local light = lamp:FindFirstChildOfClass("PointLight")
				if light and (lamp.Position - root.Position).Magnitude < 70 then
					local n = math.noise(now * (3 + intensity * 12), lamp.Position.X * 0.37)
					local dip = if n < -0.25 - (1 - intensity) * 0.15 then 0.15 else 1
					light.Brightness = 1.1 * dip
				end
			end
		end
	end)
end

return Fx
