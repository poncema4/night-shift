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
end
