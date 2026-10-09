--!strict
-- He gets faster as the crew finishes tasks: the same patrol, measured over the same time, covers more ground when the
-- crew is half done than when it has done nothing, and the progress is published for the client.
local Fake = require("../fake/Roblox")
local Escalation = require("../../src/shared/Game/Escalation")

return function(t)
	math.randomseed(9)
	local world = Fake.world()
	local V3 = world.Vector3
	local storage = world.service("ReplicatedStorage")
	world.load("src/server/RoundService").start()
	local threat = world.load("src/server/ThreatService")
	local tasks = world.load("src/server/TaskService")
	local players = {}
	for i, name in { "Ana", "Ben", "Cy", "Di" } do
		table.insert(players, world.addPlayer(name, 70 + i))
	end
	local guard = 0
	while storage:GetAttribute("Phase") ~= "Night" and guard < 400 do
		world.advance(0.5)
		guard += 1
	end
	for _, p in players do
		world.root(p).Position = V3.new(900, 3, 900) -- nobody within earshot: he just patrols
	end
	local patrol = threat.current()
	local state = storage:FindFirstChild("ThreatState")

	-- how far he walks in 3 seconds (the path length, so a corner does not hide it), with the crew `done` tasks in
	local function travelled(done: number): number
		tasks.counts = function()
			return done, 12
		end
		patrol.x, patrol.z, patrol.y = 20, 0, 0
		patrol.from, patrol.to = "C10", "C10"
		local total, lastX, lastZ = 0, patrol.x, patrol.z
		for _ = 1, 30 do
			world.advance(0.1)
			total += math.sqrt((patrol.x - lastX) ^ 2 + (patrol.z - lastZ) ^ 2)
			lastX, lastZ = patrol.x, patrol.z
		end
		return total
	end
	local calm = travelled(0)
	local angry = travelled(11)
	t.check("he moves at all", calm > 5, `{calm}`)
	t.check("he covers more ground when the crew has finished everything", angry > calm * 1.2, `{calm} vs {angry}`)
	t.check("but never more than the maximum speed-up", angry < calm * (Escalation.MAX + 0.15), `{calm} vs {angry}`)
	t.check("progress is published for the client", math.abs((state:GetAttribute("Rage") :: number) - 11 / 12) < 1e-6)
	travelled(6)
	t.equal("half done is half rage", state:GetAttribute("Rage"), 0.5)
end
