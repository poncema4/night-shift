--!strict
local Party = require("../../src/shared/Game/Party")
local ServerMode = require("../../src/shared/Game/ServerMode")

local SETTINGS = { MaxSize = 8, QueueSeconds = 30, FullSeconds = 5 }

return function(t)
	-- creating
	local lobby = Party.new(SETTINGS)
	local p = lobby:create(1, 4)
	t.check("create: party exists", p ~= nil)
	t.equal("create: leader is a member", p and p.members[1], 1)
	t.equal("create: starts at the full queue time", p and p.timeLeft, 30)
	local again, why = lobby:create(1, 4)
	t.check("create: one party per player", again == nil and why == "already in a party")
	t.equal("create: size is capped", (lobby:create(2, 99) :: Party.Party).size, 8)
	t.equal("create: size at least one", (lobby:create(3, 0) :: Party.Party).size, 1)
	t.equal(
		"create: a party of one is full at once, so it launches fast",
		(lobby:partyOf(3) :: Party.Party).timeLeft,
		5
	)

	-- joining and the 5 second rule
	local q = Party.new(SETTINGS)
	local party = q:create(10, 4) :: Party.Party
	q:tick(12) -- 18 s left
	q:join(11, party.id)
	q:join(12, party.id)
	t.equal("not full: the clock keeps running", party.timeLeft, 18)
	local ok = q:join(13, party.id)
	t.check("the last seat fills the party", ok)
	t.equal("full: clock drops to 5 s", party.timeLeft, 5)
	local late = q:join(14, party.id)
	t.check("full party refuses more", not late)

	-- a clock already below 5 s is never lengthened
	local r = Party.new(SETTINGS)
	local quick = r:create(20, 2) :: Party.Party
	r:tick(28) -- 2 s left
	r:join(21, quick.id)
	t.equal("full with 2 s left stays 2 s", quick.timeLeft, 2)

	-- launching
	local l = Party.new(SETTINGS)
	local a = l:create(30, 4) :: Party.Party
	l:join(31, a.id)
	t.equal("nothing launches early", #l:tick(29), 0)
	local out = l:tick(1.5)
	t.equal("launches when the clock runs out", #out, 1)
	t.equal("launches with whoever is there", #out[1].members, 2)
	t.check("a launched party is gone", l:partyOf(30) == nil and l:partyOf(31) == nil)
	t.check("launched players can queue again", l:create(30, 4) ~= nil)

	-- full parties launch after 5 s, not 30
	local f = Party.new(SETTINGS)
	local g = f:create(40, 3) :: Party.Party
	f:join(41, g.id)
	f:join(42, g.id)
	t.equal("full party: nothing at 4 s", #f:tick(4), 0)
	t.equal("full party: launches at 5 s", #f:tick(1), 1)

	-- leaving
	local m = Party.new(SETTINGS)
	local h = m:create(50, 4) :: Party.Party
	m:join(51, h.id)
	m:leave(50)
	t.equal("leader leaves: next member leads", h.leader, 51)
	m:leave(51)
	t.equal("last member leaves: party disbands", #m:view(), 0)
	m:leave(99) -- not in a party: harmless
	t.check("leaving while alone is harmless", true)

	-- quick play
	local qp = Party.new(SETTINGS)
	local first = qp:quickPlay(60, 4) :: Party.Party
	local second = qp:quickPlay(61, 4) :: Party.Party
	t.equal("quick play: joins the open party", second.id, first.id)
	qp:create(62, 4)
	qp:create(63, 4)
	qp:join(64, (qp:partyOf(63) :: Party.Party).id)
	qp:join(66, (qp:partyOf(63) :: Party.Party).id)
	local third = qp:quickPlay(65, 4) :: Party.Party
	t.equal("quick play: prefers the fullest party", third.id, (qp:partyOf(63) :: Party.Party).id)
	local solo = Party.new(SETTINGS)
	local fresh = solo:quickPlay(70, 3) :: Party.Party
	t.equal("quick play with no party creates one of the asked size", fresh.size, 3)

	-- view
	local v = Party.new(SETTINGS)
	v:create(80, 2)
	local view = v:view()
	t.equal("view: one entry", #view, 1)
	t.equal("view: shows the count", view[1].count, 1)
	t.check("view: not full yet", not view[1].full)
	t.equal("view: lists who is in it", view[1].members[1], 80)

	-- server mode
	t.equal("mode: public server is the lobby", ServerMode.detect("", 0, false, "Match"), "Lobby")
	t.equal("mode: reserved server is a match", ServerMode.detect("abc", 0, false, "Lobby"), "Match")
	t.equal("mode: VIP server is a lobby", ServerMode.detect("abc", 123, false, "Match"), "Lobby")
	t.equal("mode: Studio uses the setting", ServerMode.detect("", 0, true, "Match"), "Match")
	t.equal("mode: Studio can preview the lobby", ServerMode.detect("", 0, true, "Lobby"), "Lobby")
end
