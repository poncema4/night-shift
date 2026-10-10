--!strict
-- The moment he gets you: the camera snaps to his face, the screen flashes red, shakes, and holds on him for a heartbeat
-- before the spectator view takes over. Only when he is actually next to you and hunting (not for other ways of going out).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)
local Options = require(script.Parent.Options)
local Ui = require(script.Parent.Ui)

local CatchCam = {}

local NEAR = 14 -- studs: how close he must be for the catch to be "his"
local HEAD = 11.2 -- height of his face above his feet
local HOLD = 1.7 -- seconds on his face
local SNAP = 0.12 -- seconds for the zoom into his face: fast enough to be a jumpscare

function CatchCam.start()
	local me = Players.LocalPlayer
	local state = ReplicatedStorage:WaitForChild("ThreatState")
	local gui = Ui.screen(me:WaitForChild("PlayerGui"), "NightShiftCatch", 20)
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(200, 0, 18)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.Parent = gui
	local until_ = 0
	local started = 0
	local face = Vector3.zero

	local function onDied(character: Model)
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root or not state:GetAttribute("Active") then
			return
		end
		local feet =
			Vector3.new(state:GetAttribute("X") or 0, state:GetAttribute("Y") or 0, state:GetAttribute("Z") or 0)
		if (feet - Vector3.new(root.Position.X, feet.Y, root.Position.Z)).Magnitude > NEAR then
			return
		end
		face = feet + Vector3.new(0, HEAD, 0)
		started = os.clock()
		until_ = started + HOLD
		local sound = Instance.new("Sound")
		sound.SoundId = Config.Sounds.jumpscare
		sound.Volume = 1 * Options.volume()
		sound.Parent = SoundService
		sound:Play()
		task.delay(3, function()
			sound:Destroy()
		end)
	end

	local function watch(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
		if humanoid then
			humanoid.Died:Connect(function()
				onDied(character)
			end)
		end
	end
	me.CharacterAdded:Connect(watch)
	if me.Character then
		task.spawn(watch, me.Character)
	end

	local was = false
	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		local now = os.clock()
		local active = now < until_
		if active and camera then
			local t = (now - started) / HOLD
			local yaw = state:GetAttribute("Yaw") or 0
			local forward = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw)) -- the way his face points
			local shake = Options.get("calm") == true and 0.05 or 0.35
			local jitter = Vector3.new(math.noise(now * 40, 1), math.noise(now * 40, 5), 0) * shake * (1 - t)
			camera.CameraType = Enum.CameraType.Scriptable
			local snap = math.clamp((now - started) / SNAP, 0, 1)
			camera.CFrame = CFrame.lookAt(face + forward * (8 - 5.5 * snap - 1.3 * t) + jitter, face)
			-- the zoom lands almost instantly, then creeps closer; the screen strobes white-red for the first moments
			camera.FieldOfView = 70 - 40 * snap - 6 * t
			local strobe = (now - started) < 0.3 and math.floor((now - started) * 30) % 2 == 0
			flash.BackgroundColor3 = if strobe then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(200, 0, 18)
			flash.BackgroundTransparency = if strobe then 0.1 else math.clamp(0.25 + 0.75 * t, 0, 1)
		elseif was and camera then
			camera.CameraType = Enum.CameraType.Custom
			camera.FieldOfView = 70
			flash.BackgroundTransparency = 1
		end
		was = active
	end)
end

return CatchCam
