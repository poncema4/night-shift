--!strict
local Escalation = require("../../src/shared/Game/Escalation")

return function(t)
	t.equal("no tasks done: no rage", Escalation.rage(0, 12), 0)
	t.equal("half done: half rage", Escalation.rage(6, 12), 0.5)
	t.equal("all done: full rage", Escalation.rage(12, 12), 1)
	t.equal("more than all is capped", Escalation.rage(20, 12), 1)
	t.equal("no tasks exist: no rage, no divide by zero", Escalation.rage(0, 0), 0)
	t.equal("rage 0 is normal speed", Escalation.factor(0), 1)
	t.check("full rage is the maximum speed-up", math.abs(Escalation.factor(1) - Escalation.MAX) < 1e-9)
	t.check("speed rises with progress", Escalation.factor(0.8) > Escalation.factor(0.3))
	t.check("rage outside 0..1 is clamped", Escalation.factor(5) == Escalation.MAX and Escalation.factor(-1) == 1)
end
