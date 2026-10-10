--!strict
local Pods = require("../../src/shared/Game/Pods")

return function(t)
	local pods = Pods.layout(0, 14, 18)
	t.equal("six pods", #pods, Pods.COUNT)
	local clear = true
	for i = 1, #pods do
		for j = i + 1, #pods do
			-- cells must leave room to walk between them (at least 6 studs of gap)
			if math.abs(pods[i].x - pods[j].x) < pods[i].half * 2 + 6 then
				clear = false
			end
		end
	end
	t.check("the cells are spread out with a walkway between each pair", clear)
	t.check("the row is centred", math.abs(pods[1].x + pods[#pods].x) < 1e-9)
	t.check("pods are named by number, not by a fixed size", pods[1].label == "POD 1" and pods[6].label == "POD 6")
	t.equal("the middle of a cell finds it", Pods.at(pods, pods[3].x, pods[3].z) == pods[3], true)
	t.check(
		"a corner counts (it is a square, not a circle)",
		Pods.at(pods, pods[3].x + 4.9, pods[3].z + 4.9) == pods[3]
	)
	t.check("just outside does not", Pods.at(pods, pods[3].x + 5.2, pods[3].z) == nil)
	t.check("between cells is nobody's", Pods.at(pods, (pods[2].x + pods[3].x) / 2, pods[2].z) == nil)
	t.check("a margin widens the cell", Pods.inside(pods[1], pods[1].x + 5.8, pods[1].z, 1))
	t.check("without it the same spot is outside", not Pods.inside(pods[1], pods[1].x + 5.8, pods[1].z))
	t.equal("status while waiting", Pods.status(2, 5), "2/5  need 3 more")
	t.equal("status when full", Pods.status(5, 5), "5/5  full")
	t.equal("status for a lone first player", Pods.status(1, 1), "1/1  full")
end
