#!/usr/bin/env bash
set -euo pipefail

# build_clip.sh — assembles clip02-first-battle/output/clip.mp4
#
# Run from this directory. Idempotent: missing intermediates are rebuilt,
# existing ones are reused. To force a full rebuild: rm -rf tmp stage output
# before invoking.
#
# Cue structure (≈3:30 total):
#   Cue 1 — Pearl Harbor, 1941-12-07 (≈81s)
#     3 newsreel segments cut from a 1941 U.S. Navy archive, framed (black
#     canvas + cream border), narrated, with bilingual EN+ZH subtitles burned
#     in via the kit's subtitle_burn.sh, plus a lower-third caption for the
#     opening 3s.
#   Cue 2 — Kunming before 1941 (≈72s)
#     3 Ken Burns sub-clips (1940 bomber pan-up / city gate zoom / airbase
#     pan-up), narrated per sub-clip, footnote captions.
#   Cue 3 — First Battle: Tigers over Kunming (≈57s)
#     Sub A: P-40 + Chinese soldier zoom-in.
#     Sub B+C: continuous 20s — banner held at top, article fades in at t=10s.
#              Single Cue3_B narration spans both halves.
#     Sub D: tall LA Times column slow-pan + spotlight reveal on the
#            "Chennault / A.V.G." paragraph. See memory/spotlight recipe.

KIT="${KIT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/../video-production-kit}"
A="assets"
T="tmp"
S="stage/cues"
OUT="output"
CANVAS="1920x1080"
FPS=30
SAMPLE_RATE=44100
XFADE_DUR=0.8

# ---------------------------------------------------------------------------
# Preflight — fail early with a clear message if the environment is missing
# something the build needs.
# ---------------------------------------------------------------------------
preflight() {
  local missing=0
  for cmd in ffmpeg ffprobe python3; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "build_clip: missing dependency: $cmd" >&2
      missing=1
    fi
  done
  if ! python3 -c 'import PIL' >/dev/null 2>&1; then
    echo "build_clip: missing python3 package: Pillow (PIL). Install with: pip3 install --user Pillow" >&2
    missing=1
  fi
  if [[ ! -d "$KIT" ]]; then
    echo "build_clip: video-production-kit not found at: $KIT" >&2
    echo "  Override with: KIT=/path/to/video-production-kit bash build_clip.sh" >&2
    missing=1
  else
    for s in ken_burns.sh audio_attach.sh caption_overlay.sh crossfade.sh subtitle_burn.sh; do
      if [[ ! -f "$KIT/scripts/$s" ]]; then
        echo "build_clip: kit is missing script: scripts/$s under $KIT" >&2
        missing=1
      fi
    done
  fi
  [[ $missing -eq 0 ]] || exit 1
}
preflight

mkdir -p "$T/cues" "$T/frame_plates" "$S" "$OUT"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# add_silence IN OUT — mux a silent stereo AAC track of the input's duration.
add_silence() {
  local in="$1" out="$2" dur
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$in")
  ffmpeg -y -loglevel error -i "$in" \
    -f lavfi -t "$dur" -i "anullsrc=channel_layout=stereo:sample_rate=$SAMPLE_RATE" \
    -c:v copy -c:a aac -b:a 128k -shortest -movflags +faststart "$out"
}

# frame_segment_v3 IN OUT — black bg + cream 10px frame around 1120x840 inset.
frame_segment_v3() {
  local in="$1" out="$2" dur
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$in")
  ffmpeg -y -loglevel error -i "$in" \
    -f lavfi -i "color=c=black:s=$CANVAS:r=$FPS" \
    -filter_complex "[0:v]scale=1120:840:flags=lanczos,pad=1140:860:10:10:color=0xE8E1C9[fg];[1:v][fg]overlay=(W-w)/2:(H-h)/2:shortest=1[v]" \
    -map "[v]" -map "0:a?" -c:a aac -b:a 128k \
    -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p \
    -t "$dur" -movflags +faststart "$out"
}

# ===========================================================================
# Cue 1 — Pearl Harbor (≈81s)
# ===========================================================================
build_cue1() {
  echo "=== Cue 1: Pearl Harbor ==="
  local C1="$T/cue1"
  mkdir -p "$C1"

  # 1. Frame the 3 segments
  frame_segment_v3 "$A/video/clip02_PH_seg1_0016-0104.mp4" "$C1/seg1_framed.mp4"
  frame_segment_v3 "$A/video/clip02_PH_seg2_0324-0343.mp4" "$C1/seg2_framed.mp4"
  frame_segment_v3 "$A/video/clip02_PH_seg3_0600-0614.mp4" "$C1/seg3_framed.mp4"

  # 2. Concat
  local base
  base="$(pwd)/$C1"
  printf "file '%s/seg1_framed.mp4'\nfile '%s/seg2_framed.mp4'\nfile '%s/seg3_framed.mp4'\n" \
    "$base" "$base" "$base" > "$C1/concat_list.txt"
  ffmpeg -y -loglevel error -f concat -safe 0 -i "$C1/concat_list.txt" -c copy "$C1/concat.mp4"
  local total
  total=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$C1/concat.mp4")

  # 3. Mix audio — source ducked + Cue1_A at start + Cue1_B at end
  local b_dur b_delay_ms
  b_dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$A/narration/clip02_Cue1_B.mp3")
  b_delay_ms=$(awk -v t="$total" -v b="$b_dur" 'BEGIN { printf "%.0f", (t - b) * 1000 }')

  ffmpeg -y -loglevel error \
    -i "$C1/concat.mp4" \
    -i "$A/narration/clip02_Cue1_A.mp3" \
    -i "$A/narration/clip02_Cue1_B.mp3" \
    -filter_complex "[0:a]volume=0.20[src];[1:a]adelay=0|0,apad=pad_dur=80[na];[2:a]adelay=${b_delay_ms}|${b_delay_ms},apad=pad_dur=80[nb];[src][na][nb]amix=inputs=3:duration=first:normalize=0[aout]" \
    -map "0:v" -map "[aout]" -c:v copy -c:a aac -b:a 192k \
    -shortest -movflags +faststart "$C1/with_audio.mp4"

  # 4. Caption — "1941年12月7日 · 珍珠港" for first 3s
  CAPTION_START=0 CAPTION_END=3 \
    "$KIT/scripts/caption_overlay.sh" "$C1/with_audio.mp4" "1941年12月7日 · 珍珠港" \
      "$C1/with_caption.mp4" lower-third 0.5 56

  # 5. Build master SRT (per-segment SRTs offset into compiled timeline)
  python3 - <<PYEOF > "$C1/master.srt"
import re
def parse(p):
    cues=[]
    for b in open(p,encoding='utf-8').read().strip().split('\n\n'):
        ls=b.strip().split('\n')
        if len(ls)<3: continue
        m=re.match(r'(\d+):(\d+):(\d+)[,.](\d+)\s+-->\s+(\d+):(\d+):(\d+)[,.](\d+)',ls[1])
        if not m: continue
        a=[int(x) for x in m.groups()]
        s=a[0]*3600000+a[1]*60000+a[2]*1000+a[3]
        e=a[4]*3600000+a[5]*60000+a[6]*1000+a[7]
        cues.append((s,e,ls[2:]))
    return cues
def fmt(ms):
    h=ms//3600000; ms%=3600000
    mi=ms//60000;  ms%=60000
    s=ms//1000;    ms%=1000
    return f"{h:02d}:{mi:02d}:{s:02d},{ms:03d}"
segs=[
  ("$A/subtitles/clip02_PH_seg1_0016-0104.srt", 0),
  ("$A/subtitles/clip02_PH_seg2_0324-0343.srt", 48014),
  ("$A/subtitles/clip02_PH_seg3_0600-0614.srt", 67033),
]
out=[]
for p,off in segs:
    for s,e,t in parse(p): out.append((s+off,e+off,t))
for i,(s,e,t) in enumerate(out,1):
    print(i); print(f"{fmt(s)} --> {fmt(e)}")
    for ln in t: print(ln)
    print()
PYEOF

  # 6. Burn 14 bilingual cues sequentially via subtitle_burn.sh
  echo "Burning 14 subtitle cues (slow — each is a full re-encode)..."
  python3 - <<PYEOF
import re,subprocess,os,sys
cues=[]
for b in open("$C1/master.srt",encoding='utf-8').read().strip().split('\n\n'):
    ls=b.strip().split('\n')
    if len(ls)<3: continue
    m=re.match(r'(\d+):(\d+):(\d+)[,.](\d+)\s+-->\s+(\d+):(\d+):(\d+)[,.](\d+)',ls[1])
    if not m: continue
    a=[int(x) for x in m.groups()]
    s=a[0]*3600+a[1]*60+a[2]+a[3]/1000
    e=a[4]*3600+a[5]*60+a[6]+a[7]/1000
    en=ls[2] if len(ls)>=3 else ""
    zh=ls[3] if len(ls)>=4 else ""
    cues.append((s,e,en,zh))

cur="$C1/with_caption.mp4"
final="$A/video/pearl-harbor-dec7.mp4"
for i,(s,e,en,zh) in enumerate(cues,1):
    txt=f"$C1/sub_{i:02d}.txt"
    open(txt,"w",encoding="utf-8").write(f"{en}\n{zh}")
    out=final if i==len(cues) else f"$C1/sub_burn_{i:02d}.mp4"
    print(f"[{i}/{len(cues)}] {s:.1f}-{e:.1f}s")
    subprocess.run(["$KIT/scripts/subtitle_burn.sh",cur,out,f"{s:.2f}",f"{e:.2f}",f"@{txt}","bottom","40"],check=True)
    cur=out
PYEOF

  # Copy as cue1 stage artifact for the final chain
  cp "$A/video/pearl-harbor-dec7.mp4" "$S/cue1.mp4"
}

# ===========================================================================
# Cue 2 — Kunming before 1941 (≈72s)
# ===========================================================================
build_cue2() {
  echo "=== Cue 2: Kunming ==="
  local C2="$T/cue2"
  mkdir -p "$C2"

  # These Kunming stills are low-resolution (≤559px) and one is portrait. To show
  # each photo IN FULL (no crop) and tame the low-res look, composite it onto a
  # blurred + darkened copy of itself (documentary letterbox bed) with a thin
  # cream border. The blur is baked once into a still PNG — ken_burns' pad-blur
  # applies gblur per frame and OOM-kills at these durations, so we pre-render
  # the bed and then let ken_burns add only a gentle zoom to the finished still.
  full_frame() {  # src out_png — full image on a blurred self-bed, cream-bordered
    ffmpeg -y -loglevel error -i "$1" -filter_complex "\
[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,gblur=sigma=40,eq=brightness=-0.32:saturation=0.6,setsar=1[bg];\
[0:v]scale=1280:820:force_original_aspect_ratio=decrease:flags=lanczos,pad=iw+10:ih+10:5:5:color=0xE8E1C9,setsar=1[fg];\
[bg][fg]overlay=(W-w)/2:(H-h)/2[v]" -map "[v]" -frames:v 1 "$2"
  }

  # Sub A — 1940 bomber over Kunming, 22s, narration Cue2_A (~20.2s)
  full_frame "$A/images/194010_Kunming.jpeg" "$C2/c2a_full.png"
  "$KIT/scripts/ken_burns.sh" "$C2/c2a_full.png" "$C2/c2a_v.mp4" 22 zoom-in "$CANVAS" "$FPS" crop 1.05
  "$KIT/scripts/audio_attach.sh" "$C2/c2a_v.mp4" "$A/narration/clip02_Cue2_A.mp3" "$C2/c2a_audio.mp4"
  "$KIT/scripts/caption_overlay.sh" "$C2/c2a_audio.mp4" "1940年10月 · 昆明遭受频繁轰炸" "$C2/c2a.mp4" bottom-right 0.5 36

  # Sub B — 1941 city gate (portrait), 25s, narration Cue2_B (~23.4s)
  full_frame "$A/images/194112_Kunming.jpeg" "$C2/c2b_full.png"
  "$KIT/scripts/ken_burns.sh" "$C2/c2b_full.png" "$C2/c2b_v.mp4" 25 zoom-in "$CANVAS" "$FPS" crop 1.05
  "$KIT/scripts/audio_attach.sh" "$C2/c2b_v.mp4" "$A/narration/clip02_Cue2_B.mp3" "$C2/c2b_audio.mp4"
  "$KIT/scripts/caption_overlay.sh" "$C2/c2b_audio.mp4" "1941年 · 昆明 · 出城拱门" "$C2/c2b.mp4" bottom-right 0.5 36

  # Sub C — AVG airbase, 10s, narration Cue2_C (~8.0s)
  full_frame "$A/images/TigerAirBase_Kunming.jpg" "$C2/c2c_full.png"
  "$KIT/scripts/ken_burns.sh" "$C2/c2c_full.png" "$C2/c2c_v.mp4" 10 zoom-in "$CANVAS" "$FPS" crop 1.05
  "$KIT/scripts/audio_attach.sh" "$C2/c2c_v.mp4" "$A/narration/clip02_Cue2_C.mp3" "$C2/c2c_audio.mp4"
  "$KIT/scripts/caption_overlay.sh" "$C2/c2c_audio.mp4" "1941年 · 昆明 · 中国空军美籍志愿航空队基地" "$C2/c2c.mp4" bottom-right 0.5 36

  "$KIT/scripts/crossfade.sh" "$C2/c2a.mp4" "$C2/c2b.mp4" "$C2/c2c.mp4" "$S/cue2.mp4"
}

# ===========================================================================
# Cue 3 — First Battle (≈57s)
# ===========================================================================
build_cue3() {
  echo "=== Cue 3: First Battle ==="
  local C3="$T/cue3"
  mkdir -p "$C3"

  # Sub A — P-40 + Chinese soldier, zoom-in, 9s, narration Cue3_A
  "$KIT/scripts/ken_burns.sh" "$A/images/P40_withChineseSoldier.jpg" "$C3/c3a_v.mp4" 9 zoom-in "$CANVAS" "$FPS" crop
  "$KIT/scripts/audio_attach.sh" "$C3/c3a_v.mp4" "$A/narration/clip02_Cue3_A.mp3" "$C3/c3a_audio.mp4"
  "$KIT/scripts/caption_overlay.sh" "$C3/c3a_audio.mp4" '"飞虎队"在中国 · 陈纳德军事博物馆提供' "$C3/c3a.mp4" bottom-right 0.5 36

  # Sub B+C combined — banner always at top; article fades in at t=10s.
  # Single 20s video; Cue3_B narration spans both halves.
  ffmpeg -y -loglevel error \
    -f lavfi -t 20 -i "color=c=black:s=$CANVAS:r=$FPS" \
    -loop 1 -t 20 -i "$A/images/SanMateoTimes_title.jpg" \
    -loop 1 -t 20 -i "$A/images/19411220_p2_American_Down_Japs_Attacking_Burma_Rd_.jpg" \
    -filter_complex "[1:v]scale=1124:280:flags=lanczos[banner];[2:v]scale=-1:720:flags=lanczos,format=yuva420p,fade=in:st=10:d=1:alpha=1[article];[0:v][banner]overlay=(W-w)/2:30[bg];[bg][article]overlay=(W-w)/2:335:enable='gte(t\,10)':shortest=1[v]" \
    -map "[v]" -t 20 -r "$FPS" -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -movflags +faststart \
    "$C3/c3bc_v.mp4"

  CAPTION_START=0 CAPTION_END=5 \
    "$KIT/scripts/caption_overlay.sh" "$C3/c3bc_v.mp4" \
      "《圣马特奥时报》 · 旧金山地方小报 · 覆盖圣马特奥和伯灵格姆 · 1941年约3.5万人口" \
      "$C3/c3bc_cap1.mp4" bottom-right 0.5 32
  CAPTION_START=5 CAPTION_END=10 \
    "$KIT/scripts/caption_overlay.sh" "$C3/c3bc_cap1.mp4" \
      "伯灵格姆（Burlingame），以美国前驻华公使蒲安臣命名。他曾代表清朝政府出使西方，被视为中国近代第一位官方外交使节" \
      "$C3/c3bc_cap2.mp4" bottom-right 0.5 32
  CAPTION_START=10 CAPTION_END=20 \
    "$KIT/scripts/caption_overlay.sh" "$C3/c3bc_cap2.mp4" \
      "《圣马特奥时报》 · 1941年12月20日" \
      "$C3/c3bc_captioned.mp4" bottom-right 0.5 36
  "$KIT/scripts/audio_attach.sh" "$C3/c3bc_captioned.mp4" "$A/narration/clip02_Cue3_B.mp3" "$C3/c3bc.mp4"

  # Sub D — LA Times slow-pan + spotlight reveal.
  # (Slow document pan + feathered paragraph spotlight; see the kit's
  #  text_spotlight.sh recipe for the single-box variant.)
  ffmpeg -y -loglevel error -i "$A/images/19411221LAtimes_US_flyers_Bag_Four_Jap_Planes.jpg" \
    -vf "scale=650:4838:flags=lanczos" "$C3/article_scaled.png"

  python3 - <<PYEOF
from PIL import Image, ImageDraw, ImageFilter
CANVAS=(1920,1080); DIM_ALPHA=220; BOX=(615,375,1305,650); RADIUS=28; FEATHER=22
a=Image.new("L",CANVAS,255)
ImageDraw.Draw(a).rounded_rectangle(BOX,radius=RADIUS,fill=0)
a=a.filter(ImageFilter.GaussianBlur(radius=FEATHER)).point(lambda v:int(v*DIM_ALPHA/255))
black=Image.new("RGB",CANVAS,(0,0,0))
Image.merge("RGBA",(*black.split(),a)).save("$C3/spotlight.png")
PYEOF

  local DUR=26 PAN_DUR=22
  ffmpeg -y -loglevel error \
    -f lavfi -t $DUR -i "color=c=black:s=$CANVAS:r=$FPS" \
    -loop 1 -t $DUR -i "$C3/article_scaled.png" \
    -loop 1 -t $DUR -i "$C3/spotlight.png" \
    -filter_complex "[0:v][1:v]overlay=635:'if(lt(t\,${PAN_DUR}), -2660*t/${PAN_DUR}, -2660)':shortest=1[scroll];[2:v]format=rgba,fade=in:st=${PAN_DUR}:d=0.5:alpha=1[sp];[scroll][sp]overlay=0:0:enable='gte(t\,${PAN_DUR})':shortest=1[v]" \
    -map "[v]" -t $DUR -r "$FPS" -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -movflags +faststart \
    "$C3/c3d_v.mp4"
  "$KIT/scripts/audio_attach.sh" "$C3/c3d_v.mp4" "$A/narration/clip02_Cue3_C.mp3" "$C3/c3d_audio.mp4"
  "$KIT/scripts/caption_overlay.sh" "$C3/c3d_audio.mp4" "《洛杉矶时报》 · 1941年12月21日 · A.V.G. 称号首次出现" "$C3/c3d.mp4" bottom-right 0.5 36

  "$KIT/scripts/crossfade.sh" "$C3/c3a.mp4" "$C3/c3bc.mp4" "$C3/c3d.mp4" "$S/cue3.mp4"
}

# ===========================================================================
# Build (skip cues whose stage artifact already exists)
# ===========================================================================
[[ -f "$S/cue1.mp4" ]] || build_cue1
[[ -f "$S/cue2.mp4" ]] || build_cue2
[[ -f "$S/cue3.mp4" ]] || build_cue3

# Final crossfade
"$KIT/scripts/crossfade.sh" "$S/cue1.mp4" "$S/cue2.mp4" "$S/cue3.mp4" "$OUT/clip.mp4"
echo "Done: $OUT/clip.mp4"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/clip.mp4"
