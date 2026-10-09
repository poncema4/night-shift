--!strict
local MathUtil = require("../../src/shared/Util/MathUtil")

return function(t)
	t.equal("clamp keeps a value inside the range", MathUtil.clamp(5, 0, 10), 5)
	t.equal("clamp cuts a value that is too high", MathUtil.clamp(15, 0, 10), 10)
	t.equal("clamp lifts a value that is too low", MathUtil.clamp(-3, 0, 10), 0)
	t.equal("clamp accepts swapped bounds", MathUtil.clamp(5, 10, 0), 5)
	t.equal("lerp halfway", MathUtil.lerp(10, 20, 0.5), 15)
	t.equal("shorten leaves small numbers alone", MathUtil.shorten(999), "999")
	t.equal("shorten thousands", MathUtil.shorten(1200), "1.2K")
	t.equal("shorten drops a trailing .0", MathUtil.shorten(2000), "2K")
	t.equal("shorten millions", MathUtil.shorten(3400000), "3.4M")
	t.equal("shorten negative numbers", MathUtil.shorten(-1500), "-1.5K")
end
