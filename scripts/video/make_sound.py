"""Sound bed for the teaser (pure Python, no packages): a low drone, a heartbeat that speeds up, impact hits on the cuts, the
cage clang, a flashlight click and the blinded-scream sweep. Writes a stereo 44.1 kHz WAV.
Usage: python3 scripts/video/make_sound.py out.wav
Timeline (seconds): hall 0-6, cage 6-12 (bars rise ~10.3), chase 12-18, flash 18-22 (light on at 19.3), end card 22-26."""
import math
import random
import struct
import sys
import wave

RATE = 44100
LENGTH = 26.0
N = int(RATE * LENGTH)
random.seed(7)
left = [0.0] * N
right = [0.0] * N


def add(buf, start, samples, gain=1.0):
    i0 = int(start * RATE)
    for k, v in enumerate(samples):
        j = i0 + k
        if 0 <= j < N:
            buf[j] += v * gain


def env(t, attack, decay):
    return min(1.0, t / attack) * math.exp(-t / decay) if attack > 0 else math.exp(-t / decay)


def lowpassed_noise(seconds, cutoff):
    a = 1 - math.exp(-2 * math.pi * cutoff / RATE)
    y, out = 0.0, []
    for _ in range(int(seconds * RATE)):
        y += a * (random.uniform(-1, 1) - y)
        out.append(y)
    return out


def boom(seconds=2.2, f0=70.0, f1=28.0):
    out, ph = [], 0.0
    n = int(seconds * RATE)
    noise = lowpassed_noise(seconds, 180)
    for k in range(n):
        t = k / RATE
        f = f1 + (f0 - f1) * math.exp(-t * 3.2)
        ph += 2 * math.pi * f / RATE
        out.append((math.sin(ph) * 0.9 + noise[k] * 2.2) * env(t, 0.004, 0.55))
    return out


def thump(f=58.0):
    n = int(0.22 * RATE)
    return [math.sin(2 * math.pi * f * (k / RATE) * (1 - 0.35 * k / n)) * env(k / RATE, 0.003, 0.05) for k in range(n)]


def clang(seconds=1.6):
    out = []
    freqs = (410, 673, 1190, 1630, 2480)
    noise = lowpassed_noise(seconds, 5000)
    for k in range(int(seconds * RATE)):
        t = k / RATE
        v = sum(math.sin(2 * math.pi * f * t) * (0.35 / (i + 1)) for i, f in enumerate(freqs)) * math.exp(-t * 3.5)
        out.append(v * 0.7 + noise[k] * 0.5 * math.exp(-t * 18))
    return out


def click():
    n = int(0.05 * RATE)
    return [random.uniform(-1, 1) * math.exp(-k / (RATE * 0.004)) * 0.8 for k in range(n)]


def scream(seconds=1.4):
    out, ph = [], 0.0
    for k in range(int(seconds * RATE)):
        t = k / RATE
        f = 380 + 900 * (t / seconds) ** 1.5 + 40 * math.sin(t * 38)
        ph += 2 * math.pi * f / RATE
        grit = math.copysign(1, math.sin(ph)) * 0.35 + math.sin(ph * 1.5) * 0.3 + random.uniform(-1, 1) * 0.25
        out.append(grit * math.sin(math.pi * min(1.0, t / seconds)) * 0.55)
    return out


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
for when, size in ((6.0, 1.0), (12.0, 1.25), (18.0, 1.0), (22.0, 0.8)):
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
