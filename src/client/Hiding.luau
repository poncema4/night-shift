--!strict
-- While you are in a locker the camera looks OUT through its door (instead of sitting blind inside the box), with a gentle
-- breathing sway. Leaving gives the normal camera back.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Hiding = {}

local function myLocker(): BasePart?
	local me = Players.LocalPlayer
	for _, model in CollectionService:GetTagged("HidingSpot") do
		if model:GetAttribute("Occupant") == me.UserId then
			return model:FindFirstChild("Body") :: BasePart?
		end
	end
	return nil
end

function Hiding.start()
	local me = Players.LocalPlayer
	local inside = false
	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local body = if me:GetAttribute("Hidden") == true then myLocker() else nil
		if body then
			inside = true
			camera.CameraType = Enum.CameraType.Scriptable
			-- the door faces +Z of the body; the eye sits just inside it, level with where a head would be
			local eye = body.CFrame * CFrame.new(0, body.Size.Y * 0.2, body.Size.Z / 2 - 0.15)
			local out = (body.CFrame * CFrame.new(0, 0, 1)).Position - body.Position -- the door side (+Z of the model)
			local sway = math.sin(os.clock() * 1.3) * 0.4
			camera.CFrame = CFrame.lookAt(eye.Position, eye.Position + out * 20 + Vector3.new(0, sway, 0))
		elseif inside then
			inside = false
			camera.CameraType = Enum.CameraType.Custom
		end
	end)
end

return Hiding
