--!strict
-- Sprint (hold), flashlight (toggle) and leaving a hiding place. The client only sends what it WANTS; the
-- server decides what happens (see server/StealthService). Works with keyboard, gamepad and touch buttons.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controls = {}

function Controls.start()
	local player = Players.LocalPlayer
	local intent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Intent") :: RemoteEvent
	local sprint = false

	local function send(light: boolean?, leave: boolean?)
		intent:FireServer({
			sprint = sprint,
			light = if light ~= nil then light else (player:GetAttribute("LightOn") == true),
			leave = leave == true,
		})
	end

	ContextActionService:BindAction("NightShiftSprint", function(_, state)
		sprint = state == Enum.UserInputState.Begin
		send()
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL2)
	ContextActionService:SetTitle("NightShiftSprint", "RUN")
	ContextActionService:SetPosition("NightShiftSprint", UDim2.fromScale(0.78, 0.5))

	ContextActionService:BindAction("NightShiftLight", function(_, state)
		if state == Enum.UserInputState.Begin then
			send(player:GetAttribute("LightOn") ~= true)
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.F, Enum.KeyCode.ButtonX)
	ContextActionService:SetTitle("NightShiftLight", "LIGHT")
	ContextActionService:SetPosition("NightShiftLight", UDim2.fromScale(0.88, 0.38))

	local ability = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Ability") :: RemoteEvent
	ContextActionService:BindAction("NightShiftLure", function(_, state)
		if state == Enum.UserInputState.Begin then
			ability:FireServer("lure")
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Q)
	ContextActionService:BindAction("NightShiftLights", function(_, state)
		if state == Enum.UserInputState.Begin then
			ability:FireServer("lights")
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.R)

	ContextActionService:BindAction("NightShiftLeave", function(_, state)
		if state == Enum.UserInputState.Begin and player:GetAttribute("Hidden") == true then
			send(nil, true)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonB)
end

return Controls
