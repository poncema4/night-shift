--!strict
-- The round loop as a pure state machine: Lobby -> Intermission -> Night -> Dawn -> Lobby.
-- A Meeting can interrupt the Night (body reported or bell rung): the night clock is paused and resumes after.
-- It never reads the clock or Roblox services; the caller passes elapsed time and player counts.

export type Settings = {
	MinPlayers: number,
	MaxPlayers: number,
	IntermissionSeconds: number,
	NightSeconds: number,
	DawnSeconds: number,
	MeetingSeconds: number,
}
export type Phase = "Lobby" | "Intermission" | "Night" | "Meeting" | "Dawn"
export type Winner = "Crew" | "Saboteurs"
-- `coop` marks a round with too few players for a saboteur: a phantom one is counted, so the parity rule is replaced
-- by "the crew is wiped out" (otherwise a lone player would lose the moment the Night starts).
export type Stats = {
	crewAlive: number,
	saboteursAlive: number,
	tasksDone: number,
	tasksTotal: number,
	coop: boolean?,
}
export type Event = { from: Phase, to: Phase, winner: Winner? }

local Round = {}
Round.__index = Round

export type Round = typeof(setmetatable(
	{} :: { settings: Settings, phase: Phase, timeLeft: number, roundNumber: number, nightLeft: number },
	Round
))

function Round.new(settings: Settings): Round
	return setmetatable(
		{ settings = settings, phase = "Lobby" :: Phase, timeLeft = 0, roundNumber = 0, nightLeft = 0 },
		Round
	)
end

-- A winner as soon as one side has clearly won, otherwise nil.
function Round.evaluate(stats: Stats): Winner?
	if stats.saboteursAlive <= 0 then
		return "Crew"
	end
	local crewLost = if stats.coop then stats.crewAlive <= 0 else stats.crewAlive <= stats.saboteursAlive
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

-- Starts a meeting during the Night. The night clock is saved and resumes when the meeting ends.
function Round.callMeeting(self: Round): Event?
	if self.phase ~= "Night" then
		return nil
	end
	self.nightLeft = self.timeLeft
	return go(self, "Meeting", self.settings.MeetingSeconds, nil)
end

-- Cuts a meeting short (everyone has voted): only the last `seconds` remain, enough to show the result.
function Round.shortenMeeting(self: Round, seconds: number)
	if self.phase == "Meeting" then
		self.timeLeft = math.min(self.timeLeft, seconds)
	end
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
		local winner: Winner? = if stats then Round.evaluate(stats) else nil
		if winner then
			return go(self, "Dawn", s.DawnSeconds, winner)
		end
		if self.timeLeft <= 0 then
			-- The night ended with the tasks unfinished: the saboteurs held out.
			return go(self, "Dawn", s.DawnSeconds, "Saboteurs")
		end
	elseif self.phase == "Meeting" then
		if playerCount < 1 then
			return go(self, "Lobby", 0, nil)
		end
		self.timeLeft -= dt
		if self.timeLeft <= 0 then
			return go(self, "Night", self.nightLeft, nil)
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
