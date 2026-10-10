#!/usr/bin/env bash
# Generates the teaser voice-over lines (neural TTS) into $1 and prints each line's length in seconds.
# Needs: ~/tools/video-venv (python -m venv; pip install imageio-ffmpeg edge-tts pillow).
set -euo pipefail
OUT="${1:?usage: make_voice.sh <out-dir>}"
VENV="${VENV:-$HOME/tools/video-venv}"
mkdir -p "$OUT"
declare -a LINES=(
  "He hears everything."
  "Locked in a hotel. With him."
  "He starts in a cage. Then he is loose."
  "Run. Hide. Do not make a sound."
  "Blind him."
  "The Night Manager. Out now on Roblox."
)
i=0
for line in "${LINES[@]}"; do
  i=$((i+1))
  "$VENV/bin/edge-tts" --voice en-US-ChristopherNeural --rate=+12% --pitch=-6Hz --text "$line" --write-media "$OUT/raw_$i.mp3" >/dev/null 2>&1
  FF="$("$VENV/bin/python" -c 'import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())')"
  # A deep man's voice. The speech engine writes 24 kHz, so resample to 44.1 kHz FIRST and only then shift the pitch down
  # (shifting before resampling raised it to ~190 Hz and sped it up 1.7x, which is what made it squeaky). 0.95 keeps it near 80 Hz.
  # Then: chest weight (low shelf), a little grit, a quiet octave-down double for the haunted layer, and a short dark echo.
  "$FF" -y -loglevel error -i "$OUT/raw_$i.mp3" -filter_complex "[0:a]aresample=44100,asplit[a][b];[a]asetrate=44100*0.95,aresample=44100,atempo=1.0526,highpass=f=50,equalizer=f=120:t=h:w=160:g=6,equalizer=f=3200:t=q:w=1.2:g=-4,lowpass=f=6500,acompressor=threshold=-22dB:ratio=3.5:attack=5:release=120[main];[b]asetrate=44100*0.5,aresample=44100,atempo=2.0,lowpass=f=900,volume=0.5,adelay=18|18[sub];[main][sub]amix=inputs=2:normalize=0,aecho=0.8:0.5:70|140:0.25|0.14,volume=2.0,alimiter=limit=0.95" "$OUT/vo_$i.wav"
  "$VENV/bin/python" - "$OUT/vo_$i.wav" <<'PY'
import sys, wave
w = wave.open(sys.argv[1]); print(sys.argv[1].split('/')[-1], round(w.getnframes() / w.getframerate(), 2))
PY
done
