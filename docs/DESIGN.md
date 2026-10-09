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

## Open decisions (owner)
- Setting (office? hospital? diner? hotel?).
- Number of players per round (suggest 6-10).
- Saboteur count and win conditions.
