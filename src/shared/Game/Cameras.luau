--!strict
-- Security cameras. Finishing the "Fix the cameras" task gives the whole crew a few uses of the monitor; each use
-- lets one crew member watch the Night Manager on a map for a short time, then there is a team cooldown.
-- Pure rules: the caller passes the current time.
local Cameras = {}

export type State = { charges: number, readyAt: number }

Cameras.CHARGES = 3
Cameras.WATCH_SECONDS = 15
Cameras.COOLDOWN = 40 -- team-wide, counted from the moment someone starts watching

function Cameras.new(): State
	return { charges = 0, readyAt = 0 }
end

-- The cameras task was finished: the crew gets its charges (finishing it twice does not stack).
function Cameras.unlock(state: State)
	state.charges = Cameras.CHARGES
end

-- Seconds until the monitor can be used again (0 when ready or when there are no charges to wait for).
function Cameras.wait(state: State, now: number): number
	return math.max(0, state.readyAt - now)
end

-- Try to start watching. Returns true and spends a charge when allowed.
function Cameras.use(state: State, now: number): boolean
	if state.charges <= 0 or Cameras.wait(state, now) > 0 then
		return false
	end
	state.charges -= 1
	state.readyAt = now + Cameras.COOLDOWN
	return true
end

return Cameras
