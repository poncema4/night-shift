--!strict
-- Flashlight battery. The light drains it; it recovers slowly while off. At zero the light cuts out ("dead")
-- and stays off until the charge has climbed back past a threshold, so it cannot be flicked on and off.
local Battery = {}
Battery.__index = Battery

export type Battery = typeof(setmetatable(
	{} :: { charge: number, max: number, drain: number, regen: number, minToStart: number, dead: boolean },
	Battery
))

function Battery.new(): Battery
	return setmetatable({ charge = 100, max = 100, drain = 2.2, regen = 1.1, minToStart = 8, dead = false }, Battery)
end

-- Can the player switch the light on right now?
function Battery.canStart(self: Battery): boolean
	return not self.dead and self.charge > 0
end

-- Advances by dt. `wantsOn` is the player's intent; returns whether the light is actually on.
function Battery.step(self: Battery, dt: number, wantsOn: boolean): boolean
	if self.dead and self.charge >= self.minToStart then
		self.dead = false
	end
	if wantsOn and Battery.canStart(self) then
		self.charge = math.max(0, self.charge - self.drain * dt)
		if self.charge <= 0 then
			self.dead = true
			return false
		end
		return true
	end
	self.charge = math.min(self.max, self.charge + self.regen * dt)
	return false
end

return Battery
