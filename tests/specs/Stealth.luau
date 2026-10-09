--!strict
local Battery = require("../../src/shared/Game/Battery")
local Stamina = require("../../src/shared/Game/Stamina")
local Stealth = require("../../src/shared/Game/Stealth")

return function(t)
	-- stamina
	local s = Stamina.new()
	t.check("not sprinting while standing still", not s:step(0.1, true, false))
	t.check("sprints while moving and wanting to", s:step(0.1, true, true))
	local ticks = 0
	while s:step(0.1, true, true) do
		ticks += 1
		if ticks > 1000 then
			break
		end
	end
	t.check("sprint ends after about 4.5 seconds of running", ticks > 35 and ticks < 55, `{ticks} ticks`)
	t.check("running out leaves you winded", s.winded)
	t.check("a winded player cannot sprint", not s:step(0.1, true, true))
	for _ = 1, 200 do
		s:step(0.1, false, false)
	end
	t.check("resting refills stamina and clears winded", s.value == 100 and not s.winded)
	t.check("sprinting works again after resting", s:step(0.1, true, true))

	local fresh = Stamina.new()
	fresh:step(1, true, true)
	local afterSprint = fresh.value
	fresh:step(0.5, false, false)
	t.equal("stamina does not refill during the rest delay", fresh.value, afterSprint)

	-- battery
	local b = Battery.new()
	t.check("light turns on with a full battery", b:step(0.1, true))
	for _ = 1, 600 do
		b:step(0.1, true)
	end
	t.check("battery drains to empty and the light dies", b.dead and not b:step(0.1, true))
	t.check("an empty battery will not restart straight away", not b:canStart())
	for _ = 1, 20 do
		b:step(0.1, false) -- 2 seconds of rest: about 2 percent, still below the restart threshold
	end
	t.check("a barely charged battery cannot switch the light on", not b:step(0.1, true) and not b:canStart())
	for _ = 1, 100 do
		b:step(0.1, false)
	end
	t.check("the battery recovers while off and can restart", b:canStart())

	-- hearing
	local base = 35
	local walk = { moving = true, sprinting = false, flashlight = false, hidden = false }
	t.equal("walking is heard at the base range", Stealth.hearingRange(base, walk), 35)
	t.check(
		"sprinting is louder",
		Stealth.hearingRange(base, { moving = true, sprinting = true, flashlight = false, hidden = false }) > 35
	)
	t.check(
		"standing still is quieter",
		Stealth.hearingRange(base, { moving = false, sprinting = false, flashlight = false, hidden = false }) < 35
	)
	t.check(
		"a flashlight draws attention",
		Stealth.hearingRange(base, { moving = true, sprinting = false, flashlight = true, hidden = false }) > 35
	)
	t.equal(
		"a hidden player is not heard",
		Stealth.hearingRange(base, { moving = false, sprinting = false, flashlight = true, hidden = true }),
		0
	)

	-- searching a hiding place
	local timer, found = 0, false
	for _ = 1, 20 do
		timer, found = Stealth.search(timer, 0.1, 3)
	end
	t.check("a brief visit (2 s) does not find you", not found)
	for _ = 1, 25 do
		timer, found = Stealth.search(timer, 0.1, 3)
	end
	t.check("lingering next to the locker for 4 s finds you", found)
	local far, farFound = 0, false
	for _ = 1, 100 do
		far, farFound = Stealth.search(far, 0.1, math.huge)
	end
	t.check("a locker he has no reason to open is never searched", not farFound and far == 0)
	local cooled = Stealth.search(1.0, 0.25, 30)
	t.check("walking away cools the search", cooled < 1.0)
end
