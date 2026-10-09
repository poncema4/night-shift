--!strict
-- Draws the Night Manager on this client. The server only publishes where he is (ThreatState attributes);
-- the model is built and smoothed here every frame so he never stutters like a replicated anchored part.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NightManagerRig = require(ReplicatedStorage.Shared.NightManagerRig)

local ThreatView = {}

local function lerpAngle(a: number, b: number, t: number): number
	local delta = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + delta * t
end

function ThreatView.start()
	local state = ReplicatedStorage:WaitForChild("ThreatState")
	local rig = NightManagerRig.build()
	local position: Vector3? = nil
	local yaw = 0

	RunService.RenderStepped:Connect(function(dt)
		if not state:GetAttribute("Active") then
			rig.model.Parent = nil
			position = nil
			return
		end
		local target =
			Vector3.new(state:GetAttribute("X") or 0, state:GetAttribute("Y") or 0, state:GetAttribute("Z") or 0)
		local previous = position or target
		local alpha = 1 - math.exp(-dt * 10)
		local current = previous:Lerp(target, alpha)
		position = current
		yaw = lerpAngle(yaw, state:GetAttribute("Yaw") or 0, 1 - math.exp(-dt * 8))
		local speed = if dt > 0 then (current - previous).Magnitude / dt else 0
		local chasing = state:GetAttribute("Mode") == "Chase"
		local moving = math.clamp(speed / 9, 0, 1)
		local bob = math.sin(os.clock() * (if chasing then 11 else 4.5)) * 0.15 * moving
		local root = CFrame.new(current + Vector3.new(0, bob, 0)) * CFrame.Angles(0, yaw, 0)
		NightManagerRig.pose(rig, root, os.clock(), moving, chasing, state:GetAttribute("Stunned") == true)
		rig.model.Parent = workspace
	end)
end

return ThreatView
