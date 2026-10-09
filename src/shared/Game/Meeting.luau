--!strict
-- Counting a vote. Plain rules so they can be tested: only living players vote, once each; the most-voted player
-- is ejected only if they have strictly more votes than "skip" and no one else shares the top count.
local Meeting = {}

export type Result = {
	ejected: number?, -- user id, or nil when no one is ejected
	counts: { [number]: number },
	skips: number,
	tie: boolean,
	voted: number,
}

-- `votes` maps voter -> target user id, or false to skip. `alive` lists the user ids still in the game.
function Meeting.tally(votes: { [number]: number | boolean }, alive: { number }): Result
	local isAlive: { [number]: boolean } = {}
	for _, id in alive do
		isAlive[id] = true
	end
	local counts: { [number]: number } = {}
	local skips, voted = 0, 0
	for voter, target in votes do
		if isAlive[voter] then
			if typeof(target) == "number" and isAlive[target] then
				counts[target] = (counts[target] or 0) + 1
				voted += 1
			elseif target == false then
				skips += 1
				voted += 1
			end
		end
	end
	local top, topCount, tie = nil, 0, false
	for id, n in counts do
		if n > topCount then
			top, topCount, tie = id, n, false
		elseif n == topCount then
			tie = true
		end
	end
	local ejected = if top and not tie and topCount > skips then top else nil
	return { ejected = ejected, counts = counts, skips = skips, tie = tie, voted = voted }
end

-- Everyone alive has voted: the meeting can end early.
function Meeting.complete(votes: { [number]: number | boolean }, alive: { number }): boolean
	for _, id in alive do
		if votes[id] == nil then
			return false
		end
	end
	return true
end

return Meeting
