--!strict
-- Sound. Every sound id lives in Config.Sounds (placeholders from the Roblox client for now), and every cue is driven by
-- something the server already says: the flashlight attribute, task count, the meeting and scare remotes, the dawn
-- result, and the Night Manager's distance (a looping heartbeat that swells as he gets near).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)
local Options = require(script.Parent.Options)

local Audio = {}

local NEAR = 45 -- studs at which the heartbeat starts (matches the dread effect in Fx)

local function newSound(id: string, volume: number, looped: boolean): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.Looped = looped
	sound.Parent = SoundService
	return sound
end

function Audio.start()
	local me = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local state = ReplicatedStorage:WaitForChild("ThreatState")
	local sounds = Config.Sounds

	local function cue(id: string, volume: number, speed: number?)
		local sound = newSound(id, volume * Options.volume(), false)
		sound.PlaybackSpeed = speed or 1
		sound:Play()
		task.delay(4, function()
			sound:Destroy()
		end)
	end

	me:GetAttributeChangedSignal("LightOn"):Connect(function()
		cue(sounds.flashlight, 0.5)
	end)
	local lastTasks = 0
	ReplicatedStorage:GetAttributeChangedSignal("TasksDone"):Connect(function()
		local now = ReplicatedStorage:GetAttribute("TasksDone") or 0
		if now > lastTasks then
			cue(sounds.taskDone, 0.6)
		end
		lastTasks = now
	end)
	local startEvent = remotes:WaitForChild("MeetingStart") :: RemoteEvent
	startEvent.OnClientEvent:Connect(function()
		cue(sounds.meeting, 0.8, 0.7)
	end)
	local scare = remotes:WaitForChild("Scare") :: RemoteEvent
	scare.OnClientEvent:Connect(function(kind: string)
		if kind == "thud" or kind == "blackout" then
			cue(sounds.thud, 0.8, if kind == "blackout" then 0.6 else 1)
		end
	end)
	local roundResult = remotes:WaitForChild("RoundResult") :: RemoteEvent
	roundResult.OnClientEvent:Connect(function()
		cue(sounds.dawn, 0.6)
	end)

	-- the heartbeat: silent until he is within NEAR studs, then louder and quicker the closer he gets
	local beat = newSound(sounds.heartbeat, 0, true)
	RunService.RenderStepped:Connect(function()
		local character = me.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local intensity = 0
		if root and state:GetAttribute("Active") then
			local dx = (state:GetAttribute("X") or 0) - root.Position.X
			local dy = (state:GetAttribute("Y") or 0) - (root.Position.Y - 3)
			local dz = (state:GetAttribute("Z") or 0) - root.Position.Z
			intensity = math.clamp(1 - math.sqrt(dx * dx + dy * dy + dz * dz) / NEAR, 0, 1)
		end
		beat.Volume = intensity * 0.7 * Options.volume()
		beat.PlaybackSpeed = 0.7 + intensity * 0.8 + (state:GetAttribute("Rage") or 0) * 0.25
		if intensity > 0.02 and not beat.IsPlaying then
			beat:Play()
		elseif intensity <= 0.02 and beat.IsPlaying then
			beat:Pause()
		end
	end)
end

return Audio
