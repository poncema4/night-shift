"""Sound bed for the teaser (pure Python, no packages): a low drone, a heartbeat that speeds up, impact hits on the cuts, the
cage clang, a flashlight click and the blinded-scream sweep. Writes a stereo 44.1 kHz WAV.
Usage: python3 scripts/video/make_sound.py out.wav
Timeline (seconds): hall 0-6, cage 6-12 (bars rise ~10.3), chase 12-18, flash 18-22 (light on at 19.3), end card 22-26."""
import math
import os
import random
import struct
import sys
import wave

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio"))
from synth import *  # noqa: F401,F403 (the shared generators)

RATE = 44100
LENGTH = 26.0
N = int(RATE * LENGTH)
random.seed(7)
left = [0.0] * N
right = [0.0] * N


















# the drone: two detuned low tones, slow wobble, rising a little toward the chase and dropping out for the end card
ph1 = ph2 = 0.0
noise = lowpassed_noise(LENGTH, 90)
for k in range(N):
    t = k / RATE
    level = 0.16 + 0.12 * min(1.0, t / 12) + (0.1 if 12 <= t <= 18 else 0.0)
    if t > 22:
        level *= max(0.0, 1 - (t - 22) / 3)
    ph1 += 2 * math.pi * (46 + 3 * math.sin(t * 0.4)) / RATE
    ph2 += 2 * math.pi * (69.3 + 2 * math.sin(t * 0.31 + 1)) / RATE
    v = (math.sin(ph1) * 0.6 + math.sin(ph2) * 0.35 + noise[k] * 6) * level
    left[k] += v
    right[k] += v * 0.95

# heartbeat: begins at the cage cut and speeds up through the chase
t = 6.0
bpm = 64.0
while t < 21.5:
    for gap, g in ((0.0, 1.0), (0.2, 0.65)):
        add(left, t + gap, thump(), 0.55 * g)
        add(right, t + gap, thump(), 0.55 * g)
    bpm = 64 + (t - 6.0) * 6.2
    t += 60.0 / bpm

# hits on the cuts
for when, size in ((6.0, 1.0), (12.0, 1.25), (18.0, 1.0)):
    b = boom()
    add(left, when, b, 0.55 * size)
    add(right, when, b, 0.55 * size)
# the cage bars slide up (clang + scrape)
c = clang()
add(left, 10.3, c, 0.5)
add(right, 10.35, c, 0.5)
# the flashlight comes on and the Night Manager screams
for when in (19.3,):
    add(left, when, click(), 0.8)
    add(right, when, click(), 0.8)
s = scream()
add(left, 19.4, s, 0.5)
add(right, 19.45, s, 0.5)

# ---- the believable-horror layer ----------------------------------------------------------------------------------------












# whispers sit just behind the voice-over: hall (0-6) and chase (12-17), alternating ears, never loud
for when, ear in ((1.0, 0), (3.3, 1), (4.6, 0), (12.6, 1), (14.4, 0), (16.0, 1)):
    w = whisper(random.uniform(1.2, 1.9))
    add(left if ear == 0 else right, when, w, 0.22)
    add(right if ear == 0 else left, when + 0.03, w, 0.07)
# breathing in the cage (6-12), once per ~2.4 s, close and slightly left
for when in (6.4, 8.9, 11.2):
    add(left, when, breath(), 0.30)
    add(right, when + 0.01, breath(), 0.18)
# he walks: footsteps start slow at the cage cut and pound in the chase, gaining weight as he nears
t = 12.2
gap = 0.78
step_no = 0
while t < 17.9:
    weight = 0.45 + 1.6 * ((t - 12.0) / 6.0) ** 1.5
    f = footstep(weight)
    add(left, t, f, 0.5)
    add(right, t + 0.004, f, 0.5)
    gap = max(0.27, gap * 0.93)
    t += gap
    step_no += 1
# swells into every cut
for when in (6.0, 12.0, 18.0, 22.0):
    sw = swell()
    add(left, when - 1.4, sw, 0.30)
    add(right, when - 1.4, sw, 0.30)
# the cage scrape as the bars lift, and a late sub-drop under the title card
sc = scrape()
add(left, 10.15, sc, 0.28)
add(right, 10.2, sc, 0.28)
drop = boom(3.0, 48.0, 20.0)
add(left, 22.0, drop, 0.55)
add(right, 22.0, drop, 0.55)

# soft limiter and write
peak = max(max(abs(x) for x in left), max(abs(x) for x in right), 1e-6)
gain = 0.89 / peak
with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(RATE)
    frames = bytearray()
    for l, r in zip(left, right):
        frames += struct.pack("<hh", int(math.tanh(l * gain * 1.1) * 32000), int(math.tanh(r * gain * 1.1) * 32000))
    w.writeframes(bytes(frames))
print("wrote", sys.argv[1], round(peak, 3))
