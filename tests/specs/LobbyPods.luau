--!strict
-- Queue pods through the real lobby builder and server: the first player into an empty cell is asked for the party size and
-- the cell follows it; others step in until it is full; a queued player cannot walk out (they are put back) until they press
-- LEAVE; a full cell shuts its gate and launches after 5 seconds.
local Fake = require("../fake/Roblox")
local Config = require("../../src/shared/Config")
local Pods = require("../../src/shared/Game/Pods")

local function signText(world: any, podId: number): string
	local lobby = world.workspace:FindFirstChild("Lobby")
	local pod = lobby and lobby:FindFirstChild(`Pod_{podId}`)
	local text = ""
	for _, d in if pod then pod:GetDescendants() else {} do
		if d:IsA("TextLabel") then
			text ..= d.Text .. " | "
		end
	end
	return text
end

local function prompts(world: any, to: any): { number }
	local list = {}
	for _, entry in world.log do
		if entry.remote == "PodPrompt" and entry.to == "client" and entry.args[1] == to then
			table.insert(list, entry.args[2])
		end
	end
	return list
end

return function(t)
	local world = Fake.world()
	world.studio = false
	local V3 = world.Vector3
	world.load("src/server/main.server")
	local remotes = world.service("ReplicatedStorage"):FindFirstChild("Remotes")
	local action = remotes:FindFirstChild("PartyAction")
	local pods = Pods.layout(0, Config.Lobby.PodZ, Config.Lobby.PodSpacing)
	local cell = pods[4]
	local ana = world.addPlayer("Ana", 1)
	local ben = world.addPlayer("Ben", 2)
	local cy = world.addPlayer("Cy", 3)
	local di = world.addPlayer("Di", 4)
	local start = V3.new(0, 3, -4)
	for _, p in { ana, ben, cy, di } do
		world.spawnCharacter(p)
		world.root(p).Position = start
	end
	local function says(player: any, ...)
		world.setLocal(player)
		world.advance(0.3)
		action:FireServer(...)
	end
	local function inside(p: any, dx: number?, dz: number?)
		world.root(p).Position = V3.new(cell.x + (dx or 0), 3, cell.z + (dz or 0))
	end
	local function isInside(p: any): boolean
		local pos = world.root(p).Position
		return Pods.inside(cell, pos.X, pos.Z, 1)
	end
	world.advance(1)
	t.check(
		"an empty cell invites you in",
		string.find(signText(world, 4), "STEP IN TO START A PARTY", 1, true) ~= nil,
		signText(world, 4)
	)

	-- the first player is asked how many the party is for
	inside(ana)
	world.advance(1)
	t.equal("stepping into an empty cell asks the player for a size", prompts(world, ana)[1], 4)
	t.check("the sign says someone is choosing", string.find(signText(world, 4), "CHOOSING PARTY SIZE", 1, true) ~= nil)
	says(cy, "podsize", 4, 2) -- someone who was not asked cannot answer for the cell
	world.advance(1)
	t.check(
		"a size from someone who was not asked is ignored",
		string.find(signText(world, 4), "CHOOSING", 1, true) ~= nil
	)
	says(ana, "podsize", 4, 99) -- out of range is clamped by the party rules (max 8), never trusted
	world.advance(1)
	t.check(
		"the answer starts the party",
		string.find(signText(world, 4), "1/8  need 7 more", 1, true) ~= nil,
		signText(world, 4)
	)
	says(ana, "leave")
	world.advance(1)
	t.check("leaving takes her out of the cell", not isInside(ana))
	t.check(
		"and empties it",
		string.find(signText(world, 4), "STEP IN TO START A PARTY", 1, true) ~= nil,
		signText(world, 4)
	)

	-- a party of four
	inside(ana)
	world.advance(1)
	says(ana, "podsize", 4, 4)
	world.advance(1)
	t.check(
		"the cell follows her choice: 4 players",
		string.find(signText(world, 4), "1/4  need 3 more", 1, true) ~= nil,
		signText(world, 4)
	)
	inside(ben, 2, 1)
	world.advance(1)
	t.equal("a second player is not asked anything", #prompts(world, ben), 0)
	t.check("they simply join", string.find(signText(world, 4), "2/4  need 2 more", 1, true) ~= nil, signText(world, 4))

	-- queued players cannot walk out
	world.root(ben).Position = V3.new(cell.x + 12, 3, cell.z - 14)
	world.advance(1)
	t.check("walking out of the cell puts them back inside", isInside(ben))
	t.check(
		"and the party is unchanged",
		string.find(signText(world, 4), "2/4  need 2 more", 1, true) ~= nil,
		signText(world, 4)
	)
	says(ben, "leave")
	world.advance(1)
	t.check("LEAVE lets them out", not isInside(ben))
	t.check(
		"and updates the count",
		string.find(signText(world, 4), "1/4  need 3 more", 1, true) ~= nil,
		signText(world, 4)
	)

	-- filling it: the gate shuts and it launches after 5 seconds
	for _, p in { ben, cy, di } do
		inside(p, 1, 0)
	end
	world.advance(1)
	t.check("a full cell says so", string.find(signText(world, 4), "4/4  full", 1, true) ~= nil, signText(world, 4))
	local gate = world.workspace:FindFirstChild("Lobby"):FindFirstChild("Pod_4"):FindFirstChild("Gate")
	t.check("and shuts its gate", gate.CanCollide == true)
	world.advance(Config.Lobby.FullSeconds + 1)
	t.equal("a full cell launches after 5 seconds", #world.teleports, 1)
	t.equal("with all four", world.teleports[1] and #world.teleports[1].players or 0, 4)

	-- a different cell is a different party, and a lone player chooses 1
	local solo = pods[1]
	world.root(ana).Position = V3.new(solo.x, 3, solo.z)
	world.advance(1)
	t.equal("the next cell asks too", prompts(world, ana)[#prompts(world, ana)], 1)
	says(ana, "podsize", 1, 1)
	world.advance(1)
	t.check(
		"a party of one is full at once",
		string.find(signText(world, 1), "1/1  full", 1, true) ~= nil,
		signText(world, 1)
	)
end
