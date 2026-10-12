#!/usr/bin/env bash
# Renders README media: frames via example/test/media, then GIF + MP4 via
# ffmpeg. Output: doc/media/. Requires ffmpeg and the Flutter SDK on PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRAMES="${TMPDIR:-/tmp}/scroll_scene_frames"
OUT="$ROOT/doc/media"
FPS=30

rm -rf "$FRAMES"
mkdir -p "$FRAMES" "$OUT"

(cd "$ROOT/example" && SCENE_MEDIA_DIR="$FRAMES" flutter test test/media)

gif() {
  local name="$1" scale="$2" fps="${3:-20}"
  ffmpeg -y -loglevel error -framerate "$FPS" -i "$FRAMES/$name/%04d.png" \
    -vf "fps=$fps,scale=$scale:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" \
    -loop 0 "$OUT/$name.gif"
  ffmpeg -y -loglevel error -framerate "$FPS" -i "$FRAMES/$name/%04d.png" \
    -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -pix_fmt yuv420p -crf 20 \
    "$OUT/$name.mp4"
}

for name in hero phone gallery reveal snap markers; do
  gif "$name" 300
done

du -sh "$OUT"/*
