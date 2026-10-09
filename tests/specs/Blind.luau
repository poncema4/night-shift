--!strict
-- The flashlight as a weapon, through the real server: shine it on the Night Manager for a second and he is blinded for three
-- (he stops, he cannot grab anyone), then he needs time before he can be blinded again. A beam pointing away, a wall in the
-- way, or someone hidden does nothing.
local Fake = require("../fake/Roblox")

return function(t)
	math.randomseed(5)
	local world = Fake.world()
	local V3 = world.Vector3
	local CF = world.CFrame
	local storage = world.service("ReplicatedStorage")
	world.load("src/server/RoundService").start()
	local threat = world.load("src/server/ThreatService")
	local players = {}
	for i, name in { "Ana", "Ben", "Cy", "Di" } do
		table.insert(players, world.addPlayer(name, 50 + i))
	end
	local guard = 0
	while storage:GetAttribute("Phase") ~= "Night" and guard < 400 do
		world.advance(0.5)
		guard += 1
	end
	local me = players[1]
	local patrol = threat.current()
	threat.release(false) -- skip the cell and the lobby search: these specs place him by hand
	world.advance(0.2)
	local state = storage:FindFirstChild("ThreatState")
	local intent = storage:FindFirstChild("Remotes"):FindFirstChild("Intent")

	-- put him in a straight stretch of corridor and the player 20 studs west, looking at him
	local function setUp(facingHim: boolean)
		patrol.x, patrol.z, patrol.y = 20, 0, 0
		patrol.from, patrol.to = "C10", "C10"
		local root = world.root(me)
		local lookAt = if facingHim then V3.new(20, 3, 0) else V3.new(-60, 3, 0)
		root.CFrame = CF.lookAt(V3.new(0, 3, 0), lookAt)
	end
	for _, p in players do
		if p ~= me then
			world.root(p).Position = V3.new(500, 3, 500) -- everyone else far away, so only the beam matters
		end
	end

	-- 1. beam pointing away: nothing
	threat.pause()
	setUp(false)
	intent.OnServerEvent:Fire(me, { light = true })
	threat.resume()
	world.advance(1.0)
	t.equal("a beam pointing away does not blind him", state:GetAttribute("Stunned"), false)

	-- 2. a wall in the way: nothing
	setUp(true)
	world.rayBlocked = true
	world.advance(1.0)
	t.equal("a wall between them stops the beam", state:GetAttribute("Stunned"), false)
	world.rayBlocked = false

	-- 3. clear and facing: he is blinded within about a second
	patrol.x, patrol.z = 20, 0
	setUp(true)
	world.advance(1.4)
	t.equal("a beam held on him blinds him", state:GetAttribute("Stunned"), true)
	local frozenX = patrol.x
	world.advance(2)
	t.equal("while blinded he does not move", patrol.x, frozenX)
	local fate = world.humanoid(me).Health
	t.equal("and nothing is caught while he is blinded", fate, 100)
	world.advance(1.5)
	t.equal("after three seconds he can see again", state:GetAttribute("Stunned"), false)

	-- 4. cooldown: the beam is still on him, but he is not blinded again straight away
	setUp(true)
	world.advance(1.2)
	t.equal("he cannot be blinded again during the cooldown", state:GetAttribute("Stunned"), false)
end
