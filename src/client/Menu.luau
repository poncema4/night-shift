--!strict
-- The lobby's interface. First a full-screen title ("click anywhere to continue"); then the lobby itself with NOTHING open:
-- just a small dock (PARTIES / SHOP / OPTIONS / INFO) whose windows open only when you ask. Standing in a queue pod shows a
-- size picker (first player in decides the party size) and, once queued, a LEAVE QUEUE button and a status chip.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local LobbyFx = require(script.Parent.LobbyFx)
local Options = require(script.Parent.Options)
local PartyUi = require(script.Parent.PartyUi)
local Pods = require(ReplicatedStorage.Shared.Game.Pods)
local StoreUi = require(script.Parent.StoreUi)
local Ui = require(script.Parent.Ui)

local Menu = {}

local INFO = {
	"You are the night crew of a grand hotel. One of you is not.",
	"Finish the tasks before dawn. Run, hide, and keep quiet: the Night Manager hunts what he hears.",
	"Your flashlight blinds him for a moment, and shows him where you are.",
	"Fewer than four players is co-op: nobody is a saboteur, just survive.",
	"Four or more: one of you is a saboteur. Call a meeting and vote.",
}

type View = { id: number, members: { number }, count: number, size: number, timeLeft: number }

local function windowFrame(parent: Instance): Frame
	local window = Instance.new("Frame")
	window.Name = "Window"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.46)
	window.Size = UDim2.fromScale(0.5, 0.72)
	window.BackgroundTransparency = 1
	window.Visible = false
	window.Parent = parent
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(420, 380)
	limits.MaxSize = Vector2.new(780, 640)
	limits.Parent = window
	return window
end

function Menu.start()
	local me = Players.LocalPlayer
	local playerGui = me:WaitForChild("PlayerGui")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local action = remotes:WaitForChild("PartyAction") :: RemoteEvent
	local partyState = remotes:WaitForChild("PartyState") :: RemoteEvent
	local podPrompt = remotes:WaitForChild("PodPrompt") :: RemoteEvent
	LobbyFx.start()

	-- ===== 1. the title screen =====
	local titleGui = Ui.screen(playerGui, "NightShiftTitle", 50)
	local cover = Instance.new("Frame")
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = Ui.INK
	cover.BorderSizePixel = 0
	cover.Parent = titleGui
	local title = Ui.label(
		cover,
		Config.GameName,
		Enum.Font.GothamBlack,
		Ui.TEXT,
		UDim2.fromScale(0.1, 0.3),
		UDim2.fromScale(0.8, 0.2)
	)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Name = "Title"
	local limit = title:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then
		limit.MaxTextSize = 120
	end
	local tagline = Ui.label(
		cover,
		"He hears everything.",
		Enum.Font.GothamMedium,
		Ui.AMBER,
		UDim2.fromScale(0.2, 0.5),
		UDim2.fromScale(0.6, 0.05)
	)
	tagline.TextXAlignment = Enum.TextXAlignment.Center
	local click = Ui.label(
		cover,
		"CLICK ANYWHERE TO CONTINUE",
		Enum.Font.GothamBold,
		Ui.MUTED,
		UDim2.fromScale(0.2, 0.82),
		UDim2.fromScale(0.6, 0.04)
	)
	click.TextXAlignment = Enum.TextXAlignment.Center
	click.Name = "Prompt"
	local credit = Ui.label(
		cover,
		Config.StudioName:upper(),
		Enum.Font.GothamMedium,
		Ui.MUTED,
		UDim2.fromScale(0.3, 0.93),
		UDim2.fromScale(0.4, 0.03)
	)
	credit.TextXAlignment = Enum.TextXAlignment.Center
	local anywhere = Instance.new("TextButton")
	anywhere.Name = "Anywhere"
	anywhere.BackgroundTransparency = 1
	anywhere.Text = ""
	anywhere.Size = UDim2.fromScale(1, 1)
	anywhere.Parent = cover

	-- the sign flickers and the prompt breathes
	local titleOpen = true
	task.spawn(function()
		while titleOpen do
			task.wait(2 + math.random() * 4)
			for _ = 1, 3 do
				title.TextTransparency = 0.7
				task.wait(0.06)
				title.TextTransparency = 0
				task.wait(0.09)
			end
		end
	end)
	local pulse = RunService.Heartbeat:Connect(function()
		click.TextTransparency = 0.25 + 0.4 * (0.5 + 0.5 * math.sin(os.clock() * 3))
	end)
	anywhere.Activated:Connect(function()
		if not titleOpen then
			return
		end
		titleOpen = false
		pulse:Disconnect()
		task.spawn(function()
			for step = 1, 10 do
				cover.BackgroundTransparency = step / 10
				for _, child in cover:GetChildren() do
					if child:IsA("TextLabel") then
						child.TextTransparency = math.max(child.TextTransparency, step / 10)
					end
				end
				task.wait(0.04)
			end
			titleGui.Enabled = false
		end)
	end)

	-- ===== 2. the dock and its windows =====
	local windowGui = Ui.screen(playerGui, "NightShiftMenu", 30)
	local window = windowFrame(windowGui)
	local panels: { [string]: Frame } = {}
	panels.parties = PartyUi.build(window, remotes)
	panels.shop = StoreUi.build(window, remotes)

	local function simplePanel(name: string, heading: string): Frame
		local panel = Ui.panel(window, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
		Ui.label(
			panel,
			heading,
			Enum.Font.GothamBlack,
			Ui.AMBER,
			UDim2.fromScale(0.05, 0.03),
			UDim2.fromScale(0.9, 0.08)
		)
		panels[name] = panel
		return panel
	end

	local info = simplePanel("info", "HOW IT WORKS")
	local body = Ui.label(
		info,
		table.concat(INFO, "\n\n"),
		Enum.Font.Gotham,
		Ui.TEXT,
		UDim2.fromScale(0.05, 0.14),
		UDim2.fromScale(0.9, 0.8)
	)
	body.TextYAlignment = Enum.TextYAlignment.Top

	local options = simplePanel("options", "OPTIONS")
	local volume =
		Ui.label(options, "", Enum.Font.GothamBold, Ui.TEXT, UDim2.fromScale(0.05, 0.16), UDim2.fromScale(0.5, 0.07))
	Ui.button(options, "-", UDim2.fromScale(0.6, 0.15), UDim2.fromScale(0.15, 0.09), function()
		Options.nudgeVolume(-0.1)
	end)
	Ui.button(options, "+", UDim2.fromScale(0.8, 0.15), UDim2.fromScale(0.15, 0.09), function()
		Options.nudgeVolume(0.1)
	end)
	local subs = Ui.button(options, "", UDim2.fromScale(0.05, 0.28), UDim2.fromScale(0.9, 0.1), function()
		Options.set("subtitles", not Options.get("subtitles"))
	end)
	local calm = Ui.button(options, "", UDim2.fromScale(0.05, 0.42), UDim2.fromScale(0.9, 0.1), function()
		Options.set("calm", not Options.get("calm"))
	end)
	local function refreshOptions()
		volume.Text = `VOLUME  {math.floor(Options.volume() * 100)}%`
		subs.Text = `SUBTITLES: {if Options.get("subtitles") then "ON" else "OFF"}`
		calm.Text = `REDUCED FLASHING: {if Options.get("calm") then "ON" else "OFF"}`
	end
	Options.onChange(refreshOptions)
	refreshOptions()

	local current: string? = nil
	local function show(which: string?)
		current = which
		window.Visible = which ~= nil
		for name, panel in panels do
			panel.Visible = name == which
		end
	end
	show(nil)
	local close = Ui.button(window, "X", UDim2.new(1, -44, 0, 6), UDim2.fromOffset(38, 34), function()
		show(nil)
	end)
	close.ZIndex = 10
	close.Name = "Close"

	local dock = Instance.new("Frame")
	dock.Name = "Dock"
	dock.AnchorPoint = Vector2.new(0, 1)
	dock.Position = UDim2.new(0, 16, 1, -16)
	dock.Size = UDim2.fromOffset(560, 46)
	dock.BackgroundTransparency = 1
	dock.Parent = windowGui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.Parent = dock
	for _, entry in { { "PARTIES", "parties" }, { "SHOP", "shop" }, { "OPTIONS", "options" }, { "INFO", "info" } } do
		local button = Ui.button(dock, entry[1], UDim2.new(), UDim2.fromOffset(132, 46), function()
			show(if current == entry[2] then nil else entry[2])
		end)
		button.Name = entry[1]
	end

	-- ===== 3. the size picker (first player into an empty pod chooses the party size) =====
	local pickGui = Ui.screen(playerGui, "NightShiftSizePicker", 40)
	local picker = Ui.panel(pickGui, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(440, 330))
	picker.AnchorPoint = Vector2.new(0.5, 0.5)
	picker.Visible = false
	Ui.label(
		picker,
		"HOW MANY PLAYERS?",
		Enum.Font.GothamBlack,
		Ui.AMBER,
		UDim2.fromOffset(20, 14),
		UDim2.new(1, -40, 0, 40)
	)
	Ui.label(
		picker,
		"You choose the party size. Friends can join until it is full. Pick 1 to play alone.",
		Enum.Font.Gotham,
		Ui.MUTED,
		UDim2.fromOffset(20, 58),
		UDim2.new(1, -40, 0, 44)
	)
	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Position = UDim2.fromOffset(20, 112)
	grid.Size = UDim2.new(1, -40, 0, 136)
	grid.Parent = picker
	local cells = Instance.new("UIGridLayout")
	cells.CellSize = UDim2.fromOffset(90, 60)
	cells.CellPadding = UDim2.fromOffset(10, 14)
	cells.SortOrder = Enum.SortOrder.LayoutOrder
	cells.Parent = grid
	local pending = 0
	for n = 1, Config.Lobby.MaxParty do
		local b = Ui.button(grid, tostring(n), UDim2.new(), UDim2.fromOffset(90, 60), function()
			action:FireServer("podsize", pending, n)
		end, n == Config.Lobby.DefaultParty)
		b.LayoutOrder = n
		b.Name = `Size{n}`
	end
	local backOut = Ui.button(picker, "CANCEL", UDim2.new(0.5, -90, 1, -58), UDim2.fromOffset(180, 44), function()
		action:FireServer("leave")
	end)
	backOut.Name = "Cancel"
	podPrompt.OnClientEvent:Connect(function(podId: number)
		pending = podId
		picker.Visible = podId > 0
	end)

	-- ===== 4. queued: status chip + LEAVE QUEUE =====
	local queueGui = Ui.screen(playerGui, "NightShiftQueue", 35)
	local chip = Ui.panel(queueGui, UDim2.new(0.5, -230, 0, 16), UDim2.fromOffset(460, 56))
	chip.Visible = false
	local chipText =
		Ui.label(chip, "", Enum.Font.GothamBold, Ui.TEXT, UDim2.fromOffset(16, 8), UDim2.new(1, -32, 1, -16))
	chipText.Name = "Status"
	chipText.TextXAlignment = Enum.TextXAlignment.Center
	local leaveButton = Ui.button(
		queueGui,
		"LEAVE QUEUE",
		UDim2.new(0.5, -120, 1, -78),
		UDim2.fromOffset(240, 52),
		function()
			action:FireServer("leave")
		end
	)
	leaveButton.Visible = false
	leaveButton.Name = "LeaveQueue"
	partyState.OnClientEvent:Connect(function(parties: { View })
		local mine: View? = nil
		for _, party in parties do
			if table.find(party.members, me.UserId) then
				mine = party
			end
		end
		chip.Visible = mine ~= nil
		leaveButton.Visible = mine ~= nil
		if mine then
			chipText.Text = `YOUR PARTY  {Pods.status(mine.count, mine.size)}  -  starts in {math.ceil(mine.timeLeft)}s`
		end
	end)

	-- ===== 5. the hand-off: our own loading screen through the teleport =====
	local launching = remotes:WaitForChild("PartyLaunching") :: RemoteEvent
	local transit = Ui.screen(playerGui, "NightShiftTransit", 100)
	transit.Enabled = false
	local transitCover = Instance.new("Frame")
	transitCover.Size = UDim2.fromScale(1, 1)
	transitCover.BackgroundColor3 = Ui.INK
	transitCover.BorderSizePixel = 0
	transitCover.Parent = transit
	local entering = Ui.label(
		transitCover,
		"ENTERING THE HOTEL",
		Enum.Font.GothamBlack,
		Ui.TEXT,
		UDim2.fromScale(0.2, 0.4),
		UDim2.fromScale(0.6, 0.1)
	)
	entering.TextXAlignment = Enum.TextXAlignment.Center
	local tip = Ui.label(
		transitCover,
		"",
		Enum.Font.GothamMedium,
		Ui.AMBER,
		UDim2.fromScale(0.15, 0.55),
		UDim2.fromScale(0.7, 0.06)
	)
	tip.TextXAlignment = Enum.TextXAlignment.Center
	launching.OnClientEvent:Connect(function(count: number)
		tip.Text = `Party of {count}. ` .. Config.Tips[math.random(#Config.Tips)]
		transit.Enabled = true
		picker.Visible = false
		show(nil)
		TeleportService:SetTeleportGui(transitCover)
	end)
end

return Menu
