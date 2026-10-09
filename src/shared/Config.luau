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
	-- How the hotel looks. Tune these first if it is too dark or too bright (Studio playtest).
	Look = table.freeze({
		Ambient = { 26, 26, 38 },
		OutdoorAmbient = { 20, 20, 30 },
		FogStart = 20,
		FogEnd = 160,
		AtmosphereDensity = 0.3,
		Contrast = 0.12,
		Saturation = -0.15,
		BulbRange = 30,
		BulbBrightness = 1.1,
		BasementBulbBrightness = 0.8,
	}),
	-- Placeholder sounds that ship with the Roblox client (rbxasset://sounds/...). Replace with uploaded assets
	-- (rbxassetid://...) when we have our own; a missing file is simply silent.
	Sounds = table.freeze({
		flashlight = "rbxasset://sounds/switch.mp3",
		taskDone = "rbxasset://sounds/electronicpingshort.wav",
		meeting = "rbxasset://sounds/electronicpingshort.wav",
		thud = "rbxasset://sounds/collide.wav",
		heartbeat = "rbxasset://sounds/bass.wav",
		dawn = "rbxasset://sounds/victory.wav",
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
		HideGrace = 3, -- hiding within this many seconds of being heard sends him to search that spot
		InvestigateSeconds = 8, -- ...and he waits there this long
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
