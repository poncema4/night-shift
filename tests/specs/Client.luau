--!strict
-- The real CLIENT scripts (HUD, controls, meeting screen, results, locker, cameras, spectating, the Night Manager view)
-- running against the real server in the fake Roblox world, talking over the same remotes. It checks that every screen
-- builds, reacts to what the server sends, and that pressing things reaches the server.
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

-- Boots a server with four players and the client for "Marco"; returns it with the crew status of Marco.
local function boot(seed: number, untilNight: boolean)
	math.randomseed(seed)
	local world = Fake.world()
	world.load("src/server/main.server") -- the real entry point: picks the mode, then starts the round
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
	-- before the night: a lobby that says how many are needed, then a tip while waiting
	do
		local lobbyWorld, lobbyMe = boot(2, false)
		local lobbyStorage = lobbyWorld.service("ReplicatedStorage")
		local lobbyHud = gui(lobbyMe, "NightShiftHud")
		local guard = 0
		while lobbyStorage:GetAttribute("Phase") ~= "Intermission" and guard < 100 do
			play(lobbyWorld, 0.5)
			guard += 1
		end
		t.check(
			"the intermission counts down to the night",
			string.find(find(lobbyHud, "Status").Text, "Night begins in") ~= nil
		)
		t.check(
			"and shows a tip",
			find(lobbyHud, "Tip").Visible and string.find(find(lobbyHud, "Tip").Text, "TIP:") ~= nil
		)
	end

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

	-- nothing on the main screen sits on top of anything else (the overlapping-text bug)
	do
		local function rect(inst: any): { number }
			local p, z, a = inst.Position, inst.Size, inst.AnchorPoint
			local ax = if a then a.X else 0
			local ay = if a then a.Y else 0
			local x = p.X.Scale - ax * z.X.Scale
			local y = p.Y.Scale - ay * z.Y.Scale
			return { x, y, x + z.X.Scale, y + z.Y.Scale }
		end
		local hudGui = gui(me, "NightShiftHud")
		local jailGui = gui(me, "NightShiftJail")
		local named = {
			Status = find(hudGui, "Status"),
			Tasks = find(hudGui, "Tasks"),
			Role = find(hudGui, "Role"),
			Floor = find(hudGui, "Floor"),
			Tip = find(hudGui, "Tip"),
			HidingText = find(hudGui, "HidingText"),
			Leave = find(hudGui, "Leave"),
			CageBanner = find(jailGui, "Banner"),
			CageSub = find(jailGui, "Sub"),
		}
		local names, hits = {}, {}
		for name, inst in named do
			if inst then
				table.insert(names, name)
			end
		end
		table.sort(names)
		for i = 1, #names do
			for k = i + 1, #names do
				local a, b = rect(named[names[i]]), rect(named[names[k]])
				if a[1] < b[3] and b[1] < a[3] and a[2] < b[4] and b[2] < a[4] then
					table.insert(hits, `{names[i]} x {names[k]}`)
				end
			end
		end
		t.check("the HUD and the cage banner never overlap", #hits == 0, table.concat(hits, ", "))
		t.check("the elements being compared exist", #names >= 6, table.concat(names, ","))

		-- centred means centred: these sit on the vertical midline and align their text to the centre
		local offCentre = {}
		for _, name in { "Status", "Tasks", "Role", "Tip", "HidingText", "Leave", "CageBanner", "CageSub" } do
			local inst = named[name]
			if inst then
				local r = rect(inst)
				local middle = (r[1] + r[3]) / 2
				local alignment = inst.TextXAlignment
				local centred = alignment == nil or alignment == world.enum.TextXAlignment.Center
				if math.abs(middle - 0.5) > 0.01 or not centred then
					table.insert(offCentre, name)
				end
			end
		end
		t.check(
			"the main HUD text sits on the vertical midline with centred alignment",
			#offCentre == 0,
			table.concat(offCentre, ", ")
		)

		-- text never gets huge: every scaled label or button on a match screen has a size cap
		local uncapped, checked = {}, 0
		for _, screen in me.PlayerGui:GetChildren() do
			for _, item in screen:GetDescendants() do
				if (item:IsA("TextLabel") or item:IsA("TextButton")) and item.TextScaled then
					checked += 1
					local limit = item:FindFirstChildOfClass("UITextSizeConstraint")
					if not limit or limit.MaxTextSize > 48 then
						table.insert(uncapped, item.Name)
					end
				end
			end
		end
		t.check(
			"every scaled text element has a size cap of 48 or less",
			#uncapped == 0 and checked > 10,
			`{checked} checked, uncapped: {table.concat(uncapped, ",")}`
		)
	end

	-- he starts locked up: the crew sees a countdown, then "HE IS LOOSE"
	local jail = gui(me, "NightShiftJail")
	local function jailText(): string
		local text = ""
		for _, d in jail:GetDescendants() do
			if d:IsA("TextLabel") and d.Visible and d.Text ~= "" then
				text ..= d.Text .. " | "
			end
		end
		return text
	end
	t.check("a countdown shows while he is locked up", string.find(jailText(), "LOCKED UP", 1, true) ~= nil, jailText())
	local cell = world.service("CollectionService"):GetTagged("HoldingCell")[1]
	local bar = cell and cell:FindFirstChild("Bar")
	t.check("the holding cell is in the hotel", bar ~= nil)
	local closedY = bar and bar.CFrame.Position.Y or 0
	play(world, 1)
	t.check(
		"the cage stays shut while he is locked up",
		bar ~= nil and math.abs(bar.CFrame.Position.Y - closedY) < 0.01
	)
	threat.release(false)
	play(world, 0.5)
	t.check(
		"when he is released the screen says so",
		string.find(jailText(), "HE IS LOOSE", 1, true) ~= nil,
		jailText()
	)
	play(world, 2)
	t.check(
		"the cage bars slide up and out of the way",
		bar ~= nil and bar.CFrame.Position.Y > closedY + 8,
		`{closedY} -> {bar and bar.CFrame.Position.Y}`
	)

	-- every screen is built
	for _, name in
		{
			"NightShiftHud",
			"NightShiftFx",
			"NightShiftJail",
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
	t.check(
		"the tasks counter shows 0 of all of them",
		find(hud, "Tasks").Text == `TASKS 0/{#Floors.tasks()}` and find(hud, "Tasks").Visible
	)
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

	-- the scary layers: silent when he is far, rising as he nears, a sting when he starts hunting
	local threatState = storage:FindFirstChild("ThreatState")
	local myPos = world.root(me).Position
	threatState:SetAttribute("Active", true)
	threatState:SetAttribute("Mode", "Patrol")
	threatState:SetAttribute("X", myPos.X + 300)
	threatState:SetAttribute("Y", myPos.Y - 3)
	threatState:SetAttribute("Z", myPos.Z)
	play(world, 0.3)
	t.check(
		"far away his footsteps and breathing are silent",
		not heard(Config.Sounds.steps) and not heard(Config.Sounds.breath)
	)
	threatState:SetAttribute("X", myPos.X + 10)
	play(world, 0.3)
	t.check("near him the dread drone plays", heard(Config.Sounds.dread))
	t.check("near him his footsteps play", heard(Config.Sounds.steps))
	t.check("close to him his breathing plays", heard(Config.Sounds.breath))
	t.check("his heartbeat plays", heard(Config.Sounds.heartbeat))
	threatState:SetAttribute("Mode", "Chase")
	play(world, 0.1)
	t.check("when he starts hunting you a sting plays", heard(Config.Sounds.chaseSting))
	threatState:SetAttribute("Stunned", true)
	play(world, 0.1)
	t.check("blinding him makes him shriek", heard(Config.Sounds.blindShriek))
	threatState:SetAttribute("Stunned", false)
	threatState:SetAttribute("Active", false)

	-- hiding: the screen shows
	local hide
	for _, prompt in world.prompts(world.workspace, "Hide") do
		if prompt.Parent.Position.Y < 5 then
			hide = prompt
			break
		end
	end
	world.root(me).Position = hide.Parent.Position + V3.new(0, 0, 3)
	t.equal("hiding is one tap of E, not a hold", hide.HoldDuration, 0)
	hide.Triggered:Fire(me)
	play(world, 0.3)
	t.check("the hiding screen appears", find(hud, "Hiding").Visible)
	do
		-- you can SEE out of the locker: the overlay is transparent and the slats leave most of the screen clear
		local overlay = find(hud, "Hiding")
		local covered = 0
		for _, child in overlay:GetChildren() do
			if child.Name == "Slat" then
				covered += child.Size.Y.Scale
			end
		end
		t.equal("the locker overlay does not black out the screen", overlay.BackgroundTransparency, 1)
		t.check("the slats cover less than 40% of the height", covered > 0.2 and covered < 0.4, `{covered}`)
	end
	local camera = world.workspace.CurrentCamera
	do
		local lockerBody = hide.Parent
		local part = lockerBody
		t.check(
			"the locker fades for the person inside (they can see out)",
			part.LocalTransparencyModifier >= 0.5,
			`{part.LocalTransparencyModifier}`
		)
		local out = (lockerBody.CFrame * world.CFrame.new(0, 0, 1)).Position - lockerBody.Position
		local reach = (camera.CFrame.Position - lockerBody.Position):Dot(out)
		t.check("and the eye is outside the door face, not buried in the box", reach > lockerBody.Size.Z / 2, `{reach}`)
	end
	t.equal("the locker is marked as occupied by you", hide.Parent.Parent:GetAttribute("Occupant"), me.UserId)
	t.equal(
		"the camera looks out through the door instead of sitting blind inside",
		camera.CameraType,
		world.enum.CameraType.Scriptable
	)
	local eye, out =
		camera.CFrame.Position, (hide.Parent.CFrame * world.CFrame.new(0, 0, 1)).Position - hide.Parent.Position
	t.check("the eye is at the door side, looking away from the box", (eye - hide.Parent.Position):Dot(out) > 0)
	for _, b in find(hud, "Hiding"):GetChildren() do
		if b:IsA("TextButton") then
			b.Activated:Fire()
		end
	end
	play(world, 0.3)
	t.check("LEAVE on screen gets you out", not find(hud, "Hiding").Visible and me:GetAttribute("Hidden") == false)
	t.equal("and the normal camera comes back", camera.CameraType, world.enum.CameraType.Custom)
	t.equal("and the locker is free again", hide.Parent.Parent:GetAttribute("Occupant"), nil)
	t.equal("and it is solid to look at again", hide.Parent.LocalTransparencyModifier, 0)

	-- a task and the cameras
	local function station(name: string)
		return world.prompts(world.workspace, name)[1]
	end
	local cameras = station("Fix the cameras")
	world.root(me).Position = cameras.Parent.Position + V3.new(0, 0, 3)
	cameras.Triggered:Fire(me)
	play(world, 0.3)
	t.equal("the tasks counter goes up", find(hud, "Tasks").Text, `TASKS 1/{#Floors.tasks()}`)
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
	local banner = false
	for _, l in spectate:GetChildren() do
		if l:IsA("TextLabel") and l.Visible and (l.Text == "YOU WERE CAUGHT" or l.Text == "YOU WERE VOTED OUT") then
			banner = true
		end
	end
	t.check("and you are told you were caught", banner)
	t.check("the camera follows someone else", world.workspace.CurrentCamera.CameraSubject ~= world.humanoid(me))
	-- the others are still alive: let the night go on until the saboteur or crew wins by killing the rest
	for _, p in others do
		world.humanoid(p).Health = 0
	end
	play(world, 1.5)
	t.equal("dawn", storage:GetAttribute("Phase"), "Dawn")
	local results = gui(me, "NightShiftResults")
	t.check("the dawn screen opens", results.Enabled)
	t.check("dawn plays its sound", heard(Config.Sounds.dawn) or heard(Config.Sounds.deathSting))
	-- whichever side wins, the matching cue plays: relief for the crew, the sting when the crew goes down
	local crewWon = string.find(find(results, "Headline").Text, "CREW") ~= nil
	t.check(
		"the dawn cue matches the result",
		if crewWon then heard(Config.Sounds.dawn) else heard(Config.Sounds.deathSting)
	)
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
	-- he catches you: the camera snaps to his face, then hands back (own world, so the night's timeline above is untouched)
	do
		local cw, cme, _, cstorage = boot(seed, true)
		local catchCamera = cw.workspace.CurrentCamera
		local cthreat = cw.load("src/server/ThreatService")
		local nm = cthreat.current()
		cthreat.release(false)
		cstorage:FindFirstChild("Remotes"):FindFirstChild("Intent"):FireServer({ light = false }) -- a lit flashlight would blind him
		play(cw, 0.5)
		local mine = cw.root(cme).Position
		nm.x, nm.z, nm.y = mine.X + 3, mine.Z, 0
		nm.from, nm.to, nm.level = "C10", "C10", 0 -- on this floor
		play(cw, 0.5)
		t.check("he caught you", cw.humanoid(cme).Health <= 0)
		t.equal("the camera is on his face", catchCamera.CameraType, cw.enum.CameraType.Scriptable)
		local catchGui = gui(cme, "NightShiftCatch")
		t.check("with a red flash over the screen", find(catchGui, "Frame").BackgroundTransparency < 0.9)
		cthreat.pause()
		play(cw, 2.2)
		t.equal("then the normal camera comes back for spectating", catchCamera.CameraType, cw.enum.CameraType.Custom)
		t.check("and the flash is gone", find(catchGui, "Frame").BackgroundTransparency >= 1)
	end
end
