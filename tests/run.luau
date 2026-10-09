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
	require("./specs/Round"),
	require("./specs/Hotel"),
	require("./specs/Dressing"),
	require("./specs/Patrol"),
	require("./specs/TaskBoard"),
}
for _, spec in specs do
	spec(t)
end

print(`RESULT: {if failed == 0 then "ALL PASS" else "FAILED"} ({passed} passed, {failed} failed)`)
process.exit(failed)
