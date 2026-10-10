--!strict
-- The dawn screen: who won, how many tasks got done, and what happened to everyone (with their secret roles).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Ui = require(script.Parent.Ui)

local Results = {}

local FATE_TEXT = { survived = "SURVIVED", caught = "CAUGHT", ejected = "EJECTED" }

function Results.start()
	local me = Players.LocalPlayer
	local roundResult = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundResult") :: RemoteEvent

	local gui = Instance.new("ScreenGui")
	gui.Name = "NightShiftResults"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 15
	gui.Enabled = false
	gui.Parent = me:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.62, 0.78)
	panel.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = panel

	local function label(name: string, position: UDim2, size: UDim2, font: Enum.Font): TextLabel
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = position
		l.Size = size
		l.Font = font
		l.TextScaled = true
		l.TextColor3 = Color3.fromRGB(240, 240, 250)
		l.Text = ""
		l.Parent = panel
		return l
	end
	local headline = label("Headline", UDim2.fromScale(0.04, 0.04), UDim2.fromScale(0.92, 0.14), Enum.Font.GothamBlack)
	local tasks = label("Tasks", UDim2.fromScale(0.04, 0.19), UDim2.fromScale(0.92, 0.06), Enum.Font.GothamMedium)
	local you = label("You", UDim2.fromScale(0.04, 0.26), UDim2.fromScale(0.5, 0.06), Enum.Font.GothamBold)
	local earned = label("Earned", UDim2.fromScale(0.5, 0.26), UDim2.fromScale(0.46, 0.06), Enum.Font.GothamBlack)
	earned.TextColor3 = Color3.fromRGB(150, 235, 160)

	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromScale(0.04, 0.35)
	list.Size = UDim2.fromScale(0.92, 0.6)
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	-- leave now instead of waiting for the automatic trip back to the lobby
	local leave = Ui.button(
		panel,
		"RETURN TO LOBBY",
		UDim2.fromScale(0.32, 0.92),
		UDim2.fromScale(0.36, 0.06),
		function()
			ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("LeaveMatch"):FireServer()
		end
	)
	leave.ZIndex = 5

	-- the countdown to the lobby (or the next night) and the fade to black that ends it
	local countdown =
		Ui.label(gui, "", Enum.Font.GothamBlack, Ui.AMBER, UDim2.fromScale(0.2, 0.02), UDim2.fromScale(0.6, 0.05))
	countdown.Name = "Countdown"
	countdown.TextXAlignment = Enum.TextXAlignment.Center
	countdown.TextStrokeTransparency = 0.5
	countdown.ZIndex = 6
	local fade = Instance.new("Frame")
	fade.Name = "Fade"
	fade.Size = UDim2.fromScale(1, 1)
	fade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	fade.BackgroundTransparency = 1
	fade.BorderSizePixel = 0
	fade.ZIndex = 20
	fade.Active = false
	fade.Parent = gui

	local shownAt = -100 -- the phase attribute can arrive a moment after the result message
	local awardEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Award") :: RemoteEvent
	awardEvent.OnClientEvent:Connect(function(info: { xp: number, tips: number, levelUp: boolean })
		earned.Text = `+{info.xp} XP   +{info.tips} tips{if info.levelUp then "   LEVEL UP!" else ""}`
	end)

	roundResult.OnClientEvent:Connect(function(info: {
		winner: string?,
		players: { { name: string, role: string, fate: string } },
		tasksDone: number,
		tasksTotal: number,
	})
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local crewWon = info.winner == "Crew"
		headline.Text = if crewWon
			then "THE CREW SURVIVED THE NIGHT"
			elseif info.winner == "Saboteurs" then "THE SABOTEURS WIN"
			else "DAWN"
		headline.TextColor3 = if crewWon then Color3.fromRGB(120, 230, 150) else Color3.fromRGB(255, 110, 120)
		tasks.Text = `Tasks finished: {info.tasksDone} / {info.tasksTotal}`
		you.Text = ""
		for i, p in info.players do
			local row = Instance.new("Frame")
			row.LayoutOrder = i
			row.Size = UDim2.new(1, 0, 0, 30)
			row.BackgroundColor3 = if p.role == "Saboteur"
				then Color3.fromRGB(58, 22, 32)
				else Color3.fromRGB(22, 28, 40)
			row.BorderSizePixel = 0
			row.Parent = list
			local rowCorner = Instance.new("UICorner")
			rowCorner.Parent = row
			local name = Instance.new("TextLabel")
			name.BackgroundTransparency = 1
			name.Size = UDim2.fromScale(0.5, 1)
			name.Position = UDim2.fromScale(0.03, 0)
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Font = Enum.Font.GothamBold
			name.TextScaled = true
			name.TextColor3 = Color3.fromRGB(240, 240, 250)
			name.Text = p.name
			name.Parent = row
			local detail = Instance.new("TextLabel")
			detail.BackgroundTransparency = 1
			detail.Size = UDim2.fromScale(0.45, 1)
			detail.Position = UDim2.fromScale(0.52, 0)
			detail.TextXAlignment = Enum.TextXAlignment.Right
			detail.Font = Enum.Font.GothamMedium
			detail.TextScaled = true
			detail.TextColor3 = if p.role == "Saboteur"
				then Color3.fromRGB(255, 130, 150)
				else Color3.fromRGB(130, 210, 255)
			detail.Text = `{string.upper(p.role)}  {FATE_TEXT[p.fate] or p.fate}`
			detail.Parent = row
			if p.name == me.Name then
				you.Text = `You were {string.upper(p.role)}: {FATE_TEXT[p.fate] or p.fate}`
			end
		end
		shownAt = os.clock()
		gui.Enabled = true
	end)

	RunService.RenderStepped:Connect(function()
		if ReplicatedStorage:GetAttribute("Phase") == "Dawn" then
			local left =
				math.max(0, (ReplicatedStorage:GetAttribute("PhaseEndsAt") or 0) - workspace:GetServerTimeNow())
			local leaving = ReplicatedStorage:GetAttribute("ReturnsToLobby") == true
			countdown.Text = `{if leaving then "RETURNING TO LOBBY IN" else "NEXT NIGHT IN"} {math.ceil(left)}`
			fade.BackgroundTransparency = if leaving then math.clamp(left / 1.5, 0, 1) else 1
		else
			fade.BackgroundTransparency = 1
		end
		if gui.Enabled and ReplicatedStorage:GetAttribute("Phase") ~= "Dawn" and os.clock() - shownAt > 3 then
			gui.Enabled = false
			earned.Text = "" -- ready for the next round
		end
	end)
end

return Results
