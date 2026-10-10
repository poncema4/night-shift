--!strict
-- The holding-cell countdown: while the Night Manager is locked up the crew sees how long they have, and the moment he is
-- released the screen says so. Reads the "Hold" attribute the server publishes on ThreatState.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Options = require(script.Parent.Options)
local Ui = require(script.Parent.Ui)

local Jail = {}

local OPEN_SECONDS = 1.4
local LIFT = 10 -- studs the bars rise when the cage opens

-- The cage itself: its lamp pulses faster as release gets closer, and when he is let out the bars slide up out of the way.
-- Each client moves its own copy of the (non-colliding) bars, so it is smooth with no network cost.
local function animateCage(state: Instance)
	local origin: { [BasePart]: CFrame } = {}
	local lamp: BasePart? = nil
	local light: PointLight? = nil
	local openedAt: number? = nil
	local lastHold = 0

	local function find()
		if next(origin) then
			return
		end
		for _, model in CollectionService:GetTagged("HoldingCell") do
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") and (part.Name == "Bar" or part.Name == "Rail") then
					origin[part] = part.CFrame
				elseif part:IsA("BasePart") and part.Name == "Lamp" then
					lamp = part
					light = part:FindFirstChildOfClass("PointLight")
				end
			end
		end
	end

	RunService.Heartbeat:Connect(function()
		find()
		local hold = (state:GetAttribute("Hold") :: number?) or 0
		if hold > 0 then
			if lastHold == 0 then
				openedAt = nil -- a new night: the cage is closed again
				for part, cf in origin do
					part.CFrame = cf
				end
			end
			local total = Config.Threat.ReleaseSeconds
			local urgency = 1 - math.clamp(hold / total, 0, 1)
			local pulse = 0.5 + 0.5 * math.sin(os.clock() * (2 + urgency * 10))
			if lamp and light then
				light.Brightness = 0.2 + pulse * (0.4 + urgency)
				lamp.Transparency = 0.5 - pulse * 0.5
			end
		elseif lastHold > 0 and state:GetAttribute("Active") then
			openedAt = os.clock()
		end
		lastHold = hold
		local started = openedAt
		if started then
			local p = math.clamp((os.clock() - started) / OPEN_SECONDS, 0, 1)
			local eased = 1 - (1 - p) ^ 3
			for part, cf in origin do
				part.CFrame = CFrame.new(0, LIFT * eased, 0) * cf
			end
			if light then
				light.Brightness = 1.2 * (1 - p)
			end
		end
	end)
end

function Jail.start()
	local me = Players.LocalPlayer
	local state = ReplicatedStorage:WaitForChild("ThreatState")
	animateCage(state)
	local gui = Ui.screen(me:WaitForChild("PlayerGui"), "NightShiftJail", 6)
	local banner =
		Ui.label(gui, "", Enum.Font.GothamBlack, Ui.AMBER, UDim2.fromScale(0.2, 0.235), UDim2.fromScale(0.6, 0.05))
	banner.Name = "Banner"
	banner.TextStrokeTransparency = 0.5
	local sub =
		Ui.label(gui, "", Enum.Font.GothamMedium, Ui.TEXT, UDim2.fromScale(0.25, 0.292), UDim2.fromScale(0.5, 0.03))
	sub.Name = "Sub"
	sub.TextStrokeTransparency = 0.6

	local was = 0
	local function refresh()
		local hold = (state:GetAttribute("Hold") :: number?) or 0
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
