--!strict
-- Who is a Saboteur. Pure logic: the random source is injected so tests can control it.

export type Role = "Crew" | "Saboteur"

local Roles = {}

-- 1 saboteur for 2-8 players, 2 for 9+, none when playing alone (Studio test).
function Roles.saboteurCount(playerCount: number): number
	if playerCount < 2 then
		return 0
	end
	if playerCount >= 9 then
		return 2
	end
	return 1
end

-- `random(n)` must return an integer in 1..n. Returns a map userId -> role.
function Roles.assign(userIds: { number }, random: (number) -> number): { [number]: Role }
	local order = table.clone(userIds)
	for i = #order, 2, -1 do
		local j = random(i)
		order[i], order[j] = order[j], order[i]
	end
	local saboteurs = Roles.saboteurCount(#order)
	local roles: { [number]: Role } = {}
	for index, userId in order do
		roles[userId] = if index <= saboteurs then "Saboteur" else "Crew"
	end
	return roles
end

return Roles
