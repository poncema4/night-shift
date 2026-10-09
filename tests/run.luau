--!strict
-- The test runner: `lune run tests/run`. Each spec returns a function that receives `t`.
-- Exit code = number of failures, so CI fails when a check fails.

local process = require("@lune/process")

local passed, failed = 0, 0

local t = {}

function t.check(name: string, condition: boolean, detail: string?)
	if condition then
		passed += 1
		print("PASS " .. name)
	else
		failed += 1
		print("FAIL " .. name .. (if detail then "  (" .. detail .. ")" else ""))
	end
end

function t.equal(name: string, actual: any, expected: any)
	t.check(name, actual == expected, `got {actual}, expected {expected}`)
end

local specs = {
	require("./specs/MathUtil"),
	require("./specs/Roles"),
	require("./specs/Escalation"),
	require("./specs/Round"),
	require("./specs/Party"),
	require("./specs/Lobby"),
	require("./specs/Menu"),
	require("./specs/Stealth"),
	require("./specs/Flash"),
	require("./specs/Scares"),
	require("./specs/Meeting"),
	require("./specs/Cameras"),
	require("./specs/Startup"),
	require("./specs/Night"),
	require("./specs/Social"),
	require("./specs/Client"),
	require("./specs/Blind"),
	require("./specs/Rage"),
	require("./specs/Jail"),
	require("./specs/Profile"),
	require("./specs/Store"),
	require("./specs/Purchases"),
	require("./specs/Rounds"),
	require("./specs/Progress"),
	require("./specs/ModelFit"),
	require("./specs/Hotel"),
	require("./specs/Building"),
	require("./specs/Furnishing"),
	require("./specs/Patrol"),
	require("./specs/PatrolFloors"),
	require("./specs/TaskBoard"),
}
for _, spec in specs do
	spec(t)
end

print(`RESULT: {if failed == 0 then "ALL PASS" else "FAILED"} ({passed} passed, {failed} failed)`)
process.exit(failed)
