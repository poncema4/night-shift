--!strict
-- Sound. Every sound id lives in Config.Sounds (our own synthesized horror set plus a few stock Roblox cues), and every cue is driven by
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
local CHASE_STING_RANGE = 70 -- the hunting sting only plays if he is near enough to be hunting you

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
	roundResult.OnClientEvent:Connect(function(info: { winner: string? })
		-- the crew winning gets the relief chime; anything else is the sting of everyone going down
		cue(if info.winner == "Crew" then sounds.dawn else sounds.deathSting, if info.winner == "Crew" then 0.6 else 1)
	end)
	me:GetAttributeChangedSignal("Hidden"):Connect(function()
		cue(sounds.lockerCreak, 0.7)
	end)

	-- how far he is from me in studs (nil while he is not out)
	local function distance(): number?
		local character = me.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root or not state:GetAttribute("Active") then
			return nil
		end
		local dx = (state:GetAttribute("X") or 0) - root.Position.X
		local dy = (state:GetAttribute("Y") or 0) - (root.Position.Y - 3)
		local dz = (state:GetAttribute("Z") or 0) - root.Position.Z
		return math.sqrt(dx * dx + dy * dy + dz * dz)
	end

	-- one-shot stings from what the server publishes about him
	state:GetAttributeChangedSignal("Mode"):Connect(function()
		local d = distance()
		if state:GetAttribute("Mode") == "Chase" and d and d < CHASE_STING_RANGE then
			cue(sounds.chaseSting, 0.9)
		end
	end)
	local lastHold = state:GetAttribute("Hold") or 0
	state:GetAttributeChangedSignal("Hold"):Connect(function()
		local now = state:GetAttribute("Hold") or 0
		if lastHold > 0 and now == 0 then
			cue(sounds.heLoose, 1)
		end
		lastHold = now
	end)
	state:GetAttributeChangedSignal("Stunned"):Connect(function()
		local d = distance()
		if state:GetAttribute("Stunned") == true and d and d < 60 then
			cue(sounds.blindShriek, 1)
		end
	end)

	-- the proximity layers: each loop is silent until he is inside its range, then rises as he closes in
	local layers = {
		{ sound = newSound(sounds.dread, 0, true), range = 80, gain = 0.7 },
		{ sound = newSound(sounds.steps, 0, true), range = 45, gain = 0.9 },
		{ sound = newSound(sounds.breath, 0, true), range = 18, gain = 0.9 },
	}
	-- the heartbeat: louder and quicker the closer he gets
	local beat = newSound(sounds.heartbeat, 0, true)
	RunService.RenderStepped:Connect(function()
		local d = distance()
		local rage = state:GetAttribute("Rage") or 0
		local chasing = state:GetAttribute("Mode") == "Chase"
		for _, layer in layers do
			local level = if d then math.clamp(1 - d / layer.range, 0, 1) else 0
			-- the curve is squared so he is quiet far away and overwhelming up close
			layer.sound.Volume = level * level * layer.gain * Options.volume()
			layer.sound.PlaybackSpeed = if chasing then 1.25 else 1
			if level > 0.01 and not layer.sound.IsPlaying then
				layer.sound:Play()
			elseif level <= 0.01 and layer.sound.IsPlaying then
				layer.sound:Pause()
			end
		end
		local intensity = if d then math.clamp(1 - d / NEAR, 0, 1) else 0
		beat.Volume = intensity * 0.8 * Options.volume()
		beat.PlaybackSpeed = 0.7 + intensity * 0.8 + rage * 0.25
		if intensity > 0.02 and not beat.IsPlaying then
			beat:Play()
		elseif intensity <= 0.02 and beat.IsPlaying then
			beat:Pause()
		end
	end)
end

return Audio
