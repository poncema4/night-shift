--!strict
-- Task stations. The server decides everything: who may work, what counts, and the progress shown to all.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Floors = require(ReplicatedStorage.Shared.Game.Floors)
local TaskBoard = require(ReplicatedStorage.Shared.Game.TaskBoard)

local WORK_DISTANCE = 14
local PENDING = Color3.fromRGB(230, 160, 40)
local DONE = Color3.fromRGB(70, 200, 110)

local TaskService = {}

local stations: { [string]: Part } = {}
local prompts: { [string]: ProximityPrompt } = {}
local board = TaskBoard.new({})
local active = false
local finished: { [number]: number } = {}
local listeners: { (id: string, player: Player) -> () } = {}
local roleOf: (number) -> string? = function(_userId: number)
	return nil
end

-- (done, how many are needed to win): see TaskBoard.target
local function progress(): (number, number)
	local done, total = board:count()
	return done, TaskBoard.target(total, #Players:GetPlayers())
end

local function publish()
	local done, total = progress()
	ReplicatedStorage:SetAttribute("TasksDone", done)
	ReplicatedStorage:SetAttribute("TasksTotal", total)
end

function TaskService.counts(): (number, number)
	return progress()
end

-- Call `fn(taskId, player)` whenever a task is completed (used to unlock the cameras).
function TaskService.onDone(fn: (id: string, player: Player) -> ())
	table.insert(listeners, fn)
end

-- How many tasks this player finished this round.
function TaskService.completedBy(userId: number): number
	return finished[userId] or 0
end

function TaskService.setActive(on: boolean)
	active = on
	for id, prompt in prompts do
		prompt.Enabled = on and not board.done[id]
	end
end

function TaskService.reset()
	local ids = {}
	for _, task in Floors.tasks() do
		table.insert(ids, task.id)
	end
	board = TaskBoard.new(ids)
	finished = {}
	for id, station in stations do
		station.Color = PENDING
		prompts[id].Enabled = active
	end
	publish()
end

local function onTriggered(id: string, player: Player)
	if not active then
		return
	end
	local role = roleOf(player.UserId)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not role or not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	if (root.Position - stations[id].Position).Magnitude > WORK_DISTANCE then
		return -- too far away: ignore (a client cannot trigger tasks from across the map)
	end
	local result = board:complete(role, id)
	print(`[Task] {player.Name} ({role}) {id}: {result}`)
	if result == "ok" then
		finished[player.UserId] = (finished[player.UserId] or 0) + 1
		stations[id].Color = DONE
		prompts[id].Enabled = false
		publish()
		for _, fn in listeners do
			fn(id, player)
		end
	end
end

function TaskService.start(built: { [string]: Part }, getRole: (number) -> string?)
	stations = built
	roleOf = getRole
	for _, task in Floors.tasks() do
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = task.name
		prompt.ObjectText = "Night shift duty"
		prompt.HoldDuration = 2.5
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = stations[task.id]
		prompts[task.id] = prompt
		prompt.Triggered:Connect(function(player)
			onTriggered(task.id, player)
		end)
	end
	TaskService.reset()
end

return TaskService
