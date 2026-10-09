--!strict
-- The hotel as three stacked levels: Basement (-1), Ground (0) and Upstairs (1). The ground floor is the
-- original layout in Hotel; the other levels reuse its room rectangles with their own names. Two stairwell
-- annexes join them: West (Ground <-> Upstairs) and East (Ground <-> Basement), each a switchback of two
-- flights with a landing. Everything is plain data so Lune can test it (no overlaps, headroom, paths).
-- Level-local y is 0 at the walking surface; a level's world y is `level * Floors.HEIGHT`.
local Hotel = require("./Hotel")

export type Rect = Hotel.Rect
export type Box = Hotel.Box
export type Node = Hotel.Node
export type Slab = {
	x: number,
	z: number,
	w: number,
	d: number,
	y: number,
	h: number,
	kind: string,
	name: string?,
	level: number?,
}
export type Door = { x: number, z: number, alongX: boolean }
export type Annex = { id: string, x1: number, z1: number, x2: number, z2: number, side: number, levels: { number } }
export type Task = { id: string, name: string, room: string, x: number, z: number, level: number }

local Floors = {}

Floors.HEIGHT = 16 -- walking surface to walking surface
Floors.TILE = 2 -- floor slab thickness (also the next level's ceiling)
Floors.levels = { 0, 1, -1 }
Floors.RISE = 1
Floors.TREAD = 0.4
-- The stairwells are square spirals around an open well: three flights of FLIGHT_STEPS steps joined by corner landings,
-- going round the well, 15 steps = one floor (the 16th "step" is the next floor itself).
Floors.FLIGHT_STEPS = 5
Floors.FLIGHT_RUN = 1.6

local ROOM_NAMES: { [number]: { string } } = {
	[1] = {
		"Room 201",
		"Room 202",
		"Room 203",
		"Room 204",
		"Room 205",
		"Room 206",
		"Mezzanine",
		"Library",
		"Grand Suite",
		"Rooftop Spa",
	},
	[-1] = {
		"Wine Cellar",
		"Furnace Room",
		"Generator Room",
		"Meat Locker",
		"Dry Storage",
		"Mop Closet",
		"Parking Garage",
		"Maintenance",
		"Flooded Hall",
		"Locker Room",
	},
}

Floors.annexes = {
	{ id = "West", x1 = -76, z1 = -8, x2 = -60, z2 = 8, side = -1, levels = { 0, 1 } },
	{ id = "East", x1 = 60, z1 = -8, x2 = 76, z2 = 8, side = 1, levels = { 0, -1 } },
} :: { Annex }

function Floors.y(level: number): number
	return level * Floors.HEIGHT
end

function Floors.levelAt(y: number): number
	return math.clamp(math.floor(y / Floors.HEIGHT + 0.5), -1, 1)
end

local function hasLevel(annex: Annex, level: number): boolean
	return table.find(annex.levels, level) ~= nil
end

function Floors.annexesOf(level: number): { Annex }
	local list = {}
	for _, a in Floors.annexes do
		if hasLevel(a, level) then
			table.insert(list, a)
		end
	end
	return list
end

local roomCache: { [number]: { Rect } } = {}
function Floors.rooms(level: number): { Rect }
	local cached = roomCache[level]
	if cached then
		return cached
	end
	local list: { Rect } = {}
	for i, room in Hotel.rooms do
		local names = ROOM_NAMES[level]
		table.insert(
			list,
			{ name = if names then names[i] else room.name, x1 = room.x1, z1 = room.z1, x2 = room.x2, z2 = room.z2 }
		)
	end
	roomCache[level] = list
	return list
end

function Floors.room(level: number, name: string): Rect
	for _, r in Floors.rooms(level) do
		if r.name == name then
			return r
		end
	end
	error("unknown room " .. name)
end

-- Every room name is unique across levels, so a name finds its level.
function Floors.levelOfRoom(name: string): number
	for _, level in Floors.levels do
		for _, r in Floors.rooms(level) do
			if r.name == name then
				return level
			end
		end
	end
	error("unknown room " .. name)
end

function Floors.doors(level: number): { Door }
	local list: { Door } = {}
	for _, room in Floors.rooms(level) do
		local x, z = Hotel.door(room)
		table.insert(list, { x = x, z = z, alongX = true })
	end
	for _, a in Floors.annexesOf(level) do
		table.insert(list, { x = if a.side < 0 then Hotel.CORRIDOR.x1 else Hotel.CORRIDOR.x2, z = 0, alongX = false })
	end
	return list
end

-- Wall boxes for one level: the original walls, side walls split around any annex doorway, plus annex walls.
-- Boxes only touch, never overlap.
function Floors.wallBoxes(level: number): { Box }
	local c = Hotel.CORRIDOR
	local w = Hotel.WALL
	local list: { Box } = {}
	local annexAt: { [number]: boolean } = {}
	for _, a in Floors.annexesOf(level) do
		annexAt[if a.side < 0 then c.x1 else c.x2] = true
	end
	for _, box in Hotel.wallBoxes() do
		if box.z == 0 and annexAt[box.x] then
			local halfDoor = Hotel.DOOR / 2
			local edge = box.d / 2
			local d = edge - halfDoor
			table.insert(list, { x = box.x, z = -(halfDoor + d / 2), w = box.w, d = d })
			table.insert(list, { x = box.x, z = halfDoor + d / 2, w = box.w, d = d })
		else
			table.insert(list, box)
		end
	end
	for _, a in Floors.annexesOf(level) do
		local outer = if a.side < 0 then a.x1 else a.x2
		local mid = (outer + (if a.side < 0 then c.x1 else c.x2)) / 2
		local length = math.abs(outer - (if a.side < 0 then c.x1 else c.x2)) - w
		table.insert(list, { x = outer, z = 0, w = w, d = a.z2 - a.z1 + w })
		table.insert(list, { x = mid, z = a.z2, w = length, d = w })
		table.insert(list, { x = mid, z = a.z1, w = length, d = w })
	end
	return list
end

-- True inside the walkable interior of a level (main footprint or one of its annexes).
function Floors.interior(level: number, x: number, z: number): boolean
	local c = Hotel.CORRIDOR
	if x > c.x1 and x < c.x2 and z > -25 and z < 25 then
		return true
	end
	for _, a in Floors.annexesOf(level) do
		if x > a.x1 and x < a.x2 and z > a.z1 and z < a.z2 then
			return true
		end
	end
	return false
end

function Floors.inWall(level: number, x: number, z: number, margin: number): boolean
	for _, box in Floors.wallBoxes(level) do
		if Hotel.inBox(x, z, box, margin) then
			return true
		end
	end
	return false
end

-- ===== stairs =====
-- A stairwell is laid out in local coordinates: u is the distance from the corridor wall, v is z. The shaft interior is
-- u 0.5..15.5, v -7.5..7.5. Around a 8 x 8 well (u 4..12, v -4..4) run four strips 3.5 wide:
--   near strip (u 0.5..4)   the entrance: flat, level with the corridor
--   north flight (v 4..7)   5 steps going away from the corridor
--   far strip (u 12..15)    5 steps going south, after a corner landing
--   south flight (v -7..-4) 5 steps coming back toward the corridor, then the near-south corner is the next floor
-- A stairwell going UP (West) has its opening in the upper floor; one going DOWN (East) has its opening in the entrance floor.

local INSET = 0.5 -- treads stop this far from the shaft walls, so they never touch the wall trim
local FRONT = 4 -- where the well starts (u)
local BACK = 12 -- where the well ends (u)

-- +1 for the annex that climbs (West), -1 for the one that descends (East).
local function direction(annex: Annex): number
	return if annex.side < 0 then 1 else -1
end

local function innerX(annex: Annex): number
	return if annex.side < 0 then Hotel.CORRIDOR.x1 else Hotel.CORRIDOR.x2
end

-- A local rectangle (u1..u2, v1..v2) as a world rectangle.
local function worldRect(
	annex: Annex,
	u1: number,
	u2: number,
	v1: number,
	v2: number
): { x1: number, z1: number, x2: number, z2: number }
	local xa, xb = innerX(annex) + annex.side * u1, innerX(annex) + annex.side * u2
	return { x1 = math.min(xa, xb), x2 = math.max(xa, xb), z1 = math.min(v1, v2), z2 = math.max(v1, v2) }
end

type Step = { name: string, u1: number, u2: number, v1: number, v2: number, top: number, landing: boolean }

-- Every tread and landing of a stairwell, in the order you walk them. `top` is the height above the entrance floor.
local function spiral(annex: Annex): { Step }
	local steps: { Step } = {}
	local n, run = Floors.FLIGHT_STEPS, Floors.FLIGHT_RUN
	local function add(name: string, u1: number, u2: number, v1: number, v2: number, top: number, landing: boolean)
		table.insert(
			steps,
			{ name = `{annex.id}_{name}`, u1 = u1, u2 = u2, v1 = v1, v2 = v2, top = top, landing = landing }
		)
	end
	local far1, far2 = BACK, 15.5 - INSET -- far strip u 12..15
	local north1, north2 = 4, 7.5 - INSET -- north flight v 4..7
	local south1, south2 = -(7.5 - INSET), -4 -- south flight v -7..-4
	local count = 0
	for k = 1, n do -- north flight, away from the corridor
		count += 1
		add(`T{count}`, FRONT + run * (k - 1), FRONT + run * k, north1, north2, count * Floors.RISE, false)
	end
	add("LandingFarNorth", far1, far2, north1, north2, count * Floors.RISE, true)
	for k = 1, n do -- far flight, going south
		count += 1
		add(`T{count}`, far1, far2, north1 - run * k, north1 - run * (k - 1), count * Floors.RISE, false)
	end
	add("LandingFarSouth", far1, far2, south1, south2, count * Floors.RISE, true)
	for k = 1, n do -- south flight, coming back toward the corridor
		count += 1
		add(`T{count}`, BACK - run * k, BACK - run * (k - 1), south1, south2, count * Floors.RISE, false)
	end
	return steps
end

-- Tread slabs, in world coordinates (y is the world y of the bottom of the tread).
function Floors.treads(): { Slab }
	local list: { Slab } = {}
	for _, a in Floors.annexes do
		local dir = direction(a)
		for _, st in spiral(a) do
			if not st.landing then
				local r = worldRect(a, st.u1, st.u2, st.v1, st.v2)
				table.insert(list, {
					x = (r.x1 + r.x2) / 2,
					z = (r.z1 + r.z2) / 2,
					w = r.x2 - r.x1,
					d = r.z2 - r.z1,
					y = dir * st.top - Floors.TREAD,
					h = Floors.TREAD,
					kind = "tread",
					name = st.name,
				})
			end
		end
	end
	return list
end

-- The two corner landings halfway round each stairwell.
function Floors.landings(): { Slab }
	local list: { Slab } = {}
	for _, a in Floors.annexes do
		local dir = direction(a)
		for _, st in spiral(a) do
			if st.landing then
				local r = worldRect(a, st.u1, st.u2, st.v1, st.v2)
				table.insert(list, {
					x = (r.x1 + r.x2) / 2,
					z = (r.z1 + r.z2) / 2,
					w = r.x2 - r.x1,
					d = r.z2 - r.z1,
					y = dir * st.top - 0.6,
					h = 0.6,
					kind = "landing",
					name = st.name,
				})
			end
		end
	end
	return list
end

-- The opening in a level's floor above the flights (and the well). Local: West opens on the upper floor over u 4..15.5,
-- v -7.5..4; East opens on the entrance floor over u 4..15.5, v -4..7.5.
function Floors.holes(level: number): { { x1: number, z1: number, x2: number, z2: number } }
	local list = {}
	for _, a in Floors.annexesOf(level) do
		local owner = if a.side < 0 then 1 else 0
		if level == owner then
			if a.side < 0 then
				table.insert(list, worldRect(a, FRONT, 15.5, -7.5, 4))
			else
				table.insert(list, worldRect(a, FRONT, 15.5, -4, 7.5))
			end
		end
	end
	return list
end

-- Guard rails along the edges of the opening that have floor beside them, except where you step on or off the stairs.
function Floors.rails(level: number): { Slab }
	local list: { Slab } = {}
	for _, a in Floors.annexesOf(level) do
		if #Floors.holes(level) > 0 and ((a.side < 0 and level == 1) or (a.side > 0 and level == 0)) then
			local function rail(u1: number, u2: number, v1: number, v2: number)
				local r = worldRect(a, u1, u2, v1, v2)
				table.insert(list, {
					x = (r.x1 + r.x2) / 2,
					z = (r.z1 + r.z2) / 2,
					w = math.max(r.x2 - r.x1, 0.3),
					d = math.max(r.z2 - r.z1, 0.3),
					y = 0,
					h = 3.5,
					kind = "guardrail",
				})
			end
			-- the edge toward the corridor, along the near strip (the ends stay open for the way on and off)
			rail(FRONT - 0.35, FRONT - 0.05, -4, 4)
			-- the long edge beside the balcony (north strip going up, south strip going down)
			if a.side < 0 then
				rail(FRONT, 15, 4.05, 4.35)
			else
				rail(FRONT, 15, -4.35, -4.05)
			end
		end
	end
	return list
end

-- ===== floor tiles =====

type Region = { x1: number, z1: number, x2: number, z2: number }

-- `rect` minus the holes, as non-overlapping rectangles that exactly cover what is left.
function Floors.carve(rect: Region, holes: { Region }): { Region }
	local pieces: { Region } = { rect }
	for _, h in holes do
		local nextPieces: { Region } = {}
		for _, p in pieces do
			if h.x2 <= p.x1 or h.x1 >= p.x2 or h.z2 <= p.z1 or h.z1 >= p.z2 then
				table.insert(nextPieces, p)
			else
				local ix1, ix2 = math.max(p.x1, h.x1), math.min(p.x2, h.x2)
				if p.x1 < ix1 then
					table.insert(nextPieces, { x1 = p.x1, z1 = p.z1, x2 = ix1, z2 = p.z2 })
				end
				if ix2 < p.x2 then
					table.insert(nextPieces, { x1 = ix2, z1 = p.z1, x2 = p.x2, z2 = p.z2 })
				end
				if p.z1 < h.z1 then
					table.insert(nextPieces, { x1 = ix1, z1 = p.z1, x2 = ix2, z2 = math.min(h.z1, p.z2) })
				end
				if h.z2 < p.z2 then
					table.insert(nextPieces, { x1 = ix1, z1 = math.max(h.z2, p.z1), x2 = ix2, z2 = p.z2 })
				end
			end
		end
		pieces = nextPieces
	end
	return pieces
end

-- Floor slabs of a level: every room, the corridor and each annex, minus the stair holes. Local y: top at 0.
function Floors.tiles(level: number): { Slab }
	local c = Hotel.CORRIDOR
	local holes = Floors.holes(level)
	local list: { Slab } = {}
	local function add(name: string, rect: Region)
		for _, piece in Floors.carve(rect, holes) do
			table.insert(list, {
				x = (piece.x1 + piece.x2) / 2,
				z = (piece.z1 + piece.z2) / 2,
				w = piece.x2 - piece.x1,
				d = piece.z2 - piece.z1,
				y = -Floors.TILE,
				h = Floors.TILE,
				kind = "tile",
				name = name,
			})
		end
	end
	for _, room in Floors.rooms(level) do
		add(room.name, room)
	end
	add("Corridor", { x1 = c.x1, z1 = c.z1, x2 = c.x2, z2 = c.z2 })
	for _, a in Floors.annexesOf(level) do
		add(a.id .. " stairs", a)
	end
	return list
end

-- Ceiling slabs over the top of each column (world coordinates).
function Floors.roofs(): { Slab }
	local list: { Slab } = {}
	local c = Hotel.CORRIDOR
	local w = Hotel.WALL
	local top = Floors.y(1) + Hotel.CEILING
	table.insert(list, {
		x = 0,
		z = 0,
		w = c.x2 - c.x1 + w,
		d = 50 + w,
		y = top,
		h = Floors.TILE,
		kind = "roof",
	})
	for _, a in Floors.annexes do
		local atTop = hasLevel(a, 1)
		local y = if atTop then top else Hotel.CEILING
		local x1 = if a.side < 0 then a.x1 - w / 2 else c.x2
		local x2 = if a.side < 0 then c.x1 - w / 2 else a.x2 + w / 2
		table.insert(list, {
			x = (x1 + x2) / 2,
			z = 0,
			w = x2 - x1,
			d = a.z2 - a.z1 + w,
			y = y,
			h = Floors.TILE,
			kind = "roof",
			name = a.id,
		})
	end
	return list
end

-- ===== walkable graph =====

local function prefix(level: number): string
	return if level == 0 then "" elseif level > 0 then "U" else "B"
end

local function levelGraph(level: number, nodes: { [string]: Node })
	local corridorX: { number } = {}
	local seen: { [number]: boolean } = {}
	for _, room in Floors.rooms(level) do
		local x, z = Hotel.centre(room)
		nodes[room.name] =
			{ id = room.name, x = x, z = z, y = Floors.y(level), level = level, kind = "room", links = {} }
		local doorX = Hotel.door(room)
		if not seen[doorX] then
			seen[doorX] = true
			table.insert(corridorX, doorX)
		end
	end
	table.sort(corridorX)
	local function link(a: string, b: string)
		table.insert(nodes[a].links, b)
		table.insert(nodes[b].links, a)
	end
	local previous: string? = nil
	for _, x in corridorX do
		local id = prefix(level) .. "C" .. x
		nodes[id] = { id = id, x = x, z = 0, y = Floors.y(level), level = level, kind = "corridor", links = {} }
		if previous then
			link(previous, id)
		end
		previous = id
	end
	for _, room in Floors.rooms(level) do
		link(room.name, prefix(level) .. "C" .. Hotel.door(room))
	end
end

function Floors.corridorId(level: number, x: number): string
	return prefix(level) .. "C" .. x
end

-- One node per room, per corridor door and along each stairwell, all levels, linked into one graph.
function Floors.graph(): { [string]: Node }
	local nodes: { [string]: Node } = {}
	for _, level in Floors.levels do
		levelGraph(level, nodes)
	end
	local function link(a: string, b: string)
		table.insert(nodes[a].links, b)
		table.insert(nodes[b].links, a)
	end
	for _, a in Floors.annexes do
		local tag = string.sub(a.id, 1, 1) .. "A"
		local dir = direction(a)
		local ix = innerX(a)
		local n, run = Floors.FLIGHT_STEPS, Floors.FLIGHT_RUN
		local function at(
			u: number,
			v: number,
			top: number,
			lvl: number
		): { x: number, z: number, y: number, level: number }
			return { x = ix + a.side * u, z = v, y = dir * top, level = lvl }
		end
		local lower, upper = 0, if dir > 0 then 1 else -1
		local defs = {
			at(2.25, 0, 0, lower), -- 0 the entrance strip, level with the corridor
			at(2.25, 5.5, 0, lower), -- 1 the near-north corner
			at(FRONT, 5.5, 0, lower), -- 2 foot of the north flight
			at(FRONT + run * (n - 0.5), 5.5, n, lower), -- 3 top of the north flight
			at(13.5, 5.5, n, lower), -- 4 far-north landing
			at(13.5, 4, n, lower), -- 5 head of the far flight
			at(13.5, 4 - run * (n - 0.5), 2 * n, upper), -- 6 foot of the south flight's landing
			at(13.5, -5.5, 2 * n, upper), -- 7 far-south landing
			at(BACK, -5.5, 2 * n, upper), -- 8 head of the south flight
			at(BACK - run * (n - 0.5), -5.5, 3 * n, upper), -- 9 top of the south flight
			at(2.25, -5.5, 3 * n + 1, upper), -- 10 the near-south corner: this is the next floor
			at(2.25, 0, 3 * n + 1, upper), -- 11 the entrance strip on the next floor
		}
		for i, d in defs do
			nodes[`{tag}{i - 1}`] =
				{ id = `{tag}{i - 1}`, x = d.x, z = d.z, y = d.y, level = d.level, kind = "stair", links = {} }
		end
		for i = 1, #defs - 1 do
			link(`{tag}{i - 1}`, `{tag}{i}`)
		end
		link(tag .. "0", Floors.corridorId(0, a.side * 50))
		link(`{tag}{#defs - 1}`, Floors.corridorId(upper, a.side * 50))
	end
	return nodes
end

-- ===== tasks =====

local extra = {
	{ id = "elevator", name = "Fix the elevator panel", room = "Mezzanine", x = -50, z = -21 },
	{ id = "bed204", name = "Turn down the bed in Room 204", room = "Room 204", x = 3.5, z = 21 },
	{ id = "spa", name = "Drain the rooftop spa", room = "Rooftop Spa", x = 45, z = -21 },
	{ id = "generator", name = "Restart the generator", room = "Generator Room", x = -10, z = 21 },
	{ id = "valve", name = "Close the steam valve", room = "Furnace Room", x = -30, z = 21 },
	{ id = "fuse", name = "Replace the fuse box", room = "Maintenance", x = -20, z = -21 },
}

-- Every task on every level, ground first.
function Floors.tasks(): { Task }
	local list: { Task } = {}
	for _, t in Hotel.tasks do
		table.insert(list, { id = t.id, name = t.name, room = t.room, x = t.x, z = t.z, level = 0 })
	end
	for _, t in extra do
		table.insert(
			list,
			{ id = t.id, name = t.name, room = t.room, x = t.x, z = t.z, level = Floors.levelOfRoom(t.room) }
		)
	end
	return list
end

-- ===== routing =====

local function span3(a: Node, b: Node): number
	return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2)
end

-- The first node to step to from `from` on the shortest route to `goal` (Dijkstra; the graph is small).
function Floors.nextHop(graph: { [string]: Node }, from: string, goal: string): string?
	if from == goal then
		return nil
	end
	local best: { [string]: number } = { [from] = 0 }
	local first: { [string]: string } = {}
	local open: { string } = { from }
	local done: { [string]: boolean } = {}
	while #open > 0 do
		local bestIndex, bestDistance = 1, math.huge
		for i, id in open do
			if best[id] < bestDistance then
				bestIndex, bestDistance = i, best[id]
			end
		end
		local current = table.remove(open, bestIndex) :: string
		if current == goal then
			return first[goal]
		end
		done[current] = true
		for _, nextId in graph[current].links do
			if not done[nextId] then
				local d = best[current] + span3(graph[current], graph[nextId])
				if best[nextId] == nil then
					table.insert(open, nextId)
				end
				if best[nextId] == nil or d < best[nextId] then
					best[nextId] = d
					first[nextId] = if current == from then nextId else first[current]
				end
			end
		end
	end
	return nil
end

-- The graph node closest to a point (3D).
function Floors.nearestNode(graph: { [string]: Node }, x: number, y: number, z: number): string
	local bestId, bestD = "", math.huge
	for id, n in graph do
		local d = (n.x - x) ^ 2 + (n.y - y) ^ 2 + (n.z - z) ^ 2
		if d < bestD then
			bestId, bestD = id, d
		end
	end
	return bestId
end

return Floors
