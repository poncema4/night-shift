--!strict
-- The Night Manager across all three levels: he uses the stairs, never the ceiling, and his height is continuous.
local Floors = require("../../src/shared/Game/Floors")
local Patrol = require("../../src/shared/Game/Patrol")

local function makeRandom(seed: number): (number) -> number
	local s = seed
	return function(n: number): number
		s = (s * 1103515245 + 12345) % 2147483648
		return (s // 65536) % n + 1
	end
end

return function(t)
	local graph = Floors.graph()

	-- wandering: stays out of walls, visits every level, and his height never jumps
	local p = Patrol.new(graph, "Pool Room", makeRandom(11))
	local clean, levels, maxJump = true, {}, 0
	local lastY = p.y
	for _ = 1, 30000 do
		p:tick(0.1, 10, 14, nil)
		if Floors.inWall(Floors.levelAt(p.y), p.x, p.z, 0) then
			clean = false
		end
		levels[Floors.levelAt(p.y)] = true
		maxJump = math.max(maxJump, math.abs(p.y - lastY))
		lastY = p.y
	end
	t.check("wandering never enters a wall on any level", clean)
	t.check("wandering reaches the basement, ground floor and upstairs", levels[-1] and levels[0] and levels[1])
	t.check("height changes smoothly along stairs", maxJump <= 0.8, string.format("max jump %.2f", maxJump))

	-- chase up the stairs to a player in Room 204
	local up = Patrol.new(graph, "Kitchen", makeRandom(5))
	local target = { x = graph["Room 204"].x, y = Floors.y(1), z = graph["Room 204"].z }
	local usedStairs = false
	for _ = 1, 4000 do
		up:tick(0.1, 10, 14, target)
		if up.from == "WA3" or up.to == "WA3" then
			usedStairs = true
		end
	end
	t.check("chase to an upstairs room goes by the west stairs", usedStairs)
	t.check(
		"the chase arrives at the player's spot and height",
		math.abs(up.x - target.x) < 1 and math.abs(up.z - target.z) < 1 and math.abs(up.y - target.y) < 0.5
	)

	-- a player straight above him is not reachable through the ceiling
	local lobby = Patrol.new(graph, "Lobby", makeRandom(9))
	local above = { x = graph["Lobby"].x, y = Floors.y(1), z = graph["Lobby"].z }
	for _ = 1, 10 do
		lobby:tick(0.1, 10, 14, above)
	end
	t.check("a player on the floor above does not pull him through the ceiling", lobby.y < 0.5)
	for _ = 1, 4000 do
		lobby:tick(0.1, 10, 14, above)
	end
	t.check("he finds the way up to a player directly above", math.abs(lobby.y - above.y) < 0.5)

	-- chase down to the basement
	local down = Patrol.new(graph, "Room 204", makeRandom(2))
	local cellar = { x = graph["Generator Room"].x, y = Floors.y(-1), z = graph["Generator Room"].z }
	for _ = 1, 6000 do
		down:tick(0.1, 10, 14, cellar)
	end
	t.check(
		"chase from upstairs down to the generator room",
		math.abs(down.x - cellar.x) < 1 and math.abs(down.y - cellar.y) < 0.5
	)
end
