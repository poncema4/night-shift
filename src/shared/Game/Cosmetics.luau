--!strict
-- Colours are plain {r, g, b} so this stays testable outside Roblox.
-- The cosmetic catalogue and the rules for buying and wearing things. Cosmetics are purely visual: flashlight
-- colour, hats, and the colour of the footstep dust. They never change speed, noise, vision or anything else.
local Progress = require("./Progress")

local Cosmetics = {}

export type Item = {
	id: string,
	name: string,
	slot: string,
	price: number,
	level: number,
	rgb: { number }?,
	note: string?,
	pass: string?, -- owned through this game pass instead of being bought with tips
}

-- Slots: "flashlight" (beam colour), "hat" (worn on the head), "dust" (colour of footstep dust).
Cosmetics.items = {
	{
		id = "light_warm",
		name = "Warm White",
		slot = "flashlight",
		price = 0,
		level = 1,
		rgb = { 255, 244, 214 },
	},
	{
		id = "light_moon",
		name = "Moonlight",
		slot = "flashlight",
		price = 60,
		level = 2,
		rgb = { 190, 215, 255 },
	},
	{
		id = "light_ember",
		name = "Ember",
		slot = "flashlight",
		price = 120,
		level = 4,
		rgb = { 255, 150, 70 },
	},
	{
		id = "light_ghost",
		name = "Ghost Green",
		slot = "flashlight",
		price = 220,
		level = 7,
		rgb = { 150, 255, 190 },
	},
	{ id = "hat_none", name = "No Hat", slot = "hat", price = 0, level = 1 },
	{ id = "hat_bellhop", name = "Bellhop Cap", slot = "hat", price = 90, level = 3 },
	{ id = "hat_top", name = "Night Manager's Top Hat", slot = "hat", price = 200, level = 6 },
	{ id = "hat_crown", name = "Paper Crown", slot = "hat", price = 320, level = 9 },
	-- the Starlight Collection (game pass): looks only, never an advantage
	{
		id = "light_starlight",
		name = "Starlight",
		slot = "flashlight",
		price = 0,
		level = 1,
		rgb = { 200, 170, 255 },
		pass = "starlight",
	},
	{
		id = "light_crimson",
		name = "Crimson Beam",
		slot = "flashlight",
		price = 0,
		level = 1,
		rgb = { 255, 70, 90 },
		pass = "starlight",
	},
	{ id = "hat_halo", name = "Halo", slot = "hat", price = 0, level = 1, pass = "starlight" },
	{ id = "dust_none", name = "No Dust", slot = "dust", price = 0, level = 1 },
	{ id = "dust_rose", name = "Rose", slot = "dust", price = 70, level = 2, rgb = { 255, 130, 170 } },
	{ id = "dust_gold", name = "Gold", slot = "dust", price = 180, level = 5, rgb = { 255, 210, 90 } },
} :: { Item }

local byId: { [string]: Item } = {}
for _, item in Cosmetics.items do
	byId[item.id] = item
end

function Cosmetics.get(id: string): Item?
	return byId[id]
end

-- Free items are yours from the start.
function Cosmetics.owns(profile: Progress.Profile, id: string): boolean
	local item = byId[id]
	if item and item.pass then
		return profile.passes[item.pass] == true
	end
	return item ~= nil and (item.price == 0 or profile.owned[id] == true)
end

export type Outcome = "ok" | "unknown" | "owned" | "level" | "tips" | "locked"

-- Buy an item with tips. Returns why not when it fails.
function Cosmetics.buy(profile: Progress.Profile, id: string): Outcome
	local item = byId[id]
	if not item then
		return "unknown"
	end
	if Cosmetics.owns(profile, id) then
		return "owned"
	end
	if item.pass then
		return "locked" -- a pass item cannot be bought with tips
	end
	if Progress.levelFor(profile.xp) < item.level then
		return "level"
	end
	if Progress.tips(profile) < item.price then
		return "tips"
	end
	profile.tipsSpent += item.price
	profile.owned[id] = true
	return "ok"
end

-- Wear an item you own. One item per slot.
function Cosmetics.equip(profile: Progress.Profile, id: string): boolean
	local item = byId[id]
	if not item or not Cosmetics.owns(profile, id) then
		return false
	end
	profile.equipped[item.slot] = id
	return true
end

-- What a player is wearing in a slot (the free default when nothing is equipped or it is not owned).
function Cosmetics.worn(profile: Progress.Profile, slot: string): Item
	local id = profile.equipped[slot]
	if id and Cosmetics.owns(profile, id) then
		return byId[id]
	end
	local fallback = if slot == "flashlight" then "light_warm" elseif slot == "hat" then "hat_none" else "dust_none"
	return byId[fallback]
end

return Cosmetics
