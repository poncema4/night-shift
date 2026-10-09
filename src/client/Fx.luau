--!strict
-- Screen and light effects that make the night feel alive. Cheap on purpose (phones count):
-- a red pulse + camera tremble when the Night Manager is near, and flickering bulbs.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Options = require(script.Parent.Options)

local Fx = {}

local SUBTITLES: { [string]: { string } } = {
	thud = { "A heavy thud from somewhere in the hotel.", "Something fell upstairs.", "Footsteps below you." },
	whisper = {
		"Don't run.",
		"He can hear the lights.",
		"Someone here is lying.",
		"Check the Locker Room.",
		"The night shift never ends.",
	},
	blackout = { "THE LIGHTS GO OUT" },
}

local NEAR = 45 -- studs at which the dread starts
local LIGHT_CULL = 75 -- lights farther than this are switched off locally
local FLOOR_GAP = 12 -- ...and so are lights this far above or below you (another floor)

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

	local subtitle = Instance.new("TextLabel")
	subtitle.AnchorPoint = Vector2.new(0.5, 1)
	subtitle.Position = UDim2.fromScale(0.5, 0.86)
	subtitle.Size = UDim2.fromScale(0.6, 0.05)
	subtitle.BackgroundTransparency = 1
	subtitle.TextColor3 = Color3.fromRGB(215, 215, 225)
	subtitle.TextStrokeTransparency = 0.4
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextScaled = true
	subtitle.Text = ""
	subtitle.Parent = gui

	-- scares from the server: bulbs flicker harder, the camera shudders, a line of text appears
	local boostUntil, shakeUntil, subtitleUntil = 0, 0, 0
	local culled: { [PointLight]: boolean } = {}
	local base: { [PointLight]: number } = {}
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local scare = remotes:WaitForChild("Scare") :: RemoteEvent
	scare.OnClientEvent:Connect(function(kind: string, seconds: number)
		local now = os.clock()
		if kind == "flicker" then
			boostUntil = now + seconds
		elseif kind == "thud" then
			shakeUntil = now + seconds
		end
		local lines = SUBTITLES[kind]
		if lines and Options.get("subtitles") then
			subtitle.Text = lines[math.random(#lines)]
			subtitleUntil = now + math.max(seconds, 3)
		end
	end)

	-- the crew's progress angers him: warn once per night when he crosses half-way
	local warned = false
	local threatState = ReplicatedStorage:WaitForChild("ThreatState")
	threatState:GetAttributeChangedSignal("Rage"):Connect(function()
		local rage = threatState:GetAttribute("Rage") or 0
		if rage < 0.05 then
			warned = false
		elseif rage >= 0.5 and not warned and Options.get("subtitles") then
			warned = true
			subtitle.Text = "He is getting faster."
			subtitleUntil = os.clock() + 4
		end
	end)

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if now > subtitleUntil then
			subtitle.Text = ""
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		local threat = workspace:FindFirstChild("NightManager") :: Model?
		local intensity = 0
		if threat and root then
			local d = (threat:GetPivot().Position - root.Position).Magnitude
			intensity = math.clamp(1 - d / NEAR, 0, 1)
		end

		local calm = Options.get("calm") == true -- reduced flashing: no pulsing, a gentler shake
		local pulse = if calm then 0.5 else 0.5 + 0.5 * math.sin(now * (2 + intensity * 8))
		dread.BackgroundTransparency = 1 - intensity * 0.4 * (0.5 + 0.5 * pulse)
		if humanoid then
			local shake = (intensity * intensity * 0.5 + (if now < shakeUntil then 0.35 else 0))
				* (if calm then 0.3 else 1)
			humanoid.CameraOffset =
				Vector3.new((math.noise(now * 9, 1) - 0) * shake, (math.noise(now * 9, 7) - 0) * shake, 0)
		end

		-- bulbs near us flicker; much more when something is hunting close by or the director says so
		local flickerIntensity = if now < boostUntil then math.max(intensity, 0.8) else intensity
		if root then
			for _, lamp in CollectionService:GetTagged("Bulb") do
				local light = lamp:FindFirstChildOfClass("PointLight")
				if not (light and lamp:IsA("BasePart")) then
					continue
				end
				local offset = lamp.Position - root.Position
				-- lights far away or on another floor are switched off on this screen only (cheap on phones)
				if offset.Magnitude > LIGHT_CULL or math.abs(offset.Y) > FLOOR_GAP then
					if light.Enabled then
						light.Enabled = false
						culled[light] = true
					end
					continue
				end
				if culled[light] then
					light.Enabled = true
					culled[light] = nil
				end
				base[light] = base[light] or light.Brightness
				local n = math.noise(now * (3 + flickerIntensity * 12), lamp.Position.X * 0.37)
				local dip = if n < -0.25 - (1 - flickerIntensity) * 0.15 then 0.15 else 1
				light.Brightness = base[light] * dip
			end
		end
	end)
end

return Fx
