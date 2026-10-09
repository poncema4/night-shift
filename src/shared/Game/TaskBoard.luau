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

function TaskBoard.count(self: TaskBoard): (number, number)
	local n = 0
	for _ in self.done do
		n += 1
	end
	return n, #self.ids
end

return TaskBoard
