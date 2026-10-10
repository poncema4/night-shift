"""Shared sound generators (pure Python, no packages): noise, booms, heartbeats, footsteps, screams, whispers, breath, swells, scrapes.
Used by scripts/video/make_sound.py (the trailer bed) and scripts/audio/make_game_sfx.py (the in-game sounds)."""
import math
import random
import struct
import wave

RATE = 44100
random.seed(7)

def add(buf, start, samples, gain=1.0):
    """Mix `samples` into `buf` starting at `start` seconds (clipped to the buffer)."""
    i0 = int(start * RATE)
    for k, v in enumerate(samples):
        j = i0 + k
        if 0 <= j < len(buf):
            buf[j] += v * gain


def write_wav(path, left, right=None, level=0.89, drive=1.1):
    """Stereo 16-bit WAV with a soft limiter. `right` defaults to a copy of `left`."""
    right = left if right is None else right
    peak = max(max(abs(x) for x in left), max(abs(x) for x in right), 1e-6)
    gain = level / peak
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = bytearray()
        for l, r in zip(left, right):
            frames += struct.pack("<hh", int(math.tanh(l * gain * drive) * 32000), int(math.tanh(r * gain * drive) * 32000))
        w.writeframes(bytes(frames))
    return peak



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


def bandpassed_noise(seconds, lo, hi):
    """Noise limited to a frequency band (two one-pole filters), the raw material for breath, whispers and scrapes."""
    a_hi = 1 - math.exp(-2 * math.pi * hi / RATE)
    a_lo = 1 - math.exp(-2 * math.pi * lo / RATE)
    y1 = y2 = 0.0
    out = []
    for _ in range(int(seconds * RATE)):
        y1 += a_hi * (random.uniform(-1, 1) - y1)
        y2 += a_lo * (y1 - y2)
        out.append(y1 - y2)
    return out


def whisper(seconds=1.6):
    """A breathy, wordless whisper: band-limited noise chopped at syllable rate with a sibilant edge."""
    body = bandpassed_noise(seconds, 700, 3200)
    hiss = bandpassed_noise(seconds, 3500, 7000)
    out = []
    syllables = [random.uniform(0.0, seconds) for _ in range(int(seconds * 5))]
    for k in range(int(seconds * RATE)):
        t = k / RATE
        gate = sum(math.exp(-((t - c) ** 2) / 0.004) for c in syllables)
        out.append((body[k] * 1.6 + hiss[k] * 0.9) * min(1.0, gate) * math.sin(math.pi * t / seconds))
    return out


def breath(seconds=2.4):
    """A slow breath in and out, close to the microphone."""
    noise = bandpassed_noise(seconds, 300, 1400)
    return [noise[k] * 2.0 * math.sin(math.pi * (k / RATE) / seconds) ** 2 for k in range(int(seconds * RATE))]


def footstep(weight=1.0):
    """One heavy step: a low thud plus a short dull scuff."""
    n = int(0.35 * RATE)
    scuff = lowpassed_noise(0.35, 700)
    out = []
    for k in range(n):
        t = k / RATE
        thud = math.sin(2 * math.pi * 52 * t * (1 - 0.25 * t / 0.35)) * math.exp(-t / 0.07)
        out.append((thud * 1.2 + scuff[k] * 1.6 * math.exp(-t / 0.05)) * weight)
    return out


def swell(seconds=1.4):
    """A reversed rising swell that ends exactly on the cut (the classic horror 'whoosh into the hit')."""
    noise = bandpassed_noise(seconds, 200, 4200)
    n = int(seconds * RATE)
    return [noise[k] * 2.4 * (k / n) ** 2.6 for k in range(n)]


def scrape(seconds=1.1):
    """Metal dragged across metal: a falling, wobbling band of harsh partials."""
    out, ph = [], 0.0
    grit = bandpassed_noise(seconds, 1500, 5200)
    for k in range(int(seconds * RATE)):
        t = k / RATE
        ph += 2 * math.pi * (1450 - 700 * t / seconds + 90 * math.sin(t * 31)) / RATE
        out.append((math.sin(ph) * 0.35 + grit[k] * 1.3) * math.sin(math.pi * t / seconds))
    return out
