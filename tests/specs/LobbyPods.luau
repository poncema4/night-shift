--!strict
-- Walking onto a queue pad joins that pad's party, the sign says how many more are needed, stepping off leaves, and a full
-- pad launches after 5 seconds. Runs the real lobby builder and lobby service.
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

return function(t)
	local world = Fake.world()
	world.studio = false
	local V3 = world.Vector3
	world.load("src/server/main.server")
	local pods = Pods.layout(0, Config.Lobby.PodZ, Config.Lobby.PodSpacing)
	local squad = pods[4]
	local ana = world.addPlayer("Ana", 1)
	local ben = world.addPlayer("Ben", 2)
	local cy = world.addPlayer("Cy", 3)
	local di = world.addPlayer("Di", 4)
	for _, p in { ana, ben, cy, di } do
		world.spawnCharacter(p)
		world.root(p).Position = V3.new(0, 3, -4) -- the spawn: not on a pad
	end
	world.advance(1)
	t.check(
		"an empty pad invites you to queue",
		string.find(signText(world, 4), "0/4  need 4 more", 1, true) ~= nil,
		signText(world, 4)
	)

	world.root(ana).Position = V3.new(squad.x, 3, squad.z)
	world.advance(1)
	t.check(
		"stepping on a pad starts its party",
		string.find(signText(world, 4), "1/4  need 3 more", 1, true) ~= nil,
		signText(world, 4)
	)
	world.root(ben).Position = V3.new(squad.x + 2, 3, squad.z)
	world.advance(1)
	t.check(
		"a second player joins the same party",
		string.find(signText(world, 4), "2/4  need 2 more", 1, true) ~= nil,
		signText(world, 4)
	)
	world.root(ben).Position = V3.new(0, 3, -4)
	world.advance(1)
	t.check(
		"stepping off leaves it",
		string.find(signText(world, 4), "1/4  need 3 more", 1, true) ~= nil,
		signText(world, 4)
	)
	t.equal("nothing launched yet", #world.teleports, 0)

	for _, p in { ben, cy, di } do
		world.root(p).Position = V3.new(squad.x + 1, 3, squad.z + 1)
	end
	world.advance(1)
	t.check("a full pad says so", string.find(signText(world, 4), "4/4  full", 1, true) ~= nil, signText(world, 4))
	world.advance(Config.Lobby.FullSeconds + 1)
	t.equal("a full pad launches after 5 seconds", #world.teleports, 1)
	t.equal("with all four", world.teleports[1] and #world.teleports[1].players or 0, 4)

	-- a different pad is a different party
	world.root(ana).Position = V3.new(pods[1].x, 3, pods[1].z)
	world.advance(1)
	t.check(
		"the solo pad starts its own party",
		string.find(signText(world, 1), "1/1  full", 1, true) ~= nil,
		signText(world, 1)
	)
end
