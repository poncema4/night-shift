--!strict
-- The emergency meeting screen: who called it, a card for every living player (tap to vote), SKIP, a countdown,
-- ticks next to people who have voted, and at the end the result. Sizes use scale so phones fit.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MeetingUi = {}

type Card = { frame: Frame, tick: TextLabel, button: TextButton }

local function text(
	parent: Instance,
	name: string,
	position: UDim2,
	size: UDim2,
	font: Enum.Font,
	color: Color3
): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Position = position
	l.Size = size
	l.Font = font
	l.TextColor3 = color
	l.TextScaled = true
	l.Text = ""
	l.Parent = parent
	return l
end

function MeetingUi.start()
	local me = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local startEvent = remotes:WaitForChild("MeetingStart") :: RemoteEvent
	local votedEvent = remotes:WaitForChild("MeetingVoted") :: RemoteEvent
	local resultEvent = remotes:WaitForChild("MeetingResult") :: RemoteEvent
	local voteEvent = remotes:WaitForChild("Vote") :: RemoteEvent

	local gui = Instance.new("ScreenGui")
	gui.Name = "NightShiftMeeting"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.Enabled = false
	gui.Parent = me:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.78, 0.84)
	panel.BackgroundColor3 = Color3.fromRGB(14, 12, 20)
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 16)
	round.Parent = panel

	local title = text(
		panel,
		"Title",
		UDim2.fromScale(0.04, 0.03),
		UDim2.fromScale(0.92, 0.1),
		Enum.Font.GothamBlack,
		Color3.fromRGB(255, 120, 110)
	)
	local sub = text(
		panel,
		"Sub",
		UDim2.fromScale(0.04, 0.13),
		UDim2.fromScale(0.92, 0.055),
		Enum.Font.GothamMedium,
		Color3.fromRGB(200, 200, 215)
	)
	local clock = text(
		panel,
		"Clock",
		UDim2.fromScale(0.78, 0.03),
		UDim2.fromScale(0.18, 0.08),
		Enum.Font.GothamBold,
		Color3.fromRGB(255, 190, 90)
	)

	local grid = Instance.new("Frame")
	grid.Name = "Players"
	grid.BackgroundTransparency = 1
	grid.Position = UDim2.fromScale(0.04, 0.21)
	grid.Size = UDim2.fromScale(0.92, 0.5)
	grid.Parent = panel
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromScale(0.23, 0.46)
	layout.CellPadding = UDim2.fromScale(0.02, 0.05)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local skip = Instance.new("TextButton")
	skip.AnchorPoint = Vector2.new(0.5, 0)
	skip.Position = UDim2.fromScale(0.5, 0.74)
	skip.Size = UDim2.fromScale(0.3, 0.09)
	skip.Text = "SKIP VOTE"
	skip.TextScaled = true
	skip.Font = Enum.Font.GothamBold
	skip.TextColor3 = Color3.fromRGB(230, 230, 240)
	skip.BackgroundColor3 = Color3.fromRGB(50, 50, 66)
	skip.Parent = panel
	local skipCorner = Instance.new("UICorner")
	skipCorner.Parent = skip

	local result = text(
		panel,
		"Result",
		UDim2.fromScale(0.04, 0.86),
		UDim2.fromScale(0.92, 0.11),
		Enum.Font.GothamBlack,
		Color3.fromRGB(255, 255, 255)
	)
	result.Visible = false

	local cards: { [number]: Card } = {}
	local voted = false
	local endsAt = 0
	local openedAt = -100 -- when the meeting opened: the phase attribute can arrive a moment after the message

	local function clearCards()
		for _, card in cards do
			card.frame:Destroy()
		end
		cards = {}
	end

	local function cast(target: number | string)
		if voted then
			return
		end
		voted = true
		voteEvent:FireServer(target)
		skip.Active = false
		skip.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		for _, card in cards do
			card.button.Active = false
		end
	end

	skip.Activated:Connect(function()
		cast("skip")
		skip.Text = "SKIPPED"
	end)

	startEvent.OnClientEvent:Connect(
		function(
			info: { reason: string, caller: string, victim: string?, players: { { userId: number, name: string } } }
		)
			clearCards()
			voted = false
			result.Visible = false
			skip.Active = true
			skip.Text = "SKIP VOTE"
			skip.BackgroundColor3 = Color3.fromRGB(50, 50, 66)
			if info.reason == "body" then
				title.Text = `BODY REPORTED: {string.upper(info.victim or "?")}`
			else
				title.Text = "EMERGENCY MEETING"
			end
			sub.Text = `Called by {info.caller}. Talk in chat, then vote someone out.`
			local alive = false
			for i, p in info.players do
				if p.userId == me.UserId then
					alive = true
				end
				local frame = Instance.new("Frame")
				frame.LayoutOrder = i
				frame.BackgroundColor3 = Color3.fromRGB(26, 24, 36)
				frame.BorderSizePixel = 0
				frame.Parent = grid
				local corner = Instance.new("UICorner")
				corner.Parent = frame
				local face = Instance.new("ImageLabel")
				face.BackgroundTransparency = 1
				face.Position = UDim2.fromScale(0.2, 0.06)
				face.Size = UDim2.fromScale(0.6, 0.6)
				face.SizeConstraint = Enum.SizeConstraint.RelativeYY
				face.Parent = frame
				task.spawn(function()
					local ok, content = pcall(function()
						return Players:GetUserThumbnailAsync(
							p.userId,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size100x100
						)
					end)
					if ok then
						face.Image = content
					end
				end)
				local name = text(
					frame,
					"Name",
					UDim2.fromScale(0.05, 0.68),
					UDim2.fromScale(0.9, 0.16),
					Enum.Font.GothamBold,
					Color3.fromRGB(235, 235, 245)
				)
				name.Text = p.name
				local tick = text(
					frame,
					"Tick",
					UDim2.fromScale(0.62, 0.04),
					UDim2.fromScale(0.34, 0.2),
					Enum.Font.GothamBlack,
					Color3.fromRGB(120, 230, 150)
				)
				local button = Instance.new("TextButton")
				button.BackgroundTransparency = 1
				button.Size = UDim2.fromScale(1, 1)
				button.Text = ""
				button.Parent = frame
				button.Activated:Connect(function()
					if not voted and alive then
						cast(p.userId)
						frame.BackgroundColor3 = Color3.fromRGB(70, 40, 50)
					end
				end)
				cards[p.userId] = { frame = frame, tick = tick, button = button }
			end
			if not alive then
				skip.Active = false
				skip.Text = "YOU ARE OUT: WATCH"
			end
			gui.Enabled = true
		end
	)

	votedEvent.OnClientEvent:Connect(function(userId: number)
		local card = cards[userId]
		if card then
			card.tick.Text = "VOTED"
		end
	end)

	resultEvent.OnClientEvent:Connect(function(info: {
		ejected: string?,
		role: string?,
		tie: boolean,
		skips: number,
		counts: { { name: string, votes: number } },
	})
		result.Visible = true
		skip.Visible = false
		if info.ejected then
			local role = string.upper(info.role or "Crew")
			result.Text = `{string.upper(info.ejected)} WAS EJECTED  ({role})`
			result.TextColor3 = if info.role == "Saboteur"
				then Color3.fromRGB(120, 230, 150)
				else Color3.fromRGB(255, 120, 110)
		elseif info.tie then
			result.Text = "TIE: NO ONE WAS EJECTED"
			result.TextColor3 = Color3.fromRGB(230, 230, 240)
		else
			result.Text = "NO ONE WAS EJECTED"
			result.TextColor3 = Color3.fromRGB(230, 230, 240)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local phase = ReplicatedStorage:GetAttribute("Phase")
		if phase ~= "Meeting" then
			if gui.Enabled and os.clock() - openedAt > 3 then
				gui.Enabled = false
				skip.Visible = true
			end
			return
		end
		endsAt = ReplicatedStorage:GetAttribute("PhaseEndsAt") or 0
		clock.Text = `{math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))}s`
	end)
end

return MeetingUi
