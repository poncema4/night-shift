--!strict
-- Small pure helpers. No Roblox services in here, so Lune can test them on Linux.

local MathUtil = {}

function MathUtil.clamp(value: number, low: number, high: number): number
	if low > high then
		low, high = high, low
	end
	return math.max(low, math.min(high, value))
end

function MathUtil.lerp(from: number, to: number, alpha: number): number
	return from + (to - from) * alpha
end

-- "1.2K", "3.4M": for leaderboards and cash counters.
function MathUtil.shorten(value: number): string
	local suffixes = { "", "K", "M", "B", "T" }
	local index = 1
	local scaled = math.abs(value)
	while scaled >= 1000 and index < #suffixes do
		scaled /= 1000
		index += 1
	end
	local text = if scaled >= 100 or index == 1
		then string.format("%d", math.floor(scaled))
		else string.format("%.1f", scaled)
	text = string.gsub(text, "%.0$", "") :: string
	return (if value < 0 then "-" else "") .. text .. suffixes[index]
end

return MathUtil
