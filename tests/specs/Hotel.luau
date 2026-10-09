--!strict
local Hotel = require("../../src/shared/Game/Hotel")

local function overlaps(a: Hotel.Rect, b: Hotel.Rect): boolean
	return a.x1 < b.x2 and b.x1 < a.x2 and a.z1 < b.z2 and b.z1 < a.z2
end

return function(t)
	local rooms = Hotel.rooms
	local clean = true
	for i = 1, #rooms do
		for j = i + 1, #rooms do
			if overlaps(rooms[i], rooms[j]) then
				clean = false
			end
		end
	end
	t.check("no two rooms overlap", clean)

	local doorsOpen = true
	for _, room in rooms do
		local x, z = Hotel.door(room)
		if Hotel.inWall(x, z, 0) then
			doorsOpen = false
		end
	end
	t.check("every door gap is free of walls", doorsOpen)

	local fullWidth = true
	for _, room in rooms do
		local x, z = Hotel.door(room)
		local edge = Hotel.DOOR / 2
		if Hotel.inWall(x - edge + 0.1, z, 0) or Hotel.inWall(x + edge - 0.1, z, 0) then
			fullWidth = false -- the gap is narrower than DOOR
		end
		if not Hotel.inWall(x - edge - 0.6, z, 0) or not Hotel.inWall(x + edge + 0.6, z, 0) then
			fullWidth = false -- the wall is missing right next to the door
		end
	end
	t.check("every door gap is exactly DOOR wide, walls on both sides", fullWidth)

	local solid = Hotel.inWall(-45, 25, 0)
	t.check("the outer wall really is solid", solid)

	local wellPlaced = true
	for _, task in Hotel.tasks do
		local room = Hotel.room(task.room)
		local inside = task.x > room.x1 and task.x < room.x2 and task.z > room.z1 and task.z < room.z2
		if not inside or Hotel.inWall(task.x, task.z, 2) then
			wellPlaced = false
		end
	end
	t.check("every task is inside its room and clear of walls", wellPlaced)
	t.equal("six tasks", #Hotel.tasks, 6)

	local graph = Hotel.graph()
	-- connected: walk from the lobby and count what we reach
	local seen, stack, reached = { Lobby = true }, { "Lobby" }, 1
	while #stack > 0 do
		local id = table.remove(stack) :: string
		for _, other in graph[id].links do
			if not seen[other] then
				seen[other] = true
				reached += 1
				table.insert(stack, other)
			end
		end
	end
	local total = 0
	for _ in graph do
		total += 1
	end
	t.equal("the walkable graph is connected", reached, total)

	-- no edge may cut through a wall: sample along every edge
	local clear = true
	for id, node in graph do
		for _, otherId in node.links do
			local other = graph[otherId]
			for step = 0, 40 do
				local f = step / 40
				if Hotel.inWall(node.x + (other.x - node.x) * f, node.z + (other.z - node.z) * f, 0) then
					clear = false
					print("edge through wall:", id, otherId)
				end
			end
		end
	end
	t.check("no walking edge passes through a wall", clear)
end
