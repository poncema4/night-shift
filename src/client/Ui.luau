--!strict
-- The few UI pieces every menu screen shares (colours, a screen, a label, a button with a hover). The in-game HUD
-- predates this and builds its own; new screens use these so the look stays one look.
local TweenService = game:GetService("TweenService")

local Ui = {}

Ui.INK = Color3.fromRGB(8, 7, 12)
Ui.PANEL = Color3.fromRGB(18, 15, 25)
Ui.EDGE = Color3.fromRGB(52, 44, 66)
Ui.AMBER = Color3.fromRGB(255, 190, 90)
Ui.BLOOD = Color3.fromRGB(176, 30, 44)
Ui.TEXT = Color3.fromRGB(236, 232, 242)
Ui.MUTED = Color3.fromRGB(150, 144, 164)

function Ui.screen(parent: Instance, name: string, order: number): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = order
	gui.Parent = parent
	return gui
end

function Ui.label(
	parent: Instance,
	text: string,
	font: Enum.Font,
	color: Color3,
	position: UDim2,
	size: UDim2
): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = position
	l.Size = size
	l.Font = font
	l.TextScaled = true
	l.TextWrapped = true
	l.TextTransparency = 0
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = color
	l.Text = text
	l.Parent = parent
	-- text that scales to its box but never gets huge (or tiny), so neighbouring labels cannot run into each other
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 30
	limit.MinTextSize = 8
	limit.Parent = l
	return l
end

function Ui.panel(parent: Instance, position: UDim2, size: UDim2): Frame
	local f = Instance.new("Frame")
	f.Position = position
	f.Size = size
	f.BackgroundColor3 = Ui.PANEL
	f.BackgroundTransparency = 0.04
	f.BorderSizePixel = 0
	f.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = f
	local edge = Instance.new("UIStroke")
	edge.Color = Ui.EDGE
	edge.Thickness = 1.5
	edge.Parent = f
	return f
end

-- A button that brightens under the pointer. `accent` makes it the main action (amber).
function Ui.button(
	parent: Instance,
	text: string,
	position: UDim2,
	size: UDim2,
	onClick: () -> (),
	accent: boolean?
): TextButton
	local base = if accent then Ui.AMBER else Color3.fromRGB(34, 29, 46)
	local hover = if accent then Color3.fromRGB(255, 214, 140) else Color3.fromRGB(56, 48, 74)
	local b = Instance.new("TextButton")
	b.Position = position
	b.Size = size
	b.AutoButtonColor = false
	b.BackgroundColor3 = base
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBlack
	b.TextScaled = true
	b.Text = text
	b.TextColor3 = if accent then Ui.INK else Ui.TEXT
	b.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.18, 0)
	pad.PaddingBottom = UDim.new(0.18, 0)
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.Parent = b
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 26
	limit.MinTextSize = 8
	limit.Parent = b
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = hover }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = base }):Play()
	end)
	b.Activated:Connect(onClick)
	return b
end

-- Text that scales to its box has no upper limit in Roblox, so on a big screen a short label becomes enormous. This gives every
-- scaled label and button (now and any added later) a size cap, so no screen can shout. Headline-style labels get a bigger cap.
local BIG = { Headline = true, Title = true, GuideTitle = true, Caught = true, Banner = true }

local function cap(item: Instance)
	if not (item:IsA("TextLabel") or item:IsA("TextButton")) then
		return
	end
	local label = item :: TextLabel
	if not label.TextScaled or label:FindFirstChildOfClass("UITextSizeConstraint") then
		return
	end
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = if BIG[item.Name] then 44 else 26
	limit.MinTextSize = 8
	limit.Parent = label
end

function Ui.tidy(root: Instance)
	for _, item in root:GetDescendants() do
		cap(item)
	end
	root.DescendantAdded:Connect(cap)
end

return Ui
