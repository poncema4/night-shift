--!strict
-- Movement for the roaming threat: it only ever walks along the hotel graph (no clipping through walls).
-- Patrols at random; when a target is within hearing range it heads for the node closest to it.

local Hotel = require("./Hotel")

export type Target = { x: number, z: number }
export type Mode = "Patrol" | "Chase"

local Patrol = {}
Patrol.__index = Patrol

export type Patrol = typeof(setmetatable(
	{} :: {
		graph: { [string]: Hotel.Node },
		random: (number) -> number,
		x: number,
		z: number,
		from: string,
		to: string,
		mode: Mode,
	},
	Patrol
))

function Patrol.new(graph: { [string]: Hotel.Node }, startId: string, random: (number) -> number): Patrol
	local start = graph[startId]
	local first = start.links[random(#start.links)]
	return setmetatable({
		graph = graph,
		random = random,
		x = start.x,
		z = start.z,
		from = startId,
		to = first,
		mode = "Patrol" :: Mode,
	}, Patrol)
end

local function dist(ax: number, az: number, bx: number, bz: number): number
	return math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2)
end

local function chooseNext(self: Patrol, arrived: string, target: Target?): string
	local node = self.graph[arrived]
	local options = {}
	for _, id in node.links do
		if id ~= self.from then
			table.insert(options, id)
		end
	end
	if #options == 0 then
		options = node.links -- dead end: turn around
	end
	if target then
		local best, bestDistance = options[1], math.huge
		for _, id in options do
			local n = self.graph[id]
			local d = dist(n.x, n.z, target.x, target.z)
			if d < bestDistance then
				best, bestDistance = id, d
			end
		end
		return best
	end
	return options[self.random(#options)]
end

-- The room (or "Corridor") whose open floor contains the point; nil on a doorway or outside the hotel.
local function region(x: number, z: number): string?
	for _, room in Hotel.rooms do
		if x > room.x1 and x < room.x2 and z > room.z1 and z < room.z2 then
			return room.name
		end
	end
	local c = Hotel.CORRIDOR
	if x > c.x1 and x < c.x2 and z > c.z1 and z < c.z2 then
		return "Corridor"
	end
	return nil
end

-- The graph node to resume from after leaving a region: the room's own node, or the nearest corridor node.
local function anchor(self: Patrol, name: string, x: number): string
	if name ~= "Corridor" then
		return name
	end
	local best, bestDistance = "", math.huge
	for id, node in self.graph do
		if string.sub(id, 1, 1) == "C" and math.abs(node.x - x) < bestDistance then
			best, bestDistance = id, math.abs(node.x - x)
		end
	end
	return best
end

-- `target` is the closest hearable player (or nil). Returns nothing; read .x .z .mode afterwards.
function Patrol.tick(self: Patrol, dt: number, patrolSpeed: number, chaseSpeed: number, target: Target?)
	self.mode = if target then "Chase" else "Patrol"
	local remaining = dt * (if target then chaseSpeed else patrolSpeed)
	if target then
		local here = region(self.x, self.z)
		if here and here == region(target.x, target.z) then
			-- Same open room or corridor as the target: close in directly (a rectangle has no walls inside).
			local d = dist(self.x, self.z, target.x, target.z)
			if d <= remaining then
				self.x, self.z = target.x, target.z
			else
				self.x += (target.x - self.x) / d * remaining
				self.z += (target.z - self.z) / d * remaining
			end
			self.to = anchor(self, here, self.x)
			self.from = self.to
			return
		end
	end
	while remaining > 0 do
		local goal = self.graph[self.to]
		local d = dist(self.x, self.z, goal.x, goal.z)
		if remaining >= d then
			self.x, self.z = goal.x, goal.z
			remaining -= d
			local arrived = self.to
			local nextId = chooseNext(self, arrived, target)
			self.from, self.to = arrived, nextId
			if target and dist(self.x, self.z, target.x, target.z) < 0.001 then
				break -- standing on the target: nothing left to chase
			end
		else
			self.x += (goal.x - self.x) / d * remaining
			self.z += (goal.z - self.z) / d * remaining
			remaining = 0
		end
	end
end

return Patrol
