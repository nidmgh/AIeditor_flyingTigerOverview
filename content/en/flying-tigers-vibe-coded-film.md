---
title: "Write. Compile. Ship — For Video"
date: 2026-06-01
published: false
lang: en
slug: flying-tigers-vibe-coded-film
author: MaiMai
---

![Traditional video production takes three roles — storyteller, designer, editor; with this pipeline the writer keeps one seat and the machine does the rest.](/blog/assets/flying-tigers-hero_en.jpg)

*Vibe-coding a 10-minute WWII documentary — where the script is the source code.*

## The Problem

A screenwriter's job ends at the script. Dialogue, narration, scene directions, the occasional "slow push on this photo" — that's the deliverable. Turning those pages into a finished film has always been someone else's craft: an editor, a timeline, an NLE, and days of dragging clips and keyframing pans.

We wanted to delete that handoff — without asking the writer to change how they write.

The script stays the single source of truth. In this project that's `script.md`, with `outline.md` above it: the writer lays out cues, narration, and on-screen text exactly as before, and reaches for industry-standard language whenever they need it — "Ken Burns effect," "lower-third caption," "crossfade." No new authoring tool, no editor to learn.

The machine handles the rest. Vibe coding plus a set of SKILLs translates that human language into buildable shell scripts (`.sh`), and those scripts execute into the publishable `.mp4`.

It's the developer's loop applied to film. A Java programmer writes `.java`; a compiler turns it into something runnable. Here the writer's `outline.md` and `script.md` are the source; the project compiles them down to `.sh`; the shell runs and produces the video. Same shape — author in a human-readable source, compile, execute, ship.

## What That Normally Takes

Ten minutes of finished documentary is not a small thing. Industry rule-of-thumb pricing runs **$1,000 per finished minute at the rock-bottom end, $2,000–$4,000 as a realistic starting point, and $10,000+ for television-grade** — so a single ~10-minute chapter is a **$10k–$40k+** project before anyone calls it broadcast quality.

An archival, stills-and-narration chapter like this one skips the film crew, but the budget just moves: into **research and archival licensing**, a **scriptwriter**, a **narrator**, and — the big one — a **motion-graphics editor** hand-animating every photograph. Editing runs **$75–$150 an hour**, and custom-animation passes routinely top **40 hours** — and ten minutes of Ken Burns moves, burned-in captions, spotlight reveals, and crossfades is a lot of custom animation.

It also takes **three people** passing work down a line: the storyteller writes, the designer builds the visuals, the editor cuts. Every handoff is a place where intent leaks and the calendar slips into weeks.

<p class="sources"><em>Cost benchmarks (2025–2026): per-finished-minute documentary pricing from <a href="https://courses.desktop-documentaries.com/courses/documentary-going-rates-handbook">Desktop Documentaries</a>, <a href="https://windsky.com.au/how-much-does-a-documentary-cost/">Wind &amp; Sky Productions</a>, and <a href="https://www.academyvoices.com/blog/how-much-does-it-cost-to-make-a-documentary-a-complete-breakdown">Academy Voices</a>; editing and custom-animation rates from <a href="https://vidico.com/news/video-production-cost/">Vidico</a>.</em></p>

## How You Use It

You write a cue, you ask for a build, you watch the clip. That's the loop.

A cue in `script.md` reads like what a writer already jots in the margin: the photo or footage to show, the narration line, the on-screen caption, and the motion — "Ken Burns push toward the bridge," "lower-third: Summer 1941 · San Francisco," "crossfade into the next shot." Plain language, plus the industry terms the writer already knows.

Then you tell Claude Code to build it. Vibe coding turns the cue-sheet into `build_clip.sh`, runs it, and hands back `clip.mp4`. Don't like the third shot? Change a line of narration, or swap "zoom-in" for "pan-up," rebuild just that cue (`CUE=3 bash build_clip.sh`), and re-watch in seconds. Stack the finished clips into the full chapter the same way.

No timeline, no keyframes, no round-tripping assets through a designer. The writer stays in the script the whole time — the screen just keeps catching up to the words.

Under the hood it's a bottom-up pipeline — shots compose into scenes, scenes into the film:

```
  outline.md + script.md          ← you write (the source)
          |
          |   vibe coding: Claude Code generates the build scripts
          v
   cue   ──►   clip   ──►   chapter   ──►   chapter.mp4
 (one shot)  (a scene)    (the film)         (ship)
  ken_burns   crossfade    + music bed
  caption     narration    + opening/ending
```

End to end, the writer touches three things and the machine handles the rest:

1. **Write** — lay out the story in `outline.md`, then the shot-by-shot cues in `script.md`: image, narration, caption, motion.
2. **Gather** — drop in the photographs and archival clips; the narration is synthesized from the script's lines via text-to-speech.
3. **Direct & build** — tell Claude Code to build. It writes `build_clip.sh` / `build_chapter.sh` from the cues and runs them; you review a cue, tweak a line, rebuild it (`CUE=n`), and repeat. Chain the clips into the chapter — out comes the `.mp4`.

Here is one cue, start to finish — a single shot described in `script.md`, then narrated, captioned, and animated by the build:

<figure>
  <video controls preload="metadata" playsinline width="100%" style="border-radius:8px"
         poster="/blog/assets/flying-tigers-clip01-cue03.jpg">
    <source src="/blog/assets/flying-tigers-clip01-cue03.mp4" type="video/mp4">
    Your browser can't play this clip — <a href="/blog/assets/flying-tigers-clip01-cue03.mp4">download it</a>.
  </video>
  <figcaption>One cue from Clip 01 — the volunteers reach Burma and the A.V.G. forms. ~42&nbsp;s.</figcaption>
</figure>

## What It Buys You

That three-person line collapses to one. The writer keeps their seat; the designer's and editor's work is absorbed by the machine, which builds the visuals the moment the script asks for them. No handoffs — so nothing leaks in translation, and nothing waits in a queue.

Iteration drops from hours to seconds. Re-cutting a shot in a timeline means re-importing, re-keyframing, re-exporting. Here you change one line in `script.md` and rebuild that single cue — the rest of the film is untouched and never re-renders. Trying five framings of the same photo costs five small commands, not five round-trips through an editor.

And the source of truth never moves. Every change is a diff on a text file: reviewable, reversible, versioned in git like code. There's no `final_v3_REAL.prproj` — the script *is* the project, and the video is just its current build.

Put rough numbers on it. This chapter is ~9m44s built from **41 photographs, 7 archival clips, 20 narration cues, and ~67 edit operations** — Ken Burns moves, captions, spotlight reveals, crossfades. That is squarely the **$10k–$40k+, three-people, several-weeks** job from above. Here it was one person directing Claude Code, iterating in **days, not weeks** — and the designer-and-editor line items, normally the bulk of that budget, shrink to near-zero marginal cost: a Claude Code subscription and a few dollars of text-to-speech, not a crew on day rates. *(Effort here is estimated from the finished piece, not a logged timesheet.)*

## Why Re-Invent the Wheel?

Fair question. The short answer: this isn't a new wheel for its own sake — it's about building a *better* one, and making the building itself more efficient. I tried the existing tools first; each came close and stopped short.

**Descript** — I liked the direction: edit the video by editing the text. But it blends a developer's and a screenwriter's mental models into one, and that mix didn't fit my purpose. Close, not quite.

<img src="/blog/assets/logo-capcut.svg" alt="" height="22" style="vertical-align:-5px"> **CapCut** — genuinely one of the best for social-media video, with a deep template library. That's also the point: it's built for mass output and quick turnaround, not for one-of-a-kind creative work. Its pre-AI design means the workflow still leans on a lot of manual human care — it can't be driven and streamlined by an agent, and there's nothing programmable to hook into.

<img src="/blog/assets/logo-elevenlabs.svg" alt="" height="20" style="vertical-align:-4px"> <img src="/blog/assets/logo-fishaudio.svg" alt="" height="20" style="vertical-align:-4px"> **Text-to-speech (ElevenLabs vs. Fish Audio)** — both work, and both clear the bar of *acceptable*. I picked Fish Audio because it handled the Chinese narration better. Neither is easy to push all the way to convincingly human yet — but Fish Audio is actively building out a programmable API, which is exactly what matters when the whole point is an automatable pipeline, so it's the one I'd bet on.

The common thread: the existing tools are either not programmable or not built for an AI to drive end to end. That gap is what the script-as-source-code approach fills.

## The Takeaway

It's worth being honest about what *didn't* change.

The history is still hard-won. A documentary that claims to be accurate earns it the old way: finding the right archival photo, dating the newsreel, confirming the man in the frame is who the caption says he is. AI shortens the mechanical parts — fetching footage, pulling auto-captions as a translation source, drafting a search — but the judgment of what is true, and what is worth showing, stays human. Vibe coding compiles the script faster; it does not do the research for you.

And the creative core is untouched — because it's the whole point. The pacing of a reveal, the narration line that lands, the choice to hold on a face for one more beat: that is the screenwriter's craft, and it is exactly what this pipeline is built to *protect*. The machine took over the parts a writer never wanted — the keyframing, the re-exports, the handoffs — so the parts only a human can do get all the attention. Top-quality work was never bottlenecked on the editing. It was bottlenecked on the storytelling, and it still is.

That's the trade worth making. Write. Compile. Ship — and spend the time you save on the story.

---

**Watch the finished chapter** (~9m44s):

<figure>
  <video controls preload="metadata" playsinline width="100%" style="border-radius:8px"
         poster="/blog/assets/flying-tigers-chapter01.jpg">
    <source src="/blog/assets/flying-tigers-chapter01-480p.mp4" type="video/mp4">
    Your browser can't play this video — <a href="/blog/assets/flying-tigers-chapter01-480p.mp4">download it</a>, or <a href="https://youtu.be/oBjQTPtJdLE">watch on YouTube</a>.
  </video>
  <figcaption>"Flying Tigers: Sailing Out" — Chapter 1, ~9m44s (480p; <a href="https://youtu.be/oBjQTPtJdLE">HD on YouTube</a>).</figcaption>
</figure>

<p class="built-with"><strong>Built with</strong>
  <img src="/blog/assets/logo-claude-code.svg" alt="Claude Code" height="28">
  <a href="https://github.com/nidmgh/video-production-kit"><code>video-production-kit</code></a>
  <img src="/blog/assets/logo-ffmpeg.svg" alt="ffmpeg" height="28">
  <img src="/blog/assets/logo-python.svg" alt="Python + Pillow" height="28">
  <img src="/blog/assets/logo-fishaudio.svg" alt="Fish Audio" height="28">
  <img src="/blog/assets/logo-ytdlp.svg" alt="yt-dlp" height="28">
  <img src="/blog/assets/logo-git.svg" alt="git" height="28">
</p>
