--!strict
-- Four rounds in a row with four players and three different endings (crew finish every task, the saboteur catches the
-- crew, the saboteur is voted out): everything must reset between rounds (tasks, cameras, the bell, hiding places,
-- cooldowns, lights, the Night Manager's start) so round four plays exactly like round one.
local Fake = require("../fake/Roblox")
local Floors = require("../../src/shared/Game/Floors")

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
	math.randomseed(21)
	local world = Fake.world()
	local V3 = world.Vector3
	local storage = world.service("ReplicatedStorage")
	local remotes: any
	world.load("src/server/RoundService").start()
	remotes = storage:FindFirstChild("Remotes")
	local threat = world.load("src/server/ThreatService")
	local players = {}
	for i, name in { "Ana", "Ben", "Cy", "Di" } do
		table.insert(players, world.addPlayer(name, 30 + i))
	end

	local function untilPhase(name: string): boolean
		local guard = 0
		while storage:GetAttribute("Phase") ~= name and guard < 3000 do
			world.advance(0.5)
			guard += 1
		end
		return guard < 3000
	end

	-- who is who this round (from the RoleAssigned messages since `from`)
	local function roles(from: number): ({ any }, any)
		local crew, saboteur = {}, nil
		for i = from + 1, #world.log do
			local entry = world.log[i]
			if entry.remote == "RoleAssigned" then
				if entry.args[2] == "Saboteur" then
					saboteur = entry.args[1]
				else
					table.insert(crew, entry.args[1])
				end
			end
		end
		return crew, saboteur
	end

	local function stationPrompt(name: string): any
		return world.prompts(world.workspace, name)[1]
	end

	local function startOfNight(): (any, any, number)
		local mark = #world.log
		untilPhase("Night")
		world.advance(0.6)
		local crew, saboteur = roles(mark)
		return crew, saboteur, mark
	end

	-- every round must START clean
	local function checkClean(label: string, crew: any, saboteur: any)
		t.check(label .. ": four players alive and in the game", #crew == 3 and saboteur ~= nil)
		for _, p in players do
			t.equal(label .. ": " .. p.Name .. " alive", world.humanoid(p).Health > 0, true)
			t.equal(label .. ": " .. p.Name .. " not hidden", p:GetAttribute("Hidden"), false)
		end
		t.equal(label .. ": no tasks done", storage:GetAttribute("TasksDone"), 0)
		t.equal(label .. ": cameras are dead again", storage:GetAttribute("CameraCharges"), 0)
		t.equal(
			label .. ": he is hunting from the start",
			storage:FindFirstChild("ThreatState"):GetAttribute("Active"),
			true
		)
		local hideOpen = 0
		for _, prompt in world.prompts(world.workspace, "Hide") do
			if prompt.Enabled then
				hideOpen += 1
			end
		end
		t.check(
			label .. ": every hiding place is free",
			hideOpen == #world.prompts(world.workspace, "Hide") and hideOpen > 10
		)
		local pending = 0
		for _, name in { "Reset the breaker", "Wind the grand clock", "Replace the fuse box" } do
			if stationPrompt(name).Enabled then
				pending += 1
			end
		end
		t.equal(label .. ": task stations are switched on", pending, 3)
		t.equal(
			label .. ": all lights are on",
			(function()
				local off = 0
				for _, lamp in world.service("CollectionService"):GetTagged("Bulb") do
					local light = lamp:FindFirstChildOfClass("PointLight")
					if light and not light.Enabled then
						off += 1
					end
				end
				return off
			end)(),
			0
		)
	end

	-- ===== round 1: the crew finishes every task =====
	local crew1, sab1 = startOfNight()
	checkClean("round 1", crew1, sab1)
	threat.pause()
	local finishers = { crew1[1], crew1[2], crew1[3] }
	local taskNames = {}
	for _, task in Floors.tasks() do
		table.insert(taskNames, task.name)
	end
	for i, name in taskNames do
		local who = finishers[(i % 3) + 1]
		local prompt = stationPrompt(name)
		world.root(who).Position = prompt.Parent.Position
		prompt.Triggered:Fire(who)
	end
	world.advance(1.5)
	t.equal(
		"round 1: the crew wins by finishing every task",
		logged(world, "RoundResult", "all")[1].args[1].winner,
		"Crew"
	)
	t.equal("round 1: dawn", storage:GetAttribute("Phase"), "Dawn")

	-- ===== round 2: the saboteur catches the crew =====
	local crew2, sab2 = startOfNight()
	checkClean("round 2", crew2, sab2)
	threat.pause()
	for _, p in crew2 do
		world.humanoid(p).Health = 0
	end
	world.advance(1.5)
	t.equal("round 2: the saboteur wins", logged(world, "RoundResult", "all")[2].args[1].winner, "Saboteurs")

	-- ===== round 3: a bell, a vote, the saboteur is out =====
	local crew3, sab3 = startOfNight()
	checkClean("round 3", crew3, sab3)
	threat.pause()
	local bell3 = stationPrompt("Ring the bell")
	world.root(crew3[1]).Position = bell3.Parent.Position + V3.new(0, 0, 3)
	bell3.Triggered:Fire(crew3[1])
	world.advance(0.6)
	t.equal("round 3: the bell works again (it was unused this round)", storage:GetAttribute("Phase"), "Meeting")
	local vote = remotes:FindFirstChild("Vote")
	for _, p in crew3 do
		vote.OnServerEvent:Fire(p, sab3.UserId)
	end
	vote.OnServerEvent:Fire(sab3, "skip")
	world.advance(10)
	world.advance(1.5)
	t.equal(
		"round 3: the crew wins by voting out the saboteur",
		logged(world, "RoundResult", "all")[3].args[1].winner,
		"Crew"
	)

	-- ===== round 4: used the cameras and a hiding place in round 3? it must all be new again =====
	local crew4, sab4 = startOfNight()
	checkClean("round 4", crew4, sab4)
	-- the same player rang the bell in round 3: in round 4 they may ring it again
	threat.pause()
	local ringer = crew3[1]
	local bell4 = stationPrompt("Ring the bell")
	world.root(ringer).Position = bell4.Parent.Position + V3.new(0, 0, 3)
	bell4.Triggered:Fire(ringer)
	world.advance(0.6)
	t.equal(
		"round 4: the bell is available again to someone who rang it last round",
		storage:GetAttribute("Phase"),
		"Meeting"
	)
	t.equal("three results over three rounds", #logged(world, "RoundResult", "all"), 3)
	t.equal("nothing warned across four rounds", #world.warnings, 0)
end
