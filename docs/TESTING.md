# What is tested, and how

Four layers, from fastest to slowest to get:

1. **Pure rules** (`src/shared/Game`): round machine, roles, votes, stamina, battery, stealth, scares, abilities, cameras, progress, cosmetics, geometry, routing. `lune run tests/run`, milliseconds, run by CI.
2. **Type-check** (`scripts/typecheck.sh`): every file against Roblox's real API with luau-lsp (wrong property names, optional values, mixed-type arrays, a statement glued to the previous line...). CI runs it.
3. **Fake Roblox world** (`tests/fake/Roblox.luau`, specs `Startup`, `Night`, `Social`): the REAL server scripts run against a small stand-in for Instance, Vector3, CFrame, services, a clock and a scheduler, with fake players that have characters and humanoids.
   - `Startup`: the whole hotel is built (thousands of parts, all props, all stations), `RoundService.start()` wires every service, and every remote the client scripts wait for really exists.
   - `Night`: a solo night: round loop, role, sprint and stamina, flashlight, a task, hiding, cameras, the bell and a meeting, a death, the dawn report, rewards, the next round.
   - `Client`: the real CLIENT scripts (HUD, controls, meeting screen, results, locker, cameras, spectating, the Night Manager view) run in the same world, connected to the server by the same remotes: buttons reach the server, server messages reach the screens.
   - `Social`: four players: abilities and cooldowns, blackouts on the right floor, scares, hiding versus the Night Manager (passing by, then being hunted), two meetings (a tie, then a majority that ejects the saboteur), the crew wins.
4. **Studio playtest** (`docs/PLAYTEST.md`): the only layer that checks how it LOOKS and FEELS.

## What layer 3 does not prove
It is a simplified model: no physics, no rendering, no real network, no real Humanoid movement (tests set `MoveDirection` by hand), `CFrame` rotation order is approximate. It proves the server logic is wired and behaves; it does not prove the stairs feel smooth, the lighting looks scary, or a phone can reach a button.

## Bugs this layer found
- Blackouts darkened the wrong floors (bulbs at y = 13.7 round to "level 1" by height; lights now carry an explicit `Level`).
- Hiding made you almost unbeatable (he never lingered next to a locker, so the search timer could not fill): now someone he was hunting who hides is searched for.
- Two players in a Studio test ended the night instantly (one crew vs one saboteur); fewer than 3 players now runs as a sandbox.
- Hiding did not freeze you until the next frame.

- **The meeting screen would never have appeared**: the client closed it whenever the phase attribute was not "Meeting", but the server updated that attribute half a second after sending "meeting started". Same race on the dawn screen. The server now publishes first and the screens tolerate a late attribute.
- **RUN and LIGHT pressed together dropped one**: a 50 ms minimum gap between intents; now a burst allowance.
- **The "+XP" reward line was always blank**: the reward arrived before the result and the result handler cleared it; the result is sent first now.

## Adding to it
Every new server feature gets a scenario in `Night` or `Social` (or a new spec) and a mutation check: break the rule, see the test fail, put it back.
