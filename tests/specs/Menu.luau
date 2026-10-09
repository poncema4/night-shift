--!strict
-- The lobby's client screens against the real lobby server: the title menu builds, PLAY shows the party screen,
-- Quick Play and Create reach the server, the party status follows the queue clock, options change what the player
-- hears, and a launch raises the loading screen that carries through the teleport.
local Fake = require("../fake/Roblox")
local Config = require("../../src/shared/Config")

local function buttonText(root: any, text: string): any
	for _, d in root:GetDescendants() do
		if (d:IsA("TextButton") or d:IsA("TextLabel")) and d.Text == text then
			return d
		end
	end
	return nil
end

local function labelContaining(root: any, part: string): any
	for _, d in root:GetDescendants() do
		if d:IsA("TextLabel") and string.find(d.Text, part, 1, true) then
			return d
		end
	end
	return nil
end

return function(t)
	local world = Fake.world()
	world.studio = false
	world.load("src/server/main.server")
	local storage = world.service("ReplicatedStorage")
	t.equal("a public server is the lobby", storage:GetAttribute("ServerMode"), "Lobby")
	t.check("the lobby room is built", world.workspace:FindFirstChild("Lobby") ~= nil)
	t.check("the hotel is NOT built in the lobby", world.workspace:FindFirstChild("Hotel") == nil)

	local me = world.addPlayer("Marco", 1)
	world.setLocal(me)
	world.load("src/client/main.client")
	local function step(seconds: number)
		for _ = 1, math.floor(seconds / 0.1 + 0.5) do
			world.advance(0.1)
			world.render(0.1)
		end
	end
	step(0.5)

	local menu = me.PlayerGui:FindFirstChild("NightShiftMenu")
	t.check("the title menu is on screen", menu ~= nil)
	if not menu then
		return
	end
	t.check("it shows the game's name", buttonText(menu, Config.GameName) ~= nil)
	t.check(
		"PLAY, OPTIONS and INFO are there",
		buttonText(menu, "PLAY") and buttonText(menu, "OPTIONS") and buttonText(menu, "INFO")
	)
	t.check("SHOP is there too", buttonText(menu, "SHOP") ~= nil)
	t.check("the match HUD is not started in the lobby", me.PlayerGui:FindFirstChild("NightShiftHud") == nil)

	-- the lobby lamps flicker: they dip to nearly dark at times and are back to full between bursts
	local lamps = world.service("CollectionService"):GetTagged("LobbyLamp")
	t.check("the lobby has plenty of lamps", #lamps >= 10)
	local lowest, highest = math.huge, 0
	for _ = 1, 300 do
		step(0.1)
		for _, lamp in lamps do
			local light = lamp:FindFirstChildOfClass("PointLight")
			if light then
				lowest = math.min(lowest, light.Brightness)
				highest = math.max(highest, light.Brightness)
			end
		end
	end
	t.check("a lamp dips to nearly dark", lowest < 0.1, `{lowest}`)
	t.check("and shines at full between bursts", highest > 0.65, `{highest}`)

	-- play: quick play puts you in a party and the status follows the clock
	buttonText(menu, "PLAY").Activated:Fire()
	step(0.5)
	buttonText(menu, "QUICK PLAY").Activated:Fire()
	step(1)
	t.check("quick play joined a party", labelContaining(menu, "need 3 more. Starting in") ~= nil)
	step(10)
	local before = labelContaining(menu, "Starting in")
	t.check("the countdown is running", before ~= nil and not string.find(before.Text, "in 30s", 1, true))

	-- leaving
	buttonText(menu, "LEAVE PARTY").Activated:Fire()
	step(1)
	t.check("leaving clears the party status", labelContaining(menu, "Not in a party") ~= nil)

	-- the shop: cosmetics only, ids not set yet so it says coming soon
	buttonText(menu, "SHOP").Activated:Fire()
	step(0.3)
	t.check("the shop says it is cosmetics only", labelContaining(menu, "Cosmetics only") ~= nil)
	t.check(
		"the pass and the tips packs are listed",
		labelContaining(menu, "Starlight Collection") ~= nil and labelContaining(menu, "Chest of Tips") ~= nil
	)
	t.check("unset ids read COMING SOON", buttonText(menu, "COMING SOON") ~= nil)
	buttonText(menu, "COMING SOON").Activated:Fire()
	step(0.5)
	t.check("pressing it answers coming soon", labelContaining(menu, "Coming soon") ~= nil)

	-- options
	buttonText(menu, "OPTIONS").Activated:Fire()
	step(0.3)
	t.check("volume starts at 100%", labelContaining(menu, "VOLUME  100%") ~= nil)
	local minus = nil
	for _, d in menu:GetDescendants() do
		if d:IsA("TextButton") and d.Text == "-" and d.Parent and d.Parent.Visible then
			minus = d
		end
	end
	t.check("a volume button exists", minus ~= nil)
	if minus then
		minus.Activated:Fire()
		step(0.2)
		t.check("volume drops by a tenth", labelContaining(menu, "VOLUME  90%") ~= nil)
	end
	buttonText(menu, "SUBTITLES: ON").Activated:Fire()
	step(0.2)
	t.check("subtitles can be turned off", buttonText(menu, "SUBTITLES: OFF") ~= nil)

	-- a launch: a party of one is full at once, so it goes after 5 s with the loading screen up
	buttonText(menu, "PLAY").Activated:Fire()
	step(0.5)
	local transit = me.PlayerGui:FindFirstChild("NightShiftTransit")
	t.check("the transit screen starts hidden", transit ~= nil and not transit.Enabled)
	-- shrink the wanted size to 1 (default 4 minus three)
	for _ = 1, 3 do
		for _, d in menu:GetDescendants() do
			if d:IsA("TextButton") and d.Text == "-" and d.Position.X.Scale < 0.1 then
				d.Activated:Fire()
				step(0.3)
			end
		end
	end
	buttonText(menu, "CREATE PARTY").Activated:Fire()
	step(7)
	t.check("a launch shows the entering-the-hotel screen", transit ~= nil and transit.Enabled)
	t.check("which is handed to the teleport", world.teleportGui ~= nil)
	t.equal("and the party really is teleported to its own server", #world.teleports, 1)
end
