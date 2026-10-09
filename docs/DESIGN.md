# NIGHT SHIFT - design (working draft)

Not final. Each mechanic must support the identity below or it does not go in.

## Pillars
1. Survival horror: threat from the environment.
2. Social deduction: threat from other players (who can you trust?).
3. Life sim: calm moments between danger that give the world a reason to exist.
4. Tasks: concrete objectives that force movement, cooperation and decisions.
5. Progression: reasons to return, never an unfair advantage.

## Core loop (proposal to confirm with the owner)
Players are staff on a night shift in one location. They split up to do tasks. Something is wrong: threats roam, and one or more players may be saboteurs. Survive and finish tasks until dawn, then vote or reveal, score, repeat. Quiet life-sim hub between rounds (decorate a locker, cosmetics, chat).

## Rules of engineering
- Server owns all game state, rewards, inventory, roles. Clients send intent only.
- Every RemoteEvent validates the sender, the argument types and ranges, and a per-player rate limit.
- Pure logic (roles, task rules, scoring, rate limits) lives in `src/shared` and is tested with Lune.
- Data saving: wrapped in pcall with retry, and a session lock. Never block a round on a failed save.
- Monetisation later, cosmetics only. No pay-to-win.

## Decided (owner said "your call", 2026-10-09; change any time)
- Setting: an empty three-floor hotel at night (basement, ground floor, upstairs), a monster that uses the stairs.
- 6-10 players per round (Studio test: 1-2 plays as a sandbox).
- Saboteurs: 1 for 2-8 players, 2 for 9-10; they know each other.
- Night ends when all tasks are done (crew), crew <= saboteurs (saboteurs), or the timer runs out (saboteurs).
- A saboteur is ejected by a vote after a body is reported or the lobby bell is rung (once per player per night).
- Progression is cosmetic only (flashlight colours, hats, footstep dust); tips are earned by playing, never sold.

## What the build adds on top of the first draft
Stealth (sprint with stamina, a flashlight that draws him, hiding where he searches), a scare director that tightens toward dawn, security cameras for the crew, spectating, saboteur abilities (lure, lights out). See `docs/GAMEPLAY.md`. Everything above the engine rules is data plus tested pure rules.

## Still open (owner)
- Round length and task count balance (needs real playtests: docs/PLAYTEST.md).
- Real sound and the rigged Night Manager art (docs/IDEAS.md section F).
- Monetisation details (cosmetic passes only, after the free loop is fun).
