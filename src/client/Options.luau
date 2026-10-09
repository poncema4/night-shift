--!strict
-- Player options. Kept in memory for the session (a saved copy comes with the profile later); other client modules
-- read them through Options.get so a change applies at once.
local Options = {}

local values: { [string]: number | boolean } = { volume = 1, subtitles = true, calm = false }
local listeners: { (string) -> () } = {}

function Options.get(name: string): number | boolean
	return values[name]
end

function Options.volume(): number
	return values.volume :: number
end

function Options.set(name: string, value: number | boolean)
	values[name] = value
	for _, listener in listeners do
		listener(name)
	end
end

function Options.onChange(listener: (string) -> ())
	table.insert(listeners, listener)
end

-- Volume moves in tenths and stays in 0..1.
function Options.nudgeVolume(delta: number)
	Options.set("volume", math.clamp(math.floor((Options.volume() + delta) * 10 + 0.5) / 10, 0, 1))
end

return Options
