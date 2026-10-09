--!strict
-- Writes the building and furniture data to art/layout.json so Blender can draw the real layout.
-- Run: lune run scripts/export-layout
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Building = require("../src/shared/Game/Building")
local Floors = require("../src/shared/Game/Floors")
local Furnishing = require("../src/shared/Game/Furnishing")

local items = {}
for _, item in Furnishing.items() do
	local w, d = Furnishing.extent(item)
	table.insert(items, { kind = item.kind, level = item.level, x = item.x, z = item.z, w = w, d = d, h = Furnishing.foot[item.kind].h, y = Floors.y(item.level) })
end
local graph = {}
for id, node in Floors.graph() do
	graph[id] = { x = node.x, y = node.y, z = node.z, links = node.links }
end
fs.writeFile("art/layout.json", serde.encode("json", { solids = Building.solids(), items = items, graph = graph }))
print(`wrote art/layout.json: {#Building.solids()} solids, {#items} items`)
