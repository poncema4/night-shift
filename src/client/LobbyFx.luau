--!strict
-- The lobby's mood: the ceiling lamps flicker on their own broken rhythms (a long steady spell, then a stutter), and now
-- and then something heavy thuds somewhere far away. "Reduced flashing" in Options softens the flicker to a gentle dim.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)
local Options = require(script.Parent.Options)

local LobbyFx = {}

type Lamp = { part: BasePart, light: PointLight, base: number, nextAt: number, burstUntil: number }

function LobbyFx.start()
	local lamps: { Lamp } = {}
	local function adopt(part: Instance)
		local light = part:FindFirstChildOfClass("PointLight")
		if part:IsA("BasePart") and light then
			table.insert(lamps, {
				part = part,
				light = light,
				base = light.Brightness,
				nextAt = os.clock() + math.random() * 6,
				burstUntil = 0,
			})
		end
	end
	for _, part in CollectionService:GetTagged("LobbyLamp") do
		adopt(part)
	end
	CollectionService:GetInstanceAddedSignal("LobbyLamp"):Connect(adopt)

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local calm = Options.get("calm") == true
		for _, lamp in lamps do
			if now >= lamp.nextAt then
				lamp.burstUntil = now + 0.15 + math.random() * 0.45
				lamp.nextAt = now + 3 + math.random() * 12
			end
			local on = true
			if now < lamp.burstUntil then
				-- stutter: fast on/off noise during a burst
				on = math.noise(now * 38, lamp.base * 91) > -0.1
			end
			local level = if on then 1 else (if calm then 0.6 else 0.05)
			lamp.light.Brightness = lamp.base * level
			lamp.part.Material = if level > 0.5 then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end)

	-- something heavy, far away, every so often
	task.spawn(function()
		while true do
			task.wait(25 + math.random() * 35)
			local sound = Instance.new("Sound")
			sound.SoundId = Config.Sounds.thud
			sound.Volume = 0.25 * Options.volume()
			sound.PlaybackSpeed = 0.5 + math.random() * 0.2
			sound.Parent = SoundService
			sound:Play()
			task.delay(5, function()
				sound:Destroy()
			end)
		end
	end)
end

return LobbyFx
