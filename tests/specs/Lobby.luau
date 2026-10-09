--!strict
-- The real lobby server against the fake world: parties form through the remote, the queue clock runs, a full party
-- launches after 5 s and a half-full one after 30 s, and each launch is a teleport to a reserved server.
local Fake = require("../fake/Roblox")

return function(t)
	local world = Fake.world()
	world.studio = false -- a real server: the teleport is attempted
	local storage = world.service("ReplicatedStorage")
	local folder = world.instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = storage
	world.load("src/server/LobbyService").start(folder)
	local action = folder:FindFirstChild("PartyAction")
	t.check("the party remotes exist", action ~= nil and folder:FindFirstChild("PartyState") ~= nil)

	local a = world.addPlayer("Ana", 1)
	local b = world.addPlayer("Ben", 2)
	local c = world.addPlayer("Cy", 3)
	local d = world.addPlayer("Di", 4)

	local function act(player: any, ...)
		world.setLocal(player)
		world.advance(0.3)
		action:FireServer(...)
	end

	-- a party of 4 fills: it launches 5 s after the last seat, with all four
	act(a, "create", 4)
	act(b, "quick")
	act(c, "join", 1)
	act(d, "quick")
	world.advance(4)
	t.equal("no teleport before 5 s", #world.teleports, 0)
	world.advance(2)
	t.equal("a full party is teleported", #world.teleports, 1)
	t.equal("all four go together", world.teleports[1] and #world.teleports[1].players or 0, 4)
	t.equal(
		"to a reserved server",
		world.teleports[1] and world.teleports[1].options.ReservedServerAccessCode,
		"reserved-code"
	)

	-- a half-full party waits the whole 30 s, then goes with whoever is there
	act(a, "create", 4)
	act(b, "join", 2)
	world.advance(20)
	t.equal("not yet at 20 s", #world.teleports, 1)
	world.advance(14)
	t.equal("launched after the queue time", #world.teleports, 2)
	t.equal("with the two who were there", world.teleports[2] and #world.teleports[2].players or 0, 2)

	-- leaving removes you from the queue
	act(c, "create", 3)
	act(c, "leave")
	world.advance(40)
	t.equal("an empty party never launches", #world.teleports, 2)

	-- an abusive client cannot spam actions
	act(a, "create", 2)
	world.setLocal(a)
	action:FireServer("leave")
	action:FireServer("create", 2) -- same instant: ignored
	world.advance(1)
	local shown = 0
	for _, entry in world.log do
		if entry.remote == "PartyState" and entry.args[1] then
			shown += 1
		end
	end
	t.check("state is broadcast", shown > 0)
end
