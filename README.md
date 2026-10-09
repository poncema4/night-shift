# NIGHT SHIFT

A multiplayer survival-horror / social-deduction / life-sim Roblox game by **Nexus Hollow Studios** (group owner: Swag_Boy435 / V1RTU4L).

The code lives here as plain Luau files. **Rojo** syncs them into Roblox Studio, **Lune** tests the game logic on any computer, and a GitHub Action can publish the game to Roblox.

```
src/shared   code both sides use (ReplicatedStorage.Shared)   <- put testable logic here
src/server   server scripts (ServerScriptService.Server)
src/client   client scripts (StarterPlayerScripts.Client)
tests        checks that run without Roblox:  lune run tests/run
brand        logo and store art
docs         plans, marketing, notes
```

## Every day (Linux laptop: write code, check it)

```bash
git pull
rokit install                  # once, installs rojo, lune, selene, stylua, rbxcloud
selene generate-roblox-std     # once
selene src tests               # lint
stylua src tests               # format
lune run tests/run             # tests (exit code = failures)
rojo build -o build/NexusHollow.rbxl
git add -A && git commit -m "..." && git push
```

## Windows PC (play it in Roblox Studio)

One-time setup:
1. Install **Roblox Studio** and **Git for Windows**.
2. Download **Rokit** for Windows from <https://github.com/rojo-rbx/rokit/releases> (`rokit-*-windows-x86_64.zip`), unzip it, open PowerShell in that folder and run `.\rokit.exe self-install`. Close and reopen PowerShell.
3. `git clone https://github.com/poncema4/nexus-hollow.git` and `cd nexus-hollow`.
4. `rokit install` (trust the tools when asked), then `rojo plugin install` (puts the Rojo plugin into Studio).

Each time you want the latest code:
1. `git pull`
2. `rojo serve`  (leave it running)
3. In Studio: open a new Baseplate, then **Plugins > Rojo > Connect**. Your scripts appear under ServerScriptService / ReplicatedStorage / StarterPlayer and update live as you pull.
4. Press **Play**.

Changes you make in Studio (parts, maps, UI) are NOT in git unless you save them as files; ask Claude how to keep a map in the repo (a `.rbxm` model file or built from code).

## Connecting the game to the group (once)

Only the group owner can do this, because it needs a key from your Roblox account. Never paste the key anywhere except GitHub's secret form.

1. On <https://create.roblox.com/dashboard/creations> make the game (experience) under **Nexus Hollow Studios** if it does not exist, and note its **Universe ID** and **Place ID** (Creator Hub > the game > the "..." menu > Copy Universe ID / Copy Place ID).
2. On <https://create.roblox.com/dashboard/credentials> create an **API key** owned by the group (or yourself): add the API system **Place Publishing** with the operations "Write" for that experience. Copy the key once.
3. In the GitHub repo: **Settings > Secrets and variables > Actions**: add the secret `ROBLOX_API_KEY`, and the variables `ROBLOX_UNIVERSE_ID` and `ROBLOX_PLACE_ID`. Also create an environment called `roblox` (Settings > Environments); add yourself as a required reviewer if you want a confirm step before anything goes live.
4. **Actions > Publish to Roblox > Run workflow.** "saved" puts the build into Studio's version history, "published" makes it live.

## Rules (short)

- Game logic goes in `src/shared` as modules without Roblox services, with a spec in `tests/specs`, so it is tested before anyone opens Studio.
- Every change: `selene`, `stylua --check` and `lune run tests/run` must pass (CI runs them on every push).
- No keys, tokens or personal data in the repo, ever (the repo is public).
