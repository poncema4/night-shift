--!strict
-- The shop panel (lobby menu): the game pass and the tips packs, with their Robux prices. Everything sold is cosmetic and
-- the panel says so. The client only sends a KEY; the server maps it to the real id and prompts Roblox's own purchase dialog.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Ui = require(script.Parent.Ui)

local StoreUi = {}

local function sorted(map: { [string]: any }): { string }
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return (map[a].robux :: number) < (map[b].robux :: number)
	end)
	return keys
end

function StoreUi.build(parent: Instance, remotes: Instance): Frame
	local buy = remotes:WaitForChild("Buy") :: RemoteEvent
	local noticeEvent = remotes:WaitForChild("ShopNotice") :: RemoteEvent

	local panel = Ui.panel(parent, UDim2.fromScale(0.52, 0.18), UDim2.fromScale(0.44, 0.66))
	Ui.label(panel, "SHOP", Enum.Font.GothamBlack, Ui.AMBER, UDim2.fromScale(0.05, 0.03), UDim2.fromScale(0.9, 0.08))
	Ui.label(
		panel,
		"Cosmetics only. Nothing here changes how a night plays.",
		Enum.Font.GothamMedium,
		Ui.MUTED,
		UDim2.fromScale(0.05, 0.12),
		UDim2.fromScale(0.9, 0.04)
	)

	local row = 0
	local function addRow(title: string, detail: string, robux: number, id: number, kind: string, key: string)
		local y = 0.2 + row * 0.17
		row += 1
		local box = Ui.panel(panel, UDim2.fromScale(0.05, y), UDim2.fromScale(0.9, 0.15))
		Ui.label(box, title, Enum.Font.GothamBold, Ui.TEXT, UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.58, 0.4))
		Ui.label(box, detail, Enum.Font.Gotham, Ui.MUTED, UDim2.fromScale(0.04, 0.52), UDim2.fromScale(0.58, 0.34))
		local label = if id == 0 then "COMING SOON" else `R$ {robux}`
		Ui.button(box, label, UDim2.fromScale(0.66, 0.15), UDim2.fromScale(0.3, 0.7), function()
			buy:FireServer(kind, key)
		end, id ~= 0)
	end
	for _, key in sorted(Config.Monetization.Passes) do
		local pass = Config.Monetization.Passes[key]
		addRow(pass.name, pass.blurb, pass.robux, pass.id, "pass", key)
	end
	for _, key in sorted(Config.Monetization.Products) do
		local product = Config.Monetization.Products[key]
		addRow(product.name, `{product.tips} tips to spend on cosmetics`, product.robux, product.id, "product", key)
	end

	local notice =
		Ui.label(panel, "", Enum.Font.GothamMedium, Ui.AMBER, UDim2.fromScale(0.05, 0.9), UDim2.fromScale(0.9, 0.05))
	noticeEvent.OnClientEvent:Connect(function(text: string)
		notice.Text = text
		task.delay(3, function()
			if notice.Text == text then
				notice.Text = ""
			end
		end)
	end)
	return panel
end

return StoreUi
