--!strict
-- Minimal on-screen status: phase + countdown, your role, and the dawn reveal.
-- Sizes use scale so it fits phones and big monitors.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
	local role = label(gui, "Role", UDim2.fromScale(0.5, 0.16), UDim2.fromScale(0.3, 0.06))
	local result = label(gui, "Result", UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.6, 0.3))
	role.Visible = false
	result.Visible = false

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local roleAssigned = remotes:WaitForChild("RoleAssigned") :: RemoteEvent
	local roundResult = remotes:WaitForChild("RoundResult") :: RemoteEvent

	roleAssigned.OnClientEvent:Connect(function(myRole: string)
		role.Visible = true
		role.Text = `You are: {string.upper(myRole)}`
		role.TextColor3 = if myRole == "Saboteur" then Color3.fromRGB(255, 80, 120) else Color3.fromRGB(90, 220, 255)
		result.Visible = false
	end)

	roundResult.OnClientEvent:Connect(function(winner: string, reveal: { [string]: string })
		local saboteurs = {}
		for name, theirRole in reveal do
			if theirRole == "Saboteur" then
				table.insert(saboteurs, name)
			end
		end
		table.sort(saboteurs)
		result.Text = `DAWN\n{string.upper(winner)} WIN\nSaboteur: {table.concat(saboteurs, ", ")}`
		result.Visible = true
		role.Visible = false
	end)

	RunService.RenderStepped:Connect(function()
		local phase = ReplicatedStorage:GetAttribute("Phase") or "Lobby"
		local endsAt = ReplicatedStorage:GetAttribute("PhaseEndsAt") or 0
		local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
		local done = ReplicatedStorage:GetAttribute("TasksDone") or 0
		local total = ReplicatedStorage:GetAttribute("TasksTotal") or 0
		tasks.Visible = phase == "Night"
		tasks.Text = `TASKS {done}/{total}`
		if phase == "Lobby" then
			status.Text = "Waiting for players..."
			result.Visible = false
		else
			status.Text = `{string.upper(phase)}  {left}s`
		end
	end)
end

return Hud
