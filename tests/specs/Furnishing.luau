--!strict
-- Furniture never blocks a route, a doorway, a task station or another piece, and never touches a wall.
local Building = require("../../src/shared/Game/Building")
local Floors = require("../../src/shared/Game/Floors")
local Furnishing = require("../../src/shared/Game/Furnishing")

local CLEAR = 1.2 -- keep this far from any walking route (about a player's radius)

local function box(item: Furnishing.Item): (number, number, number, number)
	local w, d = Furnishing.extent(item)
	return item.x - w / 2, item.z - d / 2, item.x + w / 2, item.z + d / 2
end

local function describe(item: Furnishing.Item): string
	return `{item.kind}@{item.level}({item.x},{item.z})`
end

return function(t)
	local items = Furnishing.items()
	t.check("every level is furnished", #items > 50, `{#items}`)

	local graph = Floors.graph()
	local problems: { string } = {}
	local function fail(text: string)
		table.insert(problems, text)
	end

	for _, item in items do
		local soft = Furnishing.soft[item.kind]
		local x1, z1, x2, z2 = box(item)
		local y0 = Floors.y(item.level)
		local f = Furnishing.foot[item.kind]

		-- inside the level's walkable space
		for _, corner in { { x1, z1 }, { x1, z2 }, { x2, z1 }, { x2, z2 } } do
			if not Floors.interior(item.level, corner[1], corner[2]) then
				fail(describe(item) .. " is outside the hotel")
			end
		end
		if soft then
			continue
		end

		-- touches no wall, trim, floor edge or stair
		local hit = Building.blocked(x1, y0 + 0.05, z1, x2, y0 + math.max(f.h, 0.1), z2)
		if hit then
			fail(`{describe(item)} touches {hit.kind}`)
		end

		-- keeps clear of every walking route on its level
		for id, node in graph do
			if math.abs(node.y - y0) > 0.5 then
				continue
			end
			for _, otherId in node.links do
				local other = graph[otherId]
				if math.abs(other.y - y0) > 0.5 then
					continue
				end
				local dx, dz = other.x - node.x, other.z - node.z
				local n = math.max(1, math.ceil(math.sqrt(dx * dx + dz * dz) / 0.25))
				for k = 0, n do
					local px, pz = node.x + dx * k / n, node.z + dz * k / n
					if px > x1 - CLEAR and px < x2 + CLEAR and pz > z1 - CLEAR and pz < z2 + CLEAR then
						fail(`{describe(item)} blocks the route {id}->{otherId}`)
						break
					end
				end
			end
		end

		-- keeps clear of task stations (4 x 2.5 footprint) on its level
		for _, task in Floors.tasks() do
			if task.level == item.level then
				if
					x2 > task.x - 2 - 1
					and x1 < task.x + 2 + 1
					and z2 > task.z - 1.25 - 1
					and z1 < task.z + 1.25 + 1
				then
					fail(`{describe(item)} crowds the {task.id} station`)
				end
			end
		end
	end
	t.check(
		"furniture is inside the building, clear of walls, routes and stations",
		#problems == 0,
		table.concat(problems, "; ")
	)

	-- no two solid pieces overlap
	local clash = ""
	for i = 1, #items do
		for j = i + 1, #items do
			local a, b = items[i], items[j]
			if a.level == b.level and not Furnishing.soft[a.kind] and not Furnishing.soft[b.kind] then
				local ax1, az1, ax2, az2 = box(a)
				local bx1, bz1, bx2, bz2 = box(b)
				if ax1 < bx2 - 1e-6 and ax2 > bx1 + 1e-6 and az1 < bz2 - 1e-6 and az2 > bz1 + 1e-6 then
					clash = clash == "" and `{describe(a)} overlaps {describe(b)}` or clash
				end
			end
		end
	end
	t.check("no two pieces of furniture overlap", clash == "", clash)
end
