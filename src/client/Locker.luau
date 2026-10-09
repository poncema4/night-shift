--!strict
-- Your locker: level and XP, tips, and the cosmetics you can buy or wear. Open with L or the LOCKER button.
-- Cosmetics are purely visual (flashlight colour, hats, footstep dust). The server checks every purchase.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Cosmetics = require(ReplicatedStorage.Shared.Game.Cosmetics)

local Locker = {}

type Snapshot = {
	xp: number,
	level: number,
	levelStart: number,
	levelEnd: number,
	tips: number,
	owned: { string },
	equipped: { [string]: string },
	nights: number,
	wins: number,
	survived: number,
	bestStreak: number,
}

local SLOT_TITLES = { flashlight = "FLASHLIGHT BEAM", hat = "HATS", dust = "FOOTSTEP DUST" }
local SLOT_ORDER = { "flashlight", "hat", "dust" }

function Locker.start()
	local me = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local profileEvent = remotes:WaitForChild("Profile") :: RemoteEvent
	local shop = remotes:WaitForChild("Shop") :: RemoteEvent

	local gui = Instance.new("ScreenGui")
	gui.Name = "NightShiftLocker"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 12
	gui.Parent = me:WaitForChild("PlayerGui")

	local open = Instance.new("TextButton")
	open.AnchorPoint = Vector2.new(1, 0)
	open.Position = UDim2.fromScale(0.985, 0.02)
	open.Size = UDim2.fromScale(0.12, 0.05)
	open.Text = "LOCKER (L)"
	open.TextScaled = true
	open.Font = Enum.Font.GothamBold
	open.TextColor3 = Color3.fromRGB(255, 220, 160)
	open.BackgroundColor3 = Color3.fromRGB(34, 26, 20)
	open.BackgroundTransparency = 0.2
	open.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.5, 0.8)
	panel.BackgroundColor3 = Color3.fromRGB(14, 12, 18)
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = panel

	local function label(name: string, position: UDim2, size: UDim2, font: Enum.Font, color: Color3): TextLabel
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = position
		l.Size = size
		l.Font = font
		l.TextColor3 = color
		l.TextScaled = true
		l.Text = ""
		l.Parent = panel
		return l
	end
	local title = label(
		"Title",
		UDim2.fromScale(0.04, 0.025),
		UDim2.fromScale(0.6, 0.07),
		Enum.Font.GothamBlack,
		Color3.fromRGB(255, 190, 90)
	)
	local tips = label(
		"Tips",
		UDim2.fromScale(0.62, 0.025),
		UDim2.fromScale(0.34, 0.07),
		Enum.Font.GothamBold,
		Color3.fromRGB(150, 235, 160)
	)
	local stats = label(
		"Stats",
		UDim2.fromScale(0.04, 0.165),
		UDim2.fromScale(0.92, 0.04),
		Enum.Font.GothamMedium,
		Color3.fromRGB(190, 190, 205)
	)

	local barBack = Instance.new("Frame")
	barBack.Position = UDim2.fromScale(0.04, 0.105)
	barBack.Size = UDim2.fromScale(0.92, 0.04)
	barBack.BackgroundColor3 = Color3.fromRGB(34, 30, 44)
	barBack.BorderSizePixel = 0
	barBack.Parent = panel
	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 190, 90)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBack

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromScale(0.04, 0.23)
	list.Size = UDim2.fromScale(0.92, 0.72)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.fromScale(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local function render(snap: Snapshot)
		title.Text = `LEVEL {snap.level}`
		tips.Text = `{snap.tips} TIPS`
		local span = math.max(1, snap.levelEnd - snap.levelStart)
		barFill.Size = UDim2.fromScale(math.clamp((snap.xp - snap.levelStart) / span, 0, 1), 1)
		stats.Text =
			`{snap.xp - snap.levelStart}/{span} XP   Nights {snap.nights}   Wins {snap.wins}   Survived {snap.survived}   Best streak {snap.bestStreak}`
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local owned: { [string]: boolean } = {}
		for _, id in snap.owned do
			owned[id] = true
		end
		local order = 0
		for _, slot in SLOT_ORDER do
			order += 1
			local header = Instance.new("TextLabel")
			header.LayoutOrder = order * 100
			header.Size = UDim2.new(1, 0, 0, 26)
			header.BackgroundTransparency = 1
			header.Font = Enum.Font.GothamBlack
			header.TextSize = 18
			header.TextXAlignment = Enum.TextXAlignment.Left
			header.TextColor3 = Color3.fromRGB(255, 190, 90)
			header.Text = SLOT_TITLES[slot]
			header.Parent = list
			local n = 0
			for _, item in Cosmetics.items do
				if item.slot ~= slot then
					continue
				end
				n += 1
				local has = item.price == 0 or owned[item.id] == true
				local worn = snap.equipped[slot] == item.id
					or (
						snap.equipped[slot] == nil
						and item.price == 0
						and (item.id == "light_warm" or item.id == "hat_none" or item.id == "dust_none")
					)
				local row = Instance.new("Frame")
				row.LayoutOrder = order * 100 + n
				row.Size = UDim2.new(1, 0, 0, 40)
				row.BackgroundColor3 = Color3.fromRGB(24, 22, 32)
				row.BorderSizePixel = 0
				row.Parent = list
				local rowCorner = Instance.new("UICorner")
				rowCorner.Parent = row
				if item.rgb then
					local swatch = Instance.new("Frame")
					swatch.Position = UDim2.fromScale(0.02, 0.2)
					swatch.Size = UDim2.fromOffset(22, 22)
					swatch.BackgroundColor3 = Color3.fromRGB(item.rgb[1], item.rgb[2], item.rgb[3])
					swatch.BorderSizePixel = 0
					swatch.Parent = row
				end
				local name = Instance.new("TextLabel")
				name.BackgroundTransparency = 1
				name.Position = UDim2.fromScale(0.09, 0)
				name.Size = UDim2.fromScale(0.55, 1)
				name.TextXAlignment = Enum.TextXAlignment.Left
				name.Font = Enum.Font.GothamMedium
				name.TextSize = 17
				name.TextColor3 = Color3.fromRGB(235, 235, 245)
				name.Text = item.name
				name.Parent = row
				local action = Instance.new("TextButton")
				action.AnchorPoint = Vector2.new(1, 0.5)
				action.Position = UDim2.fromScale(0.98, 0.5)
				action.Size = UDim2.fromScale(0.3, 0.8)
				action.Font = Enum.Font.GothamBold
				action.TextSize = 16
				action.Parent = row
				local actionCorner = Instance.new("UICorner")
				actionCorner.Parent = action
				if worn then
					action.Text = "WORN"
					action.BackgroundColor3 = Color3.fromRGB(40, 70, 50)
					action.TextColor3 = Color3.fromRGB(170, 240, 190)
					action.Active = false
				elseif has then
					action.Text = "WEAR"
					action.BackgroundColor3 = Color3.fromRGB(60, 52, 90)
					action.TextColor3 = Color3.fromRGB(235, 235, 255)
					action.Activated:Connect(function()
						shop:FireServer({ action = "equip", id = item.id })
					end)
				elseif snap.level < item.level then
					action.Text = `LEVEL {item.level}`
					action.BackgroundColor3 = Color3.fromRGB(34, 30, 40)
					action.TextColor3 = Color3.fromRGB(150, 150, 165)
					action.Active = false
				else
					action.Text = `BUY {item.price}`
					action.BackgroundColor3 = if snap.tips >= item.price
						then Color3.fromRGB(110, 76, 24)
						else Color3.fromRGB(46, 36, 28)
					action.TextColor3 = Color3.fromRGB(255, 225, 170)
					action.Activated:Connect(function()
						shop:FireServer({ action = "buy", id = item.id })
					end)
				end
			end
		end
	end

	profileEvent.OnClientEvent:Connect(render)
	open.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.L then
			panel.Visible = not panel.Visible
		end
	end)
end

return Locker
