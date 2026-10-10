# Making the teaser / TikTok videos

Everything is scripted so a new video is a re-run, not a new project. Tools live in `~/tools` (no sudo): Blender (`scripts/blender.sh`)
and a small Python venv with a static ffmpeg and a neural voice: `python3 -m venv ~/tools/video-venv && ~/tools/video-venv/bin/pip install imageio-ffmpeg edge-tts pillow`.

1. **Footage** - `art/blender/trailer.py`: four shots built from the real hotel look (hallway POV, the holding cell, the chase, the flashlight
   blinding him), vertical, 24 fps. `TRAILER_OUT=<dir> TRAILER_SCALE=0.667 TRAILER_SAMPLES=14 scripts/blender.sh art/blender/trailer.py`
   (about 15 minutes; `TRAILER_STILL=1` renders one frame per shot for a quick look).
2. **Voice-over** - `scripts/video/make_voice.sh <dir>`: neural voice, pitched down, tight EQ, short echo. Prints each line's length.
3. **Sound** - `python3 scripts/video/make_sound.py bed.wav`: drone, accelerating heartbeat, hits on the cuts, cage clang, flashlight click, scream.
4. **Assemble** - `~/tools/video-venv/bin/python scripts/video/assemble.py <frames> <voice> bed.wav out.mp4`: grade, grain, captions, the
   RELEASED IN countdown and the end card. Shot and caption times are constants at the top of that file.

Rules we follow so it does not look generated: hook in the first second, one idea per shot, real in-game look (no logo stamped on the
footage; the studio name lives on the account), captions on because most people watch muted, and the end card says only what is true
("Coming soon to Roblox") until the game is public. Tags: #roblox #robloxhorror #nightmanager #scary #fyp.

## Pre-flight checklist (read this BEFORE rendering; it exists so a video is made once)

Mistakes that already cost us a remake, and the rule that prevents each:
- **A shot was nearly black** (the cage): look at a still of EVERY shot (`TRAILER_STILL=1`) and run `scripts/video/qa.py` after assembling; it fails on black stretches and a dark first frame.
- **The ffmpeg build had no `drawtext`**: captions are PNG overlays made with Pillow. Do not rely on ffmpeg text filters.
- **336 MB file**: the final encode is crf 22 with maxrate 9M (about 9 MB for 26 s). Keep it under 100 MB.
- **Studio logo stamped on art**: it never goes on game footage or thumbnails.
- **Claiming the game is out when it is not**: the end card says "Coming soon to Roblox" until the game is public. Update it the day it goes live.

Making it perform (what the top horror clips do):
1. **Hook in the first second**: the strongest image plus one line of text; no logo card, no slow fade-in.
2. **Show the monster early**, show the mechanic, end on a payoff or a cliffhanger, not on a title card alone.
3. **15-35 seconds**, vertical 1080x1920, 24-30 fps, cuts every 3-6 seconds, a sound hit on every cut.
4. **Captions on, in the safe zone**: keep text between 12% and 78% of the height (TikTok's own caption and buttons sit at the bottom ~20% and the right ~12%).
5. **Loud enough but not clipped**: voice clearly above the drone; QA checks mean and peak.
6. **3-5 hashtags** (#roblox #robloxhorror #nightmanager #scary #fyp) and a first-line caption that is a hook, not a description.
7. **Post, then reply to comments for the first hour**, and reuse the best 3-second moment as the next video's hook.

Procedure: render stills -> look at them -> render -> assemble -> `qa.py` -> view 8 frames across the video -> post.
