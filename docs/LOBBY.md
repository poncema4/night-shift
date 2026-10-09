# Lobby, parties and matches

One published place runs in two jobs (`Shared/Game/ServerMode`):

- **Lobby** (a normal public server). Players land in a small waiting hall (`server/LobbyBuilder`), see the title menu
  (`client/Menu`: PLAY / OPTIONS / INFO) and form parties (`client/PartyUi`, rules in `Shared/Game/Party`).
- **Match** (a reserved server, one per party). The hotel is built and the round runs (`server/RoundService`).

## The queue
- A party is created with a size 1..8 (any size). Its clock starts at 30 s (`Config.Lobby.QueueSeconds`).
- When the party is full the clock drops to 5 s (`FullSeconds`); it is never lengthened.
- At zero the party launches with whoever is in it: `LobbyService` reserves a server and `TeleportAsync`s them.
- Quick Play joins the fullest open party, or makes one of 4.
- Players see their own loading screen ("ENTERING THE HOTEL" + a tip) through the teleport (`SetTeleportGui`),
  after the studio-logo loading screen on first join (`src/first/Loading.client.luau`).

## Co-op
Fewer than 4 players = co-op (`Roles.COOP_BELOW`): nobody is a saboteur, a phantom is counted so only a wiped-out crew
loses, and finishing the tasks wins. 4 or more: one saboteur (two at 9+).

## He gets faster
Every task the crew finishes raises his speed up to 1.4x (`Shared/Game/Escalation`). A subtitle warns at half-way and the
heartbeat quickens. This is the "how did it get faster" moment that TikTok horror clips are built on.

## Testing in Studio
- Studio is not a real server, so `Config.Server.StudioMode` chooses what Play shows: `"Match"` (the round, default) or
  `"Lobby"` (the party screen; launching prints a line instead of teleporting).
- The world looks empty in edit mode on purpose: the server builds the hotel (or lobby) from code when you press Play, so
  every change is picked up automatically. Rojo only syncs scripts.
- Real teleports need the place published (Creator Hub) and at least two servers: test with the Local Server option or
  after publishing a private version.

## Not done yet
- Cross-server queue (parties on different lobby servers cannot merge): needs MemoryStoreService.
- Options are not saved between sessions (they live in memory; a saved copy belongs in the profile).
