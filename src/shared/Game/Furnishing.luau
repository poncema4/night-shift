--!strict
-- Where every piece of furniture stands, as plain data. Footprints are axis-aligned (yaw is a multiple of 90),
-- so tests can prove nothing blocks a route, a doorway or a task station. The builder turns each item into a
-- model with Props.
local Floors = require("./Floors")
local Hotel = require("./Hotel")

export type Item = { kind: string, level: number, x: number, z: number, yaw: number }
export type Foot = { w: number, d: number, h: number }

local Furnishing = {}

-- Width (x), depth (z) and height at yaw 0. The model's front faces +z; its back is toward -z.
Furnishing.foot = {
	armchair = { w = 5.6, d = 4.4, h = 4.7 },
	desk = { w = 14.8, d = 3.8, h = 4.05 },
	bed = { w = 6.2, d = 7, h = 4.8 },
	lamp = { w = 2, d = 2, h = 3 },
	shelf = { w = 6, d = 1.6, h = 8 },
	crate = { w = 3, d = 3, h = 3 },
	car = { w = 7, d = 14, h = 4.5 },
	locker = { w = 2, d = 2, h = 7 },
	wardrobe = { w = 4, d = 2, h = 7.5 },
	rack = { w = 8, d = 2, h = 6 },
	furnace = { w = 6, d = 6, h = 8 },
	generator = { w = 7, d = 4, h = 5 },
	table = { w = 14, d = 6, h = 2.8 },
	tub = { w = 10, d = 6, h = 2.5 },
	pool = { w = 10, d = 14, h = 0.35 },
	water = { w = 20, d = 10, h = 0.3 },
	chandelier = { w = 1, d = 1, h = 0 },
	pipe = { w = 16, d = 1.4, h = 0 },
	sludge = { w = 6, d = 14, h = 0.2 },
	cell = { w = 7, d = 7, h = 9 },
} :: { [string]: Foot }

-- Where a player can hide (the server adds a Hide prompt; the Night Manager has to search them).
Furnishing.hideable = { locker = true, wardrobe = true }

-- Things you can walk through or that hang from the ceiling: they do not block routes.
Furnishing.soft = { water = true, chandelier = true, pipe = true, sludge = true, cell = true }
Furnishing.ceiling = Hotel.CEILING -- hanging pieces are measured from the floor up to here

local MARGIN = 0.8 -- gap between a wall face and the furniture (the wall dressing sticks out 0.45)

function Furnishing.extent(item: Item): (number, number)
	local f = Furnishing.foot[item.kind]
	if item.yaw % 180 == 90 or item.yaw % 180 == -90 then
		return f.d, f.w
	end
	return f.w, f.d
end

local items: { Item } = {}

local function add(kind: string, level: number, x: number, z: number, yaw: number)
	table.insert(items, { kind = kind, level = level, x = x, z = z, yaw = yaw })
end

-- Against a wall of a room, `along` studs from the middle of that wall, facing into the room.
local function against(level: number, roomName: string, side: string, kind: string, along: number)
	local room = Floors.room(level, roomName)
	local cx, cz = Hotel.centre(room)
	local f = Furnishing.foot[kind]
	local half = Hotel.WALL / 2
	if side == "W" then
		add(kind, level, room.x1 + half + MARGIN + f.d / 2, cz + along, 90)
	elseif side == "E" then
		add(kind, level, room.x2 - half - MARGIN - f.d / 2, cz + along, -90)
	elseif side == "N" then
		add(kind, level, cx + along, room.z2 - half - MARGIN - f.d / 2, 180)
	else
		add(kind, level, cx + along, room.z1 + half + MARGIN + f.d / 2, 0)
	end
end

local function at(level: number, roomName: string, kind: string, dx: number, dz: number, yaw: number)
	local cx, cz = Hotel.centre(Floors.room(level, roomName))
	add(kind, level, cx + dx, cz + dz, yaw)
end

-- ===== ground floor =====
against(0, "Lobby", "S", "desk", 0)
at(0, "Lobby", "armchair", -10, 5.5, 180)
at(0, "Lobby", "armchair", 10, 5.5, 180)
at(0, "Lobby", "chandelier", 0, 4, 0)
against(0, "Office", "S", "desk", 0)
at(0, "Office", "armchair", -5.8, 5.5, 180)
at(0, "Ballroom", "table", 12, 0, 0)
at(0, "Ballroom", "chandelier", 12, 0, 0)
at(0, "Ballroom", "chandelier", -12, 0, 0)
at(0, "Pool Room", "pool", 8, -1, 0)
against(0, "Kitchen", "W", "shelf", 0)
against(0, "Kitchen", "E", "shelf", 0)
against(0, "Kitchen", "N", "crate", -6)
against(0, "Kitchen", "N", "crate", 6)
against(0, "Boiler Room", "W", "crate", 5)
against(0, "Boiler Room", "W", "crate", -5)
against(0, "Laundry", "W", "shelf", 0)
against(0, "Laundry", "E", "crate", 6)
against(0, "Laundry", "N", "locker", -7)
against(0, "Laundry", "N", "locker", -4.8)
against(0, "Storage", "W", "shelf", 0)
against(0, "Storage", "E", "shelf", 0)
against(0, "Storage", "N", "crate", -6)
against(0, "Storage", "N", "crate", 6)
against(0, "Security", "W", "shelf", 0)
against(0, "Security", "E", "crate", 6)
against(0, "Security", "N", "locker", -7)
against(0, "Security", "N", "locker", -4.8)
against(0, "Pantry", "W", "shelf", 0)
against(0, "Pantry", "E", "shelf", 0)
against(0, "Pantry", "N", "crate", -5)
against(0, "Pantry", "N", "crate", 5)
against(0, "Cloakroom", "W", "shelf", 0)
against(0, "Cloakroom", "E", "locker", -4.4)
against(0, "Cloakroom", "E", "locker", -2.2)
against(0, "Cloakroom", "E", "locker", 0)
against(0, "Chapel", "W", "shelf", 0)
against(0, "Chapel", "N", "crate", -5)
against(0, "Chapel", "N", "crate", 5)
at(0, "Chapel", "chandelier", 0, 0, 0)
against(0, "Gift Shop", "W", "shelf", 0)
against(0, "Gift Shop", "E", "shelf", 0)
against(0, "Gift Shop", "S", "wardrobe", 0)
at(0, "Billiards", "table", -6, 0, 90)
against(0, "Billiards", "E", "locker", 6)

-- ===== upstairs =====
for _, n in { "Room 201", "Room 202", "Room 203", "Room 204", "Room 205", "Room 206" } do
	against(1, n, "N", "bed", 0)
	against(1, n, "N", "lamp", 5.2)
	against(1, n, "W", "wardrobe", 0)
end
against(1, "Mezzanine", "S", "armchair", -11)
against(1, "Mezzanine", "S", "armchair", 8)
at(1, "Mezzanine", "chandelier", 0, 4, 0)
against(1, "Library", "W", "shelf", 0)
against(1, "Library", "E", "shelf", 0)
against(1, "Library", "S", "shelf", -6)
against(1, "Library", "S", "shelf", 6)
against(1, "Grand Suite", "S", "bed", 8)
against(1, "Grand Suite", "S", "lamp", 12.2)
at(1, "Grand Suite", "chandelier", 12, 0, 0)
at(1, "Rooftop Spa", "tub", 8, 3, 0)
for _, n in { "Room 207", "Room 208" } do
	against(1, n, "N", "bed", 0)
	against(1, n, "N", "lamp", 5.2)
	against(1, n, "W", "wardrobe", 0)
end
against(1, "Gallery", "W", "shelf", 0)
against(1, "Gallery", "E", "shelf", 0)
against(1, "Gallery", "S", "armchair", 0)
against(1, "Observatory", "S", "armchair", -5)
against(1, "Observatory", "S", "armchair", 5)
at(1, "Observatory", "chandelier", 0, 0, 0)

-- ===== basement =====
against(-1, "Wine Cellar", "W", "rack", 0)
against(-1, "Wine Cellar", "E", "rack", 0)
against(-1, "Wine Cellar", "N", "crate", -6)
against(-1, "Wine Cellar", "N", "crate", 6)
against(-1, "Furnace Room", "W", "furnace", 0)
against(-1, "Furnace Room", "E", "crate", 5)
against(-1, "Generator Room", "W", "generator", 0)
against(-1, "Generator Room", "N", "crate", 6)
against(-1, "Meat Locker", "W", "rack", 0)
against(-1, "Meat Locker", "E", "rack", 0)
against(-1, "Meat Locker", "N", "crate", -6)
against(-1, "Dry Storage", "W", "shelf", 0)
against(-1, "Dry Storage", "E", "shelf", 0)
against(-1, "Dry Storage", "N", "crate", -6)
against(-1, "Dry Storage", "N", "crate", 6)
against(-1, "Mop Closet", "W", "locker", -4.4)
against(-1, "Mop Closet", "W", "locker", -2.2)
against(-1, "Mop Closet", "W", "locker", 0)
against(-1, "Mop Closet", "N", "crate", 5)
-- the holding cell: where the Night Manager waits at the start of every night (Config.Threat.StartRoom)
at(-1, "Mop Closet", "cell", 0, 0, 0)
at(-1, "Parking Garage", "car", -10.2, 0, 0)
at(-1, "Parking Garage", "car", 10.2, 0, 0)
at(-1, "Flooded Hall", "water", 0, 0, 0)
-- sewer feel: rusted pipe runs overhead, and green sludge pools in the damp rooms
at(-1, "Flooded Hall", "pipe", 0, -4, 0)
at(-1, "Flooded Hall", "pipe", 0, 4, 0)
at(-1, "Furnace Room", "pipe", 0, -3, 0)
at(-1, "Maintenance", "pipe", 0, 0, 0)
at(-1, "Dry Storage", "pipe", 0, 0, 0)
at(-1, "Wine Cellar", "pipe", 0, 0, 0)
at(-1, "Meat Locker", "pipe", 0, 3, 0)
at(-1, "Locker Room", "sludge", 0, 0, 0)
at(-1, "Mop Closet", "sludge", 0, 0, 0)
against(-1, "Flooded Hall", "N", "crate", -8)
against(-1, "Flooded Hall", "N", "crate", 8)
against(-1, "Maintenance", "W", "locker", -4.4)
against(-1, "Maintenance", "W", "locker", -2.2)
against(-1, "Maintenance", "W", "locker", 0)
against(-1, "Locker Room", "E", "locker", -4.4)
against(-1, "Locker Room", "E", "locker", -2.2)
against(-1, "Locker Room", "E", "locker", 0)
against(-1, "Locker Room", "E", "locker", 2.2)
against(-1, "Locker Room", "S", "crate", 0)
-- the sewer wing: pipes overhead, sludge pooling, a flooded cistern
at(-1, "Sewer Junction", "pipe", 0, -4, 0)
at(-1, "Sewer Junction", "pipe", 0, 4, 0)
at(-1, "Sewer Junction", "sludge", 0, 0, 0)
against(-1, "Sewer Junction", "N", "crate", -5)
at(-1, "Drain Room", "pipe", 0, 0, 0)
at(-1, "Drain Room", "sludge", 0, 0, 90)
against(-1, "Drain Room", "W", "locker", 0)
against(-1, "Crypt", "W", "rack", 0)
against(-1, "Crypt", "E", "rack", 0)
against(-1, "Crypt", "S", "crate", 0)
at(-1, "Cistern", "sludge", -5, 0, 0)
at(-1, "Cistern", "sludge", 5, 0, 0)
at(-1, "Cistern", "pipe", 0, 5, 0)
against(-1, "Cistern", "S", "crate", 6)

function Furnishing.items(): { Item }
	return items
end

return Furnishing
