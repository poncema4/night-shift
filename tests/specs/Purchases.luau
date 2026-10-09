--!strict
-- Robux purchases through the real server: a tips pack is granted from its receipt exactly once (replays pay nothing),
-- an owned game pass is found on join and unlocks cosmetics, the client can only ask by key, and an unset id says
-- "coming soon" instead of prompting a wrong purchase.
local Fake = require("../fake/Roblox")
local Progress = require("../../src/shared/Game/Progress")

return function(t)
	local world = Fake.world()
	local storage = world.service("ReplicatedStorage")
	local market = world.service("MarketplaceService")
	world.load("src/server/RoundService").start()
	local profiles = world.load("src/server/ProfileService")
	local remotes = storage:FindFirstChild("Remotes")
	local catalog = {
		Passes = { starlight = { id = 111, name = "S", blurb = "", robux = 299 } },
		Products = { small = { id = 222, name = "P", tips = 250, robux = 49 } },
	}
	world.load("src/server/PurchaseService").start(remotes, catalog)

	market.owned["88:111"] = true
	local owner = world.addPlayer("Owner", 88)
	local buyer = world.addPlayer("Buyer", 77)
	world.advance(4)
	t.check(
		"a pass bought earlier is found on join",
		(profiles.profileOf(owner) :: Progress.Profile).passes.starlight == true
	)
	t.check(
		"a player without it does not get it",
		(profiles.profileOf(buyer) :: Progress.Profile).passes.starlight == nil
	)

	-- a receipt
	local granted = world.enum.ProductPurchaseDecision.PurchaseGranted
	local function receipt(purchaseId: string, productId: number)
		return market.ProcessReceipt({ PlayerId = 77, ProductId = productId, PurchaseId = purchaseId })
	end
	t.equal("a real receipt is granted", receipt("p1", 222), granted)
	t.equal("and adds the tips", Progress.tips(profiles.profileOf(buyer) :: Progress.Profile), 250)
	t.equal("Roblox replaying the receipt is acknowledged", receipt("p1", 222), granted)
	t.equal("but pays nothing again", Progress.tips(profiles.profileOf(buyer) :: Progress.Profile), 250)
	t.equal(
		"a different purchase pays again",
		receipt("p2", 222) == granted and Progress.tips(profiles.profileOf(buyer) :: Progress.Profile),
		500
	)
	local retry = world.enum.ProductPurchaseDecision.NotProcessedYet
	t.equal("an unknown product is not acknowledged (Roblox retries)", receipt("p3", 999), retry)
	t.equal(
		"a receipt for someone not in the server is not acknowledged",
		market.ProcessReceipt({ PlayerId = 5, ProductId = 222, PurchaseId = "p4" }),
		retry
	)

	-- a pass bought now
	world.setLocal(buyer)
	market.PromptGamePassPurchaseFinished:Fire(buyer, 111, false)
	t.check(
		"cancelling the prompt grants nothing",
		(profiles.profileOf(buyer) :: Progress.Profile).passes.starlight == nil
	)
	market.PromptGamePassPurchaseFinished:Fire(buyer, 111, true)
	t.check("buying the pass unlocks it", (profiles.profileOf(buyer) :: Progress.Profile).passes.starlight == true)
	market.PromptGamePassPurchaseFinished:Fire(buyer, 999, true)
	t.check("an unknown pass id unlocks nothing", (profiles.profileOf(buyer) :: Progress.Profile).passes.nope == nil)

	-- the client asks by key and cannot name an id
	local buy = remotes:FindFirstChild("Buy")
	world.advance(1.1)
	buy:FireServer("pass", "starlight")
	t.check("asking for a pass prompts the real pass id", #market.prompts == 1 and market.prompts[1].id == 111)
	world.advance(1.1)
	buy:FireServer("product", 222)
	buy:FireServer("product", "no_such_pack")
	t.equal("a raw id or an unknown key prompts nothing", #market.prompts, 1)
	world.advance(1.1)
	buy:FireServer("product", "small")
	t.check("a product key prompts the real product id", #market.prompts == 2 and market.prompts[2].id == 222)

	-- the shipped catalogue has unset ids: coming soon, never a prompt
	local fresh = Fake.world()
	fresh.load("src/server/RoundService").start()
	local freshMarket = fresh.service("MarketplaceService")
	fresh.load("src/server/PurchaseService").start(fresh.service("ReplicatedStorage"):FindFirstChild("Remotes"))
	local someone = fresh.addPlayer("Someone", 3)
	fresh.setLocal(someone)
	fresh.advance(1.1)
	fresh.service("ReplicatedStorage"):FindFirstChild("Remotes"):FindFirstChild("Buy"):FireServer("pass", "starlight")
	t.equal("an unset id never prompts", #freshMarket.prompts, 0)
	local said = false
	for _, entry in fresh.log do
		if entry.remote == "ShopNotice" and entry.args[2] == "Coming soon" then
			said = true
		end
	end
	t.check("it says coming soon", said)
end
