#!/usr/bin/env bash
set -euo pipefail

# build_clip.sh — assembles clip01-jagersfontein/output/clip.mp4
#
# Narrated build: each cue's crossfaded visual gets its narration via
# audio_attach.sh (narration drives length; short tail of silence). Sub-clips
# that carry no narration still get a silent AAC track via add_silence() so
# crossfade.sh's audio-stream invariant holds.

KIT="${KIT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/../video-production-kit}"
A="assets"
T="tmp/cues"
S="stage/cues"
OUT="output"
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

mkdir -p "$T" "$S" "$OUT"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# add_silence IN OUT — mux a silent stereo AAC track of exactly the input's
# duration onto a video-only mp4, so crossfade.sh sees an audio stream.
add_silence() {
  local in="$1" out="$2" dur
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$in")
  ffmpeg -y -loglevel error -i "$in" \
    -f lavfi -t "$dur" -i "anullsrc=channel_layout=stereo:sample_rate=$SAMPLE_RATE" \
    -c:v copy -c:a aac -b:a 128k -shortest -movflags +faststart "$out"
}

# kb IMAGE BASE DURATION DIRECTION — Ken Burns + silence into $T/$BASE.mp4
kb() {
  local img="$1" base="$2" dur="$3" dir="$4"
  local vid="$T/${base}_v.mp4"
  "$KIT/scripts/ken_burns.sh" "$img" "$vid" "$dur" "$dir" 1920x1080 30 crop
  add_silence "$vid" "$T/${base}.mp4"
  rm -f "$vid"
}

# ---------------------------------------------------------------------------
# Cue 1 — Out of the Golden Gate
#   Narration: clip01_Cue1.mp3 (23.5s).
#   Sub-clip budget: 9 + 9 + 9 = 27s; minus 2 x 0.8s crossfade = 25.4s
#   visual, narration 23.5s + ~1.4s tail. Narration drives length per kit.
#
#   sub1 (9s): golden gate, slow push toward bridge
#       Caption (lower-third, last 4s): 1941 年夏 · 旧金山金门桥
#   sub2 (9s): Jagersfontein archive still, slight tilt up
#       Footnote caption (bottom-right, full duration, font 36): 荷兰邮轮 The Jagersfontein
#   sub3 (9s): held wake-and-horizon
# ---------------------------------------------------------------------------

kb "$A/images/clip01_golden-gate-1941.jpg" cue01_s1 9 zoom-in
CAPTION_START=5 CAPTION_END=9 "$KIT/scripts/caption_overlay.sh" \
  "$T/cue01_s1.mp4" "1941 年夏 · 旧金山金门桥" "$T/cue01_s1c.mp4" lower-third

kb "$A/images/clip01_Jagersfontein_A.jpg" cue01_s2 9 pan-up
"$KIT/scripts/caption_overlay.sh" \
  "$T/cue01_s2.mp4" "荷兰邮轮贾赫斯方丹号(The Jagersfontein)" "$T/cue01_s2c.mp4" bottom-right 0.5 36

kb "$A/images/clip01_Jagersfontein_B.jpg" cue01_s3 9 zoom-in
cp "$T/cue01_s3.mp4" "$T/cue01_s3c.mp4"

"$KIT/scripts/crossfade.sh" \
  "$T/cue01_s1c.mp4" "$T/cue01_s2c.mp4" "$T/cue01_s3c.mp4" "$T/cue01_visual.mp4"

"$KIT/scripts/audio_attach.sh" \
  "$T/cue01_visual.mp4" "$A/narration/clip01_Cue1.mp3" "$S/cue01.mp4"

# ---------------------------------------------------------------------------
# Cue 2 — A Pilot Named Neale
#   Narration: clip01_Cue2.mp3 (19.2s).
#   Sub-clip budget: 11 + 11 = 22s; minus 1 x 0.8s crossfade = 21.2s
#   visual, narration 19.2s + ~1.5s tail.
#
#   sub1 (11s): Neale portrait, slow focal
#       Caption (center, first 3s, font 96): 罗伯特·尼尔 · 1914-1994
#   sub2 (11s): USS Saratoga archive
#       Footnote (top-third, last 3s, font 36): USS Saratoga CV-3, 美国海军
# ---------------------------------------------------------------------------

kb "$A/images/clip01_neale-portrait.jpg" cue02_s1 11 zoom-in
CAPTION_START=0 CAPTION_END=3 "$KIT/scripts/caption_overlay.sh" \
  "$T/cue02_s1.mp4" "罗伯特·尼尔 · 1914--1994" "$T/cue02_s1c.mp4" lower-third

kb "$A/images/clip01_uss-saratoga-cv3.jpg" cue02_s2 11 zoom-in
CAPTION_START=8 CAPTION_END=11 "$KIT/scripts/caption_overlay.sh" \
  "$T/cue02_s2.mp4" "美国海军 · 萨拉托加航空母舰(USS Saratoga CV-3)" "$T/cue02_s2c.mp4" top-third 0.5 36

"$KIT/scripts/crossfade.sh" \
  "$T/cue02_s1c.mp4" "$T/cue02_s2c.mp4" "$T/cue02_visual.mp4"

"$KIT/scripts/audio_attach.sh" \
  "$T/cue02_visual.mp4" "$A/narration/clip01_Cue2.mp3" "$S/cue02.mp4"

# ---------------------------------------------------------------------------
# Cue 3 — Civilian becomes soldiers
#   Narration is now two segments over four sub-clips:
#     Cue3A (19.7s) — arrive in Burma, form the A.V.G.  → sub1 + sub2
#     Cue3B (17.2s) — Neale to Kunming, becomes top ace → sub3 + sub4
#   Each half is narrated separately, then the two halves are crossfaded.
#   The ACE/双料王牌/top gun aside was extracted into
#   ../clip03-fallen-hero/assets/narration/clip03_ace_aside.m4a.
#
#   Half A budget: 11 + 11 = 22s; minus 1 x 0.8s xfade = 21.2s (Cue3A 19.7s + ~1s tail)
#     sub1 (11s): AVG group photo, push toward middle
#         Subtitle (bottom, full duration, font 36): AVG · 1941年7-9月 · 陆续到达底缅甸仰光
#     sub2 (11s): adam-eve insignia, push toward right
#         Caption (lower-third, from 3s to 10s): AVG · 亚当夏娃中队 (photo generated by AI)
#   Half B budget: 10 + 10 = 20s; minus 1 x 0.8s xfade = 19.2s (Cue3B 17.2s + ~1.5s tail)
#     sub3 (10s): AVG pilots in Kunming, held
#         Subtitle (bottom, full duration, font 32): 中国昆明 · 飞虎队员在P-40战鹰战斗机前 · 1942年3月27日 (Associated Press)
#     sub4 (10s): AVG running to airplane, zoom-out
#         Caption (lower-third, last 6s): 迎击
# ---------------------------------------------------------------------------

# --- Half A (Cue3A): forming the AVG ---
kb "$A/images/clip01_Flying_Tigers_group.jpg" cue03_s1 11 zoom-in:0.5,0.5
printf '1941年7-9月 · AVG陆续抵达缅甸仰光\n' > "$T/cue03_s1_sub.txt"
"$KIT/scripts/subtitle_burn.sh" \
  "$T/cue03_s1.mp4" "$T/cue03_s1c.mp4" 0 11 "@$T/cue03_s1_sub.txt" bottom 36

kb "$A/images/clip01_P40_adam_eve_AI_generated.png" cue03_s2 11 zoom-in:0.85,0.5
CAPTION_START=3 CAPTION_END=10 "$KIT/scripts/caption_overlay.sh" \
  "$T/cue03_s2.mp4" "AVG · 亚当夏娃中队 (AI生成)" "$T/cue03_s2c.mp4" lower-third

"$KIT/scripts/crossfade.sh" \
  "$T/cue03_s1c.mp4" "$T/cue03_s2c.mp4" "$T/cue03a_visual.mp4"
"$KIT/scripts/audio_attach.sh" \
  "$T/cue03a_visual.mp4" "$A/narration/clip01_Cue3A.mp3" "$T/cue03a.mp4"

# --- Half B (Cue3B): to Kunming, top ace ---
kb "$A/images/clip01_avg-kunming.jpg" cue03_s3 10 zoom-in
printf '1942年3月27日 · 中国昆明 · 飞虎队员在P-40战鹰战斗机前 (Associated Press)\n' > "$T/cue03_s3_sub.txt"
"$KIT/scripts/subtitle_burn.sh" \
  "$T/cue03_s3.mp4" "$T/cue03_s3c.mp4" 0 10 "@$T/cue03_s3_sub.txt" bottom 32

kb "$A/images/clip01_AVG_runto_airplane.jpg" cue03_s4 10 zoom-out
printf '飞虎出征\n' > "$T/cue03_s4_cap.txt"
CAPTION_START=4 CAPTION_END=10 "$KIT/scripts/caption_overlay.sh" \
  "$T/cue03_s4.mp4" "@$T/cue03_s4_cap.txt" "$T/cue03_s4c.mp4" lower-third

"$KIT/scripts/crossfade.sh" \
  "$T/cue03_s3c.mp4" "$T/cue03_s4c.mp4" "$T/cue03b_visual.mp4"
"$KIT/scripts/audio_attach.sh" \
  "$T/cue03b_visual.mp4" "$A/narration/clip01_Cue3B.mp3" "$T/cue03b.mp4"

# --- Join the two narrated halves into the cue ---
"$KIT/scripts/crossfade.sh" \
  "$T/cue03a.mp4" "$T/cue03b.mp4" "$S/cue03.mp4"

# ---------------------------------------------------------------------------
# Chain cues into clip output
# ---------------------------------------------------------------------------

"$KIT/scripts/crossfade.sh" \
  "$S/cue01.mp4" "$S/cue02.mp4" "$S/cue03.mp4" "$OUT/clip.mp4"

echo "Built: $OUT/clip.mp4"
