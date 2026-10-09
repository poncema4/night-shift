--!strict
local ModelFit = require("../../src/shared/Game/ModelFit")

return function(t)
	local foot = { w = 6, d = 2, h = 8 }
	t.equal("a model that is too tall is scaled by its height", ModelFit.scale(foot, 1, 16, 1, 0), 0.5)
	t.equal("a model that is too wide is scaled by its width", ModelFit.scale(foot, 12, 4, 1, 0), 0.5)
	t.equal("a model that is too deep is scaled by its depth", ModelFit.scale(foot, 1, 4, 8, 0), 0.25)
	t.equal("a small model is scaled up to fill the tightest axis", ModelFit.scale(foot, 1, 1, 1, 0), 2)
	t.equal("a quarter turn swaps width and depth", ModelFit.scale(foot, 2, 4, 6, 90), 1)
	t.equal("a half turn does not", ModelFit.scale(foot, 6, 4, 2, 180), 1)
	t.equal("a footprint without height ignores height", ModelFit.scale({ w = 4, d = 4, h = 0 }, 2, 100, 2, 0), 2)

	t.equal("repeated names keep their base", ModelFit.styleKey("leg.001"), "leg")
	t.equal("underscore suffixes too", ModelFit.styleKey("panel_12"), "panel")
	t.equal("names without a suffix are unchanged", ModelFit.styleKey("seat"), "seat")
	t.equal("digits inside a name are kept", ModelFit.styleKey("light2b"), "light2b")
end
