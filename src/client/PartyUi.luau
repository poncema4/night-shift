--!strict
-- The party screen: create a party of any size, join an open one, or Quick Play. Shows your party's queue clock
-- ("starts in 18s", or 5s once it is full). All rules are on the server; this only shows state and sends intents.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Ui = require(script.Parent.Ui)

local PartyUi = {}

type View = {
	id: number,
	leader: number,
	size: number,
	count: number,
	members: { number },
	timeLeft: number,
	full: boolean,
}

local ROWS = 5

function PartyUi.build(parent: Instance, remotes: Instance): Frame
	local me = Players.LocalPlayer
	local action = remotes:WaitForChild("PartyAction") :: RemoteEvent
	local stateEvent = remotes:WaitForChild("PartyState") :: RemoteEvent
	local noticeEvent = remotes:WaitForChild("PartyNotice") :: RemoteEvent

	local panel = Ui.panel(parent, UDim2.fromScale(0.52, 0.18), UDim2.fromScale(0.44, 0.66))
	Ui.label(
		panel,
		"FIND YOUR CREW",
		Enum.Font.GothamBlack,
		Ui.AMBER,
		UDim2.fromScale(0.05, 0.03),
		UDim2.fromScale(0.9, 0.08)
	)
	local status =
		Ui.label(panel, "", Enum.Font.GothamMedium, Ui.TEXT, UDim2.fromScale(0.05, 0.12), UDim2.fromScale(0.9, 0.06))

	-- how big a party you want
	local wanted = Config.Lobby.DefaultParty
	local sizeLabel =
		Ui.label(panel, "", Enum.Font.GothamBold, Ui.TEXT, UDim2.fromScale(0.34, 0.2), UDim2.fromScale(0.32, 0.07))
	local function refreshSize()
		sizeLabel.Text = `PARTY OF {wanted}`
	end
	refreshSize()
	Ui.button(panel, "-", UDim2.fromScale(0.05, 0.2), UDim2.fromScale(0.12, 0.07), function()
		wanted = math.max(1, wanted - 1)
		refreshSize()
	end)
	Ui.button(panel, "+", UDim2.fromScale(0.83, 0.2), UDim2.fromScale(0.12, 0.07), function()
		wanted = math.min(Config.Lobby.MaxParty, wanted + 1)
		refreshSize()
	end)
	Ui.button(panel, "CREATE PARTY", UDim2.fromScale(0.05, 0.3), UDim2.fromScale(0.43, 0.09), function()
		action:FireServer("create", wanted)
	end, true)
	Ui.button(panel, "QUICK PLAY", UDim2.fromScale(0.52, 0.3), UDim2.fromScale(0.43, 0.09), function()
		action:FireServer("quick")
	end)

	-- each row joins whichever party it currently shows (the server sends the list in a stable order)
	local rows: { TextButton } = {}
	local shown: { [number]: number? } = {}
	for i = 1, ROWS do
		local row = Ui.button(
			panel,
			"",
			UDim2.fromScale(0.05, 0.43 + (i - 1) * 0.085),
			UDim2.fromScale(0.9, 0.07),
			function()
				if shown[i] then
					action:FireServer("join", shown[i])
				end
			end
		)
		row.Visible = false
		table.insert(rows, row)
	end
	local empty = Ui.label(
		panel,
		"No parties yet. Create one, or hit Quick Play.",
		Enum.Font.Gotham,
		Ui.MUTED,
		UDim2.fromScale(0.05, 0.5),
		UDim2.fromScale(0.9, 0.06)
	)
	local leave = Ui.button(panel, "LEAVE PARTY", UDim2.fromScale(0.05, 0.88), UDim2.fromScale(0.9, 0.08), function()
		action:FireServer("leave")
	end)
	leave.Visible = false

	local notice =
		Ui.label(panel, "", Enum.Font.GothamMedium, Ui.BLOOD, UDim2.fromScale(0.05, 0.84), UDim2.fromScale(0.9, 0.04))
	noticeEvent.OnClientEvent:Connect(function(text: string)
		notice.Text = text
		task.delay(3, function()
			if notice.Text == text then
				notice.Text = ""
			end
		end)
	end)

	stateEvent.OnClientEvent:Connect(function(parties: { View })
		local mine: View? = nil
		for _, party in parties do
			if table.find(party.members, me.UserId) then
				mine = party
			end
		end
		if mine then
			local wait = math.ceil(mine.timeLeft)
			status.Text = if mine.full
				then `Party full. Starting in {wait}s`
				else `{mine.count}/{mine.size} in your party. Starting in {wait}s`
		else
			status.Text = "Not in a party"
		end
		leave.Visible = mine ~= nil
		empty.Visible = #parties == 0
		for i, row in rows do
			local party = parties[i]
			row.Visible = party ~= nil
			shown[i] = if party then party.id else nil
			if party then
				local host = Players:GetPlayerByUserId(party.leader)
				row.Text = `{if host then host.Name else "A player"}   {party.count}/{party.size}   {math.ceil(
					party.timeLeft
				)}s`
				row.TextTransparency = if mine == nil and not party.full then 0 else 0.5
			end
		end
	end)

	return panel
end

return PartyUi
