--!strict
-- The real CLIENT scripts (HUD, controls, meeting screen, results, locker, cameras, spectating, the Night Manager view)
-- running against the real server in the fake Roblox world, talking over the same remotes. It checks that every screen
-- builds, reacts to what the server sends, and that pressing things reaches the server.
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

-- Boots a server with four players and the client for "Marco"; returns it with the crew status of Marco.
local function boot(seed: number, untilNight: boolean)
	math.randomseed(seed)
	local world = Fake.world()
	local server = world.load("src/server/RoundService")
	server.start()
	local me = world.addPlayer("Marco", 1)
	local others = {}
	for i, name in { "Ana", "Ben", "Cy" } do
		table.insert(others, world.addPlayer(name, 10 + i))
	end
	world.setLocal(me)
	world.load("src/client/main.client")
	local storage = world.service("ReplicatedStorage")
	local guard = 0
	while untilNight and storage:GetAttribute("Phase") ~= "Night" and guard < 400 do
		world.advance(0.5)
		world.render(0.5)
		guard += 1
	end
	local role
	for _, entry in logged(world, "RoleAssigned", "client") do
		if entry.args[1] == me then
			role = entry.args[2]
		end
	end
	return world, me, others, storage, role
end

local function gui(player: any, name: string): any
	return player.PlayerGui:FindFirstChild(name)
end

local function find(root: any, name: string): any
	return root:FindFirstChild(name, true)
end

local function play(world: any, seconds: number)
	for _ = 1, math.floor(seconds / 0.1 + 0.5) do
		world.advance(0.1)
		world.render(0.1)
	end
end

return function(t)
	-- pick a seed where the local player is on the crew (so the crew-only screens can be shown)
	local seed = 1
	for candidate = 1, 40 do
		local _, _, _, _, role = boot(candidate, true)
		if role == "Crew" then
			seed = candidate
			break
		end
	end
	local world, me, others, storage, role = boot(seed, true)
	local V3 = world.Vector3
	local threat = world.load("src/server/ThreatService")
	local remotes = storage:FindFirstChild("Remotes")
	t.equal("the local player is on the crew", role, "Crew")

	-- every screen is built
	for _, name in
		{
			"NightShiftHud",
			"NightShiftFx",
			"NightShiftMeeting",
			"NightShiftResults",
			"NightShiftLocker",
			"NightShiftCameras",
			"NightShiftSpectate",
		}
	do
		t.check(`screen {name} exists`, gui(me, name) ~= nil)
	end

	-- the HUD in the night
	play(world, 1)
	local hud = gui(me, "NightShiftHud")
	t.check("the status shows the night and a countdown", string.find(find(hud, "Status").Text, "NIGHT") ~= nil)
	t.check("the role is shown", string.find(find(hud, "Role").Text, "CREW") ~= nil and find(hud, "Role").Visible)
	t.equal("the floor is shown", find(hud, "Floor").Text, "GROUND FLOOR")
	t.check("the tasks counter shows 0 of 12", find(hud, "Tasks").Text == "TASKS 0/12" and find(hud, "Tasks").Visible)
	local guide = find(hud, "Guide")
	t.check("the How to Play card is shown the first time", guide.Visible)
	for _, b in guide:GetChildren() do
		if b:IsA("TextButton") then
			b.Activated:Fire()
		end
	end
	t.check("and closes with one tap", not guide.Visible)

	-- the Night Manager is drawn on this client
	local manager = world.workspace:FindFirstChild("NightManager")
	t.check("the Night Manager appears on this client", manager ~= nil and #manager:GetChildren() > 30)
	threat.pause()
	play(world, 0.3)
	t.check("and disappears while he is paused (a meeting)", world.workspace:FindFirstChild("NightManager") == nil)
	threat.resume()
	play(world, 0.3)
	threat.pause()

	-- controls reach the server
	local humanoid = world.humanoid(me)
	humanoid.MoveDirection = V3.new(1, 0, 0)
	world.actions.NightShiftSprint("NightShiftSprint", world.enum.UserInputState.Begin)
	world.actions.NightShiftLight("NightShiftLight", world.enum.UserInputState.Begin)
	play(world, 1)
	t.equal("holding RUN sprints on the server", me:GetAttribute("Sprinting"), true)
	t.equal("LIGHT turns the flashlight on", me:GetAttribute("LightOn"), true)
	t.check("the stamina bar drains", find(hud, "STAMINA"):FindFirstChild("Fill").Size.X.Scale < 1)
	world.actions.NightShiftSprint("NightShiftSprint", world.enum.UserInputState.End)
	world.actions.NightShiftLight("NightShiftLight", world.enum.UserInputState.Begin)
	humanoid.MoveDirection = V3.new(0, 0, 0)
	play(world, 0.5)
	t.equal("releasing RUN stops sprinting", me:GetAttribute("Sprinting"), false)
	t.equal("LIGHT again turns it off", me:GetAttribute("LightOn"), false)

	-- sound cues fire from what the server says
	local Config = require("../../src/shared/Config")
	local function heard(id: string): boolean
		return table.find(world.played, id) ~= nil
	end
	t.check("the flashlight click plays", heard(Config.Sounds.flashlight))

	-- hiding: the screen shows
	local hide
	for _, prompt in world.prompts(world.workspace, "Hide") do
		if prompt.Parent.Position.Y < 5 then
			hide = prompt
			break
		end
	end
	world.root(me).Position = hide.Parent.Position + V3.new(0, 0, 3)
	hide.Triggered:Fire(me)
	play(world, 0.3)
	t.check("the hiding screen appears", find(hud, "Hiding").Visible)
	for _, b in find(hud, "Hiding"):GetChildren() do
		if b:IsA("TextButton") then
			b.Activated:Fire()
		end
	end
	play(world, 0.3)
	t.check("LEAVE on screen gets you out", not find(hud, "Hiding").Visible and me:GetAttribute("Hidden") == false)

	-- a task and the cameras
	local function station(name: string)
		return world.prompts(world.workspace, name)[1]
	end
	local cameras = station("Fix the cameras")
	world.root(me).Position = cameras.Parent.Position + V3.new(0, 0, 3)
	cameras.Triggered:Fire(me)
	play(world, 0.3)
	t.equal("the tasks counter goes up", find(hud, "Tasks").Text, "TASKS 1/12")
	t.check("finishing a task plays a ping", heard(Config.Sounds.taskDone))
	local camButton = find(gui(me, "NightShiftCameras"), "TextButton")
		or gui(me, "NightShiftCameras"):FindFirstChildOfClass("TextButton")
	t.check(
		"the CAMERAS button appears for the crew",
		camButton ~= nil and camButton.Visible and string.find(camButton.Text, "x3") ~= nil
	)
	camButton.Activated:Fire()
	play(world, 0.3)
	local panel = gui(me, "NightShiftCameras"):FindFirstChildOfClass("Frame")
	t.check("the monitor opens", panel ~= nil and panel.Visible)
	threat.resume()
	play(world, 0.3)
	local blipShown = false
	for _, f in gui(me, "NightShiftCameras"):GetDescendants() do
		if f:IsA("Frame") and f.BackgroundColor3.R > 0.9 and f.BackgroundColor3.G < 0.3 and f.Visible then
			blipShown = true
		end
	end
	t.check("the Night Manager shows as a blip on the map", blipShown)
	threat.pause()

	-- a meeting
	local bell = station("Ring the bell")
	world.root(me).Position = bell.Parent.Position + V3.new(0, 0, 3)
	bell.Triggered:Fire(me)
	play(world, 0.7)
	local meeting = gui(me, "NightShiftMeeting")
	t.check("the meeting screen opens", meeting.Enabled)
	t.check("the meeting plays its bell", heard(Config.Sounds.meeting))
	t.check("it names who called it", string.find(find(meeting, "Sub").Text, "Marco") ~= nil)
	local cards = {}
	for _, c in find(meeting, "Players"):GetChildren() do
		if c:IsA("Frame") then
			cards[find(c, "Name").Text] = c
		end
	end
	t.check(
		"one card per living player",
		cards.Marco ~= nil and cards.Ana ~= nil and cards.Ben ~= nil and cards.Cy ~= nil
	)
	-- tapping Ana's card votes for Ana on the server
	find(cards.Ana, "TextButton").Activated:Fire()
	local votes = logged(world, "Vote", "server")
	t.check("tapping a card sends a vote to the server", #votes == 1 and votes[1].args[1] == 11)
	local vote = remotes:FindFirstChild("Vote")
	vote.OnServerEvent:Fire(others[1], "skip")
	vote.OnServerEvent:Fire(others[2], "skip")
	vote.OnServerEvent:Fire(others[3], "skip")
	play(world, 0.5)
	t.check("a tick appears when others have voted", find(cards.Ana, "Tick").Text == "VOTED")
	play(world, 10)
	local result = find(meeting, "Result")
	t.check(
		"the result is shown at the end (a skip beats one vote)",
		string.find(result.Text, "NO ONE") ~= nil or string.find(result.Text, "TIE") ~= nil
	)
	play(world, 1)
	t.check("the screen closes when the night resumes", not meeting.Enabled)
	threat.pause()

	-- caught: dawn, the results screen, the reward and the locker
	world.humanoid(me).Health = 0
	play(world, 0.6)
	local spectate = gui(me, "NightShiftSpectate")
	local watching = false
	for _, l in spectate:GetChildren() do
		if l:IsA("TextLabel") and string.find(l.Text, "SPECTATING") ~= nil and l.Visible then
			watching = true
		end
	end
	t.check("when you are out you spectate the living", watching)
	t.check("the camera follows someone else", world.workspace.CurrentCamera.CameraSubject ~= world.humanoid(me))
	-- the others are still alive: let the night go on until the saboteur or crew wins by killing the rest
	for _, p in others do
		world.humanoid(p).Health = 0
	end
	play(world, 1.5)
	t.equal("dawn", storage:GetAttribute("Phase"), "Dawn")
	local results = gui(me, "NightShiftResults")
	t.check("the dawn screen opens", results.Enabled)
	t.check("dawn plays its sound", heard(Config.Sounds.dawn))
	t.check(
		"it names the winner",
		string.find(find(results, "Headline").Text, "SABOTEUR") ~= nil
			or string.find(find(results, "Headline").Text, "CREW") ~= nil
	)
	t.check("it shows what you earned", string.find(find(results, "Earned").Text, "XP") ~= nil)
	local locker = gui(me, "NightShiftLocker")
	t.check("the locker lists cosmetics", #find(locker, "ScrollingFrame"):GetChildren() > 8)
	t.check("and shows your level", string.find(find(locker, "Title").Text, "LEVEL") ~= nil)
	play(world, 10)
	t.check("the dawn screen closes in the lobby", not results.Enabled)
	t.equal("no client or server warnings", #world.warnings, 0)
end
