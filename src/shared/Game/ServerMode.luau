--!strict
-- Which job this server does. The same place file runs as the public Lobby (parties form here) and as a Match
-- (a private server reserved for one party). Pure: the caller passes what Roblox says about the server.

export type Mode = "Lobby" | "Match"

local ServerMode = {}

-- A reserved server has a PrivateServerId and no owner; a VIP server has both and is just a lobby for friends.
function ServerMode.detect(
	privateServerId: string,
	privateServerOwnerId: number,
	studio: boolean,
	studioMode: string
): Mode
	if studio then
		return if studioMode == "Lobby" then "Lobby" else "Match"
	end
	if privateServerId ~= "" and privateServerOwnerId == 0 then
		return "Match"
	end
	return "Lobby"
end

return ServerMode
