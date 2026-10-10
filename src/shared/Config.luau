--!strict
-- Game-wide constants. Plain data: safe to require from the server, the client and the tests.

return table.freeze({
	GameName = "THE NIGHT MANAGER",
	-- The Roblox experience title, in the pattern the top games use: NAME + one emoji (DOORS, 99 Nights in the Forest). The genre lives in the Genre field.
	StoreTitle = "THE NIGHT MANAGER 🔔",
	StudioName = "Nexus Hollow Studios",
	Version = "0.4.0",

	-- A match server holds one party: the round starts as soon as someone is in, others arrive during the intermission.
	Round = table.freeze({
		MinPlayers = 1,
		MaxPlayers = 8,
		IntermissionSeconds = 15,
		NightSeconds = 240,
		DawnSeconds = 12,
		MeetingSeconds = 50,
	}),
	-- The lobby: parties of any size up to MaxParty queue for QueueSeconds; a full party only waits FullSeconds.
	Lobby = table.freeze({
		MaxParty = 8,
		DefaultParty = 4,
		QueueSeconds = 30,
		FullSeconds = 5,
		ActionCooldown = 0.25, -- seconds between party actions from one player
		PodZ = 16, -- the row of queue pads along the back of the lobby
		PodSpacing = 18, -- cells are 10 wide: an 8 stud walkway between them
	}),
	-- Studio is not a real server: pick which job it plays ("Match" = the round, "Lobby" = the party screen).
	Server = table.freeze({ StudioMode = "Match" }),
	Brand = table.freeze({ GroupId = 749648777 }),
	-- What can be bought with Robux. COSMETICS ONLY: nothing here changes speed, noise, vision or who wins. An id of 0 means
	-- "not created yet": the shop shows COMING SOON until you paste the real id from Creator Hub (docs/MONETIZATION.md).
	Monetization = table.freeze({
		Passes = table.freeze({
			starlight = table.freeze({
				id = 0,
				name = "Starlight Collection",
				blurb = "Two exclusive flashlight colours and a halo. Looks only.",
				robux = 299,
			}),
		}),
		Products = table.freeze({
			tips_small = table.freeze({ id = 0, name = "Pocket of Tips", tips = 250, robux = 49 }),
			tips_medium = table.freeze({ id = 0, name = "Bag of Tips", tips = 700, robux = 125 }),
			tips_large = table.freeze({ id = 0, name = "Chest of Tips", tips = 1600, robux = 249 }),
		}),
	}),
	-- How the hotel looks. Tune these first if it is too dark or too bright (Studio playtest).
	Look = table.freeze({
		Ambient = { 4, 4, 8 },
		OutdoorAmbient = { 4, 4, 7 },
		FogStart = 8,
		FogEnd = 88,
		AtmosphereDensity = 0.38,
		Contrast = 0.12,
		Saturation = -0.15,
		BulbRange = 16,
		BulbBrightness = 0.38,
		BasementBulbBrightness = 0.18,
		GradeBrightness = -0.09,
	}),
	-- One shown during every intermission.
	Tips = table.freeze({
		"Standing still makes you much quieter than running.",
		"Hold your flashlight on him for a second and he is blinded for three.",
		"The flashlight lights the way, and shows him where you are.",
		"Lockers and wardrobes hide you, but he searches the one you dive into.",
		"Finish the camera task: the crew can then watch where he is.",
		"Someone who 'finishes' a task far too fast may be faking it.",
		"The lobby bell calls a meeting. Each player can ring it once a night.",
		"Stairs are at both ends of the long corridor. He uses them too.",
		"Saboteurs: lure him onto the crew, then be somewhere else.",
	}),
	-- The flashlight beam: strong enough that the dark hotel needs it.
	Beam = table.freeze({
		Brightness = 6,
		Range = 70,
		Angle = 48,
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
		-- He starts the night locked in the far-east basement, as far from the crew as the hotel allows, and is released
		-- after ReleaseSeconds; then he goes to search the lobby where the crew started.
		StartRoom = "Mop Closet",
		ReleaseSeconds = 30,
		SearchSeconds = 25, -- how long the first search of the lobby lasts after he is released
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
