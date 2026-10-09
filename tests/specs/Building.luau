--!strict
-- Geometry tests over the real data for all three levels: nothing overlaps, every walking path has a floor under
-- it and headroom over it, stairs are climbable, and every task station fits in its room.
local Building = require("../../src/shared/Game/Building")
local Dressing = require("../../src/shared/Game/Dressing")
local Floors = require("../../src/shared/Game/Floors")

local WALKABLE = { tile = true, tread = true, landing = true }
local MAX_STEP = 1.05
local HALF = 0.8 -- half a player's width
local HEAD = 5

-- Is there a walkable surface under (x, z) whose top is within `reach` of y, and room to stand on it?
local function standable(x: number, y: number, z: number): (boolean, string)
	local support = false
	for _, s in Building.solids() do
		if WALKABLE[s.kind] and math.abs(x - s.x) <= s.w / 2 + 1e-6 and math.abs(z - s.z) <= s.d / 2 + 1e-6 then
			local top = s.y + s.h
			if top >= y - 1.3 and top <= y + 1.0 then
				support = true
				break
			end
		end
	end
	if not support then
		return false, "no floor"
	end
	local hit = Building.blocked(x - HALF, y + 1.5, z - HALF, x + HALF, y + HEAD, z + HALF)
	if hit then
		return false, `blocked by {hit.kind}{if hit.name then " " .. hit.name else ""}`
	end
	return true, ""
end

return function(t)
	local solids = Building.solids()
	t.check("the building has hundreds of pieces", #solids > 500, `{#solids}`)

	-- 1. nothing shares volume with anything else (no coplanar flicker, no hidden collisions)
	local clash = ""
	for i = 1, #solids do
		for j = i + 1, #solids do
			if Dressing.intersects(solids[i], solids[j]) then
				clash = `{solids[i].kind}#{i} x {solids[j].kind}#{j}`
				break
			end
		end
		if clash ~= "" then
			break
		end
	end
	t.check("no two pieces share volume", clash == "", clash)

	-- 2. room names are unique across levels
	local names, unique = {}, true
	for _, level in Floors.levels do
		for _, room in Floors.rooms(level) do
			if names[room.name] then
				unique = false
			end
			names[room.name] = true
		end
	end
	t.check("room names are unique on every level", unique)

	-- 3. carving a hole keeps exactly the rest of the slab
	local rect = { x1 = 0, z1 = 0, x2 = 10, z2 = 6 }
	local hole = { x1 = 3, z1 = 2, x2 = 7, z2 = 5 }
	local pieces = Floors.carve(rect, { hole })
	local area = 0
	for _, p in pieces do
		area += (p.x2 - p.x1) * (p.z2 - p.z1)
	end
	t.equal("carve leaves slab area minus hole area", area, 60 - 12)

	-- 4. stairs: each step up is a climbable height and the flights meet their landings and floors
	local steps = true
	for _, a in Floors.annexes do
		local dir = if a.side < 0 then 1 else -1
		local tops = {}
		for _, s in Floors.treads() do
			if string.sub(s.name or "", 1, #a.id) == a.id then
				tops[s.name :: string] = s.y + s.h
			end
		end
		local previous = 0
		for _, flight in { "1", "2" } do
			for i = 1, Floors.STEPS do
				local top = tops[a.id .. flight .. "_" .. i] or dir * 2 * Floors.STEPS * Floors.RISE -- the floor is the last step
				if math.abs(top - previous) > MAX_STEP then
					steps = false
				end
				previous = top
			end
		end
		if math.abs(previous - dir * 2 * Floors.STEPS * Floors.RISE) > 1e-6 then
			steps = false -- the top step must land exactly on the next floor
		end
	end
	t.check("every stair step is climbable and the flights reach the next floor", steps)

	-- 5. every graph node is standable (floor underneath, headroom above)
	local graph = Floors.graph()
	local bad = ""
	for id, node in graph do
		local ok, why = standable(node.x, node.y, node.z)
		if not ok then
			bad = `{id} at ({node.x},{node.y},{node.z}): {why}`
			break
		end
	end
	t.check("every node of the walkable graph has floor and headroom", bad == "", bad)

	-- 6. every edge is walkable along its whole length (this proves the stair holes and doorways work)
	local worst = ""
	for id, node in graph do
		for _, otherId in node.links do
			local other = graph[otherId]
			local dx, dz = other.x - node.x, other.z - node.z
			local length = math.sqrt(dx * dx + dz * dz)
			local n = math.max(1, math.ceil(length / 0.5))
			for k = 0, n do
				local f = k / n
				local x, z = node.x + dx * f, node.z + dz * f
				local y = node.y + (other.y - node.y) * f
				local ok, why = standable(x, y, z)
				if not ok then
					worst = `{id}->{otherId} at ({string.format("%.1f", x)},{string.format("%.1f", y)},{string.format(
						"%.1f",
						z
					)}): {why}`
					break
				end
			end
			if worst ~= "" then
				break
			end
		end
		if worst ~= "" then
			break
		end
	end
	t.check("every walkable edge keeps a floor under it and headroom over it", worst == "", worst)

	-- 7. the graph is one connected piece
	local seen, queue = { Kitchen = true }, { "Kitchen" }
	while #queue > 0 do
		local id = table.remove(queue) :: string
		for _, nextId in graph[id].links do
			if not seen[nextId] then
				seen[nextId] = true
				table.insert(queue, nextId)
			end
		end
	end
	local reachable, total = 0, 0
	for id in graph do
		total += 1
		if seen[id] then
			reachable += 1
		end
	end
	t.equal("every node can be reached from the kitchen", reachable, total)

	-- 8. each task station (4 x 5 x 2.5) fits inside its room without touching anything
	local fits = ""
	for _, task in Floors.tasks() do
		local y = Floors.y(task.level)
		local hit = Building.blocked(task.x - 2, y, task.z - 1.25, task.x + 2, y + 5, task.z + 1.25)
		local room = Floors.room(task.level, task.room)
		local inRoom = task.x > room.x1 and task.x < room.x2 and task.z > room.z1 and task.z < room.z2
		if hit or not inRoom then
			fits = `{task.id}: {if hit then "touches " .. hit.kind else "outside " .. task.room}`
			break
		end
	end
	t.check("every task station fits in its room", fits == "", fits)

	-- 9. every doorway is open and has a header over it
	local doorsOk = true
	for _, level in Floors.levels do
		for _, door in Floors.doors(level) do
			if Floors.inWall(level, door.x, door.z, 0) then
				doorsOk = false
			end
		end
		if #Dressing.headers(level) ~= #Floors.doors(level) then
			doorsOk = false
		end
	end
	t.check("doorways are open and headed on every level", doorsOk)

	-- 10. routing finds a way between floors
	local up = Floors.nextHop(graph, "Kitchen", "Room 204")
	t.check("a route exists from the ground floor to a room upstairs", up ~= nil)
	local down = Floors.nextHop(graph, "Room 204", "Generator Room")
	t.check("a route exists from upstairs to the basement", down ~= nil)
end
