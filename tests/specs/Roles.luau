--!strict
local Roles = require("../../src/shared/Game/Roles")

local function ids(n: number): { number }
	local list = {}
	for i = 1, n do
		table.insert(list, 100 + i)
	end
	return list
end

local function count(roles: { [number]: string }, which: string): number
	local c = 0
	for _, role in roles do
		if role == which then
			c += 1
		end
	end
	return c
end

return function(t)
	t.equal("alone: no saboteur", Roles.saboteurCount(1), 0)
	t.equal("2 players: co-op, no saboteur", Roles.saboteurCount(2), 0)
	t.equal("3 players: co-op, no saboteur", Roles.saboteurCount(3), 0)
	t.equal("4 players: 1 saboteur", Roles.saboteurCount(4), 1)
	t.equal("8 players: 1 saboteur", Roles.saboteurCount(8), 1)
	t.equal("9 players: 2 saboteurs", Roles.saboteurCount(9), 2)
	t.equal("10 players: 2 saboteurs", Roles.saboteurCount(10), 2)

	local always1 = function()
		return 1
	end
	for _, n in { 2, 6, 8, 9, 10 } do
		local roles = Roles.assign(ids(n), always1)
		t.equal(`{n} players: everyone gets a role`, count(roles, "Crew") + count(roles, "Saboteur"), n)
		t.equal(`{n} players: saboteur total matches saboteurCount`, count(roles, "Saboteur"), Roles.saboteurCount(n))
	end

	local input = ids(6)
	Roles.assign(input, always1)
	t.equal("assign does not reorder the caller's list", input[1], 101)

	-- The injected random source decides who is picked: different draws, different saboteur.
	local first = Roles.assign(ids(6), always1)
	local last = Roles.assign(ids(6), function(n)
		return n
	end)
	t.check("the random source changes who is the saboteur", first[101] ~= last[101] or first[106] ~= last[106])

	-- Fair shuffle: over many seeded draws every player gets picked at least once.
	local picked: { [number]: boolean } = {}
	local seed = 7
	local function lcg(n: number): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return (seed // 65536) % n + 1
	end
	for _ = 1, 200 do
		for userId, role in Roles.assign(ids(6), lcg) do
			if role == "Saboteur" then
				picked[userId] = true
			end
		end
	end
	local distinct = 0
	for _ in picked do
		distinct += 1
	end
	t.equal("every player can be the saboteur", distinct, 6)
end
