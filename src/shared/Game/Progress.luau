--!strict
-- A player's saved progress and how a night changes it. Pure rules: no DataStore here, so everything is testable.
-- Cosmetics are the only thing progression unlocks (see Cosmetics); nothing here changes how a round plays.
local Progress = {}

export type Profile = {
	version: number,
	xp: number,
	nights: number,
	wins: number,
	survived: number,
	tasks: number,
	streak: number, -- nights survived in a row
	bestStreak: number,
	tipsEarned: number, -- tips only ever go up here...
	tipsSpent: number, -- ...and spending only ever goes up here, so two saves merge without refunding purchases
	owned: { [string]: boolean },
	equipped: { [string]: string },
}

-- What happened to one player in one night.
export type Report = {
	role: string, -- "Crew" or "Saboteur"
	won: boolean,
	survived: boolean,
	tasks: number, -- tasks this player finished
}

export type Award = { xp: number, tips: number }

Progress.VERSION = 1

-- The tips you can spend right now.
function Progress.tips(profile: Profile): number
	return profile.tipsEarned - profile.tipsSpent
end

function Progress.new(): Profile
	return {
		version = Progress.VERSION,
		xp = 0,
		nights = 0,
		wins = 0,
		survived = 0,
		tasks = 0,
		streak = 0,
		bestStreak = 0,
		tipsEarned = 0,
		tipsSpent = 0,
		owned = {},
		equipped = {},
	}
end

-- Level 1 starts at 0 xp; each level needs a bit more than the last (100, 160, 220, ...).
function Progress.xpForLevel(level: number): number
	local total = 0
	for l = 1, level - 1 do
		total += 100 + (l - 1) * 60
	end
	return total
end

function Progress.levelFor(xp: number): number
	local level = 1
	while Progress.xpForLevel(level + 1) <= xp do
		level += 1
	end
	return level
end

-- The reward for a night. Tasks count up to 6 so one lucky run cannot snowball.
function Progress.award(report: Report): Award
	local xp = 20
	if report.survived then
		xp += 25
	end
	if report.won then
		xp += 40
	end
	xp += math.min(report.tasks, 6) * 8
	local tips = math.floor(xp / 3) + (if report.won then 15 else 0)
	return { xp = xp, tips = tips }
end

-- Applies a night to a profile. Returns the award so the UI can show it.
function Progress.apply(profile: Profile, report: Report): Award
	local award = Progress.award(report)
	profile.xp += award.xp
	profile.tipsEarned += award.tips
	profile.nights += 1
	profile.tasks += report.tasks
	if report.won then
		profile.wins += 1
	end
	if report.survived then
		profile.survived += 1
		profile.streak += 1
		profile.bestStreak = math.max(profile.bestStreak, profile.streak)
	else
		profile.streak = 0
	end
	return award
end

-- Two copies of the same profile (an older save and a newer one, e.g. from two servers) become one that never
-- loses progress: counters take the larger value, owned items are the union.
function Progress.merge(a: Profile, b: Profile): Profile
	local out = Progress.new()
	for _, key in { "xp", "nights", "wins", "survived", "tasks", "bestStreak", "tipsEarned", "tipsSpent" } do
		(out :: any)[key] = math.max((a :: any)[key] or 0, (b :: any)[key] or 0)
	end
	out.streak = b.streak
	for id in a.owned do
		out.owned[id] = true
	end
	for id in b.owned do
		out.owned[id] = true
	end
	for slot, id in a.equipped do
		out.equipped[slot] = id
	end
	for slot, id in b.equipped do
		out.equipped[slot] = id
	end
	return out
end

-- Fills in anything missing from an older or damaged save.
function Progress.repair(raw: any): Profile
	local profile = Progress.new()
	if typeof(raw) ~= "table" then
		return profile
	end
	for _, key in { "xp", "nights", "wins", "survived", "tasks", "streak", "bestStreak", "tipsEarned", "tipsSpent" } do
		local v = raw[key]
		if typeof(v) == "number" and v >= 0 and v == v then
			(profile :: any)[key] = v
		end
	end
	if typeof(raw.owned) == "table" then
		for id, has in raw.owned do
			if typeof(id) == "string" and has == true then
				profile.owned[id] = true
			end
		end
	end
	if typeof(raw.equipped) == "table" then
		for slot, id in raw.equipped do
			if typeof(slot) == "string" and typeof(id) == "string" then
				profile.equipped[slot] = id
			end
		end
	end
	profile.tipsSpent = math.min(profile.tipsSpent, profile.tipsEarned) -- never negative tips
	return profile
end

return Progress
