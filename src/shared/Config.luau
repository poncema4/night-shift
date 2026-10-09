--!strict
-- Game-wide constants. Plain data: safe to require from the server, the client and the tests.

return table.freeze({
	GameName = "NIGHT SHIFT",
	StudioName = "Nexus Hollow Studios",
	Version = "0.3.0",

	Round = table.freeze({
		MinPlayers = 6,
		MaxPlayers = 10,
		IntermissionSeconds = 20,
		NightSeconds = 240,
		DawnSeconds = 12,
	}),
	Threat = table.freeze({
		PatrolSpeed = 9, -- studs per second (players walk at 16)
		ChaseSpeed = 13,
		HearRange = 35,
		KillRadius = 4,
		StartRoom = "Pool Room",
	}),
	-- Used only inside Studio so one person can see the whole loop quickly.
	StudioRound = table.freeze({
		MinPlayers = 1,
		MaxPlayers = 10,
		IntermissionSeconds = 5,
		NightSeconds = 150,
		DawnSeconds = 8,
	}),
})
