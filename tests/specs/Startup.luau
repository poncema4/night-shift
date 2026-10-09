--!strict
-- Runs the real server code against the fake Roblox world (tests/fake/Roblox): the whole hotel is built, every
-- prop is made, and RoundService.start() wires every service. This catches runtime errors the type-checker cannot
-- (a nil index, a wrong call) and checks that every remote the client waits for really exists.
local Fake = require("../fake/Roblox")
local Furnishing = require("../../src/shared/Game/Furnishing")
local Building = require("../../src/shared/Game/Building")
local Floors = require("../../src/shared/Game/Floors")
local fs = require("@lune/fs")

return function(t)
	-- 1. the hotel builder
	local world = Fake.world()
	local builder = world.load("src/server/HotelBuilder")
	local ok, result = pcall(builder.build)
	t.check("HotelBuilder.build() runs without error", ok, tostring(result))
	if ok then
		local hotel = world.workspace:FindFirstChild("Hotel")
		t.check("the Hotel folder exists", hotel ~= nil)
		local shell = hotel and hotel:FindFirstChild("Shell")
		t.equal(
			"every solid in the tested layout becomes a part",
			shell and #shell:GetChildren() or -1,
			#Building.solids()
		)
		t.equal(
			"one station per task",
			(function()
				local n = 0
				for _ in result.stations do
					n += 1
				end
				return n
			end)(),
			#Floors.tasks()
		)

		local dressed = true
		for id, station in result.stations do
			if not station:FindFirstChild("Station_" .. id) then
				dressed = false
			end
		end
		t.check("every task station is dressed", dressed)

		local hideable = 0
		for _, item in Furnishing.items() do
			if Furnishing.hideable[item.kind] then
				hideable += 1
			end
		end
		t.equal("every locker and wardrobe is a hiding spot", #result.hiding, hideable)
		local bodies = true
		for _, spot in result.hiding do
			if not spot.model:FindFirstChild("Body") then
				bodies = false
			end
		end
		t.check("every hiding spot has the Body part the prompt attaches to", bodies)
		t.check("the reception bell exists", result.bell ~= nil)
		t.check("the lobby spawn exists", result.spawn ~= nil and result.spawn.Size.Y < 0.5)

		local sane, total = true, 0
		for _, d in hotel:GetDescendants() do
			if d:IsA("BasePart") then
				total += 1
				local s, p = d.Size, d.Position
				if not (s.X > 0 and s.Y >= 0 and s.Z > 0) or p.X ~= p.X or p.Y ~= p.Y or p.Z ~= p.Z then
					sane = false
				end
			end
		end
		t.check("every part has a positive size and a real position", sane)
		t.check("the hotel is a few thousand parts (not 50, not 50000)", total > 2000 and total < 12000, `{total}`)
		t.equal("building prints no warnings", #world.warnings, 0)
	end

	-- 2. the whole server start
	local server = Fake.world()
	local round = server.load("src/server/RoundService")
	local started, err = pcall(round.start)
	t.check("RoundService.start() wires every service without error", started, tostring(err))
	if started then
		local storage = server.service("ReplicatedStorage")
		local remotes = storage:FindFirstChild("Remotes")
		t.check("the Remotes folder exists", remotes ~= nil)
		t.check("the Night Manager state folder exists", storage:FindFirstChild("ThreatState") ~= nil)

		-- every remote a client script waits for must exist, or that client hangs forever
		-- (the menu screens belong to the lobby server, so they are checked against the lobby's remotes)
		local lobbyWorld = Fake.world()
		local lobbyRemotes = lobbyWorld.instance.new("Folder")
		lobbyWorld.load("src/server/LobbyService").start(lobbyRemotes)
		lobbyWorld.load("src/server/PurchaseService").start(lobbyRemotes)
		local lobbyFiles = { ["Menu.luau"] = true, ["PartyUi.luau"] = true, ["StoreUi.luau"] = true }
		local missing = {}
		local ignore = { PlayerGui = true, Remotes = true, ThreatState = true }
		for _, file in fs.readDir("src/client") do
			local folder = if lobbyFiles[file] then lobbyRemotes else remotes
			for name in string.gmatch(fs.readFile("src/client/" .. file), 'WaitForChild%("([%w_]+)"%)') do
				if not ignore[name] and folder and not folder:FindFirstChild(name) then
					table.insert(missing, `{file}:{name}`)
				end
			end
		end
		t.check("every remote the client waits for exists", #missing == 0, table.concat(missing, ", "))
		t.equal("starting the server prints no warnings", #server.warnings, 0)
	end
end
