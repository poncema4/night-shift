--!strict
-- One whole solo night, played through the REAL server code against the fake Roblox world: the round starts, the player
-- sprints, uses the flashlight, finishes a task, hides, unlocks and uses the cameras, rings the bell, votes, dies, and the
-- dawn screen and rewards arrive. Everything the server decides is checked; only the visuals are not.
local Fake = require("../fake/Roblox")
local Floors = require("../../src/shared/Game/Floors")
local TaskBoard = require("../../src/shared/Game/TaskBoard")
local Config = require("../../src/shared/Config")

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
	math.randomseed(7)
	local world = Fake.world()
	local V3 = world.Vector3
	local storage = world.service("ReplicatedStorage")
	local server = world.load("src/server/RoundService")
	local threat = world.load("src/server/ThreatService")
	local ok, err = pcall(server.start)
	t.check("the server starts", ok, tostring(err))
	if not ok then
		return
	end
	local remotes = storage:FindFirstChild("Remotes")
	local player = world.addPlayer("Marco", 1)

	-- the round loop: Lobby -> Intermission -> Night
	world.advance(1)
	t.equal("a solo player starts the intermission in Studio", storage:GetAttribute("Phase"), "Intermission")
	world.advance(6)
	t.equal("the night begins", storage:GetAttribute("Phase"), "Night")
	t.check("the player has a character", player.Character ~= nil)
	t.equal("the role is sent to that player only", #logged(world, "RoleAssigned", "client"), 1)
	t.equal(
		"a lone player (co-op) needs a share of the tasks, not all of them",
		storage:GetAttribute("TasksTotal"),
		TaskBoard.target(#Floors.tasks(), 1)
	)
	t.equal("the Night Manager is hunting", storage:FindFirstChild("ThreatState"):GetAttribute("Active"), true)
	threat.pause() -- keep him out of the way for the rest of the checks
	local humanoid, root = world.humanoid(player), world.root(player)

	-- sprint, stamina, flashlight
	local intent = remotes:FindFirstChild("Intent")
	humanoid.MoveDirection = V3.new(1, 0, 0)
	intent.OnServerEvent:Fire(player, { sprint = true, light = true })
	world.advance(0.5)
	t.equal("sprinting is granted", player:GetAttribute("Sprinting"), true)
	t.equal("sprinting is faster", humanoid.WalkSpeed, Config.Move.Sprint)
	t.equal("the flashlight is on", player:GetAttribute("LightOn"), true)
	local beam = player.Character:FindFirstChild("Head"):FindFirstChildOfClass("SpotLight")
	t.check("the beam exists and is on", beam ~= nil and beam.Enabled)
	local tool = player.Character:FindFirstChild("Flashlight")
	t.check("the flashlight is a real item, held in the hand while it is on", tool ~= nil and tool:IsA("Tool"))
	t.check("it has a handle to hold", tool ~= nil and tool:FindFirstChild("Handle") ~= nil)
	-- putting it away from the hotbar turns the light off; taking it out turns it back on
	if tool then
		humanoid:UnequipTools()
		world.advance(0.3)
		t.equal("putting the flashlight away turns the light off", player:GetAttribute("LightOn"), false)
		t.check("it goes back to the backpack", player.Backpack:FindFirstChild("Flashlight") ~= nil)
		humanoid:EquipTool(player.Backpack:FindFirstChild("Flashlight"))
		world.advance(0.3)
		t.equal("taking it out of the hotbar turns the light on", player:GetAttribute("LightOn"), true)
	end
	world.advance(6)
	t.equal("stamina runs out", player:GetAttribute("Sprinting"), false)
	t.equal("a winded player is back to walking speed", humanoid.WalkSpeed, Config.Move.Walk)
	humanoid.MoveDirection = V3.new(0, 0, 0)
	intent.OnServerEvent:Fire(player, { sprint = false, light = false })
	world.advance(0.2)
	intent.OnServerEvent:Fire(player, { sprint = "yes", light = 5, leave = "x" }) -- junk is ignored, not a crash
	world.advance(0.2)
	t.equal("junk intents change nothing", player:GetAttribute("Sprinting"), false)

	-- a task
	local function station(name: string)
		return world.prompts(world.workspace, name)[1]
	end
	local breaker = station("Reset the breaker")
	t.check("the breaker prompt exists", breaker ~= nil)
	root.Position = breaker.Parent.Position + V3.new(0, 0, 3)
	breaker.Triggered:Fire(player)
	t.equal("finishing a task counts it", storage:GetAttribute("TasksDone"), 1)
	local lamp = breaker.Parent:FindFirstChild("Station_breaker"):FindFirstChild("Status")
	t.check("the station lamp turns green", lamp.Color.G > 0.7 and lamp.Color.R < 0.4)
	breaker.Triggered:Fire(player)
	t.equal("the same task does not count twice", storage:GetAttribute("TasksDone"), 1)
	root.Position = V3.new(500, 3, 500)
	local linens = station("Fold the linens")
	linens.Triggered:Fire(player)
	t.equal("a task cannot be done from across the map", storage:GetAttribute("TasksDone"), 1)

	-- hiding
	local hide
	for _, prompt in world.prompts(world.workspace, "Hide") do
		if prompt.Parent.Position.Y < 5 then
			hide = prompt
			break
		end
	end
	t.check("a hiding place exists on the ground floor", hide ~= nil)
	root.Position = hide.Parent.Position + V3.new(0, 0, 3)
	hide.Triggered:Fire(player)
	t.equal("the player is hidden", player:GetAttribute("Hidden"), true)
	t.check("a hidden player is frozen", root.Anchored and humanoid.WalkSpeed == 0)
	t.check("the hiding place is taken", hide.Enabled == false)
	intent.OnServerEvent:Fire(player, { leave = true })
	world.advance(0.3)
	t.equal("the player can leave", player:GetAttribute("Hidden"), false)
	t.check("and moves again", not root.Anchored)

	-- cameras
	local cameras = station("Fix the cameras")
	root.Position = cameras.Parent.Position + V3.new(0, 0, 3)
	cameras.Triggered:Fire(player)
	t.equal("finishing the cameras task powers the monitor", storage:GetAttribute("CameraCharges"), 3)
	remotes:FindFirstChild("Camera").OnServerEvent:Fire(player)
	t.check("the crew can watch", (player:GetAttribute("CamerasUntil") or 0) > world.now)
	t.equal("a charge was spent", storage:GetAttribute("CameraCharges"), 2)

	-- the bell: a meeting
	local before = root.Position
	local bell = station("Ring the bell")
	t.check("the reception bell has a prompt", bell ~= nil)
	root.Position = bell.Parent.Position + V3.new(0, 0, 3)
	local home = root.Position
	bell.Triggered:Fire(player)
	world.advance(0.6)
	t.equal("ringing the bell starts a meeting", storage:GetAttribute("Phase"), "Meeting")
	t.equal("every client is told", #logged(world, "MeetingStart", "all"), 1)
	t.check("the player is gathered and frozen in the lobby", root.Anchored and root.Position ~= home)
	remotes:FindFirstChild("Vote").OnServerEvent:Fire(player, "skip")
	world.advance(10)
	t.equal("the meeting ended", storage:GetAttribute("Phase"), "Night")
	t.equal("the result was announced", #logged(world, "MeetingResult", "all"), 1)
	t.check("the player is back where they were and free", not root.Anchored and root.Position == home)
	bell.Triggered:Fire(player)
	world.advance(0.6)
	t.equal("the bell can only be rung once per night each", storage:GetAttribute("Phase"), "Night")
	threat.pause()
	local _ = before

	-- caught: a body, then dawn, rewards and the next round
	humanoid.Health = 0
	t.check("a body can be reported", #world.prompts(world.workspace, "Report body") == 1)
	world.advance(1.5)
	t.equal("with the crew gone the night ends", storage:GetAttribute("Phase"), "Dawn")
	local results = logged(world, "RoundResult", "all")
	t.equal("the dawn result is sent", #results, 1)
	t.equal("the saboteurs won", results[1] and results[1].args[1].winner, "Saboteurs")
	t.equal("the report lists the player", results[1] and #results[1].args[1].players, 1)
	local awards = logged(world, "Award", "client")
	t.check("the player earned XP and tips", #awards == 1 and awards[1].args[2].xp > 0)
	t.check("a profile snapshot was sent", #logged(world, "Profile", "client") >= 2)
	world.advance(10)
	t.equal(
		"back to the lobby",
		storage:GetAttribute("Phase") == "Lobby" or storage:GetAttribute("Phase") == "Intermission",
		true
	)
	t.check("the player is brought back to life for the next round", world.humanoid(player).Health > 0)
	t.equal("nothing warned during the whole night", #world.warnings, 0)
end
