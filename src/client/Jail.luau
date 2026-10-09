--!strict
-- The holding-cell countdown: while the Night Manager is locked up the crew sees how long they have, and the moment he is
-- released the screen says so. Reads the "Hold" attribute the server publishes on ThreatState.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Options = require(script.Parent.Options)
local Ui = require(script.Parent.Ui)

local Jail = {}

function Jail.start()
	local me = Players.LocalPlayer
	local state = ReplicatedStorage:WaitForChild("ThreatState")
	local gui = Ui.screen(me:WaitForChild("PlayerGui"), "NightShiftJail", 6)
	local banner =
		Ui.label(gui, "", Enum.Font.GothamBlack, Ui.AMBER, UDim2.fromScale(0.25, 0.12), UDim2.fromScale(0.5, 0.05))
	banner.TextStrokeTransparency = 0.5
	local sub =
		Ui.label(gui, "", Enum.Font.GothamMedium, Ui.TEXT, UDim2.fromScale(0.3, 0.175), UDim2.fromScale(0.4, 0.03))
	sub.TextStrokeTransparency = 0.6

	local was = 0
	local function refresh()
		local hold = state:GetAttribute("Hold") or 0
		if hold > 0 then
			banner.Text = `THE NIGHT MANAGER IS LOCKED UP  -  RELEASED IN {hold}`
			banner.TextColor3 = if hold <= 5 then Ui.BLOOD else Ui.AMBER
			sub.Text = "Find your tasks and a hiding place. Once he is out, he is searching for you."
			banner.Visible = true
			sub.Visible = true
		elseif was > 0 and state:GetAttribute("Active") then
			banner.Text = "HE IS LOOSE"
			banner.TextColor3 = Ui.BLOOD
			sub.Text = if Options.get("subtitles") then "Stay quiet. Use your flashlight to blind him." else ""
			task.delay(5, function()
				if (state:GetAttribute("Hold") or 0) == 0 then
					banner.Visible = false
					sub.Visible = false
				end
			end)
		else
			banner.Visible = false
			sub.Visible = false
		end
		was = hold
	end
	state:GetAttributeChangedSignal("Hold"):Connect(refresh)
	refresh()
end

return Jail
