--!strict
-- Wall dressing as plain data: skirting, wainscot, chair rail, cornice, door frames and door headers.
-- Every piece is an axis-aligned box that touches the wall without overlapping it or any other piece,
-- so nothing shares a coplanar face (which is what makes surfaces flicker in Roblox).
local Hotel = require("./Hotel")

export type Slab = { x: number, z: number, w: number, d: number, y: number, h: number, kind: string }
type Blocker = { x1: number, z1: number, x2: number, z2: number, y0: number, y1: number }

local Dressing = {}

local EPS = 1e-4

Dressing.HEADER_Y = 10.5
Dressing.FRAME_WIDTH = 0.4
Dressing.FRAME_DEPTH = 0.3

-- Layers run along every interior wall face. y is the bottom, depth is how far they stand off the wall.
Dressing.layers = {
	{ kind = "skirting", y = 0, h = 0.8, depth = 0.3 },
	{ kind = "wainscot", y = 0.8, h = 4.2, depth = 0.15 },
	{ kind = "rail", y = 5, h = 0.5, depth = 0.3 },
	{ kind = "cornice", y = 13, h = 1, depth = 0.45 },
}

local function span(a0: number, a1: number, b0: number, b1: number): boolean
	return math.min(a1, b1) - math.max(a0, b0) > EPS
end

-- Boxes above each doorway so the opening is a normal-height door, not a 14 stud gap.
function Dressing.headers(): { Slab }
	local out: { Slab } = {}
	for _, room in Hotel.rooms do
		local cx, doorZ = Hotel.door(room)
		table.insert(out, {
			x = cx,
			z = doorZ,
			w = Hotel.DOOR,
			d = Hotel.WALL,
			y = Dressing.HEADER_Y,
			h = Hotel.CEILING - Dressing.HEADER_Y,
			kind = "header",
		})
	end
	return out
end

-- Door frames: two posts and a head piece on each face of every doorway.
function Dressing.frames(): { Slab }
	local out: { Slab } = {}
	local fw, fd = Dressing.FRAME_WIDTH, Dressing.FRAME_DEPTH
	local half = Hotel.DOOR / 2
	for _, room in Hotel.rooms do
		local cx, doorZ = Hotel.door(room)
		for _, side in { 1, -1 } do
			local zc = doorZ + side * (Hotel.WALL / 2 + fd / 2)
			for _, dir in { -1, 1 } do
				table.insert(out, {
					x = cx + dir * (half + fw / 2),
					z = zc,
					w = fw,
					d = fd,
					y = 0,
					h = Dressing.HEADER_Y,
					kind = "frame",
				})
			end
			table.insert(out, {
				x = cx,
				z = zc,
				w = Hotel.DOOR + fw * 2,
				d = fd,
				y = Dressing.HEADER_Y,
				h = 0.6,
				kind = "frame",
			})
		end
	end
	return out
end

local function clip(a0: number, a1: number, cuts: { { number } }): { { number } }
	local pieces = { { a0, a1 } }
	for _, cut in cuts do
		local nextPieces = {}
		for _, p in pieces do
			if cut[2] <= p[1] + EPS or cut[1] >= p[2] - EPS then
				table.insert(nextPieces, p)
			else
				if cut[1] > p[1] + EPS then
					table.insert(nextPieces, { p[1], cut[1] })
				end
				if cut[2] < p[2] - EPS then
					table.insert(nextPieces, { cut[2], p[2] })
				end
			end
		end
		pieces = nextPieces
	end
	return pieces
end

local function inside(x: number, z: number): boolean
	local c = Hotel.CORRIDOR
	return x > c.x1 and x < c.x2 and z > -25 and z < 25
end

local function frameBlockers(): { Blocker }
	local list: { Blocker } = {}
	for _, f in Dressing.frames() do
		table.insert(list, {
			x1 = f.x - f.w / 2,
			z1 = f.z - f.d / 2,
			x2 = f.x + f.w / 2,
			z2 = f.z + f.d / 2,
			y0 = f.y,
			y1 = f.y + f.h,
		})
	end
	return list
end

-- Layer strips along the inside face of every wall, cut so they stop at frames and perpendicular walls.
function Dressing.trim(): { Slab }
	local out: { Slab } = {}
	local frameList = frameBlockers()
	local boxes = Hotel.wallBoxes()
	local reach = 0
	for _, layer in Dressing.layers do
		reach = math.max(reach, layer.depth)
	end
	for index, box in boxes do
		local xLong = box.w >= box.d
		local thickness = if xLong then box.d else box.w
		local normals = if xLong then { { 0, 1 }, { 0, -1 } } else { { 1, 0 }, { -1, 0 } }
		for _, n in normals do
			local probeX = box.x + n[1] * (thickness / 2 + 0.5)
			local probeZ = box.z + n[2] * (thickness / 2 + 0.5)
			if not inside(probeX, probeZ) then
				continue
			end
			local sign = if xLong then n[2] else n[1]
			local centreThin = if xLong then box.z else box.x
			local long0 = if xLong then box.x - box.w / 2 else box.z - box.d / 2
			local long1 = if xLong then box.x + box.w / 2 else box.z + box.d / 2
			for _, layer in Dressing.layers do
				local thinMid = centreThin + sign * (thickness / 2 + layer.depth / 2)
				local thin0, thin1 = thinMid - layer.depth / 2, thinMid + layer.depth / 2
				local cuts: { { number } } = {}
				-- other walls, grown by the trim depth so this strip stops short of their trim
				local all: { Blocker } = {}
				for _, f in frameList do
					table.insert(all, f)
				end
				for other, o in boxes do
					if other ~= index then
						table.insert(all, {
							x1 = o.x - o.w / 2 - reach,
							z1 = o.z - o.d / 2 - reach,
							x2 = o.x + o.w / 2 + reach,
							z2 = o.z + o.d / 2 + reach,
							y0 = 0,
							y1 = Hotel.CEILING,
						})
					end
				end
				for _, b in all do
					if not span(layer.y, layer.y + layer.h, b.y0, b.y1) then
						continue
					end
					local bThin0 = if xLong then b.z1 else b.x1
					local bThin1 = if xLong then b.z2 else b.x2
					if span(thin0, thin1, bThin0, bThin1) then
						table.insert(cuts, { if xLong then b.x1 else b.z1, if xLong then b.x2 else b.z2 })
					end
				end
				for _, piece in clip(long0, long1, cuts) do
					local length = piece[2] - piece[1]
					if length < 0.2 then
						continue
					end
					local mid = (piece[1] + piece[2]) / 2
					table.insert(out, {
						x = if xLong then mid else thinMid,
						z = if xLong then thinMid else mid,
						w = if xLong then length else layer.depth,
						d = if xLong then layer.depth else length,
						y = layer.y,
						h = layer.h,
						kind = layer.kind,
					})
				end
			end
		end
	end
	return out
end

-- True when two boxes share volume (touching faces do not count).
function Dressing.intersects(a: Slab, b: Slab): boolean
	return span(a.x - a.w / 2, a.x + a.w / 2, b.x - b.w / 2, b.x + b.w / 2)
		and span(a.z - a.d / 2, a.z + a.d / 2, b.z - b.d / 2, b.z + b.d / 2)
		and span(a.y, a.y + a.h, b.y, b.y + b.h)
end

return Dressing
