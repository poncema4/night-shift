--!strict
local Scares = require("../../src/shared/Game/Scares")

local function makeRandom(seed: number): (number) -> number
	local s = seed
	return function(n: number): number
		s = (s * 1103515245 + 12345) % 2147483648
		return (s // 65536) % n + 1
	end
end

local function night(seed: number, seconds: number): { { kind: string, at: number } }
	local director = Scares.new(makeRandom(seed), seconds)
	local log = {}
	local clock = 0
	for _ = 1, seconds * 10 do
		clock += 0.1
		local event = director:tick(0.1)
		if event then
			table.insert(log, { kind = event.kind, at = clock })
		end
	end
	return log
end

return function(t)
	local ok, early, late, firstBlackout, tooClose = true, 0, 0, math.huge, false
	for seed = 1, 40 do
		local log = night(seed, 240)
		if #log < 6 or #log > 20 then
			ok = false
		end
		local lastBlackout = -1e9
		for _, e in log do
			if e.at < 80 then
				early += 1
			elseif e.at >= 160 then
				late += 1
			end
			if e.kind == "blackout" then
				firstBlackout = math.min(firstBlackout, e.at)
				if e.at - lastBlackout < 60 then
					tooClose = true
				end
				lastBlackout = e.at
			end
		end
	end
	t.check("a 240 second night has between 6 and 20 scares, every time", ok)
	t.check("the night gets busier toward the end", late > early, `early {early}, late {late}`)
	t.check("no blackout in the first quarter of the night", firstBlackout >= 60, `first at {firstBlackout}`)
	t.check("blackouts are at least a minute apart", not tooClose)

	local kinds = {}
	for seed = 1, 40 do
		for _, e in night(seed, 240) do
			kinds[e.kind] = true
		end
	end
	t.check("every kind of scare happens", kinds.flicker and kinds.thud and kinds.whisper and kinds.blackout)
end
