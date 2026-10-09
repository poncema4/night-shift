--!strict
-- The scare director's schedule. Events come further apart early in the night and closer together as it goes on,
-- so the tension builds. Pure rules: the server asks "what happens now?" and the clients make it look scary.
local Scares = {}
Scares.__index = Scares

export type Kind = "flicker" | "blackout" | "thud" | "whisper"
export type Event = { kind: string, seconds: number } -- kind is one of Kind

export type Scares = typeof(setmetatable(
	{} :: {
		random: (number) -> number,
		nightSeconds: number,
		elapsed: number,
		nextIn: number,
		lastBlackout: number,
	},
	Scares
))

local EARLY, LATE = 38, 14 -- seconds between events at the start and at the end of the night
local BLACKOUT_AFTER = 0.25 -- fraction of the night before blackouts can happen
local BLACKOUT_GAP = 60

local function unit(random: (number) -> number): number
	return (random(1000) - 1) / 999
end

function Scares.new(random: (number) -> number, nightSeconds: number): Scares
	local self = setmetatable({
		random = random,
		nightSeconds = nightSeconds,
		elapsed = 0,
		nextIn = 0,
		lastBlackout = -1e9,
	}, Scares)
	self.nextIn = 12 + unit(random) * 10 -- the first one comes early enough to set the mood
	return self
end

local function interval(self: Scares): number
	local t = math.clamp(self.elapsed / self.nightSeconds, 0, 1)
	local base = EARLY + (LATE - EARLY) * t
	return base * (0.7 + unit(self.random) * 0.6)
end

type Weight = { kind: Kind, weight: number }

local function pick(self: Scares): Kind
	local blackoutOk = self.elapsed / self.nightSeconds >= BLACKOUT_AFTER
		and self.elapsed - self.lastBlackout >= BLACKOUT_GAP
	local weights: { Weight } = {
		{ kind = "flicker", weight = 4 },
		{ kind = "thud", weight = 3 },
		{ kind = "whisper", weight = 3 },
	}
	if blackoutOk then
		table.insert(weights, { kind = "blackout", weight = 1.5 })
	end
	local total = 0
	for _, w in weights do
		total += w.weight
	end
	local roll = unit(self.random) * total
	for _, w in weights do
		roll -= w.weight
		if roll <= 0 then
			return w.kind
		end
	end
	return "flicker"
end

-- Advance by dt seconds; returns an event when one is due.
function Scares.tick(self: Scares, dt: number): Event?
	self.elapsed += dt
	self.nextIn -= dt
	if self.nextIn > 0 then
		return nil
	end
	local kind = pick(self)
	self.nextIn = interval(self)
	local event: Event = { kind = kind, seconds = 4 }
	if kind == "blackout" then
		self.lastBlackout = self.elapsed
		event.seconds = 5 + unit(self.random) * 4
	elseif kind == "flicker" then
		event.seconds = 3
	elseif kind == "thud" then
		event.seconds = 0.6
	end
	return event
end

return Scares
