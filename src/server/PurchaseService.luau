--!strict
-- Robux purchases: game passes (checked when a player joins and when one is bought) and developer products (tips packs,
-- granted from the receipt). Everything sold is cosmetic (see Shared/Game/Store). A purchase is only acknowledged to
-- Roblox once it is SAVED, so a failed save makes Roblox retry the receipt instead of the player losing what they paid for.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Store = require(ReplicatedStorage.Shared.Game.Store)
local ProfileService = require(script.Parent.ProfileService)

local PurchaseService = {}

local catalog = Config.Monetization :: Store.Catalog

local function grantOwnedPasses(player: Player)
	local profile = ProfileService.profileOf(player)
	if not profile then
		return
	end
	local changed = false
	for key, pass in catalog.Passes do
		if pass.id ~= 0 and not profile.passes[key] then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and owns and Store.grantPass(profile, key) then
				changed = true
			end
		end
	end
	if changed then
		ProfileService.commit(player)
	end
end

-- `override` lets a test sell things with real-looking ids (the shipped catalogue keeps 0 until Creator Hub ids exist).
function PurchaseService.start(remotes: Instance, override: Store.Catalog?)
	if override then
		catalog = override
	end
	local buy = Instance.new("RemoteEvent")
	buy.Name = "Buy"
	buy.Parent = remotes
	local notice = Instance.new("RemoteEvent")
	notice.Name = "ShopNotice"
	notice.Parent = remotes
	local last: { [Player]: number } = {}

	-- the client asks to buy something by KEY; the server maps it to the real id (a client never sends an id)
	buy.OnServerEvent:Connect(function(player: Player, kind: any, key: any)
		if typeof(kind) ~= "string" or typeof(key) ~= "string" then
			return
		end
		local now = os.clock()
		if now - (last[player] or 0) < 1 then
			return
		end
		last[player] = now
		if kind == "pass" then
			local pass = catalog.Passes[key]
			if not pass then
				return
			end
			if pass.id == 0 then
				notice:FireClient(player, "Coming soon")
			else
				MarketplaceService:PromptGamePassPurchase(player, pass.id)
			end
		elseif kind == "product" then
			local product = catalog.Products[key]
			if not product then
				return
			end
			if product.id == 0 then
				notice:FireClient(player, "Coming soon")
			else
				MarketplaceService:PromptProductPurchase(player, product.id)
			end
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, passId: number, purchased: boolean)
			local profile = ProfileService.profileOf(player)
			local key = Store.passKey(catalog, passId)
			if purchased and profile and key and Store.grantPass(profile, key) then
				ProfileService.commit(player)
			end
		end
	)

	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		local profile = player and ProfileService.profileOf(player)
		if not player or not profile then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local outcome = Store.grantProduct(catalog, profile, info.ProductId, tostring(info.PurchaseId))
		if outcome == "unknown" then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if outcome == "granted" and not ProfileService.commit(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	Players.PlayerAdded:Connect(function(player)
		task.delay(3, grantOwnedPasses, player) -- after the profile has loaded
	end)
	for _, player in Players:GetPlayers() do
		task.delay(3, grantOwnedPasses, player)
	end
end

return PurchaseService
