"""Builds the teaser MP4 from the Blender frame sequences, the voice-over and the sound bed.
Usage: python3 scripts/video/assemble.py <frames-dir> <voice-dir> <bed.wav> <out.mp4> [--preview]
Shots (24 fps): hall 6 s, cage 6 s, chase 6 s, flash 4 s, then a 4 s end card. Needs ~/tools/video-venv (imageio-ffmpeg, pillow)."""
import os
import subprocess
import sys

import imageio_ffmpeg
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

FF = imageio_ffmpeg.get_ffmpeg_exe()
LATO_BLACK = "/usr/share/fonts/truetype/lato/Lato-Black.ttf"
LATO_BOLD = "/usr/share/fonts/truetype/lato/Lato-Bold.ttf"
frames_dir, voice_dir, bed, out = sys.argv[1:5]
preview = "--preview" in sys.argv
W, H = 1080, 1920
work = os.path.dirname(os.path.abspath(out))

SHOTS = [("hall", 6), ("cage", 6), ("chase", 6), ("flash", 4)]
VOICE = [(1, 0.5), (2, 2.6), (3, 6.2), (4, 12.3), (5, 18.5), (6, 22.5)]
CAPTIONS = [
    ("HE HEARS EVERYTHING.", 0.5, 2.3),
    ("EVERY NIGHT, LOCKED IN A\\nHOTEL WITH HIM.", 2.6, 5.5),
    ("HE STARTS IN A CAGE.", 6.2, 8.4),
    ("THEN HE IS LOOSE.", 8.6, 11.8),
    ("RUN. HIDE.\\nDON'T MAKE A SOUND.", 12.3, 16.0),
    ("BLIND HIM.", 18.5, 20.6),
]


def esc(text):
    return text.replace("'", "’").replace(":", "\\:")


def end_card(path):
    card = Image.new("RGB", (W, H), (5, 4, 9))
    face = Image.open(os.path.join(os.path.dirname(__file__), "..", "..", "art", "renders", "hero_icon.png")).convert("RGB")
    face = face.resize((1080, 1080), Image.LANCZOS)
    card.paste(face, (0, 250))
    fade = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(fade)
    for y in range(900, H):
        d.line((0, y, W, y), fill=int(255 * min(1, (y - 900) / 380)))
    for y in range(250, 500):
        d.line((0, y, W, y), fill=int(255 * (1 - (y - 250) / 250)))
    card = Image.composite(Image.new("RGB", (W, H), (5, 4, 9)), card, fade)
    d = ImageDraw.Draw(card)
    big = ImageFont.truetype(LATO_BLACK, 118)
    mid = ImageFont.truetype(LATO_BOLD, 56)
    small = ImageFont.truetype(LATO_BOLD, 44)

    def centered(text, y, font, fill, spread=4):
        w = d.textlength(text, font=font)
        for dx in range(-spread, spread + 1, 2):
            for dy in range(-spread, spread + 1, 2):
                d.text(((W - w) / 2 + dx, y + dy), text, font=font, fill=(0, 0, 0))
        d.text(((W - w) / 2, y), text, font=font, fill=fill)

    centered("THE", 1340, mid, (190, 186, 196))
    centered("NIGHT MANAGER", 1385, big, (240, 234, 226))
    centered("COMING SOON TO ROBLOX", 1560, mid, (222, 38, 50))
    centered("Follow for updates", 1650, small, (200, 196, 210))
    card.save(path)


def run(args):
    subprocess.run([FF, "-y", "-loglevel", "error"] + args, check=True)


card_png = os.path.join(work, "endcard.png")
end_card(card_png)

# one clip per shot, then the end card
clips = []
for name, seconds in SHOTS:
    clip = os.path.join(work, f"clip_{name}.mp4")
    run(["-framerate", "24", "-i", os.path.join(frames_dir, name, "f_%04d.png"), "-t", str(seconds), "-vf", f"scale={W}:{H}:flags=lanczos", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "14", clip])
    clips.append(clip)
card_clip = os.path.join(work, "clip_card.mp4")
run(["-loop", "1", "-framerate", "24", "-i", card_png, "-t", "4", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "14", card_clip])
clips.append(card_clip)
listing = os.path.join(work, "clips.txt")
with open(listing, "w") as f:
    for c in clips:
        f.write(f"file '{c}'\n")
joined = os.path.join(work, "joined.mp4")
run(["-f", "concat", "-safe", "0", "-i", listing, "-c", "copy", joined])

# captions and the cage countdown are transparent PNGs overlaid on timed windows (this ffmpeg build has no drawtext)
def caption_png(path, text, size, fill, y_frac):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(LATO_BLACK, size)
    lines = text.split("\n")
    line_h = size * 1.18
    y = H * y_frac - (len(lines) - 1) * line_h / 2
    for line in lines:
        w = d.textlength(line, font=font)
        d.text(((W - w) / 2, y), line, font=font, fill=fill, stroke_width=max(4, size // 11), stroke_fill=(0, 0, 0, 255))
        y += line_h
    img.save(path)


overlays = []  # (png, start, end)
for n, (text, a, b) in enumerate(CAPTIONS):
    png = os.path.join(work, f"cap_{n}.png")
    caption_png(png, text.replace("\\n", "\n"), 78, (255, 255, 255, 255), 0.72)
    overlays.append((png, a, b))
for n in range(10, 0, -1):
    a = 6.5 + (10 - n) * 0.55
    png = os.path.join(work, f"count_{n}.png")
    caption_png(png, f"RELEASED IN {n}", 70, (255, 48, 64, 255), 0.14)
    overlays.append((png, a, a + 0.55))

# grade (a touch of contrast, vignette, film grain) then the overlays
graded = os.path.join(work, "graded.mp4")
args = ["-i", joined]
for png, _, _ in overlays:
    args += ["-i", png]
chain = "[0:v]eq=contrast=1.08:saturation=0.92,vignette=PI/5,noise=alls=4:allf=t[v0]"
for n, (_, a, b) in enumerate(overlays):
    chain += f";[v{n}][{n + 1}:v]overlay=enable='between(t,{a},{b})'[v{n + 1}]"
run(args + ["-filter_complex", chain, "-map", f"[v{len(overlays)}]", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "17", graded])

# sound: the bed plus each voice line at its time
inputs = ["-i", graded, "-i", bed]
chains, labels = [], ["[1:a]volume=0.85[bed]"]
for idx, (line, at) in enumerate(VOICE):
    inputs += ["-i", os.path.join(voice_dir, f"vo_{line}.wav")]
    labels.append(f"[{idx + 2}:a]adelay={int(at * 1000)}|{int(at * 1000)}[v{idx}]")
mix = ";".join(labels) + ";[bed]" + "".join(f"[v{i}]" for i in range(len(VOICE))) + f"amix=inputs={len(VOICE) + 1}:normalize=0,alimiter=limit=0.95[a]"
run(inputs + ["-filter_complex", mix, "-map", "0:v", "-map", "[a]", "-c:v", "libx264", "-preset", "medium", "-crf", "22", "-maxrate", "9M", "-bufsize", "18M", "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-c:a", "aac", "-b:a", "192k", "-shortest", out])
print("wrote", out)
