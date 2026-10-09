--!strict
-- The lobby's parties and their queue clock, as pure logic (the server only feeds it joins, leaves and time).
-- A party is created with a size (how many people the leader wants). Its queue counts down from `QueueSeconds`;
-- once the party is full the clock drops to `FullSeconds` (there is no point waiting for people who are already here).
-- When the clock reaches zero the party launches with whoever is in it.

export type Settings = { MaxSize: number, QueueSeconds: number, FullSeconds: number }
export type Party = {
	id: number,
	leader: number,
	size: number,
	members: { number },
	timeLeft: number,
}
export type Launch = { id: number, members: { number } }
export type View = {
	id: number,
	leader: number,
	size: number,
	count: number,
	members: { number },
	timeLeft: number,
	full: boolean,
}

local Lobby = {}
Lobby.__index = Lobby

export type Lobby = typeof(setmetatable(
	{} :: { settings: Settings, parties: { [number]: Party }, byUser: { [number]: number }, nextId: number },
	Lobby
))

function Lobby.new(settings: Settings): Lobby
	return setmetatable({ settings = settings, parties = {}, byUser = {}, nextId = 1 }, Lobby)
end

local function isFull(party: Party): boolean
	return #party.members >= party.size
end

-- Whoever was just added may have filled the party: the clock never runs longer than FullSeconds from then on.
local function settle(self: Lobby, party: Party)
	if isFull(party) then
		party.timeLeft = math.min(party.timeLeft, self.settings.FullSeconds)
	end
end

function Lobby.partyOf(self: Lobby, userId: number): Party?
	local id = self.byUser[userId]
	return if id then self.parties[id] else nil
end

-- Returns the new party, or nil and the reason.
function Lobby.create(self: Lobby, userId: number, size: number): (Party?, string?)
	if self.byUser[userId] then
		return nil, "already in a party"
	end
	local clamped = math.clamp(math.floor(size), 1, self.settings.MaxSize)
	local party: Party = {
		id = self.nextId,
		leader = userId,
		size = clamped,
		members = { userId },
		timeLeft = self.settings.QueueSeconds,
	}
	self.nextId += 1
	self.parties[party.id] = party
	self.byUser[userId] = party.id
	settle(self, party)
	return party, nil
end

function Lobby.join(self: Lobby, userId: number, partyId: number): (boolean, string?)
	if self.byUser[userId] then
		return false, "already in a party"
	end
	local party = self.parties[partyId]
	if not party then
		return false, "that party is gone"
	end
	if isFull(party) then
		return false, "that party is full"
	end
	table.insert(party.members, userId)
	self.byUser[userId] = party.id
	settle(self, party)
	return true, nil
end

function Lobby.leave(self: Lobby, userId: number)
	local party = self:partyOf(userId)
	if not party then
		return
	end
	self.byUser[userId] = nil
	local at = table.find(party.members, userId)
	if at then
		table.remove(party.members, at)
	end
	if #party.members == 0 then
		self.parties[party.id] = nil
	elseif party.leader == userId then
		party.leader = party.members[1]
	end
end

-- Quick Play: the fullest open party (so players are not scattered), otherwise a fresh party of `size`.
function Lobby.quickPlay(self: Lobby, userId: number, size: number): (Party?, string?)
	if self.byUser[userId] then
		return nil, "already in a party"
	end
	local best: Party? = nil
	for _, party in self.parties do
		if
			not isFull(party)
			and (not best or #party.members > #best.members or (#party.members == #best.members and party.id < best.id))
		then
			best = party
		end
	end
	if best then
		self:join(userId, best.id)
		return best, nil
	end
	return self:create(userId, size)
end

-- Advance every queue by `dt`. Parties whose clock ran out are removed and returned, ready to launch.
function Lobby.tick(self: Lobby, dt: number): { Launch }
	local launches: { Launch } = {}
	for id, party in self.parties do
		party.timeLeft -= dt
		if party.timeLeft <= 0 then
			table.insert(launches, { id = id, members = table.clone(party.members) })
		end
	end
	for _, launch in launches do
		for _, userId in launch.members do
			self.byUser[userId] = nil
		end
		self.parties[launch.id] = nil
	end
	table.sort(launches, function(a, b)
		return a.id < b.id
	end)
	return launches
end

-- A copy safe to send to clients, oldest party first.
function Lobby.view(self: Lobby): { View }
	local list: { View } = {}
	for _, party in self.parties do
		table.insert(list, {
			id = party.id,
			leader = party.leader,
			size = party.size,
			count = #party.members,
			members = table.clone(party.members),
			timeLeft = math.max(0, party.timeLeft),
			full = isFull(party),
		})
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return list
end

return Lobby
