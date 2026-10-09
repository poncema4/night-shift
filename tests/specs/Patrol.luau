--!strict
local Hotel = require("../../src/shared/Game/Hotel")
local Patrol = require("../../src/shared/Game/Patrol")

local function makeRandom(seed: number): (number) -> number
	local s = seed
	return function(n: number): number
		s = (s * 1103515245 + 12345) % 2147483648
		return (s // 65536) % n + 1
	end
end

local function distanceToSegment(px: number, pz: number, a: Hotel.Node, b: Hotel.Node): number
	local dx, dz = b.x - a.x, b.z - a.z
	local len2 = dx * dx + dz * dz
	local f = math.clamp(((px - a.x) * dx + (pz - a.z) * dz) / len2, 0, 1)
	local cx, cz = a.x + dx * f, a.z + dz * f
	return math.sqrt((px - cx) ^ 2 + (pz - cz) ^ 2)
end

local function onGraph(graph: { [string]: Hotel.Node }, x: number, z: number): boolean
	for _, a in graph do
		for _, id in a.links do
			if distanceToSegment(x, z, a, graph[id]) < 1e-6 then
				return true
			end
		end
	end
	return false
end

return function(t)
	local graph = Hotel.graph()

	local p = Patrol.new(graph, "Pool Room", makeRandom(3))
	local stays, visited = true, {}
	for _ = 1, 4000 do
		p:tick(0.1, 10, 14, nil)
		if not onGraph(graph, p.x, p.z) or Hotel.inWall(p.x, p.z, 0) then
			stays = false
		end
		visited[p.to] = true
	end
	t.check("patrol never leaves the walkable graph or enters a wall", stays)
	local count = 0
	for _ in visited do
		count += 1
	end
	t.check("patrol wanders through many places", count >= 8, `visited {count}`)
	t.equal("patrol mode", p.mode, "Patrol")

	-- chase: from the far west corridor the threat reaches a target standing in the pool room
	local chaser = Patrol.new(graph, "Kitchen", makeRandom(5))
	local target = { x = graph["Pool Room"].x, z = graph["Pool Room"].z }
	for _ = 1, 600 do
		chaser:tick(0.1, 10, 14, target)
	end
	t.equal("chase mode", chaser.mode, "Chase")
	t.check("chase reaches the target", math.abs(chaser.x - target.x) < 1 and math.abs(chaser.z - target.z) < 1)

	-- an off-centre target inside a room: the threat closes in, stays on it, and never touches a wall
	local roomTarget = { x = 40, z = -20 }
	local seeker = Patrol.new(graph, "Kitchen", makeRandom(11))
	local inWall = false
	for _ = 1, 900 do
		seeker:tick(0.1, 10, 14, roomTarget)
		if Hotel.inWall(seeker.x, seeker.z, 0) then
			inWall = true
		end
	end
	t.check("chase into a room ends on the target", math.abs(seeker.x - 40) < 0.01 and math.abs(seeker.z + 20) < 0.01)
	t.check("a chase never passes through a wall", not inWall)

	-- once the target leaves the room, the threat resumes along the graph without cutting through walls
	local leftWall = false
	for _ = 1, 300 do
		seeker:tick(0.1, 10, 14, { x = -50, z = 15 })
		if Hotel.inWall(seeker.x, seeker.z, 0) then
			leftWall = true
		end
	end
	t.check("switching targets never cuts through a wall", not leftWall)

	-- speed limit: one tick can never move further than speed * dt
	local q = Patrol.new(graph, "Lobby", makeRandom(9))
	local fastest = 0
	for _ = 1, 500 do
		local x, z = q.x, q.z
		q:tick(0.25, 10, 14, nil)
		fastest = math.max(fastest, math.sqrt((q.x - x) ^ 2 + (q.z - z) ^ 2))
	end
	t.check("movement never exceeds speed times time", fastest <= 10 * 0.25 + 1e-6, `moved {fastest}`)
end
