--!strict
-- Four players, one saboteur: the vote, the abilities, blackouts, scares, and what hiding really protects against.
-- Runs the real server code against the fake Roblox world.
local Fake = require("../fake/Roblox")

local function logged(world: any, remote: string, to: string?): { any }
	local list = {}
	for _, entry in world.log do
		if entry.remote == remote and (to == nil or entry.to == to) then
			table.insert(list, entry)
		end
	end
	return list
end

return function(t)
	math.randomseed(3)
	local world = Fake.world()
	local V3 = world.Vector3
	local storage = world.service("ReplicatedStorage")
	local server = world.load("src/server/RoundService")
	local threat = world.load("src/server/ThreatService")
	server.start()
	local players = {}
	for i, name in { "Ana", "Ben", "Cy", "Di" } do
		table.insert(players, world.addPlayer(name, 10 + i))
	end
	local guard = 0
	while storage:GetAttribute("Phase") ~= "Night" and guard < 400 do
		world.advance(0.5)
		guard += 1
	end
	t.equal("the night begins with four players", storage:GetAttribute("Phase"), "Night")
	threat.pause()
	local remotes = storage:FindFirstChild("Remotes")

	local roles = {}
	for _, entry in logged(world, "RoleAssigned", "client") do
		roles[entry.args[1].Name] = entry.args[2]
	end
	local saboteur
	local crew = {}
	for _, p in players do
		if roles[p.Name] == "Saboteur" then
			saboteur = p
		else
			table.insert(crew, p)
		end
	end
	t.check("one saboteur and three crew", saboteur ~= nil and #crew == 3)

	-- abilities: crew cannot, the saboteur can, and cooldowns hold
	local ability = remotes:FindFirstChild("Ability")
	ability.OnServerEvent:Fire(crew[1], "lights")
	t.equal("a crew member cannot use saboteur abilities", crew[1]:GetAttribute("LightsReadyAt") or 0, 0)
	world.root(saboteur).Position = V3.new(-45, 3, -14) -- ground floor
	local bulbs = world.service("CollectionService"):GetTagged("Bulb")
	local function groundLightsOff(): number
		local off = 0
		for _, lamp in bulbs do
			local light = lamp:FindFirstChildOfClass("PointLight")
			if light and lamp.Position.Y > 0 and lamp.Position.Y < 15 and not light.Enabled then
				off += 1
			end
		end
		return off
	end
	local offBefore = groundLightsOff()
	ability.OnServerEvent:Fire(saboteur, "lights")
	t.check("the saboteur's lights-out darkens the floor", groundLightsOff() > offBefore)
	t.check("and starts a cooldown", (saboteur:GetAttribute("LightsReadyAt") or 0) > world.now)
	local readyAt = saboteur:GetAttribute("LightsReadyAt")
	ability.OnServerEvent:Fire(saboteur, "lights")
	t.equal("using it again straight away does nothing", saboteur:GetAttribute("LightsReadyAt"), readyAt)
	world.advance(9)
	t.equal("the lights come back on", groundLightsOff(), offBefore)
	ability.OnServerEvent:Fire(saboteur, "teleport")
	t.equal("an unknown ability is ignored", #world.warnings, 0)

	-- scares: over a minute, the director produces events
	local scaresBefore = #logged(world, "Scare", "all")
	world.advance(70)
	t.check("the scare director plays events", #logged(world, "Scare", "all") > scaresBefore)

	-- hiding: passing by does not find or kill a hidden player; but someone he was hunting who hides is searched for
	local hide
	for _, prompt in world.prompts(world.workspace, "Hide") do
		if prompt.Parent.Position.Y < 5 then
			hide = prompt
			break
		end
	end
	local body = hide.Parent
	local victim = crew[1]
	world.root(victim).Position = body.Position + V3.new(0, 0, 3)
	hide.Triggered:Fire(victim)
	t.equal("a crew member hides", victim:GetAttribute("Hidden"), true)
	local patrol = threat.current()
	threat.resume()
	patrol.x, patrol.z, patrol.y = body.Position.X + 2.5, body.Position.Z, 0
	patrol.from, patrol.to = patrol.to, patrol.to
	world.advance(0.6)
	t.equal("passing close by does not kill a hidden player", world.humanoid(victim).Health, 100)
	t.equal("he does not hear them", patrol.mode, "Patrol")
	world.advance(5)
	t.equal("a player he never heard stays hidden", victim:GetAttribute("Hidden"), true)
	threat.pause()
	remotes:FindFirstChild("Intent").OnServerEvent:Fire(victim, { leave = true })
	world.advance(0.3)
	t.equal("the player leaves the locker", victim:GetAttribute("Hidden"), false)

	-- now he is close and hears them (standing still, 14 studs), then they dive into the locker: he comes to search it
	world.root(victim).Position = body.Position + V3.new(0, 0, 3)
	patrol.x, patrol.z, patrol.y = body.Position.X + 9, body.Position.Z, 0
	patrol.from, patrol.to = patrol.to, patrol.to
	threat.resume()
	world.advance(0.3)
	t.equal("he hears someone standing close by", patrol.mode, "Chase")
	hide.Triggered:Fire(victim)
	t.equal("they hide in front of him", victim:GetAttribute("Hidden"), true)
	world.advance(10)
	t.equal("he searched the locker and caught them", world.humanoid(victim).Health <= 0, true)
	threat.pause()
	t.equal("the night goes on with three left", storage:GetAttribute("Phase"), "Night")

	-- a meeting: the saboteur is voted out, one vote short of a tie does not eject
	local bell = world.prompts(world.workspace, "Ring the bell")[1]
	world.root(crew[2]).Position = bell.Parent.Position + V3.new(0, 0, 3)
	bell.Triggered:Fire(crew[2])
	world.advance(0.6)
	t.equal("the bell starts a meeting", storage:GetAttribute("Phase"), "Meeting")
	local started = logged(world, "MeetingStart", "all")[1].args[1]
	t.equal("only the living are gathered", #started.players, 3)
	local vote = remotes:FindFirstChild("Vote")
	vote.OnServerEvent:Fire(crew[2], saboteur.UserId)
	vote.OnServerEvent:Fire(crew[3], crew[2].UserId)
	vote.OnServerEvent:Fire(saboteur, "skip")
	vote.OnServerEvent:Fire(victim, saboteur.UserId) -- the dead cannot vote
	vote.OnServerEvent:Fire(crew[2], crew[3].UserId) -- a second vote from the same person does not count
	world.advance(0.6)
	t.check("everyone alive voted so the meeting ends early", storage:GetAttribute("PhaseEndsAt") - world.now < 10)
	world.advance(10)
	local first = logged(world, "MeetingResult", "all")[1].args[1]
	t.equal("1 vs 1 plus a skip is a tie: no one is ejected", first.ejected, nil)
	t.equal("the night resumes", storage:GetAttribute("Phase"), "Night")
	threat.pause()

	-- the second meeting: two votes beat the skip and the saboteur is out, so the crew wins
	local bell2 = world.prompts(world.workspace, "Ring the bell")[1]
	world.root(crew[3]).Position = bell2.Parent.Position + V3.new(0, 0, 3)
	bell2.Triggered:Fire(crew[3])
	world.advance(0.6)
	t.equal("a second person can ring the bell", storage:GetAttribute("Phase"), "Meeting")
	vote.OnServerEvent:Fire(crew[2], saboteur.UserId)
	vote.OnServerEvent:Fire(crew[3], saboteur.UserId)
	vote.OnServerEvent:Fire(saboteur, crew[2].UserId)
	world.advance(10)
	local second = logged(world, "MeetingResult", "all")[2].args[1]
	t.equal("the saboteur is ejected", second.ejected, saboteur.Name)
	t.equal("and their role is revealed", second.role, "Saboteur")
	t.equal("the ejected saboteur is out", world.humanoid(saboteur).Health <= 0, true)
	world.advance(1.5)
	t.equal("with the saboteur gone the crew wins", logged(world, "RoundResult", "all")[1].args[1].winner, "Crew")
	t.equal("everyone alive got a reward", #logged(world, "Award", "client") >= 2, true)
	t.equal("nothing warned", #world.warnings, 0)
end
