"""The in-game horror sounds, synthesized from scratch (original audio, so we own every sample). Writes one WAV per sound.
Usage: python3 scripts/audio/make_game_sfx.py <out-dir>
Loops are seamless (the tail is cross-faded into the head). Then convert with ffmpeg to ogg and upload (docs/AUDIO.md)."""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from synth import *  # noqa: F401,F403

out_dir = sys.argv[1]
os.makedirs(out_dir, exist_ok=True)
random.seed(11)


def silent(seconds):
    return [0.0] * int(seconds * RATE)


def loop_fade(buf, fade=0.6):
    """Make a buffer loop seamlessly: fold the last `fade` seconds into the first and cut them off."""
    n = int(fade * RATE)
    body = buf[:-n]
    for k in range(n):
        w = k / n
        body[k] = body[k] * w + buf[len(body) + k] * (1 - w)
    return body


def drone(seconds, f1=46.0, f2=69.0, level=1.0):
    """Two sub tones with a slow beating wobble; frequencies are whole cycles per loop so it joins up."""
    n = int(seconds * RATE)
    noise = lowpassed_noise(seconds, 110)
    out = []
    for k in range(n):
        t = k / RATE
        wob = 1 + 0.35 * math.sin(2 * math.pi * t / seconds * 3)
        v = math.sin(2 * math.pi * f1 * t) * 0.55 + math.sin(2 * math.pi * f2 * t) * 0.32 * wob + noise[k] * 5.0
        out.append(v * level)
    return out


def tail_fade(buf, seconds=0.12):
    """One-shots end on a short fade so they never click."""
    n = min(int(seconds * RATE), len(buf))
    out = list(buf)
    for k in range(n):
        out[len(out) - n + k] *= 1 - k / n
    return out


def save(name, left, right=None):
    if not name.endswith("_loop"):
        left = tail_fade(left)
        right = tail_fade(right) if right is not None else None
    path = os.path.join(out_dir, name + ".wav")
    peak = write_wav(path, left, right)
    print(f"{name}.wav  {len(left) / RATE:.1f}s  peak {peak:.2f}")


# 1. dread loop: sits under the whole night and gets louder with the Night Manager's closeness (the client sets volume)
d = loop_fade(drone(13.0), 0.8)
save("dread_loop", d, [x * 0.97 for x in d])

# 2. his footsteps: four heavy steps, alternating sides, slightly irregular
steps = silent(3.6 + 0.6)
left, right = list(steps), list(steps)
for i, when in enumerate((0.0, 0.92, 1.78, 2.74)):
    f = footstep(1.0 if i % 2 == 0 else 0.85)
    add(left, when, f, 0.9 if i % 2 == 0 else 0.5)
    add(right, when + 0.006, f, 0.5 if i % 2 == 0 else 0.9)
save("monster_steps_loop", loop_fade(left, 0.5), loop_fade(right, 0.5))

# 3. his breathing: wet low breath with a growl underneath
n = int(5.0 * RATE)
growl_noise = lowpassed_noise(5.0, 160)
growl = [(math.sin(2 * math.pi * 62 * (k / RATE)) + 0.5 * math.sin(2 * math.pi * 93 * (k / RATE))) * (0.5 + 0.5 * math.sin(2 * math.pi * 0.4 * (k / RATE))) * 0.35 + growl_noise[k] * 2.5 for k in range(n)]
breaths = silent(5.6)
add(breaths, 0.0, breath(2.6), 0.9)
add(breaths, 2.7, breath(2.6), 1.0)
mix = [growl[min(k, n - 1)] * 0.6 + breaths[k] for k in range(len(breaths))]
mix = loop_fade(mix, 0.6)
save("monster_breath_loop", mix)

# 4. heartbeat: two beats, ~100 bpm, loops
beat = silent(1.8)
for when in (0.0, 0.62):
    add(beat, when, thump(), 1.0)
    add(beat, when + 0.2, thump(52.0), 0.65)
save("heartbeat_loop", loop_fade(beat, 0.2))

# 5. the jumpscare: no lead-in. A sub boom, a distorted scream, a noise burst and a second scream layer an octave up
js_l, js_r = silent(2.6), silent(2.6)
b = boom(2.4, 80.0, 26.0)
add(js_l, 0.0, b, 1.0)
add(js_r, 0.0, b, 1.0)
s1, s2 = scream(1.6), scream(1.4)
add(js_l, 0.0, s1, 1.0)
add(js_r, 0.02, s1, 1.0)
add(js_l, 0.04, [x * 0.8 for x in s2], 0.9)
add(js_r, 0.05, [x * 0.8 for x in s2], 0.9)
burst = lowpassed_noise(0.5, 6000)
add(js_l, 0.0, [x * 3 * math.exp(-k / (RATE * 0.12)) for k, x in enumerate(burst)], 0.9)
add(js_r, 0.0, [x * 3 * math.exp(-k / (RATE * 0.12)) for k, x in enumerate(burst)], 0.9)
save("jumpscare", js_l, js_r)

# 6. everyone is down: a reversed swell into a low hit, then a descending groan and a whisper
ds_l, ds_r = silent(5.0), silent(5.0)
sw = swell(2.0)
add(ds_l, 0.0, sw, 0.8)
add(ds_r, 0.0, sw, 0.8)
hit = boom(2.8, 60.0, 22.0)
add(ds_l, 2.0, hit, 1.0)
add(ds_r, 2.0, hit, 1.0)
groan, ph = [], 0.0
for k in range(int(2.8 * RATE)):
    t = k / RATE
    ph += 2 * math.pi * (120 - 60 * t / 2.8) / RATE
    groan.append((math.sin(ph) * 0.6 + math.sin(ph * 1.5) * 0.25) * math.exp(-t / 1.6))
add(ds_l, 2.1, groan, 0.7)
add(ds_r, 2.1, groan, 0.7)
add(ds_l, 3.2, whisper(1.6), 0.5)
add(ds_r, 3.3, whisper(1.6), 0.5)
save("death_sting", ds_l, ds_r)

# 7. "he is loose": a klaxon (alternating square-ish tones) over a boom
k_l = silent(3.6)
siren = []
ph = 0.0
for k in range(int(3.2 * RATE)):
    t = k / RATE
    f = 540 if int(t / 0.38) % 2 == 0 else 420
    ph += 2 * math.pi * f / RATE
    siren.append(math.copysign(1, math.sin(ph)) * 0.25 + math.sin(ph) * 0.2)
low = lowpassed_noise(3.2, 2600)
siren = [(siren[k] + low[k] * 0.4) * (1 - 0.6 * (k / len(siren))) for k in range(len(siren))]
add(k_l, 0.0, siren, 0.8)
add(k_l, 0.0, boom(2.4, 70.0, 26.0), 1.0)
save("he_is_loose", k_l)

# 8. blinded: a short, glitchy shriek (the clip moment when the flashlight stuns him)
bl = scream(1.3)
glitch = [x * (0 if (int(k / (RATE * 0.045)) % 5 == 4) else 1) for k, x in enumerate(bl)]
save("blind_shriek", glitch)

# 9. chase sting: when he starts hunting you: a quick swell and a screech
cs_l = silent(1.8)
add(cs_l, 0.0, swell(0.7), 0.9)
add(cs_l, 0.7, scream(0.9), 0.9)
add(cs_l, 0.7, boom(1.0, 70.0, 30.0), 0.8)
save("chase_sting", cs_l)

# 10. locker creak: a low, slow metallic complaint
cr, ph = [], 0.0
grit = bandpassed_noise(1.2, 250, 1200)
for k in range(int(1.2 * RATE)):
    t = k / RATE
    ph += 2 * math.pi * (190 - 70 * t + 25 * math.sin(t * 19)) / RATE
    cr.append((math.sin(ph) * 0.4 + math.copysign(1, math.sin(ph * 2)) * 0.12 + grit[k] * 1.4) * math.sin(math.pi * t / 1.2))
save("locker_creak", cr)

# 11. the lobby: a quiet drone, far-off knocks and a distant whisper (loops, 24 s)
lob = drone(24.0, 41.0, 61.5, 0.55)
for when in (3.1, 3.9, 11.4, 17.2, 17.9, 18.7):
    add(lob, when, thump(70.0), 0.5)
add(lob, 8.0, whisper(2.0), 0.18)
add(lob, 20.5, whisper(1.6), 0.15)
save("lobby_ambience_loop", loop_fade(lob, 1.0))
