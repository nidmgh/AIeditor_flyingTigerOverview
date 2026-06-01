#!/usr/bin/env bash
# build_ending.sh "<ENDING TEXT>" <OUTPUT.mp4> [MUSIC.mp3] [MUSIC_START_SEC]
#
# ~4.5s chapter ending card: metallic text on the dark/ember atmosphere,
# fades up from black, holds, fades to black. Two lines allowed via "|".
# Music defaults to the resolving tail of the series track.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

TEXT="${1:?usage: build_ending.sh \"<text>\" <output.mp4> [music] [music_start]}"
OUT="${2:?output path required}"
MUSIC="${3:-../assets/music/intro_sample.mp3}"
MSTART="${4:-14.2}"   # the track's resolving tail
DUR=4.5

mkdir -p plates tmp
[[ -f plates/bg.png ]] || python3 make_assets.py
python3 make_ending.py "$TEXT" plates/_ending.png

ffmpeg -y -nostdin -hide_banner -loglevel error \
 -loop 1 -t $DUR -i plates/bg.png \
 -loop 1 -t $DUR -i plates/embers.png \
 -loop 1 -t $DUR -i plates/_ending.png \
 -filter_complex "\
[0:v]zoompan=z='1.0+0.0004*on':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=1920x1080:fps=30,format=rgba[bg];\
[1:v]format=rgba[em];\
[bg][em]overlay=x=0:y='-(t*16)':format=auto[b0];\
[2:v]format=rgba,fade=t=in:st=0.4:d=0.9:alpha=1,fade=t=out:st=3.3:d=0.9:alpha=1[txt];\
[b0][txt]overlay=0:0,fade=t=in:st=0:d=0.5,fade=t=out:st=4.0:d=0.5,format=yuv420p[v]" \
 -map "[v]" -r 30 -t $DUR -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p tmp/ending_v.mp4

ffmpeg -y -nostdin -hide_banner -loglevel error -i tmp/ending_v.mp4 -ss "$MSTART" -t $DUR -i "$MUSIC" \
 -filter_complex "[1:a]afade=t=in:st=0:d=0.4,afade=t=out:st=3.6:d=0.9,alimiter=limit=0.97[a]" \
 -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -shortest "$OUT"
echo "ending -> $OUT ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")s) | text: $TEXT"
