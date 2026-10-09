--!strict
-- Saboteur abilities and their cooldowns. The caller passes the current time, so this stays pure.
local Abilities = {}

export type Spec = { cooldown: number, seconds: number }

-- lure: the Night Manager investigates where you stand. lights: the lights on your floor go out.
Abilities.specs = {
	lure = { cooldown = 60, seconds = 12 },
	lights = { cooldown = 90, seconds = 8 },
} :: { [string]: Spec }

export type Tracker = { readyAt: { [number]: { [string]: number } } }

function Abilities.new(): Tracker
	return { readyAt = {} }
end

-- Time left before this player can use the ability again (0 when ready).
function Abilities.wait(tracker: Tracker, userId: number, ability: string, now: number): number
	local mine = tracker.readyAt[userId]
	local ready = mine and mine[ability] or 0
	return math.max(0, ready - now)
end

-- Try to use an ability. Returns true and starts the cooldown when allowed.
function Abilities.use(tracker: Tracker, userId: number, ability: string, now: number): boolean
	local spec = Abilities.specs[ability]
	if not spec or Abilities.wait(tracker, userId, ability, now) > 0 then
		return false
	end
	local mine = tracker.readyAt[userId] or {}
	tracker.readyAt[userId] = mine
	mine[ability] = now + spec.cooldown
	return true
end

return Abilities
