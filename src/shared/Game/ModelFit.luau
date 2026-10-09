--!strict
-- How an imported mesh is fitted to the footprint the furniture data gives it. Pure maths, so the loader in
-- server/Props stays a thin wrapper and the rules are tested.
local ModelFit = {}

export type Foot = { w: number, d: number, h: number }

-- The uniform scale that makes a model of `size` (x, y, z) fit the footprint: the tightest of width, depth and
-- (when the footprint has one) height. `yaw` is the extra turn applied to the import (0, 90, 180, 270): at 90 or 270
-- the model's x and z swap.
function ModelFit.scale(foot: Foot, x: number, y: number, z: number, yaw: number): number
	local sx, sz = x, z
	if yaw % 180 == 90 then
		sx, sz = z, x
	end
	local k = math.min(foot.w / sx, foot.d / sz)
	if foot.h > 0 then
		k = math.min(k, foot.h / y)
	end
	return k
end

-- Blender and Roblox add suffixes to repeated names ("leg.001", "leg_2"): the style key is the base name.
function ModelFit.styleKey(name: string): string
	local base = string.gsub(name, "[%._]%d+$", "")
	return base
end

return ModelFit
