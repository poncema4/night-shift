--!strict
-- The flashlight as a weapon of last resort: holding the beam on the Night Manager for about a second blinds him for a few
-- seconds, then he needs time to recover before he can be blinded again. Pure rules: positions in, yes/no out.
local Flash = {}

export type State = { exposure: number, stunUntil: number, readyAt: number }

Flash.RANGE = 45 -- studs
Flash.HALF_ANGLE = 22 -- degrees either side of where you are looking
Flash.EXPOSURE = 0.9 -- seconds of beam it takes
Flash.STUN = 3 -- seconds he is blinded
Flash.COOLDOWN = 18 -- seconds after the stun ends before he can be blinded again

function Flash.new(): State
	return { exposure = 0, stunUntil = 0, readyAt = 0 }
end

-- Is `target` inside the cone that starts at `origin` and points along the unit vector `look`?
function Flash.inBeam(
	origin: { number },
	look: { number },
	target: { number },
	range: number,
	halfAngleDegrees: number
): boolean
	local dx, dy, dz = target[1] - origin[1], target[2] - origin[2], target[3] - origin[3]
	local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
	if distance > range then
		return false
	end
	if distance < 0.001 then
		return true
	end
	local cos = (dx * look[1] + dy * look[2] + dz * look[3]) / distance
	return cos >= math.cos(math.rad(halfAngleDegrees))
end

function Flash.stunned(state: State, now: number): boolean
	return now < state.stunUntil
end

-- Advance by dt. `lit` is true while someone's beam is on him (in the cone and in line of sight).
-- Returns true on the step he becomes blinded.
function Flash.step(state: State, dt: number, lit: boolean, now: number): boolean
	if Flash.stunned(state, now) or now < state.readyAt then
		state.exposure = 0
		return false
	end
	if lit then
		state.exposure += dt
		if state.exposure >= Flash.EXPOSURE then
			state.exposure = 0
			state.stunUntil = now + Flash.STUN
			state.readyAt = state.stunUntil + Flash.COOLDOWN
			return true
		end
	else
		state.exposure = math.max(0, state.exposure - dt * 2) -- looking away lets him recover quickly
	end
	return false
end

return Flash
