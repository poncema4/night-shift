--!strict
-- Which tasks are finished this round. Saboteurs can pretend to work but never add progress.

export type Result = "ok" | "fake" | "done" | "unknown"

local TaskBoard = {}
TaskBoard.__index = TaskBoard

export type TaskBoard = typeof(setmetatable({} :: { done: { [string]: boolean }, ids: { string } }, TaskBoard))

function TaskBoard.new(ids: { string }): TaskBoard
	return setmetatable({ done = {}, ids = table.clone(ids) }, TaskBoard)
end

function TaskBoard.complete(self: TaskBoard, role: string, id: string): Result
	if not table.find(self.ids, id) then
		return "unknown"
	end
	if role == "Saboteur" then
		return "fake"
	end
	if self.done[id] then
		return "done"
	end
	self.done[id] = true
	return "ok"
end

-- How many tasks the crew must finish to win. With fewer than 4 players (co-op) they need only a share of them, so a
-- lone player is not asked to do what a full crew of four does: 1 player = 62%, 2 = 75%, 3 = 88%, 4 or more = all.
function TaskBoard.target(total: number, players: number): number
	if players >= 4 then
		return total
	end
	return math.min(total, math.ceil(total * (0.5 + 0.125 * math.max(players, 1))))
end

function TaskBoard.count(self: TaskBoard): (number, number)
	local n = 0
	for _ in self.done do
		n += 1
	end
	return n, #self.ids
end

return TaskBoard
