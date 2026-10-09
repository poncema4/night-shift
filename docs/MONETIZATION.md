# Monetization (cosmetics only)

Rule: nothing sold changes speed, noise, vision or who wins. Robux buys looks and a shortcut to cosmetic currency.

## What exists
- **Game pass: Starlight Collection** (`Config.Monetization.Passes.starlight`, R$299): two flashlight colours (Starlight, Crimson Beam) and a Halo hat. Unlocked through the pass, never with tips.
- **Developer products** (`Products`): Pocket of Tips (250, R$49), Bag of Tips (700, R$125), Chest of Tips (1600, R$249). Tips only buy cosmetics in the Locker.
- The lobby menu has a SHOP panel. Every id is `0` until you create it, and the shop shows COMING SOON (it never prompts a wrong purchase).

## Turning it on (you do this in Creator Hub; Claude does not create or price anything on your account)
1. Publish the place (root place 84666312718541, experience 10770001120).
2. Creator Hub > the experience > Monetization > Passes: create "Starlight Collection", set the price, upload an icon, copy the pass id.
3. Same page > Developer Products: create the three packs, copy each product id.
4. Paste the ids into `src/shared/Config.luau` under `Monetization`, open a PR, merge. The shop switches from COMING SOON to the price.
5. Test in Studio with a test purchase before telling anyone.

## How it is kept safe
- The client sends only a key ("pass", "starlight"). The server maps it to the real id, so a client cannot name an id.
- A receipt is acknowledged only after the profile is SAVED (`ProfileService.commit`); if the save fails Roblox retries.
- Receipt ids are stored in the profile, so a replayed receipt never pays twice. Passes are re-checked on every join.
- Tested: `tests/specs/Store.luau`, `tests/specs/Purchases.luau`.

## Later ideas (still cosmetic)
Seasonal flashlight colours and hats, a monthly subscription for a name tag, a "supporter" lobby plaque, private server pricing. Titles must not lead with money words (Roblox discovery guidance).
