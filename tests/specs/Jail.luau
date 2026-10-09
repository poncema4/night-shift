--!strict
-- The Night Manager starts every night locked in a holding cell as far from the crew as the hotel allows. A countdown is
-- published, he hears and grabs no one while caged (even someone standing right at the bars), and when the timer ends he
-- is released and goes to search the lobby where the crew started.
local Fake = require("../fake/Roblox")
local Config = require("../../src/shared/Config")
local Hotel = require("../../src/shared/Game/Hotel")

return function(t)
	math.randomseed(31)
	local world = Fake.world()
	local V3 = world.Vector3
	local storage = world.service("ReplicatedStorage")
	world.load("src/server/RoundService").start()
	local threat = world.load("src/server/ThreatService")
	local players = {}
	for i, name in { "Ana", "Ben", "Cy", "Di" } do
		table.insert(players, world.addPlayer(name, 90 + i))
	end
	local guard = 0
	while storage:GetAttribute("Phase") ~= "Night" and guard < 400 do
		world.advance(0.5)
		guard += 1
	end
	local state = storage:FindFirstChild("ThreatState")
	local patrol = threat.current()
	local sx, sz = Hotel.spawnPoint()

	t.equal(
		"the cell countdown starts at the configured time",
		state:GetAttribute("Hold") :: number >= Config.Threat.ReleaseSeconds - 2,
		true
	)
	local startX, startZ = patrol.x, patrol.z
	local away = math.sqrt((startX - sx) ^ 2 + (startZ - sz) ^ 2)
	t.check("the cell is far from where the crew starts", away > 80, `{away}`)
	t.check("the cell is below ground", patrol.y < -10)

	-- someone stands right next to him: nothing happens while he is caged
	local victim = players[1]
	world.root(victim).Position = V3.new(startX + 1.5, patrol.y + 3, startZ)
	world.advance(10)
	t.equal("a player at the bars is not caught", world.humanoid(victim).Health, 100)
	t.check("he has not moved", patrol.x == startX and patrol.z == startZ)
	t.check("the countdown is running", (state:GetAttribute("Hold") :: number) < Config.Threat.ReleaseSeconds - 8)

	-- everyone else is far away; release by waiting the rest of the countdown
	for _, p in players do
		world.root(p).Position = V3.new(sx, 3, sz)
	end
	world.advance(Config.Threat.ReleaseSeconds)
	t.equal("the countdown reaches zero", state:GetAttribute("Hold"), 0)
	local before = math.sqrt((patrol.x - sx) ^ 2 + (patrol.z - sz) ^ 2)
	world.advance(3)
	t.check("once released he moves", patrol.x ~= startX or patrol.z ~= startZ)
	t.check("and heads toward the lobby to search", math.sqrt((patrol.x - sx) ^ 2 + (patrol.z - sz) ^ 2) < before)
end
