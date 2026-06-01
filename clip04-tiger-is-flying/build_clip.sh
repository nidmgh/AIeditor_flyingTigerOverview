#!/usr/bin/env bash
set -euo pipefail

# build_clip.sh — assembles clip04-tiger-is-flying/output/clip.mp4
#
# Run from this directory. Idempotent: missing intermediates are rebuilt,
# existing ones are reused. To force a full rebuild: rm -rf tmp stage output.
# Set CUE=1|2|3 to force-rebuild a single cue's stage artifact (per-cue review).
#
# Cue structure:
#   Cue 1 — where the "Flying Tigers" name (≈34s)
#     Sub A: SMT 1942-02-12 p6, full page (pad-blur) → push to headline (9s)
#     Sub B: same page, focal MOVE headline → "Flying Tigers"/Chennault
#            paragraph, then a feathered spotlight on the paragraph (14s)
#       (Subs A+B share narration clip04_cue1A.mp3)
#     Sub C: 3rd Sq "Hell's Angels" photo, cream-framed low-res, focal push
#            to the shark-mouth nose (12s; narration clip04_cue1B.mp3)

KIT="${KIT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/../video-production-kit}"
A="assets"
T="tmp"
S="stage/cues"
OUT="output"
CANVAS="1920x1080"
FPS=30

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
preflight() {
  local missing=0
  for cmd in ffmpeg ffprobe python3; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "build_clip: missing dependency: $cmd" >&2; missing=1; }
  done
  python3 -c 'import PIL' >/dev/null 2>&1 || { echo "build_clip: missing python3 Pillow (pip3 install --user Pillow)" >&2; missing=1; }
  if [[ ! -d "$KIT" ]]; then
    echo "build_clip: video-production-kit not found at: $KIT (override with KIT=...)" >&2
    missing=1
  else
    for s in ken_burns.sh lowres_frame.sh caption_overlay.sh audio_attach.sh crossfade.sh; do
      [[ -f "$KIT/scripts/$s" ]] || { echo "build_clip: kit missing scripts/$s under $KIT" >&2; missing=1; }
    done
  fi
  [[ $missing -eq 0 ]] || exit 1
}
preflight

mkdir -p "$T/cue1" "$S" "$OUT"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# concat_silent OUT IN1 IN2 ... — back-to-back concat (re-encoded).
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

# headline_to_para OUT — Sub B custom graph. Crops the page to its top 16:9
# band (headline + the "Can't Find Enough" paragraph), zoom+pans from the
# headline framing to the paragraph, then holds and fades in a feathered
# spotlight over the paragraph (which names "Flying Tigers" and Chennault).
# Coordinates measured from a ruler grid over the 1366×1561 source:
#   headline  ≈ src y 45–265 (full width)
#   paragraph ≈ src x 18–518, y 470–598  ("Can't Find Enough" → Chennault)
headline_to_para() {
  local out="$1"
  local img="$A/images/19420212_p6_tigerfliers.jpg"
  local move=8 total=14
  local cw="${CANVAS%x*}" ch="${CANVAS#*x}"
  local mf=$(( move * FPS )) tf=$(( total * FPS ))

  # Crop the page to its top 16:9 band (1366×768) so headline + paragraph
  # share the frame; pre-scale for smooth zoompan.
  local crop_png="${out%.*}.topband.png"
  ffmpeg -y -loglevel error -i "$img" -vf "crop=1366:768:0:0,scale=2048:-2:flags=lanczos" "$crop_png"

  # Spotlight box (canvas coords) at the end framing (zoom 1.6; window clamps
  # to the left edge and near the crop bottom, centering the paragraph).
  # Measured against the rendered hold frame.
  local bl=30 bt=399 br=1175 bb=707
  local mask_png="${out%.*}.spotlight.png"
  CANVAS_W="$cw" CANVAS_H="$ch" DIM_ALPHA=220 RADIUS=28 FEATHER=22 \
  BL="$bl" BT="$bt" BR="$br" BB="$bb" OUT_PNG="$mask_png" python3 - <<'PYEOF'
import os
from PIL import Image, ImageDraw, ImageFilter
W=int(os.environ["CANVAS_W"]); H=int(os.environ["CANVAS_H"])
DIM=int(os.environ["DIM_ALPHA"]); R=int(os.environ["RADIUS"]); F=int(os.environ["FEATHER"])
box=(int(os.environ["BL"]),int(os.environ["BT"]),int(os.environ["BR"]),int(os.environ["BB"]))
alpha=Image.new("L",(W,H),255)
ImageDraw.Draw(alpha).rounded_rectangle(box,radius=R,fill=0)
alpha=alpha.filter(ImageFilter.GaussianBlur(radius=F)).point(lambda v:int(v*DIM/255))
black=Image.new("RGB",(W,H),(0,0,0))
Image.merge("RGBA",(*black.split(),alpha)).save(os.environ["OUT_PNG"])
PYEOF

  # Move: P=min(on/mf,1); zoom 1.25→1.60; focal (0.50,0.20)→(0.196,0.695).
  local P="min(on/${mf}\\,1)"
  local Z="1.25+0.35*${P}"
  local X="max(0\\,min(iw-iw/zoom\\,iw*(0.50-0.304*${P})-iw/zoom/2))"
  local Y="max(0\\,min(ih-ih/zoom\\,ih*(0.20+0.495*${P})-ih/zoom/2))"

  ffmpeg -y -loglevel error \
    -loop 1 -framerate "$FPS" -t "$total" -i "$crop_png" \
    -loop 1 -t "$total" -i "$mask_png" \
    -filter_complex "\
[0:v]zoompan=z='${Z}':x='${X}':y='${Y}':d=${tf}:s=${cw}x${ch}:fps=${FPS},format=yuv420p[mv];\
[1:v]format=rgba,fade=in:st=${move}:d=0.5:alpha=1[sp];\
[mv][sp]overlay=0:0:enable='gte(t\\,${move})':shortest=1[v]" \
    -map "[v]" -t "$total" -r "$FPS" \
    -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -movflags +faststart "$out"
}

# build_item1 OUT — Sub A: full page (pad-blur), gentle push toward the
# headline. Low zoom (1.10) keeps the full-width "TIGER FLIERS … BURMA ROAD"
# headline uncropped through the push.
build_item1() {
  KB_PRESCALE_W=3000 "$KIT/scripts/ken_burns.sh" \
    "$A/images/19420212_p6_tigerfliers.jpg" "$1" \
    9 "zoom-in:0.5,0.16" "$CANVAS" "$FPS" pad-blur 1.05
}

# build_item3 OUT — Sub C: 3rd Sq photo, cream-framed low-res, focal push to
# the shark-mouth nose (upper-left, near center).
build_item3() {
  local kb="${1%.*}_kb.mp4"
  KB_PRESCALE_W=3000 "$KIT/scripts/ken_burns.sh" \
    "$A/images/FlyingTigers_3rdSQ.jpg" "$kb" \
    12 "zoom-in:0.30,0.37" 1200x800 "$FPS" crop 1.35
  "$KIT/scripts/lowres_frame.sh" "$kb" "$1" 1200 800 12 0xE8E1C9
}

# ===========================================================================
# Cue 1 — where the "Flying Tigers" name (≈34s)
# ===========================================================================
build_cue1() {
  echo "=== Cue 1: where the Flying Tigers name ==="
  local C1="$T/cue1"
  local SMT="《圣马特奥时报》 · 1942 年 2 月 12 日 · 第 6 版"

  build_item1 "$C1/c1a_v.mp4"
  CAPTION_START=6 CAPTION_END=9 \
    "$KIT/scripts/caption_overlay.sh" "$C1/c1a_v.mp4" "$SMT" \
      "$C1/c1a.mp4" lower-third 0.5 36

  headline_to_para "$C1/c1b_v.mp4"
  CAPTION_START=11 CAPTION_END=14 \
    "$KIT/scripts/caption_overlay.sh" "$C1/c1b_v.mp4" "$SMT" \
      "$C1/c1b.mp4" lower-third 0.5 36

  build_item3 "$C1/c1c_v.mp4"
  CAPTION_START=9 CAPTION_END=12 \
    "$KIT/scripts/caption_overlay.sh" "$C1/c1c_v.mp4" \
      "第三中队: “地狱天使（Hell's Angels）”中队" \
      "$C1/c1c.mp4" lower-third 0.5 36

  # Segment A (subs 1+2) carries clip04_cue1A.mp3; segment B (sub 3) cue1B.
  concat_silent "$C1/segA_silent.mp4" "$C1/c1a.mp4" "$C1/c1b.mp4"
  "$KIT/scripts/audio_attach.sh" "$C1/segA_silent.mp4" "$A/narration/clip04_cue1A.mp3" "$C1/segA.mp4"
  "$KIT/scripts/audio_attach.sh" "$C1/c1c.mp4" "$A/narration/clip04_cue1B.mp3" "$C1/segB.mp4"
  concat_silent "$S/cue1.mp4" "$C1/segA.mp4" "$C1/segB.mp4"
}

# ===========================================================================
# Cue 2 — The Chinese nickname became "official" (≈17s)
# ===========================================================================
build_cue2() {
  echo "=== Cue 2: the Chinese nickname became official ==="
  local C2="$T/cue2"; mkdir -p "$C2"

  # Item 1 — R.T. Smith beside the Disney tiger insignia (insignia left, Smith
  # right); slow pan left across the scene toward the winged-tiger insignia.
  "$KIT/scripts/ken_burns.sh" "$A/images/Flying_tigers_pilot_Smith.jpg" \
    "$C2/c2a_v.mp4" 9 pan-left "$CANVAS" "$FPS" crop 1.25
  CAPTION_START=0 CAPTION_END=4 \
    "$KIT/scripts/caption_overlay.sh" "$C2/c2a_v.mp4" \
      "中国昆明 · 王牌飞行员罗伯特·“R.T.”·史密斯 · 迪斯尼公司设计“飞虎队”官方标志" \
      "$C2/c2a.mp4" lower-third 0.5 36

  # Item 2 — Hank Porter's original sketch; zoom to the upper-left dedication.
  KB_PRESCALE_W=3000 "$KIT/scripts/ken_burns.sh" \
    "$A/images/FlyingTigerbyHankPorter.jpg" "$C2/c2b_v.mp4" \
    8 "zoom-in:0.15,0.13" "$CANVAS" "$FPS" crop 1.6
  CAPTION_START=0 CAPTION_END=4 \
    "$KIT/scripts/caption_overlay.sh" "$C2/c2b_v.mp4" \
      "迪斯尼设计师汉克·波特绘制的飞虎队原始草图" \
      "$C2/c2b.mp4" lower-third 0.5 36

  concat_silent "$C2/c2_silent.mp4" "$C2/c2a.mp4" "$C2/c2b.mp4"
  "$KIT/scripts/audio_attach.sh" "$C2/c2_silent.mp4" "$A/narration/Clip04_cue2.mp3" "$S/cue2.mp4"
}

# wrapcap IN OUT TEXT FONT_SIZE Y_FRAC START END — overlay a word-wrapped
# caption (centered plate, semi-transparent) on IN during [START,END]. caption_
# overlay.sh renders a single un-wrapped line; these cue-3 captions are long and
# font 96, so they must wrap. Y_FRAC is the plate's vertical center (0..1), so
# two captions can stack (e.g. 0.70 main + 0.88 footnote). Plate spans the full
# clip; fades gate visibility (see the srt_burn truncation bug).
wrapcap() {
  local in="$1" out="$2" text="$3" fs="$4" yf="$5" st="$6" en="$7"
  local cw="${CANVAS%x*}" ch="${CANVAS#*x}"
  local plate="${out%.*}.cap.png"
  local dur; dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$in")
  CAP_W="$cw" CAP_H="$ch" TEXT="$text" FS="$fs" YF="$yf" \
  FONT="${CAP_FONT:-/System/Library/Fonts/Supplemental/Songti.ttc}" OUT_PNG="$plate" \
  python3 - <<'PYEOF'
import os
from PIL import Image, ImageDraw, ImageFont
W=int(os.environ["CAP_W"]); H=int(os.environ["CAP_H"])
text=os.environ["TEXT"]; fs=int(os.environ["FS"]); yf=float(os.environ["YF"])
font=ImageFont.truetype(os.environ["FONT"], fs)
canvas=Image.new("RGBA",(W,H),(0,0,0,0)); d=ImageDraw.Draw(canvas)
maxw=int(W*0.85)
def measure(s): b=d.textbbox((0,0),s,font=font); return b[2]-b[0]
lines=[]
for para in text.split("\n"):
    line=""
    for ch in list(para):
        if measure(line+ch)<=maxw: line+=ch
        else:
            if line: lines.append(line)
            line=ch
    if line: lines.append(line)
lh=int(fs*1.35); th=lh*len(lines); padx,pady=30,16
widest=max((measure(l) for l in lines), default=0)
bw=widest+2*padx; bh=th+2*pady
bx=(W-bw)//2; by=int(yf*H-bh/2)
d.rectangle([bx,by,bx+bw,by+bh], fill=(0,0,0,140))
y=by+pady
for l in lines:
    b=d.textbbox((0,0),l,font=font); x=bx+(bw-measure(l))//2
    d.text((x-b[0], y-b[1]), l, font=font, fill=(255,255,255,255)); y+=lh
canvas.save(os.environ["OUT_PNG"])
PYEOF
  local fo; fo=$(awk -v e="$en" 'BEGIN{printf "%.3f", e-0.3}')
  ffmpeg -y -loglevel error -i "$in" -loop 1 -framerate "$FPS" -t "$dur" -i "$plate" \
    -filter_complex "[1]format=rgba,fade=in:st=${st}:d=0.3:alpha=1,fade=out:st=${fo}:d=0.3:alpha=1[c];[0:v][c]overlay=0:0:format=auto:shortest=1[v]" \
    -map "[v]" -map "0:a?" -c:a copy \
    -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -movflags +faststart "$out"
}

# ===========================================================================
# Cue 3 — AVG end, the Tiger keeps flying (≈19s, narration clip04_cue3.mp3)
# ===========================================================================
build_cue3() {
  echo "=== Cue 3: AVG end, the Tiger keeps flying ==="
  local C3="$T/cue3"; mkdir -p "$C3"

  # Item 1 — black title card: AVG disbanded, 1942-07-03 (~5s).
  "$KIT/scripts/title_card.sh" \
    "1942年7月3日 中华民国空军美籍志愿大队奉命解散" \
    "$C3/c3a.mp4" 5 "$CANVAS" "$FPS" 72

  # Item 2 — AVG group photo, slow zoom + bottom-third caption (first 5s).
  KB_PRESCALE_W=3000 "$KIT/scripts/ken_burns.sh" \
    "$A/images/clip01_Flying_Tigers_group.jpg" "$C3/c3b_v.mp4" 7 zoom-in "$CANVAS" "$FPS" crop 1.18
  wrapcap "$C3/c3b_v.mp4" "$C3/c3b.mp4" "1942年7月4日 · 昆明 · 美国第23战斗机大队成立" 56 0.82 0 5

  # Item 3 — 76th Sq photo, slow zoom + main caption + smaller footnote (first 5s).
  KB_PRESCALE_W=3000 "$KIT/scripts/ken_burns.sh" \
    "$A/images/AF14_23_76.png" "$C3/c3c_v.mp4" 7 zoom-in "$CANVAS" "$FPS" crop 1.15
  wrapcap "$C3/c3c_v.mp4" "$C3/c3c_1.mp4" "美国第14空军第23战斗机大队第76中队的成员" 56 0.76 0 5
  wrapcap "$C3/c3c_1.mp4" "$C3/c3c.mp4" "美国空军正式成立于1947年，此时第14空军隶属陆军" 40 0.88 0 5

  # Concat then attach the ~18.6s narration.
  concat_silent "$C3/c3_silent.mp4" "$C3/c3a.mp4" "$C3/c3b.mp4" "$C3/c3c.mp4"
  "$KIT/scripts/audio_attach.sh" "$C3/c3_silent.mp4" "$A/narration/clip04_cue3.mp3" "$S/cue3.mp4"
}

# ===========================================================================
# Cue 4 — Flying Tiger newsreels (the 3-segment compile w/ Chinese subs)
# ===========================================================================
build_cue4() {
  echo "=== Cue 4: Flying Tiger newsreels (3-segment compile, dip-to-black joins, 1080p ZH subs) ==="
  local cw="${CANVAS%x*}" ch="${CANVAS#*x}"
  local N="$T/newsreel"; mkdir -p "$N"
  local SRC="$A/video/FlyingTiger_newsreels.mp4"   # 640x480 4:3, original English narration

  # 1) Cut three narration-complete segments and concat them with a short
  #    dip-to-black at each inner join (0.35s fade out + 0.35s fade in). The
  #    out-points were chosen (frame- and silence-verified) so the English
  #    narrator finishes a whole sentence at every boundary:
  #      seg1  04.0 -> 47.3  "...all American flying forces in China"
  #      seg2  77.0 ->103.0  "...uniforms of Uncle Sam"  (lands on the shark-nose P-40)
  #      seg3 109.0 ->123.8  "...the famous Flying Tigers" (ends before the next reel's title card)
  ffmpeg -y -loglevel error -i "$SRC" -filter_complex "\
[0:v]trim=4:47.3,setpts=PTS-STARTPTS,fade=t=in:st=0:d=0.25,fade=t=out:st=42.95:d=0.35,setsar=1[v1];\
[0:a]atrim=4:47.3,asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.25,afade=t=out:st=42.95:d=0.35[a1];\
[0:v]trim=77:103,setpts=PTS-STARTPTS,fade=t=in:st=0:d=0.35,fade=t=out:st=25.65:d=0.35,setsar=1[v2];\
[0:a]atrim=77:103,asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.35,afade=t=out:st=25.65:d=0.35[a2];\
[0:v]trim=109:123.8,setpts=PTS-STARTPTS,fade=t=in:st=0:d=0.35,fade=t=out:st=14.45:d=0.35,setsar=1[v3];\
[0:a]atrim=109:123.8,asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.35,afade=t=out:st=14.45:d=0.35[a3];\
[v1][a1][v2][a2][v3][a3]concat=n=3:v=1:a=1[v][a]" \
    -map "[v]" -map "[a]" -r "$FPS" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
    -c:a aac -b:a 192k -movflags +faststart "$N/compiled.mp4"

  # 2) Pillarbox 4:3 -> 16:9 (black side bars) at full 1080p BEFORE burning subs,
  #    so the Chinese subtitles render crisp at native resolution (not 480p-then-upscaled).
  ffmpeg -y -loglevel error -i "$N/compiled.mp4" \
    -vf "scale=-2:${ch},pad=${cw}:${ch}:(ow-iw)/2:0:black,setsar=1" \
    -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
    -c:a aac -b:a 192k -movflags +faststart "$N/compiled_1080.mp4"

  # 3) Burn the Chinese subtitles in one pass (Pillow plates) -> stage cue.
  bash "$KIT/scripts/srt_burn.sh" "$N/compiled_1080.mp4" \
    "$A/subtitles/FlyingTiger_newsreels_zh.srt" "$S/cue4.mp4" bottom 50
}

# ===========================================================================
# Cue 5 — Star Wars–style opening crawl: AVG → CATF → 14 AF → CACW lineage (50s)
# ===========================================================================
build_cue5() {
  echo "=== Cue 5: opening crawl (lineage) ==="
  local C5="$T/cue5"; mkdir -p "$C5"
  local DUR=50

  cat > "$C5/crawl.txt" <<'CRAWL'
AVG于1941年8月1日在昆明正式成立。1942年7月3日解散，编制并入美军驻华空军特遣队（China Air Task Force，CATF），1943年3月改编为美国陆军第14航空队，陈纳德被任命为总司令，并晋升为少将。由于在中国境内同日本作战的美国空军大部分时间都在陈纳德的领导下，其编制和战术均有明显的传承。所有战斗大队——包括美籍志愿大队（AVG）、驻华航空特遣队（CATF）、第14航空队（14 AF）和中美空军混合联队（Chinese-American Composite Wing，CACW）——的徽章均沿用标志性插翅老虎的形象。在大众和传媒的认知中，“飞虎队”代表着抗日战争期间所有在华美籍和美军空军，从来没有解散
CRAWL

  # 1) Receding crawl (silent).
  "$KIT/scripts/crawl.sh" "@$C5/crawl.txt" "$C5/crawl.mp4" "$DUR" "$CANVAS" "$FPS" 46 FFD24A

  # 2) Inline insignia flashes (upper-right) as the enumeration is named:
  #    CATF (25-30s) -> 14 AF (31-36s) -> CACW (37-42s). (No clean AVG emblem.)
  ffmpeg -y -loglevel error -i "$C5/crawl.mp4" \
    -loop 1 -t "$DUR" -i "$A/images/CATF_23rdFG_plaque.jpg" \
    -loop 1 -t "$DUR" -i "$A/images/14AF_emblem.png" \
    -loop 1 -t "$DUR" -i "$A/images/CACW_patch.jpg" \
    -filter_complex "\
[1:v]scale=-1:280,format=rgba,fade=in:st=25:d=0.4:alpha=1,fade=out:st=30:d=0.5:alpha=1[i1];\
[2:v]scale=-1:280,format=rgba,fade=in:st=31:d=0.4:alpha=1,fade=out:st=36:d=0.5:alpha=1[i2];\
[3:v]scale=-1:280,format=rgba,fade=in:st=37:d=0.4:alpha=1,fade=out:st=42:d=0.5:alpha=1[i3];\
[0:v][i1]overlay=x=W-w-80:y=150:format=auto[a];\
[a][i2]overlay=x=W-w-80:y=150:format=auto[b];\
[b][i3]overlay=x=W-w-80:y=150:format=auto[out]" \
    -map "[out]" -t "$DUR" -r "$FPS" \
    -c:v libx264 -preset medium -crf 19 -pix_fmt yuv420p -movflags +faststart "$C5/crawl_ins.mp4"

  # 3) Audio: air-raid bed (-24 dB) + plane accent (-6 dB, open) + narration at 18s.
  ffmpeg -y -loglevel error -i "$C5/crawl_ins.mp4" \
    -i "$A/music/freesound_community-air-raid-76679.mp3" \
    -i "$A/music/freesound_community-plane-flying-overhead-70830.mp3" \
    -i "$A/narration/clip04_cue5.mp3" \
    -filter_complex "\
[1:a]atrim=0:${DUR},volume=-24dB,afade=t=in:st=0:d=2,afade=t=out:st=47:d=3[bed];\
[2:a]volume=-6dB,afade=t=out:st=12:d=2[acc];\
[3:a]adelay=18000|18000[narr];\
[bed][acc][narr]amix=inputs=3:duration=first:normalize=0,alimiter=limit=0.95[a]" \
    -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -movflags +faststart "$S/cue5.mp4"
}

# ===========================================================================
# Build. ITEM=1|2|3 builds a single silent sub-clip to tmp/items/ for review;
# CUE=1 (re)builds the full cue's stage artifact.
# ===========================================================================
case "${ITEM:-}" in
  1) mkdir -p "$T/items"; build_item1     "$T/items/item1.mp4"; echo "Built $T/items/item1.mp4"; exit 0 ;;
  2) mkdir -p "$T/items"; headline_to_para "$T/items/item2.mp4"; echo "Built $T/items/item2.mp4"; exit 0 ;;
  3) mkdir -p "$T/items"; build_item3     "$T/items/item3.mp4"; echo "Built $T/items/item3.mp4"; exit 0 ;;
esac

case "${CUE:-all}" in
  1) rm -f "$S/cue1.mp4"; build_cue1; echo "Built $S/cue1.mp4"; exit 0 ;;
  2) rm -f "$S/cue2.mp4"; build_cue2; echo "Built $S/cue2.mp4"; exit 0 ;;
  3) rm -f "$S/cue3.mp4"; build_cue3; echo "Built $S/cue3.mp4"; exit 0 ;;
  4) rm -f "$S/cue4.mp4"; build_cue4; echo "Built $S/cue4.mp4"; exit 0 ;;
  5) rm -f "$S/cue5.mp4"; build_cue5; echo "Built $S/cue5.mp4"; exit 0 ;;
esac

[[ -f "$S/cue1.mp4" ]] || build_cue1
[[ -f "$S/cue2.mp4" ]] || build_cue2
[[ -f "$S/cue3.mp4" ]] || build_cue3
[[ -f "$S/cue4.mp4" ]] || build_cue4
[[ -f "$S/cue5.mp4" ]] || build_cue5

# Final crossfade of all five cues.
"$KIT/scripts/crossfade.sh" \
  "$S/cue1.mp4" "$S/cue2.mp4" "$S/cue3.mp4" "$S/cue4.mp4" "$S/cue5.mp4" "$OUT/clip.mp4"
echo "Done: $OUT/clip.mp4"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/clip.mp4"
