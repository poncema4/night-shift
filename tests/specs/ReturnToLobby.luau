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
	guard = 0
	while #world.teleports == 0 and guard < 200 do
		world.advance(0.5)
		guard += 1
	end
	world.advance(1)
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
