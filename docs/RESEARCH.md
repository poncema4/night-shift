# Research: what makes the big games work (2026-10-09)

Sources: Roblox's own creator guide on discovery (https://create.roblox.com/docs/production/promotion/discovery), Roblox's public game and thumbnail APIs and its Charts page (looked at logged in as the studio owner, read-only), third-party TikTok guides (Hootsuite, SocialPilot, Darkroom), and the Game Developer piece on why horror works on Roblox. Third-party numbers are estimates; Roblox changes its signals over time.

## The numbers (live from the public API, today)

| Game | Playing now | Visits | Favorites | Like ratio | Max players |
|---|---|---|---|---|---|
| Brookhaven 🏡RP | 451,326 | 88.4B | 30.4M | 85% | 30 |
| Murder Mystery 2 | 210,800 | 31.2B | 24.4M | 90% | 12 |
| 99 Nights in the Forest 🔦 | 181,643 | 30.0B | 9.8M | 90% | 25 |
| Forsaken | 53,195 | 5.8B | 3.2M | 84% | 9 |
| DOORS 🚨 | 51,719 | 7.9B | 8.3M | 93% | 50 |
| Flee the Facility | 25,895 | 6.1B | 9.7M | 92% | 5 |
| Piggy [SEASON 9 - FRIGHT NIGHT] | 18,740 | 14.4B | 12.3M | 90% | 6 |
| Dead Rails | 15,245 | 6.6B | 6.1M | 92% | 16 |
| [🧑‍🌾] Grow a Garden 🌶️ | 14,406 | 36.0B | 11.4M | 89% | 4 |
| The Mimic | 2,604 | 1.3B | 3.4M | 90% | 45 |

What stands out: **small servers are normal in this genre** (Piggy 6, Flee the Facility 5, Forsaken 9, Murder Mystery 2 12; only the co-op DOORS runs 50), so a 4-10 player match is right. **Like ratios of 90-93 % are the bar** for the horror and social-deduction hits. Almost every title carries **one emoji or tag** (DOORS 🚨, 99 Nights 🔦, [UPD], season names), and the best-known ones carry a **big, simple title word**.

## How Roblox decides who sees a game (from Roblox's own guide)

Ranked by Roblox, most important first:
1. **Play-through rate**: how often people who SEE your game in Recommended actually press play. This is your icon, thumbnails and title.
2. **First-play bounce rate** (negative): leaving within 60 seconds, and within 61-180 seconds. This is your loading screen, lobby and first minute.
3. **Play days per user**: do they come back on day 1, days 2-7, days 8-28.
4. **Playtime per user** (capped at 60 minutes a day).
5. Also counted: **intentional co-play** (joins, invites, private servers), qualified sessions, days a player spends Robux, Robux spent.

Creator advice Roblox gives: thumbnails and title must be accurate; **never lead the title with money words**; use original art and names; games that closely copy others rank lower; keep the group, events, passes and subscriptions current; encourage co-play with invites and private servers; use experience notifications and events to bring people back.

**What we do about each**
- Play-through: one clear icon (a face-forward character, bold title, high contrast), 3-5 thumbnails that show real play, title "NIGHT SHIFT" with at most one emoji (docs/LAUNCH.md).
- First-minute bounce: a fast loading screen with a progress bar and a tip, a title menu with a big PLAY, and a lobby where the next step is obvious (Quick Play). A solo or duo player must be able to start a game in seconds.
- Return days: daily streak and cosmetic goals (Locker), events, the saboteur-guessing hook makes every round different.
- Co-play: parties are the whole lobby. Friends join friends, private parties, a share-friendly "one of you is lying" hook.
- Spend: cosmetic passes and tip packs only (docs/MONETIZATION.md), never power.

## What the top icons and thumbnails share (looked at: DOORS, Piggy, Murder Mystery 2, Flee the Facility, Forsaken, The Mimic, Dead Rails, 99 Nights)
- **One subject, close up, facing the viewer** (a creature's face, a hammer, a knife, a mask), filling the frame.
- **One bold title word**, large, readable at icon size (the icons are shown at about 150 px on Charts).
- **Two or three colours**: black plus one hot accent (green for DOORS, red for Forsaken and Flee, purple for Piggy). Dark games put the colour on the creature and the light, not the background.
- **Thumbnails show the game, not a logo**: a monster in a corridor, characters in danger, a recognisable place. A few use a stylised render, none look like a screenshot of a menu.
- **Characters have faces with eyes**: eyes are the focal point of every horror thumbnail in the set.

Applied to NIGHT SHIFT: the Night Manager's pale mask and red-lit eyes at the end of the corridor (brand/thumbnail_corridor.png) is that one subject; the icon is a tighter crop of the mask with the title.

## TikTok / short video (third-party estimates, not TikTok's own word)
- The **first 1-3 seconds** decide most of it: start on the scare, the reveal or the question, never a logo.
- **Completion, rewatches, shares and saves** matter more than follower count; short clips (7-20 s) that loop or beg a rewatch do best.
- Caption, on-screen text, sound and hashtags are how the video is categorised: say what happens in the caption in plain words.
- Hashtags: one or two for the game, one for the clip type, one or two community tags. Suggested sets in docs/MARKETING.md.
- The Roblox guide says social media sharing can speed up organic discovery: every TikTok link should be the experience link.

## Honest limits
Nobody can promise a game blows up. What we control: a strong icon and title, a first minute that does not bounce, a reason to return, a reason to bring friends, and clips that are easy to make. Those are the signals Roblox and TikTok both measure.
