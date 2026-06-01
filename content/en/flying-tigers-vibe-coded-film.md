---
title: ""
date: 2026-06-01
published: false
lang: en
slug: flying-tigers-vibe-coded-film
author: MaiMai
---

<!-- Hero image: drop a file under assets/ and public/blog/assets/, then:
![](/blog/assets/flying-tigers-hero.png) -->

**Write. Compile. Ship. — For Video.**

## The Problem

A screenwriter's job ends at the script. Dialogue, narration, scene directions, the occasional "slow push on this photo" — that's the deliverable. Turning those pages into a finished film has always been someone else's craft: an editor, a timeline, an NLE, and days of dragging clips and keyframing pans.

We wanted to delete that handoff — without asking the writer to change how they write.

The script stays the single source of truth. In this project that's `script.md`, with `outline.md` above it: the writer lays out cues, narration, and on-screen text exactly as before, and reaches for industry-standard language whenever they need it — "Ken Burns effect," "lower-third caption," "crossfade." No new authoring tool, no editor to learn.

The machine handles the rest. Vibe coding plus a set of SKILLs translates that human language into buildable shell scripts (`.sh`), and those scripts execute into the publishable `.mp4`.

It's the developer's loop applied to film. A Java programmer writes `.java`; a compiler turns it into something runnable. Here the writer's `outline.md` and `script.md` are the source; the project compiles them down to `.sh`; the shell runs and produces the video. Same shape — author in a human-readable source, compile, execute, ship.

## How You Use It

You write a cue, you ask for a build, you watch the clip. That's the loop.

A cue in `script.md` reads like what a writer already jots in the margin: the photo or footage to show, the narration line, the on-screen caption, and the motion — "Ken Burns push toward the bridge," "lower-third: Summer 1941 · San Francisco," "crossfade into the next shot." Plain language, plus the industry terms the writer already knows.

Then you tell Claude Code to build it. Vibe coding turns the cue-sheet into `build_clip.sh`, runs it, and hands back `clip.mp4`. Don't like the third shot? Change a line of narration, or swap "zoom-in" for "pan-up," rebuild just that cue (`CUE=3 bash build_clip.sh`), and re-watch in seconds. Stack the finished clips into the full chapter the same way.

No timeline, no keyframes, no round-tripping assets through a designer. The writer stays in the script the whole time — the screen just keeps catching up to the words.

## What It Buys You

Three roles become one. The traditional pipeline needs a storyteller, a designer, and an editor — plus the handoffs between them, each one a place where intent leaks and the schedule slips. Here the writer holds all three seats, because the machine does the design and edit work the moment the script asks for it.

Iteration drops from hours to seconds. Re-cutting a shot in a timeline means re-importing, re-keyframing, re-exporting. Here you change one line in `script.md` and rebuild that single cue — the rest of the film is untouched and never re-renders. Trying five framings of the same photo costs five small commands, not five round-trips through an editor.

And the source of truth never moves. Every change is a diff on a text file: reviewable, reversible, versioned in git like code. There's no `final_v3_REAL.prproj` — the script *is* the project, and the video is just its current build.

For this chapter that added up to ~9m44s of narrated, captioned, scored documentary — four clips plus opening and closing cards — assembled entirely by directing Claude Code in plain language. One person, one script, one build command.

## Lesson
