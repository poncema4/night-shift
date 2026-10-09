--!strict
local Pods = require("../../src/shared/Game/Pods")

return function(t)
	local pods = Pods.layout(0, 14, 10)
	t.equal("six pods", #pods, 6)
	t.equal("they cover solo to eight", pods[1].size == 1 and pods[6].size == 8, true)
	local clear = true
	for i = 1, #pods do
		for j = i + 1, #pods do
			if math.abs(pods[i].x - pods[j].x) < pods[i].radius + pods[j].radius then
				clear = false
			end
		end
	end
	t.check("no two pads overlap", clear)
	local centred = math.abs(pods[1].x + pods[6].x) < 1e-9
	t.check("the row is centred", centred)
	t.equal("standing in the middle of a pad finds it", Pods.at(pods, pods[3].x, pods[3].z) == pods[3], true)
	t.check("the edge counts", Pods.at(pods, pods[3].x + Pods.RADIUS, pods[3].z) == pods[3])
	t.check("just outside does not", Pods.at(pods, pods[3].x + Pods.RADIUS + 0.2, pods[3].z) == nil)
	t.check("between pads is nobody's", Pods.at(pods, (pods[2].x + pods[3].x) / 2, pods[2].z) == nil)
	t.equal("status while waiting", Pods.status(2, 5), "2/5  need 3 more")
	t.equal("status when full", Pods.status(5, 5), "5/5  full")
	t.equal("status when empty", Pods.status(0, 4), "0/4  need 4 more")
end
