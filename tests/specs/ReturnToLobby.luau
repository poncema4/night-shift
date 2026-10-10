--!strict
-- A match server is one night long: when the night ends (here, everyone is caught) the players are sent back to a PUBLIC
-- lobby (a teleport with no reserved-server code), and anyone can leave early with the results-screen button.
local Fake = require("../fake/Roblox")

return function(t)
	math.randomseed(12)
	local world = Fake.world()
	world.studio = false
	world.game.PrivateServerId = "match-1" -- a reserved server: this one is a match
	local storage = world.service("ReplicatedStorage")
	world.load("src/server/main.server")
	t.equal("a reserved server runs as a match", storage:GetAttribute("ServerMode"), "Match")
	local players = {}
	for i, name in { "Ana", "Ben", "Cy" } do
		table.insert(players, world.addPlayer(name, 20 + i))
	end
	local guard = 0
	while storage:GetAttribute("Phase") ~= "Night" and guard < 400 do
		world.advance(0.5)
		guard += 1
	end
	t.equal("the night starts", storage:GetAttribute("Phase"), "Night")
	t.equal("nobody is sent away mid-night", #world.teleports, 0)

	-- everyone is caught: the crew is wiped out
	for _, p in players do
		world.humanoid(p).Health = 0
	end
	-- the results screen and a 15 second countdown: nobody is respawned and nothing teleports yet
	guard = 0
	while storage:GetAttribute("Phase") ~= "Dawn" and guard < 100 do
		world.advance(0.5)
		guard += 1
	end
	t.equal("the night ends in the results phase", storage:GetAttribute("Phase"), "Dawn")
	t.equal(
		"the server tells the clients they are going back to the lobby",
		storage:GetAttribute("ReturnsToLobby"),
		true
	)
	world.advance(10)
	t.equal("ten seconds in, they are still on the results screen", storage:GetAttribute("Phase"), "Dawn")
	t.equal("and nobody has been sent yet", #world.teleports, 0)
	local stillDead = true
	for _, p in players do
		if world.humanoid(p).Health > 0 then
			stillDead = false
		end
	end
	t.check("and nobody was respawned underneath the results screen", stillDead)
	guard = 0
	while #world.teleports == 0 and guard < 200 do
		world.advance(0.5)
		guard += 1
	end
	world.advance(1)
	t.check("after the countdown the whole party goes together", guard < 200)
	world.advance(25)
	t.equal(
		"no new night starts on that server",
		storage:GetAttribute("Phase") == "Night" or storage:GetAttribute("Phase") == "Intermission",
		false
	)
	local stillDeadAfter = true
	for _, p in players do
		local char = p.Character
		local h = char and char:FindFirstChildOfClass("Humanoid")
		if h and h.Health > 0 then
			stillDeadAfter = false
		end
	end
	t.check("and nobody is respawned after the teleport either", stillDeadAfter)
	t.check("the night ended and the players were sent away", guard < 200)
	t.equal("everyone is sent back once", #world.teleports, 1)
	t.equal("all three of them", world.teleports[1] and #world.teleports[1].players or 0, 3)
	t.equal("to a public lobby, not another reserved server", world.teleports[1] and world.teleports[1].options, nil)

	-- leaving early
	local before = #world.teleports
	world.setLocal(players[1])
	storage:FindFirstChild("Remotes"):FindFirstChild("LeaveMatch"):FireServer()
	world.advance(0.5)
	t.equal("the button sends that one player", #world.teleports, before + 1)
	t.equal(
		"alone",
		world.teleports[#world.teleports].players[1] == players[1] and #world.teleports[#world.teleports].players,
		1
	)
end
