--!strict
local Cosmetics = require("../../src/shared/Game/Cosmetics")
local Progress = require("../../src/shared/Game/Progress")

return function(t)
	-- levels
	t.equal("level 1 at zero xp", Progress.levelFor(0), 1)
	t.equal("level 2 needs 100 xp", Progress.levelFor(100), 2)
	t.equal("99 xp is still level 1", Progress.levelFor(99), 1)
	t.equal("level 3 needs 260 xp", Progress.levelFor(260), 3)
	local monotonic = true
	for xp = 1, 3000 do
		if Progress.levelFor(xp) < Progress.levelFor(xp - 1) then
			monotonic = false
		end
	end
	t.check("levels never go down as xp grows", monotonic)

	-- awards
	local lose = Progress.award({ role = "Crew", won = false, survived = false, tasks = 0 })
	local win = Progress.award({ role = "Crew", won = true, survived = true, tasks = 4 })
	t.check("playing always earns something", lose.xp > 0 and lose.tips >= 0)
	t.check("winning, surviving and doing tasks earns more", win.xp > lose.xp and win.tips > lose.tips)
	local capped = Progress.award({ role = "Crew", won = true, survived = true, tasks = 99 })
	local six = Progress.award({ role = "Crew", won = true, survived = true, tasks = 6 })
	t.equal("task rewards are capped", capped.xp, six.xp)

	local p = Progress.new()
	Progress.apply(p, { role = "Crew", won = true, survived = true, tasks = 3 })
	Progress.apply(p, { role = "Saboteur", won = false, survived = true, tasks = 0 })
	t.equal("nights are counted", p.nights, 2)
	t.equal("a survived night extends the streak", p.streak, 2)
	Progress.apply(p, { role = "Crew", won = false, survived = false, tasks = 1 })
	t.check("being caught resets the streak but keeps the best", p.streak == 0 and p.bestStreak == 2)

	-- merging two copies never loses progress
	local a, b = Progress.new(), Progress.new()
	a.xp, a.tipsEarned, a.tipsSpent, a.owned.hat_top = 500, 100, 90, true
	b.xp, b.tipsEarned, b.tipsSpent, b.owned.light_moon = 300, 100, 10, true
	local m = Progress.merge(a, b)
	t.check("merge keeps the larger counters", m.xp == 500 and m.tipsEarned == 100)
	t.equal("merging never refunds spent tips", Progress.tips(m), 10)
	t.check("merge keeps everything owned", m.owned.hat_top == true and m.owned.light_moon == true)

	-- repairing a damaged save
	local fixed = Progress.repair({
		xp = -5,
		tips = "lots",
		nights = 7,
		owned = { hat_top = true, bad = "yes" },
		equipped = { hat = 3 },
	})
	t.check(
		"repair drops bad values and keeps good ones",
		fixed.xp == 0 and fixed.tipsEarned == 0 and fixed.nights == 7
	)
	t.check("repair keeps valid owned items only", fixed.owned.hat_top == true and fixed.owned.bad == nil)
	t.equal("repair drops a non-string equipped id", fixed.equipped.hat, nil)
	t.equal("repair of nothing gives a fresh profile", Progress.repair(nil).xp, 0)

	-- cosmetics
	local c = Progress.new()
	t.equal("a free item is owned from the start", Cosmetics.owns(c, "light_warm"), true)
	t.equal("a priced item is not", Cosmetics.owns(c, "light_moon"), false)
	t.equal("an unknown item cannot be bought", Cosmetics.buy(c, "jetpack"), "unknown")
	t.equal("a level-locked item cannot be bought", Cosmetics.buy(c, "hat_top"), "level")
	c.xp = Progress.xpForLevel(3)
	c.tipsEarned = 50
	t.equal("not enough tips", Cosmetics.buy(c, "hat_bellhop"), "tips")
	c.tipsEarned = 100
	t.equal("buying works with level and tips", Cosmetics.buy(c, "hat_bellhop"), "ok")
	t.equal("buying spends the tips", Progress.tips(c), 10)
	t.equal("buying twice is refused", Cosmetics.buy(c, "hat_bellhop"), "owned")
	t.check(
		"an owned item can be worn",
		Cosmetics.equip(c, "hat_bellhop") and Cosmetics.worn(c, "hat").id == "hat_bellhop"
	)
	t.check("an unowned item cannot be worn", not Cosmetics.equip(c, "hat_crown"))
	c.equipped.flashlight = "light_ghost"
	t.equal("a cheated equip falls back to the default", Cosmetics.worn(c, "flashlight").id, "light_warm")
end
