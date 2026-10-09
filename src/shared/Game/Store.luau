--!strict
-- What a purchase does to a profile. Pure: the server calls these from MarketplaceService callbacks, tests call them
-- directly. Everything sold is cosmetic: tips only buy cosmetics, and passes only unlock cosmetics.
local Cosmetics = require("./Cosmetics")
local Progress = require("./Progress")

export type Pass = { id: number, name: string, blurb: string, robux: number }
export type Product = { id: number, name: string, tips: number, robux: number }
export type Catalog = { Passes: { [string]: Pass }, Products: { [string]: Product } }

local Store = {}

-- The pass or product key for a Roblox id (nil for an unknown or unset id).
function Store.passKey(catalog: Catalog, id: number): string?
	for key, pass in catalog.Passes do
		if pass.id ~= 0 and pass.id == id then
			return key
		end
	end
	return nil
end

function Store.productKey(catalog: Catalog, id: number): string?
	for key, product in catalog.Products do
		if product.id ~= 0 and product.id == id then
			return key
		end
	end
	return nil
end

-- Owning a pass unlocks everything gated behind it (the items read the pass at look-up time, so nothing else to copy).
function Store.grantPass(profile: Progress.Profile, key: string): boolean
	if profile.passes[key] then
		return false
	end
	profile.passes[key] = true
	return true
end

export type Outcome = "granted" | "duplicate" | "unknown"

-- A developer-product receipt: tips are added once per receipt id, however many times Roblox replays it.
function Store.grantProduct(catalog: Catalog, profile: Progress.Profile, productId: number, receiptId: string): Outcome
	local key = Store.productKey(catalog, productId)
	local product = if key then catalog.Products[key] else nil
	if not product then
		return "unknown"
	end
	if profile.receipts[receiptId] then
		return "duplicate"
	end
	profile.receipts[receiptId] = true
	profile.tipsEarned += product.tips
	return "granted"
end

-- Every pass item in the catalogue belongs to a pass that can actually be sold (a typo would orphan it).
function Store.orphanItems(catalog: Catalog): { string }
	local orphans = {}
	for _, item in Cosmetics.items do
		if item.pass and not catalog.Passes[item.pass] then
			table.insert(orphans, item.id)
		end
	end
	return orphans
end

return Store
