#!/usr/bin/env bash
set -euo pipefail

# build_chapter.sh — assembles chapter01's final product:
#
#   opening.mp4 -> clip01 -> clip02 -> clip03 -> clip04 -> ending.mp4
#
# crossfaded together into output/chapter.mp4.
#
# Background-music bed rule (per user):
#   * Cues sourced from STILL images (Ken Burns over narration) get the
#     chapter music bed laid under the narration.
#   * Cues sourced from VIDEO footage (Pearl Harbor / newsreels) — or that
#     already carry their own background sound (clip04 cue5's air-raid +
#     plane bed) — are SKIPPED; their own audio stands alone.
#   * opening.mp4 / ending.mp4 carry their own title track and are left
#     untouched.
#
# Each clip happens to have a single contiguous "bed window" (the video /
# own-sound cues sit at a clip's front or back), so one windowed music
# overlay per clip covers it. The music is seeked continuously across
# windows (looped as needed) so it plays as one evolving piece that simply
# ducks out for the video/SFX sections rather than restarting each time.
#
# NOTE: build all four clips immediately before the chapter, and do not delete
# stage/ in between. The clip02/clip04 bed windows are computed from each clip's
# stage/cues/*.mp4 (not just output/clip.mp4); if they're missing the build
# stops with a clear message (see require_stage) instead of misplacing the bed.

KIT="${KIT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../video-production-kit}"
OUT="output"
TMP="tmp"
ASSETS="assets"

BGM="$ASSETS/music/music-bed.mp3"
BED_DB="${BED_DB:--18}"     # music level under narration (kit documentary default)
FADE="${FADE:-2.0}"         # bed fade-in / fade-out at each window edge

OPENING="$ASSETS/opening.mp4"
ENDING="$ASSETS/ending.mp4"

mkdir -p "$OUT" "$TMP"

dur() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$1"; }
fadd() { awk "BEGIN{printf \"%.3f\", $1}"; }   # eval a float expression

# require_stage CLIP FILE — clip02/clip04 bed windows are computed from each
# clip's per-cue stage artifacts (under the gitignored stage/, produced by
# build_clip.sh) so the bed can duck out for archival-video / own-sound cues.
# Fail loudly with an actionable message rather than silently misplacing the
# bed if they were never built or were cleared (e.g. `rm -rf tmp stage output`).
require_stage() {
  local clip="$1" f="$2"
  [ -f "$f" ] && return 0
  echo "Error: $clip is missing a per-cue stage artifact: $f" >&2
  echo "  The chapter music bed reads stage/cues/*.mp4. Re-run 'bash build_clip.sh'" >&2
  echo "  in $clip just before building the chapter, and don't delete stage/ in between." >&2
  exit 1
}

# bed_window_for CLIPDIR CLIP_DUR -> echoes "S E" (the still/narration span
# to lay the music under, in clip-local seconds). Empty output = no bed.
#
# Cue start offsets in the final clip use the crossfade model:
#   PAD_BETWEEN(1.0) - XFADE_DUR(0.8) = +0.2s drift per cue boundary.
bed_window_for() {
  local clip="$1" d="$2"
  case "$clip" in
    clip01-*|clip03-*)
      # all cues are stills -> bed the whole clip
      echo "0 $d" ;;
    clip02-*)
      # cue1 = Pearl Harbor video (skip); cue2+cue3 stills (bed to end)
      require_stage "$clip" "$clip/stage/cues/cue1.mp4"
      local c1; c1=$(dur "$clip/stage/cues/cue1.mp4")
      echo "$(fadd "$c1 + 0.2") $d" ;;
    clip04-*)
      # cue1+2+3 stills (bed); cue4 video + cue5 own-sound (skip) -> bed front
      require_stage "$clip" "$clip/stage/cues/cue1.mp4"
      require_stage "$clip" "$clip/stage/cues/cue2.mp4"
      require_stage "$clip" "$clip/stage/cues/cue3.mp4"
      local a b c
      a=$(dur "$clip/stage/cues/cue1.mp4")
      b=$(dur "$clip/stage/cues/cue2.mp4")
      c=$(dur "$clip/stage/cues/cue3.mp4")
      echo "0 $(fadd "$a + $b + $c + 0.4")" ;;
    *)
      echo "" ;;   # unknown clip: no bed
  esac
}

# bed_clip IN S E MUSIC_OFFSET OUT — mix BGM under IN's audio on [S,E] only.
bed_clip() {
  local in="$1" s="$2" e="$3" moff="$4" out="$5"
  local len fout sms mend
  len=$(fadd "$e - $s")
  fout=$(awk "BEGIN{v=$len-$FADE; if(v<0)v=0; printf \"%.3f\", v}")
  sms=$(awk "BEGIN{printf \"%d\", $s*1000}")
  mend=$(fadd "$moff + $len")
  ffmpeg -y -nostdin -hide_banner -loglevel error \
    -i "$in" \
    -stream_loop -1 -i "$BGM" \
    -filter_complex \
"[1:a]atrim=start=${moff}:end=${mend},asetpts=PTS-STARTPTS,\
volume=${BED_DB}dB,afade=t=in:st=0:d=${FADE},afade=t=out:st=${fout}:d=${FADE},\
adelay=${sms}|${sms}[bed];\
[0:a][bed]amix=inputs=2:duration=first:normalize=0[a]" \
    -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -movflags +faststart "$out"
}

# ---------------------------------------------------------------------------
# 1) Per-clip music bed
# ---------------------------------------------------------------------------
[ -f "$BGM" ] || { echo "Error: bgm not found: $BGM" >&2; exit 1; }

BEDDED=()
MOFF=0
for clip_dir in clip*/; do
  clip="${clip_dir%/}"
  src="$clip/output/clip.mp4"
  [ -f "$src" ] || { echo "Warning: $src not found; run build_clip.sh in $clip first" >&2; continue; }

  d=$(dur "$src")
  # Capture (not process-substitute) so a require_stage failure inside
  # bed_window_for propagates here instead of being swallowed by the subshell.
  win=$(bed_window_for "$clip" "$d") || exit 1
  read -r S E <<<"$win"
  out="$TMP/${clip}_bed.mp4"

  if [ -z "${S:-}" ]; then
    cp "$src" "$out"
    echo "  $clip: no bed (cp)" >&2
  else
    bed_clip "$src" "$S" "$E" "$MOFF" "$out"
    len=$(fadd "$E - $S")
    MOFF=$(fadd "$MOFF + $len")
    echo "  $clip: bed [$S, $E]s @ ${BED_DB}dB (music offset -> ${MOFF}s)" >&2
  fi
  BEDDED+=("$out")
done

[ ${#BEDDED[@]} -gt 0 ] || { echo "Error: no clip outputs found" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 2) Chain: opening -> bedded clips -> ending
# ---------------------------------------------------------------------------
CHAIN=()
[ -f "$OPENING" ] && CHAIN+=("$OPENING") || echo "Warning: $OPENING missing; skipping opener" >&2
CHAIN+=("${BEDDED[@]}")
[ -f "$ENDING" ] && CHAIN+=("$ENDING") || echo "Warning: $ENDING missing; skipping ending" >&2

if [ ${#CHAIN[@]} -eq 1 ]; then
  cp "${CHAIN[0]}" "$OUT/chapter.mp4"
else
  "$KIT/scripts/crossfade.sh" "${CHAIN[@]}" "$OUT/chapter.mp4"
fi

echo "Built: $OUT/chapter.mp4 ($(dur "$OUT/chapter.mp4")s)"
