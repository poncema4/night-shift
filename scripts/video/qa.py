"""Pre-flight check for a TikTok video. Fails loudly on the mistakes that force a remake.
Usage: ~/tools/video-venv/bin/python scripts/video/qa.py video.mp4
Checks: 9:16 and 1080x1920, 15-60 s, file size, has audio, not silent / not clipping, no long black stretches, not a
dark frame at the start (first frame is the thumbnail), codec H.264 + AAC."""
import os
import re
import subprocess
import sys

import imageio_ffmpeg

FF = imageio_ffmpeg.get_ffmpeg_exe()
path = sys.argv[1]
problems, notes = [], []


def ff(args):
    return subprocess.run([FF, "-hide_banner", "-nostats"] + args, capture_output=True, text=True).stderr


info = ff(["-i", path])
duration = re.search(r"Duration: (\d+):(\d+):([\d.]+)", info)
seconds = int(duration.group(1)) * 3600 + int(duration.group(2)) * 60 + float(duration.group(3)) if duration else 0
size = re.search(r"Video: (\w+).*?, (\d+)x(\d+)", info)
codec, w, h = (size.group(1), int(size.group(2)), int(size.group(3))) if size else ("?", 0, 0)
mb = os.path.getsize(path) / 1e6
notes.append(f"{w}x{h}, {seconds:.1f}s, {mb:.1f} MB, {codec}")
if (w, h) != (1080, 1920):
    problems.append(f"size is {w}x{h}, want 1080x1920 (9:16)")
if not 15 <= seconds <= 60:
    problems.append(f"length {seconds:.1f}s: keep 15-60 s (the sweet spot for a first video is 20-35 s)")
if mb > 100:
    problems.append(f"{mb:.0f} MB is heavy; re-encode (crf 22, maxrate 9M)")
if codec != "h264":
    problems.append(f"video codec {codec}, want h264")
if "Audio:" not in info or "aac" not in info.lower():
    problems.append("no AAC audio track")

levels = ff(["-i", path, "-af", "volumedetect", "-f", "null", "-"])
mean = re.search(r"mean_volume: (-?[\d.]+) dB", levels)
peak = re.search(r"max_volume: (-?[\d.]+) dB", levels)
if mean and peak:
    notes.append(f"loudness mean {mean.group(1)} dB, peak {peak.group(1)} dB")
    if float(mean.group(1)) < -32:
        problems.append("audio is nearly silent (mean below -32 dB)")
    if float(peak.group(1)) > -0.3:
        problems.append("audio is clipping (peak above -0.3 dB): lower the gain")

black = ff(["-i", path, "-vf", "blackdetect=d=0.6:pix_th=0.12", "-an", "-f", "null", "-"])
stretches = [(float(a), float(b)) for a, b in re.findall(r"black_start:([\d.]+) black_end:([\d.]+)", black)]
for a, b in stretches:
    problems.append(f"black frames from {a:.1f}s to {b:.1f}s: re-light that shot (the viewer will swipe)")
if stretches == []:
    notes.append("no black stretches")

# the first frame is what most people see before it plays: it must not be dark
frame = ff(["-ss", "0.3", "-i", path, "-frames:v", "1", "-vf", "signalstats,metadata=print", "-f", "null", "-"])
yavg = re.search(r"lavfi.signalstats.YAVG=([\d.]+)", frame)
if yavg:
    notes.append(f"opening brightness {float(yavg.group(1)):.0f}/255")
    if float(yavg.group(1)) < 12:
        problems.append("the opening frame is almost black: start on the strongest image")

print("\n".join("  " + n for n in notes))
if problems:
    print("PROBLEMS:")
    print("\n".join("  - " + p for p in problems))
    sys.exit(1)
print("QA PASSED")
