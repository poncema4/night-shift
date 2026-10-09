--!strict
-- Sprint stamina. Pure rules: the server steps it, the client only shows the bar.
-- Sprinting while moving drains it; resting refills it after a short delay. Hitting zero leaves you winded
-- (no sprint) until you have recovered a little, so you cannot just tap-sprint forever.
local Stamina = {}
Stamina.__index = Stamina

export type Stamina = typeof(setmetatable(
	{} :: {
		value: number,
		max: number,
		winded: boolean,
		rest: number, -- seconds since last sprinting
		drain: number,
		regen: number,
		delay: number,
		recover: number,
	},
	Stamina
))

function Stamina.new(): Stamina
	return setmetatable({
		value = 100,
		max = 100,
		winded = false,
		rest = 99,
		drain = 22, -- per second while sprinting
		regen = 16, -- per second while resting
		delay = 1, -- seconds of rest before it refills
		recover = 30, -- a winded player may sprint again above this
	}, Stamina)
end

-- Advances by dt. Returns true when the player is actually sprinting this step.
function Stamina.step(self: Stamina, dt: number, wantsSprint: boolean, moving: boolean): boolean
	local sprinting = wantsSprint and moving and not self.winded and self.value > 0
	if sprinting then
		self.rest = 0
		self.value = math.max(0, self.value - self.drain * dt)
		if self.value <= 0 then
			self.winded = true
			sprinting = false
		end
	else
		self.rest += dt
		if self.rest >= self.delay then
			self.value = math.min(self.max, self.value + self.regen * dt)
		end
		if self.winded and self.value >= self.recover then
			self.winded = false
		end
	end
	return sprinting
end

return Stamina
