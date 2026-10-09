--!strict
local TaskBoard = require("../../src/shared/Game/TaskBoard")

return function(t)
	local b = TaskBoard.new({ "a", "b", "c" })
	t.equal("crew completes a task", b:complete("Crew", "a"), "ok")
	t.equal("the same task cannot count twice", b:complete("Crew", "a"), "done")
	t.equal("unknown task is rejected", b:complete("Crew", "zzz"), "unknown")
	t.equal("saboteur only fakes the task", b:complete("Saboteur", "b"), "fake")
	local done, total = b:count()
	t.equal("fake work adds no progress", done, 1)
	t.equal("total tasks", total, 3)
	t.equal("a saboteur cannot finish a task for the crew", b:complete("Crew", "b"), "ok")
	-- co-op: fewer than four players need only a share of the tasks
	t.equal("4 players need every task", TaskBoard.target(15, 4), 15)
	t.equal("more than 4 need every task", TaskBoard.target(15, 8), 15)
	t.equal("3 players need 88%", TaskBoard.target(15, 3), 14)
	t.equal("2 players need 75%", TaskBoard.target(15, 2), 12)
	t.equal("1 player needs 62%", TaskBoard.target(15, 1), 10)
	t.equal("nobody (0) is treated as one player", TaskBoard.target(15, 0), 10)
	t.equal("never more than exist", TaskBoard.target(2, 3), 2)
end
