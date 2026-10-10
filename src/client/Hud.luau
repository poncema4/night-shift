--!strict
-- Minimal on-screen status: phase + countdown, your role, and the dawn reveal.
-- Sizes use scale so it fits phones and big monitors.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Floors = require(ReplicatedStorage.Shared.Game.Floors)

local Hud = {}

local function label(parent: Instance, name: string, position: UDim2, size: UDim2): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.AnchorPoint = Vector2.new(0.5, 0)
	l.Position = position
	l.Size = size
	l.BackgroundTransparency = 0.4
	l.BackgroundColor3 = Color3.fromRGB(10, 12, 24)
	l.TextColor3 = Color3.fromRGB(235, 240, 255)
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.Text = ""
	l.Parent = parent
	return l
end

function Hud.start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "NightShiftHud"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local status = label(gui, "Status", UDim2.fromScale(0.5, 0.02), UDim2.fromScale(0.4, 0.07))
	local tasks = label(gui, "Tasks", UDim2.fromScale(0.5, 0.1), UDim2.fromScale(0.25, 0.05))
	local tip = label(gui, "Tip", UDim2.fromScale(0.5, 0.74), UDim2.fromScale(0.6, 0.06)) -- above the LEAVE button (0.82)
	tip.Visible = false
	local tipFor = -1
	local floorLabel = label(gui, "Floor", UDim2.fromScale(0.12, 0.02), UDim2.fromScale(0.17, 0.05))
	local role = label(gui, "Role", UDim2.fromScale(0.5, 0.16), UDim2.fromScale(0.3, 0.06))
	role.Visible = false

	-- stamina and battery bars (bottom left), and the screen you see while hiding
	local function bar(name: string, y: number, color: Color3): Frame
		local back = Instance.new("Frame")
		back.Name = name
		back.AnchorPoint = Vector2.new(0, 1)
		back.Position = UDim2.fromScale(0.02, y)
		back.Size = UDim2.fromScale(0.16, 0.022)
		back.BackgroundColor3 = Color3.fromRGB(10, 12, 24)
		back.BackgroundTransparency = 0.35
		back.BorderSizePixel = 0
		back.Parent = gui
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = color
		fill.BorderSizePixel = 0
		fill.Parent = back
		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Text = name
		text.TextColor3 = Color3.fromRGB(235, 240, 255)
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.ZIndex = 2
		text.Parent = back
		return fill
	end
	local staminaFill = bar("STAMINA", 0.95, Color3.fromRGB(90, 200, 120))
	local batteryFill = bar("BATTERY", 0.92, Color3.fromRGB(240, 200, 80))

	-- The locker view: you look OUT through the door's slits. The frame itself is fully transparent; the dark slats leave
	-- real gaps (about 60% of the screen is clear), with a soft shadow at the left and right edges.
	local hiding = Instance.new("Frame")
	hiding.Name = "Hiding"
	hiding.Size = UDim2.fromScale(1, 1)
	hiding.BackgroundTransparency = 1
	hiding.BorderSizePixel = 0
	hiding.Visible = false
	hiding.Active = false
	hiding.Parent = gui
	for i = 0, 9 do
		local slat = Instance.new("Frame")
		slat.Name = "Slat"
		slat.Position = UDim2.fromScale(0, 0.04 + i * 0.096)
		slat.Size = UDim2.fromScale(1, 0.034)
		slat.BackgroundColor3 = Color3.fromRGB(14, 12, 12)
		slat.BackgroundTransparency = 0.04
		slat.BorderSizePixel = 0
		slat.Parent = hiding
	end
	for _, edge in { 0, 0.92 } do
		local shade = Instance.new("Frame")
		shade.Name = "Shade"
		shade.Position = UDim2.fromScale(edge, 0)
		shade.Size = UDim2.fromScale(0.08, 1)
		shade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		shade.BackgroundTransparency = 0.45
		shade.BorderSizePixel = 0
		shade.Parent = hiding
	end
	local hidingText = Instance.new("TextLabel")
	hidingText.Name = "HidingText"
	hidingText.BackgroundTransparency = 1
	hidingText.AnchorPoint = Vector2.new(0.5, 0)
	hidingText.Position = UDim2.fromScale(0.5, 0.64) -- below the slats, clear of the Status/Tasks/Role stack
	hidingText.Size = UDim2.fromScale(0.5, 0.08)
	hidingText.Text = "HIDING... stay quiet"
	hidingText.TextColor3 = Color3.fromRGB(190, 190, 200)
	hidingText.Font = Enum.Font.GothamBold
	hidingText.TextScaled = true
	hidingText.Parent = hiding
	local leaveButton = Instance.new("TextButton")
	leaveButton.Name = "Leave"
	leaveButton.AnchorPoint = Vector2.new(0.5, 0)
	leaveButton.Position = UDim2.fromScale(0.5, 0.82)
	leaveButton.Size = UDim2.fromScale(0.22, 0.07)
	leaveButton.Text = "LEAVE (E)"
	leaveButton.TextScaled = true
	leaveButton.Font = Enum.Font.GothamBold
	leaveButton.TextColor3 = Color3.fromRGB(235, 240, 255)
	leaveButton.BackgroundColor3 = Color3.fromRGB(60, 20, 30)
	leaveButton.Parent = hiding

	-- "how to play": shown the first time you are given a role, closed with one tap
	local guide = Instance.new("Frame")
	guide.Name = "Guide"
	guide.AnchorPoint = Vector2.new(0.5, 0.5)
	guide.Position = UDim2.fromScale(0.5, 0.5)
	guide.Size = UDim2.fromScale(0.56, 0.62)
	guide.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
	guide.BackgroundTransparency = 0.08
	guide.BorderSizePixel = 0
	guide.Visible = false
	guide.ZIndex = 10
	guide.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = guide
	local guideTitle = Instance.new("TextLabel")
	guideTitle.BackgroundTransparency = 1
	guideTitle.Position = UDim2.fromScale(0.05, 0.04)
	guideTitle.Size = UDim2.fromScale(0.9, 0.12)
	guideTitle.Text = `{Config.GameName}: HOW TO PLAY`
	guideTitle.TextColor3 = Color3.fromRGB(255, 190, 90)
	guideTitle.Font = Enum.Font.GothamBlack
	guideTitle.TextScaled = true
	guideTitle.ZIndex = 11
	guideTitle.Parent = guide
	local guideBody = Instance.new("TextLabel")
	guideBody.BackgroundTransparency = 1
	guideBody.Position = UDim2.fromScale(0.05, 0.19)
	guideBody.Size = UDim2.fromScale(0.9, 0.62)
	guideBody.RichText = true
	guideBody.TextXAlignment = Enum.TextXAlignment.Left
	guideBody.TextYAlignment = Enum.TextYAlignment.Top
	guideBody.TextWrapped = true
	guideBody.TextScaled = true
	guideBody.Font = Enum.Font.Gotham
	guideBody.TextColor3 = Color3.fromRGB(225, 225, 235)
	guideBody.ZIndex = 11
	guideBody.Text = "<b>The Night Manager hunts this hotel.</b> It has three floors; stairs are at both ends of the long corridor.\n"
		.. "<b>CREW:</b> hold <b>E</b> at the orange stations to finish every task before dawn.\n"
		.. "<b>SABOTEUR:</b> secretly help him. Fake tasks, stay unseen, and don't be the last one standing with the crew.\n"
		.. "<b>RUN</b> (Shift) is loud. <b>LIGHT</b> (F) draws him, but hold it on him for a second and he is <b>blinded</b> for three. Stand still to be quiet.\n"
		.. "<b>HIDE</b> in lockers and wardrobes (hold E). He searches the ones he lingers beside."
	guideBody.Parent = guide
	local guideClose = Instance.new("TextButton")
	guideClose.AnchorPoint = Vector2.new(0.5, 1)
	guideClose.Position = UDim2.fromScale(0.5, 0.95)
	guideClose.Size = UDim2.fromScale(0.34, 0.11)
	guideClose.Text = "GOT IT"
	guideClose.TextScaled = true
	guideClose.Font = Enum.Font.GothamBold
	guideClose.TextColor3 = Color3.fromRGB(20, 14, 10)
	guideClose.BackgroundColor3 = Color3.fromRGB(255, 190, 90)
	guideClose.ZIndex = 11
	guideClose.Parent = guide
	local guideSeen = false
	guideClose.Activated:Connect(function()
		guide.Visible = false
		guideSeen = true
	end)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	leaveButton.Activated:Connect(function()
		local intent = remotes:WaitForChild("Intent") :: RemoteEvent
		intent:FireServer({ leave = true })
	end)
	local roleAssigned = remotes:WaitForChild("RoleAssigned") :: RemoteEvent

	local isSaboteur = false
	local haveRole = false
	roleAssigned.OnClientEvent:Connect(function(myRole: string, allies: { string }?)
		if not guideSeen then
			guide.Visible = true
		end
		isSaboteur = myRole == "Saboteur"
		haveRole = true
		local partner = if allies and #allies > 0 then `  (with {table.concat(allies, ", ")})` else ""
		role.Text = `You are: {string.upper(myRole)}{partner}`
		role.TextColor3 = if myRole == "Saboteur" then Color3.fromRGB(255, 80, 120) else Color3.fromRGB(90, 220, 255)
	end)

	-- saboteur abilities: LURE sends him to where you stand, LIGHTS darkens your floor
	local abilityRemote = remotes:WaitForChild("Ability") :: RemoteEvent
	local abilityButtons: { { button: TextButton, attribute: string, name: string, kind: string } } = {}
	for i, def in { { "lure", "LURE", "LureReadyAt" }, { "lights", "LIGHTS OUT", "LightsReadyAt" } } do
		local button = Instance.new("TextButton")
		button.AnchorPoint = Vector2.new(1, 1)
		button.Position = UDim2.fromScale(0.98, 0.98 - (i - 1) * 0.075)
		button.Size = UDim2.fromScale(0.16, 0.065)
		button.BackgroundColor3 = Color3.fromRGB(70, 22, 36)
		button.TextColor3 = Color3.fromRGB(255, 220, 226)
		button.Font = Enum.Font.GothamBold
		button.TextScaled = true
		button.Visible = false
		button.Parent = gui
		local kind = def[1]
		button.Activated:Connect(function()
			abilityRemote:FireServer(kind)
		end)
		table.insert(abilityButtons, { button = button, attribute = def[3], name = def[2], kind = kind })
	end

	RunService.RenderStepped:Connect(function()
		local phase = ReplicatedStorage:GetAttribute("Phase") or "Lobby"
		local endsAt = ReplicatedStorage:GetAttribute("PhaseEndsAt") or 0
		local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
		local done = ReplicatedStorage:GetAttribute("TasksDone") or 0
		local total = ReplicatedStorage:GetAttribute("TasksTotal") or 0
		local root = Players.LocalPlayer.Character
			and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local level = Floors.levelAt(root.Position.Y - 3)
			floorLabel.Text = if level > 0 then "FLOOR 2  UPSTAIRS" elseif level < 0 then "BASEMENT" else "GROUND FLOOR"
		end
		local me = Players.LocalPlayer
		staminaFill.Size = UDim2.fromScale(math.clamp((me:GetAttribute("Stamina") or 100) / 100, 0, 1), 1)
		batteryFill.Size = UDim2.fromScale(math.clamp((me:GetAttribute("Battery") or 100) / 100, 0, 1), 1)
		hiding.Visible = me:GetAttribute("Hidden") == true
		for _, a in abilityButtons do
			a.button.Visible = isSaboteur and phase == "Night"
			local wait = math.max(0, math.ceil((me:GetAttribute(a.attribute) or 0) - workspace:GetServerTimeNow()))
			a.button.Text = if wait > 0 then `{a.name} {wait}s` else a.name
			a.button.Active = wait == 0
			a.button.BackgroundTransparency = if wait > 0 then 0.6 else 0.1
		end
		if phase == "Lobby" or phase == "Intermission" then
			haveRole = false -- a new round hands out new roles
			isSaboteur = false
		end
		role.Visible = haveRole and (phase == "Night" or phase == "Meeting")
		tasks.Visible = phase == "Night" or phase == "Meeting"
		tasks.Text = `TASKS {done}/{total}`
		if phase == "Lobby" then
			local need = ReplicatedStorage:GetAttribute("MinPlayers") or 1
			status.Text = `Waiting for players ({#Players:GetPlayers()}/{need})`
		elseif phase == "Intermission" then
			status.Text = `Night begins in {left}s`
		elseif phase == "Dawn" then
			status.Text = "DAWN"
		else
			status.Text = `{string.upper(phase)}  {left}s`
		end
		-- a tip of the night while you wait (the same one for everybody in a round)
		tip.Visible = phase == "Intermission"
		if tip.Visible then
			local round = ReplicatedStorage:GetAttribute("RoundNumber") or 0
			if tipFor ~= round then
				tipFor = round
				tip.Text = "TIP: " .. Config.Tips[(round % #Config.Tips) + 1]
			end
		end
	end)
end

return Hud
