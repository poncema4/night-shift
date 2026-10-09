# NIGHT SHIFT: handoff

**Studio:** Nexus Hollow Studios. **Repo:** poncema4/night-shift. **Stack:** Luau, Rojo, Lune (tests), Selene, StyLua, luau-lsp (type-check), Blender 4.5 (headless).
**Rule of the repo:** every change is a PR; CI (lint, format, tests, type-check, place build) must pass; merge with rebase; delete the branch; commits are authored by Claude with `Co-authored-by: poncema4 <144962839+poncema4@users.noreply.github.com>`. `main` is the only long-lived branch.

## What exists (all merged to `main`)

| Area | Where | Tested how |
|---|---|---|
| Round loop with Meeting phase | `shared/Game/Round`, `server/RoundService` | state-machine tests |
| Roles, tasks, win rules | `Roles`, `TaskBoard`, `Round.evaluate` | pure tests |
| 3-floor hotel, stairs, doors, trim, furniture | `Floors`, `Dressing`, `Building`, `Furnishing`, `server/HotelBuilder`, `Props`, `StationProps` | 100+ geometry checks (no overlaps, headroom, routes, stairs) |
| The Night Manager | `Patrol` (Dijkstra across floors), `server/ThreatService`, `shared/NightManagerRig`, `client/ThreatView` | patrol/chase tests on all floors |
| Stealth (sprint, flashlight, hiding, noise) | `Stamina`, `Battery`, `Stealth`, `server/StealthService`, `client/Controls` | pure tests |
| Scares | `Scares`, `server/ScareDirector`, `client/Fx` | schedule tests |
| Meetings, voting, abilities | `Meeting`, `Abilities`, `server/MeetingService`, `AbilityService`, `client/MeetingUi`, `Results` | tally/cooldown tests |
| Progression and cosmetics | `Progress`, `Cosmetics`, `server/ProfileService`, `client/Locker` | pure tests |
| Art | `art/blender/*.py`, `art/models`, `ModelStyles`, `ModelFit` | renders reviewed; fit maths tested |

193 automated checks plus a Roblox-API type-check. Systems are in `docs/GAMEPLAY.md`, the map in `docs/MAP.md`, art in `docs/ART.md`.

## What is NOT verified (be honest about it)
Nothing since the first round loop has been run in **Studio** (it looks and feels unchecked), but the server logic is exercised end to end by a simulated world: see `docs/TESTING.md`. The riskiest bits, in order: stairs feel and Humanoid step height; hiding (anchored, invisible character) and the meeting teleport ring; the vote UI on a phone; DataStore round trip; the imported-model path (FBX axes/scale); performance with ~3500 parts and ~16 active lights. `docs/PLAYTEST.md` is the checklist.

## What Marco needs to do
1. `git pull`, Rojo connect, run the checklist in `docs/PLAYTEST.md`, send screenshots and any red Output text.
2. Import the Blender models (docs/ART.md), once.
3. Turn on *Enable Studio Access to API Services* to test saving.
4. For publishing: create the experience under the group, then set `ROBLOX_API_KEY` (GitHub secret), `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID` (variables), environment `roblox`. Never paste the key in chat.
5. TikTok: sign in once in the Playwright browser; Claude drafts posts (docs/MARKETING.md), Marco presses Post.
6. On the PC: close the old PowerShell window that ran `scripts/logs` (it keeps recreating a `studio-logs` branch), delete the old `night-shift-logs` folder, and delete the `poncema4/night-shift-logs` repo on GitHub (needs `gh auth refresh -h github.com -s delete_repo`).

## Next work (sections, biggest value first)
1. **Fix what the playtest finds** (always first).
2. **Sound** and a **rigged Night Manager** (docs/IDEAS.md section F): the two things that most change the feel.
3. **Security cameras** mechanic, **keycards**, **vents** (section B): the clip-friendly depth.
4. **Daily streak, titles, leaderboard**, then cosmetic game passes (sections E).
5. **Launch kit**: icon/thumbnails (brand/), trailer from real clips, TikTok cadence.

## How Claude works here
Small, tested steps; pure logic in `shared/Game` with a spec; Roblox glue stays thin; every claim of "works" names how it was verified and what was not. A mutation check (break the rule, see the test fail) is done for every new rule. Errors from Studio arrive as pasted text or screenshots (there is no log bridge on purpose).
