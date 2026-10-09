--!strict
local Config = require("../../src/shared/Config")
local Cosmetics = require("../../src/shared/Game/Cosmetics")
local Progress = require("../../src/shared/Game/Progress")
local Store = require("../../src/shared/Game/Store")

return function(t)
	local catalog = {
		Passes = { starlight = { id = 111, name = "S", blurb = "", robux = 299 } },
		Products = { small = { id = 222, name = "P", tips = 250, robux = 49 } },
	}

	-- the shipped catalogue is consistent and cosmetic
	t.equal("every pass item belongs to a sellable pass", #Store.orphanItems(Config.Monetization :: any), 0)
	local passItems = 0
	for _, item in Cosmetics.items do
		if item.pass then
			passItems += 1
			t.check(`{item.id} costs no tips (it comes with the pass)`, item.price == 0)
		end
	end
	t.check("the Starlight pass has items", passItems >= 3)
	t.check("unset ids are 0, never a guess", Config.Monetization.Passes.starlight.id == 0)
	t.equal("an unset id never matches a real purchase", Store.productKey(Config.Monetization :: any, 0), nil)

	-- passes
	local p = Progress.new()
	t.check("a pass item is not owned without the pass", not Cosmetics.owns(p, "light_starlight"))
	t.equal("and cannot be bought with tips", Cosmetics.buy(p, "light_starlight"), "locked")
	p.tipsEarned = 5000
	t.equal("even with plenty of tips", Cosmetics.buy(p, "light_crimson"), "locked")
	t.check("the pass key is found by id", Store.passKey(catalog, 111) == "starlight")
	t.check("granting a pass works once", Store.grantPass(p, "starlight") and not Store.grantPass(p, "starlight"))
	t.check("the pass unlocks its items", Cosmetics.owns(p, "light_starlight") and Cosmetics.owns(p, "hat_halo"))
	t.check("and they can be worn", Cosmetics.equip(p, "hat_halo") and p.equipped.hat == "hat_halo")

	-- products and receipts
	local q = Progress.new()
	t.equal("a real product grants tips", Store.grantProduct(catalog, q, 222, "r1"), "granted")
	t.equal("tips were added", Progress.tips(q), 250)
	t.equal("a replayed receipt pays nothing more", Store.grantProduct(catalog, q, 222, "r1"), "duplicate")
	t.equal("tips unchanged", Progress.tips(q), 250)
	t.equal("a new receipt pays again", Store.grantProduct(catalog, q, 222, "r2"), "granted")
	t.equal("an unknown product is refused", Store.grantProduct(catalog, q, 999, "r3"), "unknown")
	t.equal("and does not use up its receipt", q.receipts.r3, nil)

	-- saves never lose a purchase
	local old = Progress.new()
	local merged = Progress.merge(old, q)
	t.check("merging keeps receipts", merged.receipts.r1 == true and merged.receipts.r2 == true)
	p.passes.extra = true
	t.check("merging keeps passes", Progress.merge(Progress.new(), p).passes.starlight == true)
	local fixed = Progress.repair({ passes = { starlight = true, bad = "yes" }, receipts = { a = true, [5] = true } })
	t.check("repair keeps real passes and drops junk", fixed.passes.starlight == true and fixed.passes.bad == nil)
	t.check("repair keeps real receipts only", fixed.receipts.a == true)
end
