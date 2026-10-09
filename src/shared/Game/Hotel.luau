--!strict
-- The hotel as plain data: rooms, wall boxes, task stations and the walkable graph the threat follows.
-- Everything is x/z on a flat floor (y is handled by the builder). Units are studs.

export type Rect = { name: string, x1: number, z1: number, x2: number, z2: number }
export type Box = { x: number, z: number, w: number, d: number } -- centre + size
export type TaskSpot = { id: string, name: string, room: string, x: number, z: number }
export type Node = { id: string, x: number, z: number, links: { string } }

local Hotel = {}

Hotel.CEILING = 14
Hotel.WALL = 1
Hotel.DOOR = 8
Hotel.CORRIDOR = { x1 = -60, z1 = -5, x2 = 60, z2 = 5 }

Hotel.rooms = {
	{ name = "Kitchen", x1 = -60, z1 = 5, x2 = -40, z2 = 25 },
	{ name = "Boiler Room", x1 = -40, z1 = 5, x2 = -20, z2 = 25 },
	{ name = "Laundry", x1 = -20, z1 = 5, x2 = 0, z2 = 25 },
	{ name = "Storage", x1 = 0, z1 = 5, x2 = 20, z2 = 25 },
	{ name = "Security", x1 = 20, z1 = 5, x2 = 40, z2 = 25 },
	{ name = "Pantry", x1 = 40, z1 = 5, x2 = 60, z2 = 25 },
	{ name = "Lobby", x1 = -60, z1 = -25, x2 = -30, z2 = -5 },
	{ name = "Office", x1 = -30, z1 = -25, x2 = -10, z2 = -5 },
	{ name = "Ballroom", x1 = -10, z1 = -25, x2 = 30, z2 = -5 },
	{ name = "Pool Room", x1 = 30, z1 = -25, x2 = 60, z2 = -5 },
} :: { Rect }

Hotel.tasks = {
	{ id = "breaker", name = "Reset the breaker", room = "Boiler Room", x = -30, z = 21 },
	{ id = "minibar", name = "Restock the minibar", room = "Kitchen", x = -50, z = 21 },
	{ id = "linens", name = "Fold the linens", room = "Laundry", x = -10, z = 21 },
	{ id = "cameras", name = "Fix the cameras", room = "Security", x = 30, z = 21 },
	{ id = "clock", name = "Wind the grand clock", room = "Ballroom", x = 10, z = -21 },
	{ id = "chlorine", name = "Refill the pool chlorine", room = "Pool Room", x = 45, z = -21 },
} :: { TaskSpot }

function Hotel.centre(room: Rect): (number, number)
	return (room.x1 + room.x2) / 2, (room.z1 + room.z2) / 2
end

local function isNorth(room: Rect): boolean
	return room.z1 >= Hotel.CORRIDOR.z2
end

-- Where the door of a room opens into the corridor (centre of the gap).
function Hotel.door(room: Rect): (number, number)
	local cx = Hotel.centre(room)
	return cx, if isNorth(room) then Hotel.CORRIDOR.z2 else Hotel.CORRIDOR.z1
end

function Hotel.room(name: string): Rect
	for _, room in Hotel.rooms do
		if room.name == name then
			return room
		end
	end
	error("unknown room " .. name)
end

-- Walls only ever touch, never overlap: overlapping same-material faces are coplanar and shimmer in Roblox.
function Hotel.wallBoxes(): { Box }
	local boxes: { Box } = {}
	local c = Hotel.CORRIDOR
	local w = Hotel.WALL
	local half = w / 2
	local north, south = 25, -25
	table.insert(boxes, { x = 0, z = north, w = (c.x2 - c.x1) + w, d = w })
	table.insert(boxes, { x = 0, z = south, w = (c.x2 - c.x1) + w, d = w })
	local sideLength = (north - south) - w
	table.insert(boxes, { x = c.x1, z = 0, w = w, d = sideLength })
	table.insert(boxes, { x = c.x2, z = 0, w = w, d = sideLength })
	for _, room in Hotel.rooms do
		local cx, doorZ = Hotel.door(room)
		local gap = Hotel.DOOR / 2
		local leftStart, leftEnd = room.x1 + half, cx - gap
		local rightStart, rightEnd = cx + gap, room.x2 - half
		table.insert(boxes, { x = (leftStart + leftEnd) / 2, z = doorZ, w = leftEnd - leftStart, d = w })
		table.insert(boxes, { x = (rightStart + rightEnd) / 2, z = doorZ, w = rightEnd - rightStart, d = w })
		if room.x2 < c.x2 then
			local z1, z2
			if room.z1 >= c.z2 then
				z1, z2 = room.z1 + half, north - half
			else
				z1, z2 = south + half, room.z2 - half
			end
			table.insert(boxes, { x = room.x2, z = (z1 + z2) / 2, w = w, d = z2 - z1 })
		end
	end
	return boxes
end

function Hotel.inBox(x: number, z: number, box: Box, margin: number): boolean
	return math.abs(x - box.x) <= box.w / 2 + margin and math.abs(z - box.z) <= box.d / 2 + margin
end

function Hotel.inWall(x: number, z: number, margin: number): boolean
	for _, box in Hotel.wallBoxes() do
		if Hotel.inBox(x, z, box, margin) then
			return true
		end
	end
	return false
end

-- Walkable graph: one node per room centre, one per door on the corridor, corridor nodes chained west to east.
function Hotel.graph(): { [string]: Node }
	local nodes: { [string]: Node } = {}
	local corridorX: { number } = {}
	local seen: { [number]: boolean } = {}
	for _, room in Hotel.rooms do
		local x, z = Hotel.centre(room)
		nodes[room.name] = { id = room.name, x = x, z = z, links = {} }
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
		local id = "C" .. x
		nodes[id] = { id = id, x = x, z = 0, links = {} }
		if previous then
			link(previous, id)
		end
		previous = id
	end
	for _, room in Hotel.rooms do
		link(room.name, "C" .. Hotel.door(room))
	end
	return nodes
end

return Hotel
