# Opening / Ending toolkit (shared across chapters)

A reusable ~6s **opening** and ~4.5s **ending** card in the metallic
飞虎队 / FLYING TIGERS style. Only the chapter-specific text changes.

## Driven by `outline.md` fields

Each chapter's `outline.md` carries two simple fields:

```
title:  第一章 · 飞虎出征          # shown in the last 3s of the opening
ending: 本章完 | 下一章 · AVG 的诞生  # ending card text ("|" splits two lines)
```

## Build

```bash
# from the repo root
TITLE=$(grep -E '^title:'  chapterNN-.../outline.md | sed -E 's/^title:[[:space:]]*//')
ENDING=$(grep -E '^ending:' chapterNN-.../outline.md | sed -E 's/^ending:[[:space:]]*//')

bash opening/build_opening.sh "$TITLE"  /abs/path/chapterNN-.../assets/opening.mp4
bash opening/build_ending.sh  "$ENDING" /abs/path/chapterNN-.../assets/ending.mp4
```
Pass **absolute** output paths (the scripts `cd` into `opening/`).

Optional 3rd/4th args: `MUSIC.mp3` and `MUSIC_START_SEC`
(opening default slice start 9.0s — puts the track's drop on the ignite;
ending default 14.2s — the resolving tail).

## Pieces

- `make_title.py`   — series-fixed 飞虎队/FLYING TIGERS metal plate → `plates/title.png`, `title_flash.png`
- `make_assets.py`  — atmosphere plates → `plates/bg.png`, `embers.png`, `flare.png`
- `make_chapter_title.py "<text>" out.png [y]` — per-chapter title tag plate
- `make_ending.py "<a|b>" out.png` — ending card plate
- `build_opening.sh`, `build_ending.sh` — assemble video + music

`plates/*.png` (except the `_`-prefixed per-chapter temporaries) are the
series-fixed assets; regenerated automatically if missing.

## Output

Rendered per chapter into `chapterNN-.../assets/opening.mp4` and `ending.mp4`,
1920×1080 / 30fps. These get chained as the first/last segments when the
chapter is compiled (opening → clips → ending).

Currently wired: **chapter01** only.
