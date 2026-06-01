#!/usr/bin/env bash
set -euo pipefail

# build_clip.sh — assembles clip03-fallen-hero/output/clip.mp4
#
# Run from this directory. Idempotent: missing intermediates are rebuilt,
# existing ones are reused. To force a full rebuild: rm -rf tmp stage output
# before invoking.
#
# Cue structure (≈1:20 total):
#   Cue 1 — A Name in the Papers (≈18s)
#     Sub A: Newkirk USN portrait — 220×294 low-res, framed inset + slow push (6.5s)
#     Sub B: Newkirk 2nd-Sq chalkboard photo — 250×364 low-res, framed inset (6.5s)
#     Sub C: 2nd Squadron "Panda Bears" group photo, push to front-row middle (6s)
#     (The Feb-12-1942 SMT "TIGER FLIERS" headline moved to clip04 Cue 2.)
#   Cue 2 — Lost over Thailand (≈25s)
#     Sub A: Thailand locator map (marked), push toward Chiang Mai (12s)
#     Sub B: P-40 in flight (AI-gen, banking pass), slow zoom + caption (13s)
#   Cue 3 — What the Name Carries (≈30s)
#     Sub A: SMT 1942-03-25 article, pan top → "Newkirk Killed" + spotlight (9s)
#     Sub B: pan → "Liked to Shoot"/"He was 28", two-box spotlight + sub (11s)
#     Sub C: bilingual memorial bust, full image + subtitle (10s)

KIT="${KIT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/../video-production-kit}"
A="assets"
T="tmp"
S="stage/cues"
OUT="output"
CANVAS="1920x1080"
FPS=30
SAMPLE_RATE=44100

# ---------------------------------------------------------------------------
# Preflight — fail early with a clear message if anything is missing.
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
    for s in ken_burns.sh lowres_frame.sh text_spotlight.sh audio_attach.sh caption_overlay.sh crossfade.sh; do
      if [[ ! -f "$KIT/scripts/$s" ]]; then
        echo "build_clip: kit is missing script: scripts/$s under $KIT" >&2
        missing=1
      fi
    done
  fi
  [[ $missing -eq 0 ]] || exit 1
}
preflight

mkdir -p "$T/cue1" "$T/cue2" "$T/cue3" "$S" "$OUT"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# concat_silent OUT IN1 IN2 [IN3...] — simple back-to-back concat (no
# transition) of silent sub-clips into a single silent clip. Re-encodes to
# guarantee the result plays cleanly on any decoder.
concat_silent() {
  local out="$1"; shift
  local list="${out%.mp4}.concat.txt"
  : > "$list"
  for f in "$@"; do
    printf "file '%s'\n" "$(cd "$(dirname "$f")" && pwd)/$(basename "$f")" >> "$list"
  done
  ffmpeg -y -loglevel error -f concat -safe 0 -i "$list" \
    -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -r "$FPS" \
    -movflags +faststart "$out"
}

# ===========================================================================
# Cue 1 — A Name in the Papers (≈18s)
# ===========================================================================
build_cue1() {
  echo "=== Cue 1: A Name in the Papers ==="
  local C1="$T/cue1"
  local border="0xE8E1C9"   # cream/parchment frame

  # Sub A — Newkirk USN portrait (220×294, low-res). Gentle push at inset size,
  # then frame as a cream-bordered inset on black. Caption first 3s.
  # KB_PRESCALE_W trimmed to 3000 so the tiny source isn't blown to an 8000px
  # (≈340 MB) RGBA buffer — the inset is only 600px wide.
  KB_PRESCALE_W=3000 "$KIT/scripts/ken_burns.sh" \
    "$A/images/JackNewkirk_portrait_USN.jpg" "$C1/c1a_kb.mp4" 6.5 zoom-in 600x800 "$FPS" crop 1.08
  "$KIT/scripts/lowres_frame.sh" "$C1/c1a_kb.mp4" "$C1/c1a_v.mp4" 600 800 12 "$border"
  CAPTION_START=0 CAPTION_END=3 \
    "$KIT/scripts/caption_overlay.sh" "$C1/c1a_v.mp4" \
      "杰克·纽柯克 · 1913-1942" \
      "$C1/c1a.mp4" lower-third 0.5 96

  # Sub B — Newkirk 2nd-Sq chalkboard photo (250×364, low-res). Same framed
  # treatment. Caption first 3s, bottom-left.
  KB_PRESCALE_W=3000 "$KIT/scripts/ken_burns.sh" \
    "$A/images/JackNewkirk_2ndSQ.jpg" "$C1/c1b_kb.mp4" 6.5 zoom-in 550x800 "$FPS" crop 1.08
  "$KIT/scripts/lowres_frame.sh" "$C1/c1b_kb.mp4" "$C1/c1b_v.mp4" 550 800 12 "$border"
  CAPTION_START=0 CAPTION_END=3 \
    "$KIT/scripts/caption_overlay.sh" "$C1/c1b_v.mp4" \
      "杰克·纽柯克 · 第二中队“熊猫队”" \
      "$C1/c1b.mp4" bottom-left 0.5 96

  # Sub C — Panda Bears group photo (875×524), slow push toward the middle of
  # the front row (focal 0.5,0.60; zoom 1.35 keeps that focal in-band).
  # Footnote caption, full duration, bottom-right.
  "$KIT/scripts/ken_burns.sh" "$A/images/AVG_2ndSquadron_PandaBears_pilots.jpg" \
    "$C1/c1c_v.mp4" 6 "zoom-in:0.5,0.60" "$CANVAS" "$FPS" crop 1.35
  "$KIT/scripts/caption_overlay.sh" "$C1/c1c_v.mp4" \
    "AVG 第二中队“熊猫队” · 纽柯克任中队长" \
    "$C1/c1c.mp4" bottom-right 0.5 36

  # Concat silent then attach narration (.mp3 for this cue)
  concat_silent "$C1/c1_silent.mp4" "$C1/c1a.mp4" "$C1/c1b.mp4" "$C1/c1c.mp4"
  "$KIT/scripts/audio_attach.sh" "$C1/c1_silent.mp4" "$A/narration/clip03_Cue1.mp3" "$S/cue1.mp4"
}

# ===========================================================================
# Cue 2 — Lost over Thailand (≈25s)
# ===========================================================================
build_cue2() {
  echo "=== Cue 2: Lost over Thailand ==="
  local C2="$T/cue2"

  # Sub A — Thailand locator map (marked: red dot + 清迈 label at the city),
  # slow push toward Chiang Mai. Focal 0.20,0.13 = the dot's normalized
  # position on the 1052×1849 map. pad-blur keeps the tall portrait map whole
  # with a blurred fill; 12s stays under the pad-blur OOM band. PRESCALE
  # trimmed to 3000 so the tall source isn't blown to a giant RGBA buffer.
  KB_PRESCALE_W=3000 "$KIT/scripts/ken_burns.sh" \
    "$A/images/Thailand_ChiangMai_locator_marked.png" "$C2/c2a_v.mp4" \
    12 "zoom-in:0.20,0.13" "$CANVAS" "$FPS" pad-blur 1.5
  CAPTION_START=0 CAPTION_END=4 \
    "$KIT/scripts/caption_overlay.sh" "$C2/c2a_v.mp4" \
      "泰国清迈" \
      "$C2/c2a.mp4" top-third 0.5 56

  # Sub B — P-40 in flight (AI-gen, banking pass), slow zoom (13s).
  # Caption first 4s: date · place (near Chiang Mai / Lampang) · subject · AI tag.
  "$KIT/scripts/ken_burns.sh" "$A/images/P40_AVG_inflight_AIgen.png" \
    "$C2/c2b_v.mp4" 13 zoom-in "$CANVAS" "$FPS" crop 1.2
  CAPTION_START=0 CAPTION_END=4 \
    "$KIT/scripts/caption_overlay.sh" "$C2/c2b_v.mp4" \
      "1942 年 3 月 24 日 · 泰国清迈附近（南邦） · 纽柯克 (AI 生成)" \
      "$C2/c2b.mp4" lower-third 0.5 40

  concat_silent "$C2/c2_silent.mp4" "$C2/c2a.mp4" "$C2/c2b.mp4"
  "$KIT/scripts/audio_attach.sh" "$C2/c2_silent.mp4" "$A/narration/clip03_Cue2.mp3" "$S/cue2.mp4"
}

# ===========================================================================
# Cue 3 — What the Name Carries (≈30s)
# ===========================================================================
# Target paragraphs measured from a ruler-annotated crop of the 524×3129
# source (NOT estimated line heights — per the spotlight recipe's gotcha):
#   "Newkirk Killed"  src y 816–842
#   "Liked to Shoot"  src y 2156–2182
#   "He was 28."      src y 2280–2304
build_cue3() {
  echo "=== Cue 3: What the Name Carries ==="
  local C3="$T/cue3"
  local ART="$A/images/19420325_p2_newkirk_flyingtiger.jpg"
  local TW=650   # article scaled width on the 1920 canvas (≈⅓)

  # Sub A — pan top → "Newkirk Killed", feathered spotlight, hold 3s.
  "$KIT/scripts/text_spotlight.sh" "$ART" "$C3/c3a.mp4" 816 26 6 3 "$TW"

  # Sub B — continue the pan from "Newkirk Killed" down to the
  # "Liked to Shoot" / "He was 28" block, then a TWO-box feathered spotlight.
  # Custom graph: text_spotlight.sh is single-box and always pans from the
  # top, so it can't do this continuation + dual highlight.
  build_cue3_subB "$ART" "$C3/c3b_v.mp4" "$TW"
  CAPTION_START=6 CAPTION_END=11 \
    "$KIT/scripts/caption_overlay.sh" "$C3/c3b_v.mp4" \
      "《圣马特奥时报》 · 1942年3月25日" \
      "$C3/c3b.mp4" lower-third 0.5 36

  # Sub C — bilingual memorial bust, full image (pad-blur), very gentle push.
  KB_PRESCALE_W=3000 "$KIT/scripts/ken_burns.sh" \
    "$A/images/JackMewkirk_memorialstatue.jpeg" "$C3/c3c_v.mp4" \
    10 zoom-in "$CANVAS" "$FPS" pad-blur 1.06
  CAPTION_START=7 CAPTION_END=10 \
    "$KIT/scripts/caption_overlay.sh" "$C3/c3c_v.mp4" \
      "四川民间纪念馆" \
      "$C3/c3c.mp4" lower-third 0.5 36

  concat_silent "$C3/c3_silent.mp4" "$C3/c3a.mp4" "$C3/c3b.mp4" "$C3/c3c.mp4"
  "$KIT/scripts/audio_attach.sh" "$C3/c3_silent.mp4" "$A/narration/clip03_Cue3.mp3" "$S/cue3.mp4"
}

# build_cue3_subB ART OUT TARGET_WIDTH — pan continuation + two-box spotlight.
# Pans from "Newkirk Killed" (centered, continuing Sub A's end position) down
# to the midpoint of the two target lines centered on canvas, then fades in a
# feathered spotlight over BOTH "Liked to Shoot" and "He was 28". Output silent.
build_cue3_subB() {
  local art="$1" out="$2" tw="$3"
  local pan=7 hold=4 pad=10
  local cw="${CANVAS%x*}" ch="${CANVAS#*x}"

  local src_w src_h
  IFS=',' read -r src_w src_h < <(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height -of csv=p=0 "$art")
  local sc scaled_h img_x
  sc=$(awk -v t="$tw" -v s="$src_w" 'BEGIN{printf "%.6f", t/s}')
  scaled_h=$(awk -v s="$src_h" -v c="$sc" 'BEGIN{printf "%d", s*c+0.5}')
  img_x=$(awk -v cw="$cw" -v sw="$tw" 'BEGIN{printf "%d", (cw-sw)/2}')

  # Pan start = "Newkirk Killed" centered (src cy 829); pan end = midpoint of
  # the two targets centered (src cy 2230).
  local pstart pend delta total
  pstart=$(awk -v y=829  -v c="$sc" -v ch="$ch" 'BEGIN{printf "%.0f", y*c-ch/2}')
  pend=$(awk   -v y=2230 -v c="$sc" -v ch="$ch" 'BEGIN{printf "%.0f", y*c-ch/2}')
  delta=$(awk -v a="$pstart" -v b="$pend" 'BEGIN{printf "%.0f", b-a}')
  total=$(awk -v p="$pan" -v h="$hold" 'BEGIN{printf "%.3f", p+h}')

  # Spotlight boxes in canvas coords at pan-end.
  local bl br b1t b1b b2t b2b
  bl=$(awk -v x="$img_x" -v p="$pad" 'BEGIN{printf "%d", x-p}')
  br=$(awk -v x="$img_x" -v w="$tw" -v p="$pad" 'BEGIN{printf "%d", x+w+p}')
  b1t=$(awk -v y=2156 -v c="$sc" -v e="$pend" -v p="$pad" 'BEGIN{printf "%d", y*c-e-p}')
  b1b=$(awk -v y=2182 -v c="$sc" -v e="$pend" -v p="$pad" 'BEGIN{printf "%d", y*c-e+p}')
  b2t=$(awk -v y=2280 -v c="$sc" -v e="$pend" -v p="$pad" 'BEGIN{printf "%d", y*c-e-p}')
  b2b=$(awk -v y=2304 -v c="$sc" -v e="$pend" -v p="$pad" 'BEGIN{printf "%d", y*c-e+p}')

  local art_png="${out%.*}.article_scaled.png" mask_png="${out%.*}.spotlight.png"
  ffmpeg -y -loglevel error -i "$art" -vf "scale=${tw}:${scaled_h}:flags=lanczos" "$art_png"

  CANVAS_W="$cw" CANVAS_H="$ch" DIM_ALPHA="${DIM_ALPHA:-220}" \
  RADIUS="${RADIUS:-28}" FEATHER="${FEATHER:-22}" \
  BL="$bl" BR="$br" B1T="$b1t" B1B="$b1b" B2T="$b2t" B2B="$b2b" \
  OUT_PNG="$mask_png" python3 - <<'PYEOF'
import os
from PIL import Image, ImageDraw, ImageFilter
W=int(os.environ["CANVAS_W"]); H=int(os.environ["CANVAS_H"])
DIM=int(os.environ["DIM_ALPHA"]); R=int(os.environ["RADIUS"]); F=int(os.environ["FEATHER"])
L=int(os.environ["BL"]); Rr=int(os.environ["BR"])
boxes=[(L,int(os.environ["B1T"]),Rr,int(os.environ["B1B"])),
       (L,int(os.environ["B2T"]),Rr,int(os.environ["B2B"]))]
alpha=Image.new("L",(W,H),255)
d=ImageDraw.Draw(alpha)
for b in boxes: d.rounded_rectangle(b,radius=R,fill=0)
alpha=alpha.filter(ImageFilter.GaussianBlur(radius=F)).point(lambda v:int(v*DIM/255))
black=Image.new("RGB",(W,H),(0,0,0))
Image.merge("RGBA",(*black.split(),alpha)).save(os.environ["OUT_PNG"])
PYEOF

  local oy="if(lt(t\\,${pan}), -(${pstart}+${delta}*t/${pan}), -${pend})"
  ffmpeg -y -loglevel error \
    -f lavfi -t "$total" -i "color=c=black:s=${cw}x${ch}:r=${FPS}" \
    -loop 1 -t "$total" -i "$art_png" \
    -loop 1 -t "$total" -i "$mask_png" \
    -filter_complex "\
[0:v][1:v]overlay=${img_x}:'${oy}':shortest=1[scroll];\
[2:v]format=rgba,fade=in:st=${pan}:d=0.5:alpha=1[sp];\
[scroll][sp]overlay=0:0:enable='gte(t\\,${pan})':shortest=1[v]" \
    -map "[v]" -t "$total" -r "$FPS" \
    -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -movflags +faststart "$out"
}

# ===========================================================================
# Build. Default: all cues (reusing existing stage artifacts) + crossfade.
# Set CUE=1|2|3 to force-rebuild a single cue's stage artifact only — for
# per-cue review before chaining into the clip.
# ===========================================================================
case "${CUE:-all}" in
  1) rm -f "$S/cue1.mp4"; build_cue1; echo "Built $S/cue1.mp4"; exit 0 ;;
  2) rm -f "$S/cue2.mp4"; build_cue2; echo "Built $S/cue2.mp4"; exit 0 ;;
  3) rm -f "$S/cue3.mp4"; build_cue3; echo "Built $S/cue3.mp4"; exit 0 ;;
esac

[[ -f "$S/cue1.mp4" ]] || build_cue1
[[ -f "$S/cue2.mp4" ]] || build_cue2
[[ -f "$S/cue3.mp4" ]] || build_cue3

# Final crossfade
"$KIT/scripts/crossfade.sh" "$S/cue1.mp4" "$S/cue2.mp4" "$S/cue3.mp4" "$OUT/clip.mp4"
echo "Done: $OUT/clip.mp4"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/clip.mp4"
