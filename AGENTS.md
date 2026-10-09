# AGENTS.md - NIGHT SHIFT (Roblox, Rojo)

NIGHT SHIFT, a Roblox game by Nexus Hollow Studios (Swag_Boy435 / V1RTU4L). Claude Code works on Linux (no Roblox Studio there); the owner playtests on a Windows PC through Rojo.

## What Claude can and cannot check
- CAN: Luau logic in `src/shared` (Lune tests), lint (Selene), format (StyLua), build (`rojo build`), CI.
- CANNOT: see the 3D game, physics, GUI layout, DataStores, Roblox services. Keep those parts thin; ask the owner to playtest and report (screenshots or the Studio Output text).

## Workflow
1. Branch -> small change -> `selene src tests && stylua --check src tests && lune run tests/run` -> commit -> PR -> CI green -> rebase merge.
2. Every new rule of game logic gets a spec in `tests/specs` with a check that FAILS if the logic is wrong (prove it by breaking the code once).
3. Commits: Claude as author, owner's account `poncema4` as Co-authored-by; PRs opened as poncema4 (plain `gh`); merge with `--rebase`.
4. The repo is PUBLIC: never commit keys, tokens, cookies or personal data. The Roblox API key lives only in the GitHub secret `ROBLOX_API_KEY`.
5. Publishing is manual (`Publish to Roblox` workflow). Never publish "published" without the owner saying so.
