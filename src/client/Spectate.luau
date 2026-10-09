--!strict
-- When you are out (caught or ejected) you watch the people still alive: Left / Right arrows (or the on-screen
-- buttons) switch between them. When you are alive again your own camera comes back.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Spectate = {}

local function aliveHumanoid(player: Player): Humanoid?
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return if humanoid and humanoid.Health > 0 then humanoid else nil
end

function Spectate.start()
	local me = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "NightShiftSpectate"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Parent = me:WaitForChild("PlayerGui")

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.fromScale(0.5, 0.97)
	label.Size = UDim2.fromScale(0.34, 0.05)
	label.BackgroundColor3 = Color3.fromRGB(10, 12, 24)
	label.BackgroundTransparency = 0.35
	label.TextColor3 = Color3.fromRGB(220, 225, 245)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Visible = false
	label.Parent = gui

	local caught = Instance.new("TextLabel")
	caught.AnchorPoint = Vector2.new(0.5, 0.5)
	caught.Position = UDim2.fromScale(0.5, 0.4)
	caught.Size = UDim2.fromScale(0.6, 0.14)
	caught.BackgroundTransparency = 1
	caught.TextColor3 = Color3.fromRGB(255, 70, 80)
	caught.TextStrokeTransparency = 0.3
	caught.Font = Enum.Font.GothamBlack
	caught.TextScaled = true
	caught.Text = ""
	caught.Visible = false
	caught.Parent = gui
	local wasAlive = false
	local caughtUntil = 0

	local index = 1
	local function others(): { Player }
		local list = {}
		for _, player in Players:GetPlayers() do
			if player ~= me and aliveHumanoid(player) then
				table.insert(list, player)
			end
		end
		table.sort(list, function(a, b)
			return a.UserId < b.UserId
		end)
		return list
	end
	local function step(delta: number)
		index += delta
	end
	local arrows = { { text = "<", dir = -1, x = 0.3 }, { text = ">", dir = 1, x = 0.7 } }
	for i, def in arrows do
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(0.5, 1)
		b.Position = UDim2.fromScale(def.x, 0.97)
		b.Size = UDim2.fromScale(0.07, 0.05)
		b.Text = def.text
		b.TextScaled = true
		b.Font = Enum.Font.GothamBold
		b.BackgroundColor3 = Color3.fromRGB(10, 12, 24)
		b.TextColor3 = Color3.fromRGB(220, 225, 245)
		b.Name = `Step{i}`
		b.Parent = gui
		local dir = def.dir
		b.Activated:Connect(function()
			step(dir)
		end)
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Left then
			step(-1)
		elseif input.KeyCode == Enum.KeyCode.Right then
			step(1)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		local own = aliveHumanoid(me)
		local out = own == nil and me.Character ~= nil
		if wasAlive and out and ReplicatedStorage:GetAttribute("Phase") ~= "Lobby" then
			caught.Text = if ReplicatedStorage:GetAttribute("Phase") == "Meeting"
				then "YOU WERE VOTED OUT"
				else "YOU WERE CAUGHT"
			caughtUntil = os.clock() + 3.5
		end
		wasAlive = own ~= nil
		caught.Visible = os.clock() < caughtUntil
		local list = if out then others() else {}
		for _, child in gui:GetChildren() do
			if child:IsA("TextButton") then
				child.Visible = out and #list > 1
			end
		end
		if own then
			label.Visible = false
			if camera.CameraSubject ~= own then
				camera.CameraSubject = own
			end
			return
		end
		if #list == 0 then
			label.Visible = out
			label.Text = "NO ONE LEFT TO WATCH"
			return
		end
		index = ((index - 1) % #list) + 1
		local target = list[index]
		local humanoid = aliveHumanoid(target)
		if humanoid then
			camera.CameraSubject = humanoid
			label.Text = `SPECTATING  {target.Name}`
			label.Visible = true
		end
	end)
end

return Spectate
