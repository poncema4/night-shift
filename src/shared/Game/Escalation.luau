--!strict
-- The Night Manager gets faster as the crew finishes tasks: every task you complete is a noise he answers.
-- Pure: progress in, speed multiplier out. 0 tasks done = normal speed; all done = `Max` times as fast.

local Escalation = {}

Escalation.MAX = 1.4

-- 0..1: how far the crew has got.
function Escalation.rage(done: number, total: number): number
	if total <= 0 then
		return 0
	end
	return math.clamp(done / total, 0, 1)
end

function Escalation.factor(rage: number): number
	return 1 + (Escalation.MAX - 1) * math.clamp(rage, 0, 1)
end

return Escalation
