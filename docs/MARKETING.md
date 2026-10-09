# TikTok / marketing plan

Rules: real gameplay only, no bots or fake engagement, follow Roblox community and TikTok rules, keep real names/ids out of captions.
Cadence: 1 short clip/day while developing (devlog, 15-30 s), 3+ per week at launch.
Hook in first 2 s. Formats: "the saboteur got caught" reveal, jump-scare clip, "building a horror game for 30 days", before/after devlog.
Tags (mix): #roblox #robloxgames #robloxdev #robloxhorror #horrorgame #indiedev #gamedev #nightshift #socialdeduction #fyp
Each post: clip, caption with game name + play link, pinned comment with the link. Record on the Windows PC (Studio recorder or OBS); Claude edits captions/scripts and, with a signed-in Playwright browser, can fill the TikTok upload form, but Marco confirms each Post click.

## Thumbnails and stills (rendered from the real game data)
- `brand/thumbnail_corridor.png` (1920x1080): the ground-floor corridor with the Night Manager at the far end, built from the exact walls, trim and lights in `src/shared/Game` (`lune run scripts/export-layout`, then `scripts/blender.sh art/blender/thumbnail.py`).
- Roblox wants 1920x1080 thumbnails (up to 10) plus a 512x512 icon (`brand/icon_512.png`): use this one first. More angles are one camera change away in `art/blender/thumbnail.py` (the stairwell, the Locker Room, the basement garage).
- Real gameplay clips and Studio screenshots beat renders for trust: post renders as "concept art" or the cold open of a trailer, not as gameplay.
