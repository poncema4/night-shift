# Gameplay systems

Rules live in `src/shared/Game` as pure modules with tests; the Roblox services only apply them.

| System | Rules (pure, tested) | Roblox glue |
|---|---|---|
| Sprint | `Stamina`: 4.5 s of running, then winded until recovered | `StealthService` sets WalkSpeed 16 / 24 |
| Flashlight | `Battery`: ~45 s of light, slow recharge, dead until 8 % | `StealthService` owns a SpotLight on the head |
| Hiding | `Stealth.search`: he must linger ~1.5 s within 5 studs; a hidden player is never grabbed in passing; if he HEARD someone and they then hide, he comes and waits at that spot for 8 s and pulls them out | lockers + wardrobes get a Hide prompt; hidden players are invisible and frozen |
| Noise | `Stealth.hearingRange`: sprint x1.5, light x1.25, still x0.4, hidden 0 | `ThreatService` uses it to pick who to hunt |
| Scares | `Scares`: schedule gets busier through the night; blackouts only after 25 % and a minute apart | `ScareDirector` plays them; `Fx` shakes, flickers, subtitles |

Controls: **Shift** run (hold), **F** flashlight, **E** interact / leave a hiding place. On phones the same actions are touch buttons (RUN, LIGHT) plus an on-screen LEAVE button while hiding.

Everything the client sends is a *wish* (`Intent`: sprint / light / leave). The server rate-limits it, validates the types and decides what really happens.

## Social deduction

| System | Rules (pure, tested) | Roblox glue |
|---|---|---|
| Meeting phase | `Round`: a meeting pauses the night clock and resumes it after; can only start at night | `RoundService` freezes tasks, stealth, the Night Manager and scares |
| Reporting | none needed | a dead player leaves a body with a **Report body** prompt (night only) |
| Emergency bell | none needed | the bell on the lobby desk: **one ring per player per night** |
| Voting | `Meeting.tally`: plurality, a tie or skip wins ties, only living players vote once | `MeetingService` validates every vote; ends early when all voted |
| Ejection | the most-voted player (strictly above skips, no tie) | their role is shown to everyone, they are out |
| Abilities | `Abilities`: per-player cooldowns (lure 60 s, lights 90 s) | `AbilityService`: saboteurs only, night only; **Q** lure, **R** lights out |
| Dawn screen | none needed | winner, tasks done, every player's role and fate (survived / caught / ejected) |

A meeting gathers everyone alive in the lobby (frozen in a ring), shows a card per player, lets you talk in the normal chat, then counts the votes. The last 9 seconds show the result. Everyone returns to where they stood and the night carries on from the same second.

**Saboteur abilities.** *Lure* sends the Night Manager to where you stand for 12 s (unless he hears someone closer): use it to pull him off your friends, or onto the crew. *Lights out* darkens the lights on your floor for 8 s. Saboteurs also see who their partner is (9-10 players have two).

## Progression (cosmetics only)

Every night earns **XP** and **tips** (the in-game currency): playing, surviving, winning and finishing tasks (capped at 6 so one lucky run cannot snowball). XP makes your **level**; tips buy **cosmetics** in your Locker (open with **L**): flashlight beam colours, hats and footstep dust. Cosmetics never change speed, noise, vision or anything that matters in a round, so there is nothing to pay for to win.

| Piece | Where |
|---|---|
| Levels, awards, merging two saves, repairing a damaged save | `Game/Progress` (pure, tested) |
| Catalogue, buying, wearing, level locks | `Game/Cosmetics` (pure, tested) |
| DataStore load/save with retries, autosave every 60 s, save on leave and shutdown, merge-on-save so progress never goes backwards | `server/ProfileService` |
| Locker screen, reward line on the dawn screen | `client/Locker`, `client/Results` |

Tips are stored as `tipsEarned` and `tipsSpent` (both only ever grow), so merging two saves can never refund a purchase.

**Testing saves in Studio:** Game Settings > Security > *Enable Studio Access to API Services*. Without it the game warns once and plays normally without saving.

## Security cameras and spectating

Finishing the **Fix the cameras** task (Security room) powers the monitor for the whole crew: **3 charges**, each lets one crew member watch the Night Manager as a red blip on a three-floor map for **15 seconds** (press **C**), with a **40 second team cooldown**. Saboteurs cannot use it. Rules: `Game/Cameras` (pure, tested); `CameraService` enforces them; `client/CameraUi` draws the map from the same room data the hotel is built from.

When you are out (caught or ejected) you **spectate**: **Left / Right** (or the on-screen arrows) switch between living players (`client/Spectate`).
