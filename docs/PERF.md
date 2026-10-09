# Performance notes

Measured on the built hotel with the fake world (parts and lights are real counts; frame rate needs Studio):

| What | Count |
|---|---|
| Parts in the hotel | about 3,000 (shell 1,360 + props 1,500 + stations and fixtures) |
| Point lights | about 60 (52 ceiling lights + lamps, furnace, generator) |
| Lights actually rendering on a screen | roughly 15: the client switches off lights farther than 75 studs or on another floor (`client/Fx`) |

What is already done to keep it light:
- Wall trim, panelling, frames and every prop part under 1.2 studs are non-colliding, non-queryable and cast no shadow.
- All parts are anchored; the Night Manager is one client-side rig of about 40 small parts, moved on the client; the server only publishes his position 20 times a second.
- Remote traffic: the Night Manager state (5 attributes at 20 Hz), player attributes only on change, scares and meetings are rare events.

What to measure first in Studio (Shift+F3 Stats, MicroProfiler Ctrl+F6):
1. FPS standing in the lobby, in the ballroom (most parts in view), and on the stairs.
2. Memory (the three floors are loaded at once; `StreamingEnabled` would help phones if it is high).
3. Test > Device emulator on a phone profile: send the numbers and a screenshot.

If it is heavy, in this order: turn on StreamingEnabled, cut the book count on shelves (`Props.shelf`), merge floor tiles and trim into fewer, larger parts.
