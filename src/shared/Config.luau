--!strict
-- Game-wide constants. Plain data: safe to require from the server, the client and the tests.

return table.freeze({
	GameName = "NIGHT SHIFT",
	StudioName = "Nexus Hollow Studios",
	Version = "0.2.0",

	Round = table.freeze({
		MinPlayers = 6,
		MaxPlayers = 10,
		IntermissionSeconds = 20,
		NightSeconds = 240,
		DawnSeconds = 12,
	}),
	-- Used only inside Studio so one person can see the whole loop quickly.
	StudioRound = table.freeze({
		MinPlayers = 1,
		MaxPlayers = 10,
		IntermissionSeconds = 5,
		NightSeconds = 20,
		DawnSeconds = 6,
	}),
})
