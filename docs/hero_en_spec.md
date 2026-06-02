# Hero image spec — `flying-tigers-hero_en.png`

Design brief for the EN-page hero of the blog post
`content/en/flying-tigers-vibe-coded-film.md`. Works as an illustrator brief
or an AI image-gen prompt.

> **Key reframe vs. the Chinese original:** the bottom-right panel is changed
> from "AI templates / auto-edit" to the post's actual thesis — the writer
> specifies the craft and the machine **compiles** the script. That's the
> differentiator the article sells, so the hero should show it.

## Goal

Top-of-post hero for the EN page. Conveys "traditional video = 3 roles &
handoffs" vs. "this pipeline = 1 role, the machine compiles the script."

## Format / size

- ~1600×1040 px (≈3:2 landscape), PNG (or SVG); provide a 2× export for retina.
- Keep text large enough to survive a ~700 px column; short body bullets only —
  small text blurs on mobile.

## Style

Hand-drawn sketchbook look matching the Chinese reference: warm cream paper
background, pencil/ink line art, friendly cartoon figures, muted accents
(sage green, warm orange, soft gray), hand-lettered headings. Same charm,
English copy.

## Layout — two stacked panels split by a dashed horizontal divider

### Top panel — heading: "Traditional video production — 3 roles"

- Box 1 **STORY TELLER** (writer at a desk): *Brainstorm the theme · Write the
  script · Define the core message*
- arrow labeled *"hands off the script"* →
- Box 2 **DESIGNER** (at a monitor): *Design the visuals · Produce assets ·
  Export design files*
- arrow labeled *"hands off assets"* →
- Box 3 **VIDEO EDITOR** (headphones, timeline): *Cut the video · Subtitles /
  VO / SFX · Export the final cut*
- → **Final video** (play-button frame)
- Orange callout box, *"The old way costs:"* — *Hire 3 people · High
  coordination overhead · Long cycle, low throughput · Quality bound by the editor*

### Bottom panel — heading: "The script-driven flow — 1 role"

- Box 1 **STORY TELLER** (writer at a laptop): *Write the script (`script.md`) —
  Ken Burns, captions, crossfades, all specified in plain language*
- arrow labeled *"compile"* (green) →
- **One** engine box titled **VIBE CODING + SKILLs** (friendly robot): *Reads the
  script → generates the build scripts (`.sh`) → runs them → `.mp4` · Writer
  keeps full creative control · Re-run one cue in seconds*
- → **Final video** (play-button frame)
- Green callout box, *"What it buys you:"* — *1 core role · Machine does
  design + edit · The script stays the source of truth · Iterate fast, focus
  on the story*

### Bottom banner (full width)

⭐ *"Shift from 'making the video' to 'telling the story.'"* with the tagline
**Write. Compile. Ship. — For Video.**

## Deliverables

- `flying-tigers-hero_en.png` — this spec, for the EN page.
- `flying-tigers-hero_zh.png` — the existing hand-drawn diagram, for the ZH page.
  - ⚠️ For consistency, consider updating the ZH version too — swap its
    "AI DESIGN (templates) / AI VIDEO (auto-edit)" boxes for the same single
    "vibe coding compiles the script" box, so EN and ZH heroes tell the same story.

Both ship to the blog repo's `assets/` at deploy → served from `/blog/assets/`.

## Prompt-ready one-paragraph version (for an image model)

> A hand-drawn sketchbook-style infographic on warm cream paper, pencil-and-ink
> line art with friendly cartoon figures and muted sage-green/orange/gray
> accents, hand-lettered English headings. Two stacked panels divided by a
> dashed line. Top panel "Traditional video production — 3 roles": three labeled
> boxes — STORY TELLER, DESIGNER, VIDEO EDITOR — connected by arrows reading
> "hands off the script" and "hands off assets," ending at a "Final video"
> play-button frame, with an orange callout "The old way costs: hire 3 people,
> high coordination overhead, long cycle, quality bound by the editor." Bottom
> panel "The script-driven flow — 1 role": a STORY TELLER at a laptop, a green
> "compile" arrow into a single robot-labeled box "VIBE CODING + SKILLs: reads
> the script → generates build scripts → runs them → .mp4," ending at a "Final
> video" frame, with a green callout "What it buys you: 1 core role, machine
> does design + edit, the script stays the source of truth, iterate fast, focus
> on the story." Full-width bottom banner: "Shift from making the video to
> telling the story — Write. Compile. Ship. For Video." Landscape 3:2.
