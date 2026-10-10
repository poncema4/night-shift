#!/usr/bin/env bash
# Generates the teaser voice-over lines (neural TTS) into $1 and prints each line's length in seconds.
# Needs: ~/tools/video-venv (python -m venv; pip install imageio-ffmpeg edge-tts pillow).
set -euo pipefail
OUT="${1:?usage: make_voice.sh <out-dir>}"
VENV="${VENV:-$HOME/tools/video-venv}"
mkdir -p "$OUT"
declare -a LINES=(
  "He hears everything."
  "Every night, you are locked inside a hotel with him."
  "He starts in a cage. Thirty seconds. Then he is loose."
  "Run. Hide. Do not make a sound."
  "Blind him with your flashlight."
  "The Night Manager. Coming soon to Roblox."
)
i=0
for line in "${LINES[@]}"; do
  i=$((i+1))
  "$VENV/bin/edge-tts" --voice en-US-ChristopherNeural --rate=-14% --pitch=-8Hz --text "$line" --write-media "$OUT/raw_$i.mp3" >/dev/null 2>&1
  FF="$("$VENV/bin/python" -c 'import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())')"
  # a deep, close, slightly haunted voice: pitch down a touch, tight low-pass, short echo, compression
  "$FF" -y -loglevel error -i "$OUT/raw_$i.mp3" -af "asetrate=44100*0.93,aresample=44100,atempo=1.075,highpass=f=70,lowpass=f=5200,acompressor=threshold=-20dB:ratio=3,aecho=0.8:0.55:70|140:0.3|0.18,volume=2.2" "$OUT/vo_$i.wav"
  "$VENV/bin/python" - "$OUT/vo_$i.wav" <<'PY'
import sys, wave
w = wave.open(sys.argv[1]); print(sys.argv[1].split('/')[-1], round(w.getnframes() / w.getframerate(), 2))
PY
done
