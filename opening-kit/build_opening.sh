#!/usr/bin/env bash
# build_opening.sh "<CHAPTER TITLE>" <OUTPUT.mp4> [MUSIC.mp3] [MUSIC_START_SEC]
#
# Reusable ~6s chapter opening shared by every chapter:
#   dark atmosphere build -> 飞虎队/FLYING TIGERS ignites (~2.5s) and holds ->
#   the chapter title fades in beneath FLYING TIGERS for the last 3s.
# Only the chapter-title text changes per chapter. Music is a 6s slice of the
# series track, sliced so its drop lands on the ignite.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

TITLE="${1:?usage: build_opening.sh \"<chapter title>\" <output.mp4> [music] [music_start]}"
OUT="${2:?output path required}"
MUSIC="${3:-../assets/music/intro_sample.mp3}"
MSTART="${4:-9.0}"   # source offset so the drop (~src 11.5s) lands on the ignite (~2.5s)
DUR=8.0
# music fade-out: long, smooth landing (avoids the abrupt cut). Starts AFADE_ST,
# runs AFADE_D, ending exactly at DUR.
AFADE_D=2.2
AFADE_ST=$(awk "BEGIN{printf \"%.2f\", $DUR-$AFADE_D}")

mkdir -p plates tmp
# regenerate the series plates if missing
[[ -f plates/title.png ]]    || python3 make_title.py
[[ -f plates/bg.png ]]       || python3 make_assets.py
# per-chapter title plate
python3 make_chapter_title.py "$TITLE" plates/_chapter_title.png 880

ffmpeg -y -nostdin -hide_banner -loglevel error \
 -loop 1 -t $DUR -i plates/bg.png \
 -loop 1 -t $DUR -i plates/embers.png \
 -loop 1 -t $DUR -i plates/title_flash.png \
 -loop 1 -t $DUR -i plates/title.png \
 -loop 1 -t $DUR -i plates/flare.png \
 -loop 1 -t $DUR -i plates/_chapter_title.png \
 -filter_complex "\
[0:v]zoompan=z='1.0+0.0006*on':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=1920x1080:fps=30,format=rgba[bg];\
[1:v]format=rgba[em];\
[bg][em]overlay=x=0:y='-(t*22)':format=auto[b0];\
[4:v]format=rgba,split=2[fa][fb];\
[fa]colorchannelmixer=aa=0.30,fade=t=in:st=0.8:d=0.25:alpha=1,fade=t=out:st=1.7:d=0.4:alpha=1[pf];\
[b0][pf]overlay=x='-960+1300*(t-0.8)':y=0:enable='between(t,0.8,2.1)'[b1];\
[3:v]format=rgba,split=2[tg][tf];\
[tg]eq=brightness=-0.5:saturation=0.4,fade=t=in:st=1.2:d=1.2:alpha=1,colorchannelmixer=aa=0.24[ghost];\
[b1][ghost]overlay=0:0:enable='between(t,1.2,2.55)'[b2];\
[tf]fade=t=in:st=2.5:d=0.35:alpha=1[title];\
[b2][title]overlay=0:0:enable='gte(t,2.5)'[b3];\
[2:v]format=rgba,fade=t=in:st=2.42:d=0.12:alpha=1,fade=t=out:st=2.6:d=0.7:alpha=1[flash];\
[b3][flash]overlay=0:0[b4];\
[fb]fade=t=in:st=2.4:d=0.15:alpha=1,fade=t=out:st=3.1:d=0.5:alpha=1[mfl];\
[b4][mfl]overlay=x='-960+1600*(t-2.5)':y=0:enable='between(t,2.4,3.7)'[b5];\
[5:v]format=rgba,fade=t=in:st=3.0:d=0.7:alpha=1[ct];\
[b5][ct]overlay=0:0:enable='gte(t,3.0)',format=yuv420p[v]" \
 -map "[v]" -r 30 -t $DUR -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p tmp/opening_v.mp4

ffmpeg -y -nostdin -hide_banner -loglevel error -i tmp/opening_v.mp4 -ss "$MSTART" -t $DUR -i "$MUSIC" \
 -filter_complex "[1:a]afade=t=in:st=0:d=0.25,afade=t=out:st=$AFADE_ST:d=$AFADE_D,alimiter=limit=0.97[a]" \
 -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -shortest "$OUT"
echo "opening -> $OUT ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")s) | title: $TITLE"
