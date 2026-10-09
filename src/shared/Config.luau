--!strict
-- Game-wide constants. Plain data: safe to require from the server, the client and the tests.

return table.freeze({
	GameName = "NIGHT SHIFT",
	StudioName = "Nexus Hollow Studios",
	Version = "0.4.0",

	Round = table.freeze({
		MinPlayers = 6,
		MaxPlayers = 10,
		IntermissionSeconds = 20,
		NightSeconds = 240,
		DawnSeconds = 12,
		MeetingSeconds = 50,
	}),
	Move = table.freeze({
		Walk = 16,
		Sprint = 24,
	}),
	Threat = table.freeze({
		PatrolSpeed = 9, -- studs per second (players walk at 16)
		ChaseSpeed = 13,
		HearRange = 35,
		KillRadius = 4,
		FloorHearFactor = 0.5, -- footsteps carry through a floor, but only half as far
		FloorPenalty = 12, -- studs of 'distance' added per floor between him and a player when choosing who to hunt
		KillHeight = 6, -- he can only catch someone within this height of him
		StartRoom = "Pool Room",
	}),
	-- Used only inside Studio so one person can see the whole loop quickly.
	StudioRound = table.freeze({
		MinPlayers = 1,
		MaxPlayers = 10,
		IntermissionSeconds = 5,
		NightSeconds = 300,
		DawnSeconds = 8,
		MeetingSeconds = 30,
	}),
})
