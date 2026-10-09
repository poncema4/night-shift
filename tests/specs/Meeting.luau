--!strict
local Abilities = require("../../src/shared/Game/Abilities")
local Meeting = require("../../src/shared/Game/Meeting")
local Round = require("../../src/shared/Game/Round")

return function(t)
	local alive = { 1, 2, 3, 4, 5 }

	-- tally
	local r = Meeting.tally({ [1] = 3, [2] = 3, [3] = 4, [4] = 3, [5] = false }, alive)
	t.equal("the player with the most votes is ejected", r.ejected, 3)
	t.equal("votes and skips are counted", r.counts[3] == 3 and r.skips == 1 and r.voted == 5, true)

	t.equal(
		"a tie ejects no one",
		Meeting.tally({ [1] = 2, [2] = 2, [3] = 4, [4] = 4, [5] = false }, alive).ejected,
		nil
	)
	t.equal(
		"skip wins a tie with the top player",
		Meeting.tally({ [1] = 2, [2] = 2, [3] = false, [4] = false, [5] = 1 }, alive).ejected,
		nil
	)
	t.equal(
		"a clear plurality beats skip",
		Meeting.tally({ [1] = 2, [2] = 2, [3] = 2, [4] = false, [5] = false }, alive).ejected,
		2
	)
	t.equal("no votes ejects no one", Meeting.tally({}, alive).ejected, nil)

	local dead = Meeting.tally({ [1] = 9, [9] = 2, [2] = 9 }, alive)
	t.check("dead players cannot vote or be voted for", dead.ejected == nil and dead.voted == 0)
	t.equal("a vote for yourself still counts", Meeting.tally({ [1] = 1, [2] = 1, [3] = 1 }, alive).ejected, 1)

	t.check(
		"the meeting ends early once everyone alive voted",
		Meeting.complete({ [1] = 2, [2] = false, [3] = 1, [4] = 1, [5] = 2 }, alive)
	)
	t.check("it does not end while someone has not voted", not Meeting.complete({ [1] = 2, [2] = false }, alive))

	-- abilities
	local tracker = Abilities.new()
	t.check("an ability can be used when ready", Abilities.use(tracker, 7, "lure", 100))
	t.check("it is on cooldown straight after", not Abilities.use(tracker, 7, "lure", 130))
	t.equal("the wait counts down", Abilities.wait(tracker, 7, "lure", 130), 30)
	t.check("it is ready again after the cooldown", Abilities.use(tracker, 7, "lure", 161))
	t.check("another player has their own cooldown", Abilities.use(tracker, 8, "lure", 130))
	t.check("a different ability is separate", Abilities.use(tracker, 7, "lights", 130))
	t.check("an unknown ability is refused", not Abilities.use(tracker, 7, "teleport", 500))

	-- the meeting phase
	local round = Round.new({
		MinPlayers = 1,
		MaxPlayers = 10,
		IntermissionSeconds = 1,
		NightSeconds = 100,
		DawnSeconds = 5,
		MeetingSeconds = 20,
	})
	t.equal("a meeting cannot start outside the night", round:callMeeting(), nil)
	round:tick(0, 4)
	round:tick(1.1, 4)
	round:tick(1.1, 4) -- Intermission -> Night
	t.equal("the round is in the night", round.phase, "Night")
	round:tick(30, 4, { crewAlive = 3, saboteursAlive = 1, tasksDone = 0, tasksTotal = 6 })
	local before = round.timeLeft
	local event = round:callMeeting()
	t.check("a meeting can interrupt the night", event ~= nil and event.to == "Meeting" and round.phase == "Meeting")
	t.equal("the meeting lasts its full time", round.timeLeft, 20)
	round:tick(19, 4)
	t.equal("the meeting is still on before its time is up", round.phase, "Meeting")
	local back = round:tick(2, 4)
	t.check("the meeting ends and the night resumes", back ~= nil and back.to == "Night" and round.phase == "Night")
	t.equal("the night clock was paused during the meeting", round.timeLeft, before)
	t.equal("a meeting cannot start in a meeting", (round:callMeeting() and round:callMeeting()), nil)
	-- ending a meeting early leaves time to show the result
	local early = Round.new({
		MinPlayers = 1,
		MaxPlayers = 10,
		IntermissionSeconds = 1,
		NightSeconds = 100,
		DawnSeconds = 5,
		MeetingSeconds = 50,
	})
	early:tick(0, 4)
	early:tick(1.1, 4)
	early:tick(1.1, 4)
	early:callMeeting()
	early:shortenMeeting(8)
	t.equal("shortening a meeting leaves only the result time", early.timeLeft, 8)
	early:shortenMeeting(30)
	t.equal("shortening never makes a meeting longer", early.timeLeft, 8)
end
