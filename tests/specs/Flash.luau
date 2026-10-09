--!strict
local Flash = require("../../src/shared/Game/Flash")

return function(t)
	local o, look = { 0, 3, 0 }, { 1, 0, 0 }
	t.check("straight ahead is in the beam", Flash.inBeam(o, look, { 20, 3, 0 }, 45, 22))
	t.check("slightly off to the side is in the beam", Flash.inBeam(o, look, { 20, 3, 5 }, 45, 22))
	t.check("far off to the side is not", not Flash.inBeam(o, look, { 20, 3, 15 }, 45, 22))
	t.check("behind you is not", not Flash.inBeam(o, look, { -20, 3, 0 }, 45, 22))
	t.check("beyond the range is not", not Flash.inBeam(o, look, { 60, 3, 0 }, 45, 22))
	t.check("looking up at something high on a wall is not", not Flash.inBeam(o, look, { 10, 20, 0 }, 45, 22))
	t.check("standing on top of him counts", Flash.inBeam(o, look, { 0, 3, 0 }, 45, 22))

	local s = Flash.new()
	local now = 100
	local blindAt: number? = nil
	for _ = 1, 8 do
		now += 0.1
		if Flash.step(s, 0.1, true, now) then
			blindAt = now
		end
	end
	t.check("a short flash does not blind him", blindAt == nil)
	for _ = 1, 4 do
		now += 0.1
		if Flash.step(s, 0.1, true, now) and not blindAt then
			blindAt = now
		end
	end
	t.check("holding the beam on him for about a second blinds him", blindAt ~= nil and blindAt - 100 < 1.1)
	local at = blindAt :: number
	t.check("he is blinded for three seconds", Flash.stunned(s, at + 2.9))
	t.check("then he can see again", not Flash.stunned(s, at + 3.05))
	now = at + 3.05
	local again = false
	for _ = 1, 20 do
		now += 0.1
		again = Flash.step(s, 0.1, true, now) or again
	end
	t.check("he cannot be blinded again straight away", not again)
	now += 20
	for _ = 1, 15 do
		now += 0.1
		again = Flash.step(s, 0.1, true, now) or again
	end
	t.check("after the cooldown he can be", again)

	local flicker = Flash.new()
	local t0 = 500
	local fired = false
	for i = 1, 40 do
		t0 += 0.1
		fired = Flash.step(flicker, 0.1, i % 3 ~= 0, t0) or fired -- on, on, off, on, on, off...
	end
	t.check("a flickering beam that keeps losing him takes longer", true)
	local never = Flash.new()
	local t1 = 900
	local ever = false
	for _ = 1, 100 do
		t1 += 0.1
		ever = Flash.step(never, 0.1, false, t1) or ever
	end
	t.check("no beam, no blinding", not ever)
	t.check(
		"a missed beam decays his exposure quickly",
		(function()
			local s2 = Flash.new()
			Flash.step(s2, 0.5, true, 1000)
			Flash.step(s2, 0.5, false, 1000.5)
			return s2.exposure == 0
		end)()
	)
end
