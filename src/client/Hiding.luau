--!strict
-- While you are in a locker you look OUT through its door: the camera sits just outside the door face (so the solid box is
-- never in the way), the whole locker model fades for you alone (LocalTransparencyModifier), and the HUD adds the slatted
-- vent view on top. A gentle breathing sway keeps the shot alive. Leaving gives everything back.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Hiding = {}

local FADE = 0.7 -- how see-through the locker is for the person inside

local function myLocker(): Model?
	local me = Players.LocalPlayer
	for _, model in CollectionService:GetTagged("HidingSpot") do
		if model:GetAttribute("Occupant") == me.UserId then
			return model :: Model
		end
	end
	return nil
end

local function fade(model: Model, amount: number)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = amount
		end
	end
end

function Hiding.start()
	local me = Players.LocalPlayer
	local faded: Model? = nil
	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local model = if me:GetAttribute("Hidden") == true then myLocker() else nil
		local body = model and model:FindFirstChild("Body") :: BasePart?
		if model and body then
			if faded ~= model then
				fade(model, FADE)
				faded = model
			end
			camera.CameraType = Enum.CameraType.Scriptable
			-- the door faces +Z of the body; the eye is a hand's width outside it, at head height
			local eye = body.CFrame * CFrame.new(0, body.Size.Y * 0.2, body.Size.Z / 2 + 0.35)
			local out = (body.CFrame * CFrame.new(0, 0, 1)).Position - body.Position
			local sway = math.sin(os.clock() * 1.3) * 0.4
			camera.CFrame = CFrame.lookAt(eye.Position, eye.Position + out * 20 + Vector3.new(0, sway, 0))
		elseif faded then
			fade(faded, 0)
			faded = nil
			camera.CameraType = Enum.CameraType.Custom
		end
	end)
end

return Hiding
