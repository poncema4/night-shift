--!strict
-- The lobby's title screen: the game's name (the sign flickers like a dying hotel sign), the studio's logo, and
-- PLAY / OPTIONS / INFO. PLAY opens the party screen. Only shown on the lobby server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local LobbyFx = require(script.Parent.LobbyFx)
local Options = require(script.Parent.Options)
local PartyUi = require(script.Parent.PartyUi)
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

function Menu.start()
	local me = Players.LocalPlayer
	LobbyFx.start()
	local gui = Ui.screen(me:WaitForChild("PlayerGui"), "NightShiftMenu", 30)

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Ui.INK
	backdrop.BackgroundTransparency = 0.25
	backdrop.BorderSizePixel = 0
	backdrop.Parent = gui

	-- the studio's logo, used as given
	local logo = Instance.new("ImageLabel")
	logo.BackgroundTransparency = 1
	logo.Image = `rbxthumb://type=GroupIcon&id={Config.Brand.GroupId}&w=420&h=420`
	logo.Position = UDim2.fromScale(0.03, 0.04)
	logo.Size = UDim2.fromOffset(64, 64)
	logo.Parent = backdrop
	Ui.label(
		backdrop,
		Config.StudioName:upper(),
		Enum.Font.GothamMedium,
		Ui.MUTED,
		UDim2.new(0.03, 72, 0.04, 14),
		UDim2.fromOffset(260, 36)
	)

	local title = Ui.label(
		backdrop,
		Config.GameName,
		Enum.Font.GothamBlack,
		Ui.TEXT,
		UDim2.fromScale(0.05, 0.2),
		UDim2.fromScale(0.42, 0.14)
	)
	title.TextXAlignment = Enum.TextXAlignment.Left
	Ui.label(
		backdrop,
		"The hotel never sleeps. He hears everything.",
		Enum.Font.GothamMedium,
		Ui.AMBER,
		UDim2.fromScale(0.05, 0.35),
		UDim2.fromScale(0.42, 0.04)
	).TextXAlignment =
		Enum.TextXAlignment.Left

	local main = Instance.new("Frame")
	main.BackgroundTransparency = 1
	main.Position = UDim2.fromScale(0.05, 0.45)
	main.Size = UDim2.fromScale(0.28, 0.4)
	main.Parent = backdrop

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local party = PartyUi.build(backdrop, remotes)
	party.Visible = false
	local shop = StoreUi.build(backdrop, remotes)
	shop.Visible = false

	local side = Ui.panel(backdrop, UDim2.fromScale(0.52, 0.18), UDim2.fromScale(0.44, 0.66))
	side.Visible = false
	local sideTitle =
		Ui.label(side, "", Enum.Font.GothamBlack, Ui.AMBER, UDim2.fromScale(0.05, 0.03), UDim2.fromScale(0.9, 0.08))
	local body = Ui.label(side, "", Enum.Font.Gotham, Ui.TEXT, UDim2.fromScale(0.05, 0.14), UDim2.fromScale(0.9, 0.5))
	body.TextScaled = false
	body.TextSize = 20
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top

	local function show(which: string)
		party.Visible = which == "play"
		shop.Visible = which == "shop"
		side.Visible = which == "options" or which == "info"
		sideTitle.Text = if which == "options" then "OPTIONS" elseif which == "info" then "HOW IT WORKS" else ""
		body.Text = if which == "info" then table.concat(INFO, "\n\n") else ""
	end

	-- options live in the side panel as three rows
	local volume =
		Ui.label(side, "", Enum.Font.GothamBold, Ui.TEXT, UDim2.fromScale(0.05, 0.16), UDim2.fromScale(0.5, 0.07))
	local function refreshOptions()
		volume.Text = `VOLUME  {math.floor(Options.volume() * 100)}%`
	end
	local optionRows: { GuiObject } = { volume }
	local function addOption(
		text: string,
		position: UDim2,
		size: UDim2,
		onClick: () -> (),
		accent: boolean?
	): TextButton
		local b = Ui.button(side, text, position, size, onClick, accent)
		table.insert(optionRows, b)
		return b
	end
	addOption("-", UDim2.fromScale(0.6, 0.16), UDim2.fromScale(0.15, 0.07), function()
		Options.nudgeVolume(-0.1)
	end)
	addOption("+", UDim2.fromScale(0.8, 0.16), UDim2.fromScale(0.15, 0.07), function()
		Options.nudgeVolume(0.1)
	end)
	local subs: TextButton
	subs = addOption("", UDim2.fromScale(0.05, 0.28), UDim2.fromScale(0.9, 0.08), function()
		Options.set("subtitles", not Options.get("subtitles"))
	end)
	local calm: TextButton
	calm = addOption("", UDim2.fromScale(0.05, 0.4), UDim2.fromScale(0.9, 0.08), function()
		Options.set("calm", not Options.get("calm"))
	end)
	local function refreshAll()
		refreshOptions()
		subs.Text = `SUBTITLES: {if Options.get("subtitles") then "ON" else "OFF"}`
		calm.Text = `REDUCED FLASHING: {if Options.get("calm") then "ON" else "OFF"}`
	end
	Options.onChange(refreshAll)
	refreshAll()
	local function setOptionsVisible(on: boolean)
		for _, row in optionRows do
			row.Visible = on
		end
	end
	setOptionsVisible(false)

	local function open(which: string)
		show(which)
		setOptionsVisible(which == "options")
	end
	Ui.button(main, "PLAY", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.22), function()
		open("play")
	end, true)
	Ui.button(main, "OPTIONS", UDim2.fromScale(0, 0.28), UDim2.fromScale(1, 0.16), function()
		open("options")
	end)
	Ui.button(main, "SHOP", UDim2.fromScale(0, 0.48), UDim2.fromScale(1, 0.16), function()
		open("shop")
	end)
	Ui.button(main, "INFO", UDim2.fromScale(0, 0.68), UDim2.fromScale(1, 0.16), function()
		open("info")
	end)
	open("play")

	-- the sign: THE NIGHT MANAGER flickers now and then
	task.spawn(function()
		while gui.Parent do
			task.wait(2 + math.random() * 5)
			for _ = 1, 3 do
				title.TextTransparency = 0.7
				task.wait(0.06)
				title.TextTransparency = 0
				task.wait(0.09)
			end
		end
	end)

	-- the hand-off: when the party launches, show our own loading screen through the teleport
	local launching = remotes:WaitForChild("PartyLaunching") :: RemoteEvent
	local transit = Ui.screen(me.PlayerGui, "NightShiftTransit", 100)
	transit.Enabled = false
	local cover = Instance.new("Frame")
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = Ui.INK
	cover.BorderSizePixel = 0
	cover.Parent = transit
	Ui.label(
		cover,
		"ENTERING THE HOTEL",
		Enum.Font.GothamBlack,
		Ui.TEXT,
		UDim2.fromScale(0.2, 0.4),
		UDim2.fromScale(0.6, 0.1)
	)
	local tip =
		Ui.label(cover, "", Enum.Font.GothamMedium, Ui.AMBER, UDim2.fromScale(0.15, 0.55), UDim2.fromScale(0.7, 0.05))
	launching.OnClientEvent:Connect(function(count: number)
		tip.Text = `Party of {count}. ` .. Config.Tips[math.random(#Config.Tips)]
		transit.Enabled = true
		TeleportService:SetTeleportGui(cover)
	end)
end

return Menu
