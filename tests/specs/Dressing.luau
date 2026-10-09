--!strict
local Dressing = require("../../src/shared/Game/Dressing")
local Hotel = require("../../src/shared/Game/Hotel")

return function(t)
	local walls: { Dressing.Slab } = {}
	for _, box in Hotel.wallBoxes() do
		table.insert(walls, { x = box.x, z = box.z, w = box.w, d = box.d, y = 0, h = Hotel.CEILING, kind = "wall" })
	end
	local trim = Dressing.trim()
	local frames = Dressing.frames()
	local headers = Dressing.headers()

	t.check("trim has pieces on every layer", #trim > 100)

	local pieces: { Dressing.Slab } = {}
	for _, list in { walls, trim, frames, headers } do
		for _, s in list do
			table.insert(pieces, s)
		end
	end

	local firstClash = ""
	for i = 1, #pieces do
		for j = i + 1, #pieces do
			if Dressing.intersects(pieces[i], pieces[j]) then
				firstClash = `{pieces[i].kind}#{i} x {pieces[j].kind}#{j}`
				break
			end
		end
		if firstClash ~= "" then
			break
		end
	end
	t.check("no two pieces share volume (no coplanar flicker)", firstClash == "", firstClash)

	local clear = true
	local half = Hotel.DOOR / 2
	for _, room in Hotel.rooms do
		local cx, doorZ = Hotel.door(room)
		for _, s in trim do
			if s.y < Dressing.HEADER_Y and math.abs(s.x - cx) < half - 0.01 and math.abs(s.z - doorZ) < 2 then
				clear = false
			end
		end
	end
	t.check("doorways stay clear below the header", clear)

	local headroom = true
	for _, h in headers do
		if h.y + h.h ~= Hotel.CEILING or h.y < 9 then
			headroom = false
		end
	end
	t.check("headers run from door height to the ceiling", headroom and #headers == #Hotel.rooms)

	local outsideClean = true
	for _, s in trim do
		if math.abs(s.x) > 60 or math.abs(s.z) > 25 then
			outsideClean = false
		end
	end
	t.check("trim stays inside the hotel shell", outsideClean)
end
