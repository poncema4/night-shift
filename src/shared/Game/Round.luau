--!strict
-- The round loop as a pure state machine: Lobby -> Intermission -> Night -> Dawn -> Lobby.
-- It never reads the clock or Roblox services; the caller passes elapsed time and player counts.

export type Settings = {
	MinPlayers: number,
	MaxPlayers: number,
	IntermissionSeconds: number,
	NightSeconds: number,
	DawnSeconds: number,
}
export type Phase = "Lobby" | "Intermission" | "Night" | "Dawn"
export type Winner = "Crew" | "Saboteurs"
-- `sandbox` marks a solo test round in Studio: the saboteur is a phantom, so the parity rule is replaced
-- by "the crew is wiped out", otherwise a lone player would lose the moment the Night starts.
export type Stats = {
	crewAlive: number,
	saboteursAlive: number,
	tasksDone: number,
	tasksTotal: number,
	sandbox: boolean?,
}
export type Event = { from: Phase, to: Phase, winner: Winner? }

local Round = {}
Round.__index = Round

export type Round = typeof(setmetatable(
	{} :: { settings: Settings, phase: Phase, timeLeft: number, roundNumber: number },
	Round
))

function Round.new(settings: Settings): Round
	return setmetatable({ settings = settings, phase = "Lobby" :: Phase, timeLeft = 0, roundNumber = 0 }, Round)
end

-- A winner as soon as one side has clearly won, otherwise nil.
function Round.evaluate(stats: Stats): Winner?
	if stats.saboteursAlive <= 0 then
		return "Crew"
	end
	local crewLost = if stats.sandbox then stats.crewAlive <= 0 else stats.crewAlive <= stats.saboteursAlive
	if crewLost then
		return "Saboteurs"
	end
	if stats.tasksTotal > 0 and stats.tasksDone >= stats.tasksTotal then
		return "Crew"
	end
	return nil
end

local function go(self: Round, to: Phase, seconds: number, winner: Winner?): Event
	local event: Event = { from = self.phase, to = to, winner = winner }
	self.phase = to
	self.timeLeft = seconds
	return event
end

-- Advance by `dt` seconds. Returns at most one phase change. `stats` is only used during Night.
function Round.tick(self: Round, dt: number, playerCount: number, stats: Stats?): Event?
	local s = self.settings
	if self.phase == "Lobby" then
		if playerCount >= s.MinPlayers then
			return go(self, "Intermission", s.IntermissionSeconds, nil)
		end
	elseif self.phase == "Intermission" then
		if playerCount < s.MinPlayers then
			return go(self, "Lobby", 0, nil)
		end
		self.timeLeft -= dt
		if self.timeLeft <= 0 then
			self.roundNumber += 1
			return go(self, "Night", s.NightSeconds, nil)
		end
	elseif self.phase == "Night" then
		if playerCount < 1 then
			return go(self, "Lobby", 0, nil)
		end
		self.timeLeft -= dt
		local winner = if stats then Round.evaluate(stats) else nil
		if winner then
			return go(self, "Dawn", s.DawnSeconds, winner)
		end
		if self.timeLeft <= 0 then
			-- The night ended with the tasks unfinished: the saboteurs held out.
			return go(self, "Dawn", s.DawnSeconds, "Saboteurs")
		end
	else
		self.timeLeft -= dt
		if self.timeLeft <= 0 then
			return go(self, "Lobby", 0, nil)
		end
	end
	return nil
end

return Round
