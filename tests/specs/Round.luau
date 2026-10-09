--!strict
local Round = require("../../src/shared/Game/Round")

local settings = { MinPlayers = 3, MaxPlayers = 10, IntermissionSeconds = 10, NightSeconds = 60, DawnSeconds = 5 }
local alive = { crewAlive = 5, saboteursAlive = 1, tasksDone = 0, tasksTotal = 4 }

return function(t)
	t.equal("starts in the lobby", Round.new(settings).phase, "Lobby")

	local r = Round.new(settings)
	t.equal("lobby waits below the minimum", r:tick(1, 2), nil)
	t.equal("lobby still Lobby", r.phase, "Lobby")
	local e = r:tick(1, 3)
	t.check("lobby starts intermission at the minimum", e ~= nil and e.to == "Intermission")
	t.equal("intermission timer is set", r.timeLeft, 10)

	t.equal("intermission counts down", (r:tick(4, 3)), nil)
	t.equal("timer after 4s", r.timeLeft, 6)
	e = r:tick(1, 2)
	t.check("intermission aborts if players leave", e ~= nil and e.to == "Lobby" and r.phase == "Lobby")

	r = Round.new(settings)
	r:tick(1, 3)
	r:tick(1, 3)
	e = r:tick(10, 3)
	t.check("intermission becomes Night when it runs out", e ~= nil and e.to == "Night")
	t.equal("round number counts up", r.roundNumber, 1)
	t.equal("night timer is set", r.timeLeft, 60)

	t.equal("night with nobody winning continues", (r:tick(10, 3, alive)), nil)
	e = r:tick(1, 3, { crewAlive = 5, saboteursAlive = 0, tasksDone = 0, tasksTotal = 4 })
	t.check("crew win when no saboteur is left", e ~= nil and e.to == "Dawn" and e.winner == "Crew")
	t.equal("dawn timer is set", r.timeLeft, 5)
	e = r:tick(5, 3)
	t.check("dawn returns to the lobby", e ~= nil and e.to == "Lobby" and r.phase == "Lobby")

	-- Night ends by time with no stats: saboteurs held out.
	r = Round.new(settings)
	r:tick(1, 3)
	r:tick(10, 3)
	e = r:tick(60, 3, alive)
	t.check("time runs out: saboteurs win", e ~= nil and e.to == "Dawn" and e.winner == "Saboteurs")

	-- Night abandoned.
	r = Round.new(settings)
	r:tick(1, 3)
	r:tick(10, 3)
	e = r:tick(1, 0)
	t.check("everyone leaves during the night: back to the lobby", e ~= nil and e.to == "Lobby")

	t.equal(
		"evaluate: crew win when saboteurs are gone",
		Round.evaluate({ crewAlive = 3, saboteursAlive = 0, tasksDone = 0, tasksTotal = 0 }),
		"Crew"
	)
	t.equal(
		"evaluate: saboteurs win when they match crew",
		Round.evaluate({ crewAlive = 2, saboteursAlive = 2, tasksDone = 0, tasksTotal = 3 }),
		"Saboteurs"
	)
	t.equal(
		"evaluate: all tasks done is a crew win",
		Round.evaluate({ crewAlive = 4, saboteursAlive = 1, tasksDone = 3, tasksTotal = 3 }),
		"Crew"
	)
	t.equal(
		"evaluate: zero tasks total is NOT an instant win",
		Round.evaluate({ crewAlive = 4, saboteursAlive = 1, tasksDone = 0, tasksTotal = 0 }),
		nil
	)
	-- Solo in Studio the lone player faces a phantom saboteur: that must not end the round at once.
	t.equal(
		"evaluate: sandbox solo round keeps going",
		Round.evaluate({ crewAlive = 1, saboteursAlive = 1, tasksDone = 0, tasksTotal = 6, sandbox = true }),
		nil
	)
	t.equal(
		"evaluate: sandbox solo round ends when the player dies",
		Round.evaluate({ crewAlive = 0, saboteursAlive = 1, tasksDone = 0, tasksTotal = 6, sandbox = true }),
		"Saboteurs"
	)
	t.equal(
		"evaluate: sandbox solo round is won by finishing the tasks",
		Round.evaluate({ crewAlive = 1, saboteursAlive = 1, tasksDone = 6, tasksTotal = 6, sandbox = true }),
		"Crew"
	)
	t.equal(
		"evaluate: real 1v1 still ends at parity",
		Round.evaluate({ crewAlive = 1, saboteursAlive = 1, tasksDone = 0, tasksTotal = 6 }),
		"Saboteurs"
	)
end
