--!strict
-- Progress end to end against the real server: play nights, earn XP and tips, buy and wear a cosmetic through the Shop
-- remote, leave, rejoin, and find everything saved (DataStore round trip with merge-on-save).
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
	math.randomseed(11)
	local world = Fake.world()
	local storage = world.service("ReplicatedStorage")
	world.load("src/server/RoundService").start()
	local threat = world.load("src/server/ThreatService")
	local profiles = world.load("src/server/ProfileService")
	local player = world.addPlayer("Marco", 77)

	local function untilPhase(name: string)
		local guard = 0
		while storage:GetAttribute("Phase") ~= name and guard < 2000 do
			world.advance(0.5)
			guard += 1
		end
		return guard < 2000
	end
	local function playOneNight()
		untilPhase("Night")
		threat.pause()
		for _, name in { "Reset the breaker", "Restock the minibar", "Fold the linens" } do
			local prompt = world.prompts(world.workspace, name)[1]
			world.root(player).Position = prompt.Parent.Position
			prompt.Triggered:Fire(player)
		end
		world.humanoid(player).Health = 0 -- then caught: a short night
		untilPhase("Dawn")
		world.advance(1)
		untilPhase("Lobby")
		world.advance(1)
	end

	local function lastSnapshot(): any
		local list = logged(world, "Profile", "client")
		return list[#list].args[2]
	end

	t.equal("a new player starts at level 1 with nothing", lastSnapshot().level, 1)
	for _ = 1, 6 do
		playOneNight()
	end
	local snap = lastSnapshot()
	t.equal("six nights are counted", snap.nights, 6)
	t.check("they earned XP and tips", snap.xp >= 200 and snap.tips >= 60, `xp {snap.xp} tips {snap.tips}`)
	t.check("that is enough for level 2", snap.level >= 2)

	-- the shop
	local shop = storage:FindFirstChild("Remotes"):FindFirstChild("Shop")
	shop.OnServerEvent:Fire(player, { action = "buy", id = "light_moon" })
	t.check("buying a flashlight colour works", table.find(lastSnapshot().owned, "light_moon") ~= nil)
	t.equal("a bought item is worn at once", lastSnapshot().equipped.flashlight, "light_moon")
	t.check("it cost tips", lastSnapshot().tips < snap.tips)
	local beam = profiles.flashlightColor(player)
	t.check("the beam is moonlight blue", beam.B > beam.R)
	shop.OnServerEvent:Fire(player, { action = "buy", id = "hat_crown" })
	t.check("a level-locked item cannot be bought", table.find(lastSnapshot().owned, "hat_crown") == nil) -- level 9
	shop.OnServerEvent:Fire(player, { action = "buy", id = "jetpack" })
	shop.OnServerEvent:Fire(player, { action = "equip", id = "hat_top" })
	shop.OnServerEvent:Fire(player, "garbage")
	shop.OnServerEvent:Fire(player, { action = 5, id = {} })
	t.check("junk and unowned items change nothing", lastSnapshot().equipped.hat == nil)

	-- leave and rejoin: saved
	local before = lastSnapshot()
	world.removePlayer(player)
	t.equal("leaving does not warn", #world.warnings, 0)
	local again = world.addPlayer("Marco", 77)
	world.advance(1)
	local after = lastSnapshot()
	t.equal("XP survived the rejoin", after.xp, before.xp)
	t.equal("nights survived the rejoin", after.nights, 6)
	t.check("the bought item is still owned", table.find(after.owned, "light_moon") ~= nil)
	t.equal("and still worn", after.equipped.flashlight, "light_moon")
	t.equal("tips were not refunded", after.tips, before.tips)
	local again2 = profiles.flashlightColor(again)
	t.check("the rejoined player's beam is still moonlight", again2.B > again2.R)
	t.equal("nothing warned", #world.warnings, 0)
end
