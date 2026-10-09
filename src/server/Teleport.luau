--!strict
-- The two trips in the game, with retries: lobby -> a party's private match server, and match -> back to the public lobby.
local TeleportService = game:GetService("TeleportService")

local TRIES = 3

local Teleport = {}

local function attempt(label: string, fn: () -> ()): boolean
	for tryNumber = 1, TRIES do
		local ok, err = pcall(fn :: () -> any)
		if ok then
			return true
		end
		warn(`[Teleport] {label} attempt {tryNumber} failed: {err}`)
		task.wait(1)
	end
	return false
end

-- A fresh reserved server for exactly these players.
function Teleport.toMatch(players: { Player }): boolean
	return attempt("match", function()
		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = TeleportService:ReserveServer(game.PlaceId)
		options:SetTeleportData({ size = #players })
		TeleportService:TeleportAsync(game.PlaceId, players, options)
	end)
end

-- Back to a public lobby server (no reserved code: Roblox picks one).
function Teleport.toLobby(players: { Player }): boolean
	return attempt("lobby", function()
		TeleportService:TeleportAsync(game.PlaceId, players)
	end)
end

return Teleport
