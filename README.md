# AIeditor · Flying Tigers (Overview Chapter)

A complete, **vibe-coded** documentary chapter about the WWII **Flying Tigers**
(the American Volunteer Group, AVG) — written, edited, scored, and assembled
entirely by directing [Claude Code](https://claude.com/claude-code) in natural
language. No timeline editor, no NLE; just a script, archival stills, narration,
and a toolbox of shell recipes.

This repository is a **worked example** for the
[`video-production-kit`](https://github.com/nidmgh/video-production-kit) Claude
Code skill. It is published for **study and research** — clone it, read the
cue-sheets, and rebuild the film yourself to see the whole stills-to-video
pipeline end to end.

> **Watch the finished chapter:** https://youtu.be/oBjQTPtJdLE
> (~9 min 44 s: title → 4 clips → end card.)

---

## What you're looking at

The chapter tells the AVG's story from sailing out of San Francisco in summer
1941 through the moment the "Flying Tigers" name was born. It is built **bottom
up** — individual shots (*cues*) compose into *clips*, clips chain into the
*chapter*:

```
opening.mp4 → clip01 → clip02 → clip03 → clip04 → ending.mp4
```

| Clip | Story beat |
|---|---|
| `clip01-jagersfontein`   | Flying Tigers sail out, summer 1941 |
| `clip02-first-battle`    | The first battle, 20 Dec 1941 |
| `clip03-fallen-hero`     | An airman's ultimate sacrifice, spring 1942 |
| `clip04-tiger-is-flying` | The name is born: AVG becomes the Flying Tigers |

## How it was made

Everything was produced by **vibe coding** — instructing Claude Code in plain
language, which drove the edit pipeline via the `video-production-kit` recipes.

| Layer | Tooling |
|---|---|
| Dev environment | **Claude Code** (CLI / claude.ai/code) |
| Model | **Anthropic Opus 4.7 / 4.8** |
| Edit pipeline | **`video-production-kit`** (Claude Code skill) — recipe toolbox + bottom-up conventions |
| Narration (TTS) | **Fish Audio** |
| Media processing | **ffmpeg / ffprobe** |
| Text & graphics | **Python 3 + Pillow** (subtitle plates, spotlight masks, metallic title, Star-Wars crawl) |
| Archival sourcing | **yt-dlp** (newsreel clips + caption tracks as a translation source) |
| Orchestration | **bash** (`set -euo pipefail`, macOS bash 3.2 compatible) |
| Fonts (macOS system) | STHeiti Medium, Songti, DIN Condensed Bold |

A longer Chinese-language development write-up lives in
[`making-of.md`](./making-of.md).

## Archival material

| Type | Count | Notes |
|---|---|---|
| Historical photos | **41** | newspapers, crew portraits, insignia, aircraft (jpg/png/webp) |
| Archival footage | **7 files** | cut from **2 newsreels** (Pearl Harbor naval reel; Flying Tigers reel) |
| Narration tracks | **20** | Chinese narration, split per cue (mp3) |
| Music | 2 | opening/ending title cue; chapter bed (`music-bed.mp3`) |

## Recipes used (from `video-production-kit`)

| Recipe | Uses | Role |
|---|---|---|
| `caption_overlay.sh` | 27 | lower-third / corner captions (captions, years, names, sources) |
| `ken_burns.sh` | 17 | zoom/pan motion on stills |
| `audio_attach.sh` | 17 | fit narration to silent footage, align durations |
| `crossfade.sh` | 12 | crossfade chaining between cues and clips |
| `subtitle_burn.sh` | 3 | single timed subtitle burn-in |
| `lowres_frame.sh` | 3 | beige archival frame around low-res footage |
| `title_card.sh` | 1 | black title card (AVG disband date) |
| `text_spotlight.sh` | 1 | slow document pan + paragraph spotlight (newspaper reveal) |
| `srt_burn.sh` | 1 | whole-SRT burn-in (newsreel subtitles) |
| `crawl.sh` | 1 | Star-Wars receding crawl (AVG → CATF → 14AF → CACW lineage) |

The chapter-level music bed is applied inline in `build_chapter.sh` (under
still-image + narration cues only; archival-video and own-sound cues are
skipped).

---

## Build it yourself

### Prerequisites

- **macOS** (the build leans on system fonts: STHeiti, Songti, DIN Condensed)
- **ffmpeg / ffprobe** on your `PATH`
- **Python 3 + Pillow** (`pip install pillow`)
- The **`video-production-kit`** repo, cloned **next to this one**:

```
your-workspace/
├── AIeditor_flyingTigerOverview/   ← this repo
└── video-production-kit/           ← https://github.com/nidmgh/video-production-kit
```

The build scripts default `KIT` to that sibling path. To point elsewhere:

```bash
export KIT=/path/to/video-production-kit
```

### Bottom-up build

Build each clip first, then chain the chapter:

```bash
# 1) clips  (each writes its own output/clip.mp4)
cd clip01-jagersfontein && bash build_clip.sh && cd ..
cd clip02-first-battle  && bash build_clip.sh && cd ..
cd clip03-fallen-hero   && bash build_clip.sh && cd ..
cd clip04-tiger-is-flying && bash build_clip.sh && cd ..

# 2) chapter  (opening → clips → ending, with music bed) → output/chapter.mp4
bash build_chapter.sh
```

> **Note:** build the four clips immediately before the chapter, and don't
> delete `stage/` in between — the chapter's music-bed windowing reads each
> clip's `stage/cues/*.mp4`. If they're missing, `build_chapter.sh` stops with
> a clear message rather than misplacing the bed.

`opening.mp4` / `ending.mp4` ship prebuilt in `assets/`. The generator that
produced them is included under [`opening-kit/`](./opening-kit/) for reference.

### Tunables

- `BED_DB` — music-bed level under narration (default `-18`)
- `FADE` — bed fade in/out at each window edge (default `2.0`)
- `CUE=n bash build_clip.sh` — rebuild a single cue for review

---

## Repository layout

```
build_chapter.sh        chain opening → clips → ending + music bed
outline.md              chapter overview, meta, build notes
making-of.md            development write-up (Chinese)
assets/                 chapter-shared: images, narration, video, music, opening/ending
clip0N-<slug>/
  build_clip.sh         per-cue render → crossfade into output/clip.mp4
  script.md             cue-format shot list
  assets/               clip-only stills, narration, video
opening-kit/            generator for the metallic opening / end card (reference)
```

## A note on assets & rights

This is a **study/research** repository. The archival imagery and newsreel
footage are historical material used for educational purposes. `music-bed.mp3`
is a **placeholder** background track — swap in your own music for any reuse.

## Credits

Conceived, edited, and assembled with **Claude Code** and the
**[`video-production-kit`](https://github.com/nidmgh/video-production-kit)**
skill.
