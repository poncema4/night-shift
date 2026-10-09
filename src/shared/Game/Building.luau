--!strict
-- Every solid box in the hotel in world coordinates: walls, floor slabs, dressing, stairs, rails and roofs.
-- The builder turns each one into a Part; tests use the same list to prove nothing overlaps or blocks a path.
local Dressing = require("./Dressing")
local Floors = require("./Floors")
local Hotel = require("./Hotel")

export type Slab = Floors.Slab

local Building = {}

local cache: { Slab }? = nil

local function lifted(list: { Slab }, dy: number, level: number): { Slab }
	local out: { Slab } = {}
	for _, s in list do
		table.insert(
			out,
			{
				x = s.x,
				z = s.z,
				w = s.w,
				d = s.d,
				y = s.y + dy,
				h = s.h,
				kind = s.kind,
				name = s.name,
				level = level,
			} :: any
		)
	end
	return out
end

function Building.solids(): { Slab }
	if cache then
		return cache
	end
	local all: { Slab } = {}
	local function add(list: { Slab })
		for _, s in list do
			table.insert(all, s)
		end
	end
	for _, level in Floors.levels do
		local dy = Floors.y(level)
		local walls: { Slab } = {}
		for _, box in Floors.wallBoxes(level) do
			table.insert(walls, { x = box.x, z = box.z, w = box.w, d = box.d, y = 0, h = Hotel.CEILING, kind = "wall" })
		end
		add(lifted(walls, dy, level))
		add(lifted(Floors.tiles(level), dy, level))
		add(lifted(Dressing.headers(level), dy, level))
		add(lifted(Dressing.frames(level), dy, level))
		add(lifted(Dressing.trim(level), dy, level))
		add(lifted(Floors.rails(level), dy, level))
	end
	add(Floors.treads())
	add(Floors.landings())
	add(Floors.roofs())
	cache = all
	return all
end

-- True when a solid occupies the box [x1,x2] x [y1,y2] x [z1,z2].
function Building.blocked(
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	skip: ((Slab) -> boolean)?
): Slab?
	for _, s in Building.solids() do
		if
			x1 < s.x + s.w / 2
			and x2 > s.x - s.w / 2
			and y1 < s.y + s.h
			and y2 > s.y
			and z1 < s.z + s.d / 2
			and z2 > s.z - s.d / 2
			and not (skip and skip(s))
		then
			return s
		end
	end
	return nil
end

return Building
