# Playtest checklist (first Studio session)

Nothing in the game has been run in Studio yet except the very first rounds: every system below is covered by tests and the type-checker but **not by eyes**. This list is the fastest way to find what is wrong. Send screenshots of anything odd, and paste red Output lines.

## Setup
1. `git pull`, run `scripts\serve.ps1`, in Studio click **Connect** on the Rojo plugin, **Accept**.
2. Game Settings > Security: turn on **Enable Studio Access to API Services** (for saving) and **Allow HTTP Requests** is no longer needed.
3. Press **Play** (solo). For meetings/voting use **Test > Clients and Servers** with 2 or more players.

## 1. World (30 seconds)
- [ ] Output prints `[Hotel] removed template Part "Baseplate"` (and a SpawnLocation line). No flickering floors or walls.
- [ ] You spawn in the Lobby on a small pad. Chandelier overhead, desk with a bell, armchairs.
- [ ] Walk the corridor: wall panelling, door frames, carpet runner. No gaps you can fall through.
- [ ] **West end:** doorway into the stair annex; climb to the upstairs corridor. **East end:** descend to the basement. Stairs feel smooth (not snagging).
- [ ] HUD top-left shows GROUND FLOOR / FLOOR 2 UPSTAIRS / BASEMENT as you move.

## 2. Round (solo test round: Night is 5 minutes)
- [ ] Intermission 5 s then Night. How to Play card appears once; GOT IT closes it.
- [ ] Role label shows; TASKS 0/12. Task stations look like objects (breaker, clock, barrels...), amber lamp.
- [ ] Hold **E** at a station: it completes, the lamp turns green, TASKS goes up.
- [ ] The Night Manager walks the hotel (tall figure, red eyes, bellhop cap), smooth, not stuttering. He climbs stairs.
- [ ] Get close: red pulse + camera tremble. Being caught = you die; round ends "Saboteurs win" (solo has a phantom saboteur).

## 3. Stealth
- [ ] **Shift** sprints; stamina bar drains, you get winded. **F** toggles the flashlight; battery bar drains.
- [ ] Hold **E** at a locker/wardrobe: you vanish, black screen with vent slats. **LEAVE (E)** gets you out. Stand next to the locker while he is near: he eventually pulls you out and you die.
- [ ] Standing still, he hears you from less far; sprinting + light, from farther.

## 4. Atmosphere
- [ ] Every 15-40 s something happens: flicker burst, a subtitle line, camera thud, and later a blackout on your floor.

## 5. Meetings (2+ players)
- [ ] Walk up to a dead player: **Report body** prompt. Or ring the **bell** on the lobby desk (once per night).
- [ ] Everyone is gathered in the lobby, meeting screen shows a card per player. Vote or SKIP; the result shows who was ejected and their role. Everyone returns to where they stood and the night continues.
- [ ] Saboteur: **Q** lure, **R** lights out (buttons bottom-right), with cooldown timers.

## 5b. Cameras and spectating
- [ ] Finish the **Fix the cameras** task in the Security room (ground floor, north). A CAMERAS (C) x3 button appears (crew only). Press C: a three-floor map with a red blip for 15 s, then a 40 s cooldown.
- [ ] After you die, Left/Right arrows switch whose view you watch (needs 2+ players in a Clients and Servers test).

## 6. Dawn and progress
- [ ] Dawn screen: winner, tasks, every player's role and fate, `+XP +tips`.
- [ ] **L** opens the Locker: level, XP bar, cosmetics. Buy/wear a hat or flashlight colour. Stop and re-Play: progress is still there (needs API access on).

## 7. Performance and phone
- [ ] **Test > Device**: pick a phone: HUD readable, RUN/LIGHT touch buttons appear, nothing off-screen.
- [ ] Open the **Stats** (Shift+F3 in game): note FPS and memory; send a screenshot.

## What to send back
Screenshots of: the lobby, the stairwell, a task station, the Night Manager, the meeting screen, the dawn screen, the Locker. Plus any red text from Output.
