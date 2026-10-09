--!strict
-- The security monitor. Finishing the "Fix the cameras" task unlocks it for the crew; a crew member asks to watch
-- and the pure rules (Shared/Game/Cameras) decide: charges, a team cooldown, 15 seconds each.
-- The map itself is drawn on the client from the Night Manager's published position.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cameras = require(ReplicatedStorage.Shared.Game.Cameras)

local CameraService = {}

local state = Cameras.new()
local roleOf: (number) -> string? = function(_userId: number)
	return nil
end
local isNight: () -> boolean = function()
	return false
end

local function publish()
	ReplicatedStorage:SetAttribute("CameraCharges", state.charges)
	ReplicatedStorage:SetAttribute("CameraReadyAt", workspace:GetServerTimeNow() + Cameras.wait(state, os.clock()))
end

local function onRequest(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not isNight() or roleOf(player.UserId) ~= "Crew" or not humanoid or humanoid.Health <= 0 then
		return
	end
	if Cameras.use(state, os.clock()) then
		player:SetAttribute("CamerasUntil", workspace:GetServerTimeNow() + Cameras.WATCH_SECONDS)
		print(`[Cameras] {player.Name} watches the monitor ({state.charges} left)`)
		publish()
	end
end

function CameraService.start(remotes: Folder, getRole: (number) -> string?, night: () -> boolean)
	roleOf = getRole
	isNight = night
	local remote = Instance.new("RemoteEvent")
	remote.Name = "Camera"
	remote.Parent = remotes
	remote.OnServerEvent:Connect(onRequest)
	publish()
end

-- The cameras task was finished.
function CameraService.unlock()
	Cameras.unlock(state)
	publish()
end

-- A new night (or the lobby): the monitor is dead again and nobody is watching.
function CameraService.reset()
	state = Cameras.new()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("CamerasUntil", 0)
	end
	publish()
end

return CameraService
