--!strict
-- How far the Night Manager can hear you, and how long he needs to find you in a hiding place.
local Stealth = {}

export type State = { moving: boolean, sprinting: boolean, flashlight: boolean, hidden: boolean }

Stealth.SPRINT = 1.5 -- running is loud
Stealth.STILL = 0.4 -- standing still is quiet
Stealth.LIGHT = 1.25 -- a flashlight draws attention
Stealth.SMELL = 5 -- within this many studs he can find you even in a locker
Stealth.SEARCH_SECONDS = 1.5 -- he needs this long near a locker to pull you out

-- Hearing range for one player given the base range. Hidden players are not heard at all.
function Stealth.hearingRange(base: number, state: State): number
	if state.hidden then
		return 0
	end
	local factor = 1
	if state.sprinting then
		factor = Stealth.SPRINT
	elseif not state.moving then
		factor = Stealth.STILL
	end
	if state.flashlight then
		factor *= Stealth.LIGHT
	end
	return base * factor
end

-- Time near a hiding place builds up; he finds you once it passes SEARCH_SECONDS. Moving away cools it.
-- Returns the new timer and whether you were found.
function Stealth.search(timer: number, dt: number, distance: number): (number, boolean)
	if distance <= Stealth.SMELL then
		local t = timer + dt
		return t, t >= Stealth.SEARCH_SECONDS
	end
	return math.max(0, timer - dt * 2), false
end

return Stealth
