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
rojo build -o build/NightShift.rbxl
git add -A && git commit -m "..." && git push
```

## Quick start (scripts)

Linux / macOS (laptop where Claude Code runs):
```bash
git clone https://github.com/poncema4/night-shift.git && cd night-shift
./scripts/setup.sh     # once: installs Rokit + all tools
./scripts/check.sh     # lint + format + tests + place build (same as CI)
```

Windows PC (where Roblox Studio runs). Install Roblox Studio and Git for Windows first, then in PowerShell:
```powershell
git clone https://github.com/poncema4/night-shift.git
cd night-shift
powershell -ExecutionPolicy Bypass -File scripts\setup.ps1   # once: Rokit, tools, Rojo Studio plugin
```
Open a NEW PowerShell window after setup, then every session:
```powershell
cd night-shift
.\scripts\serve.ps1     # git pull + rojo serve, leave it running
```
In Studio: open a Baseplate, **Plugins > Rojo > Connect**, press **Play**. Scripts appear under ServerScriptService / ReplicatedStorage / StarterPlayer and update live after each pull.
`.\scripts\check.ps1` runs the same checks as CI on Windows.

Maps and models built in Studio or Blender are not synced by Rojo; see `docs/WORKFLOW.md`.

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

## Seeing Studio errors from the laptop (log bridge)

Studio runs on the Windows PC, so its Output window is invisible here. In Studio the game forwards its server Output to a small listener, which pushes it to the `studio-logs` branch; the laptop reads it with `scripts/read-logs.sh`.

On the Windows PC, once per place: **Home > Game Settings > Security > Allow HTTP Requests = ON**. Each playtest session, in a second PowerShell window: `.\scripts\logs.ps1` (leave it running), then press Play. Output arrives within about 12 seconds.

Limits: only SERVER output is forwarded (client-side errors and the Rojo plugin's own messages are not; paste those or send a screenshot). It runs only inside Studio, never in the live game. The branch is public with the repo, so it can show your username in lines the game prints.

### If Rojo says "denied script injection permission"
Studio > **Plugins** tab > **Manage Plugins** > Rojo > gear icon > turn on **Script Injection**, then Connect again and click **Accept** on the "initializing sync session" prompt.
