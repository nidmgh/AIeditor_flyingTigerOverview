---
title: "写作 · 编译 · 交付 —— 为视频而生"
date: 2026-06-01
published: false
lang: zh
slug: flying-tigers-vibe-coded-film
translated: true
author: 迈哥
---

![传统视频制作需要三个角色——编剧、设计师、剪辑师；而在这套流程里，创作者只保留一个位置，其余交给机器。](/blog/assets/flying-tigers-hero_zh.jpg)

*用 vibe coding 做一部约 10 分钟的二战纪录片——剧本，就是源代码。*

## 问题

编剧的工作，到剧本为止。对白、旁白、场景说明，偶尔来一句"这里在照片上缓缓推近"——这就是交付物。把这些纸面文字变成成片，向来是另一门手艺：剪辑师、时间线、NLE，外加好几天的拖拽素材和关键帧调试。

我们想把这道交接删掉——而且不要求编剧改变写作方式。

剧本始终是唯一的真实来源。在这个项目里就是 `script.md`，上面再加一份 `outline.md`：创作者照旧写下分镜、旁白和画面文字，需要时直接用行业术语——"Ken Burns 运镜""下三分之一字幕""交叉淡入淡出"。不用学新的创作工具，也不用学剪辑软件。

剩下的交给机器。Vibe coding 加上一套 SKILL，把这些人类语言翻译成可构建的 shell 脚本（`.sh`），脚本再执行成可发布的 `.mp4`。

这就是把开发者的循环套用到影片上。Java 程序员写 `.java`，编译器把它变成可运行的东西；这里，创作者的 `outline.md` 和 `script.md` 是源文件，项目把它们编译成 `.sh`，shell 一跑就产出视频。同一个形状——用人类可读的源文件创作，编译、执行、交付。

## 通常这要花多少

十分钟的成片可不是小事。行业经验法则的报价：最低端约**每分钟 1,000 美元**，比较现实的起步价是**每分钟 2,000–4,000 美元**，电视级则要 **10,000 美元以上**——所以单是一章约 10 分钟的片子，在还谈不上"广播级"之前，就已经是一个 **1 万到 4 万美元以上**的项目。

像本章这样以档案照片加旁白为主的片子省掉了摄制组，但预算只是换了个地方：花在**资料研究与档案授权**、一位**编剧**、一位**配音**，以及——重头戏——一位**动态图形剪辑师**，逐张照片做动画。剪辑通常**每小时 75–150 美元**，定制动画往往**超过 40 小时**——而十分钟的 Ken Burns 运镜、烧录字幕、聚光揭示和交叉淡入淡出，是一大堆定制动画。

它还需要**三个人**沿着流水线接力：编剧写、设计师做画面、剪辑师剪。每一次交接都是意图流失、周期被拉长成数周的地方。

<p class="sources"><em>成本基准（2025–2026）：每分钟成片的纪录片报价参考 <a href="https://courses.desktop-documentaries.com/courses/documentary-going-rates-handbook">Desktop Documentaries</a>、<a href="https://windsky.com.au/how-much-does-a-documentary-cost/">Wind &amp; Sky Productions</a> 和 <a href="https://www.academyvoices.com/blog/how-much-does-it-cost-to-make-a-documentary-a-complete-breakdown">Academy Voices</a>；剪辑与定制动画费率参考 <a href="https://vidico.com/news/video-production-cost/">Vidico</a>。</em></p>

## 怎么用

写一个 cue，让它构建，看片段。就这么个循环。

`script.md` 里的一个 cue，读起来就像编剧本来就会在旁边记下的东西：要出现的照片或影像、旁白台词、画面上的字幕，以及运动方式——"Ken Burns 向大桥推近""下三分之一字幕：1941 年夏 · 旧金山""交叉淡入下一镜"。大白话，加上编剧本就熟悉的行业术语。

然后你叫 Claude Code 去构建。Vibe coding 把这份 cue 表变成 `build_clip.sh`，跑一遍，交回 `clip.mp4`。第三镜不满意？改一句旁白，或把 "zoom-in" 换成 "pan-up"，只重建那一个 cue（`CUE=3 bash build_clip.sh`），几秒钟就能重看。把做好的片段串成整章，方法一样。

没有时间线，没有关键帧，不用把素材在设计师那里来回倒腾。创作者全程待在剧本里——画面只是不断追上文字。

底层是一条自底向上的流水线——镜头组成片段，片段组成成片：

```
  outline.md + script.md          ← 你来写（源文件）
          |
          |   vibe coding：Claude Code 生成构建脚本
          v
   cue   ──►   clip   ──►   chapter   ──►   chapter.mp4
 （单镜头） （一个片段）   （整部）           （交付）
  ken_burns   crossfade    + 音乐床
  字幕         旁白          + 片头/片尾
```

从头到尾，创作者只碰三样东西，其余交给机器：

1. **写** —— 在 `outline.md` 里铺陈故事，再在 `script.md` 里写逐镜头的 cue：图像、旁白、字幕、运动。
2. **备料** —— 放进照片和档案影像；旁白由剧本里的台词通过文字转语音合成。
3. **指挥并构建** —— 让 Claude Code 去构建。它根据 cue 写出 `build_clip.sh` / `build_chapter.sh` 并运行；你审一个 cue、改一句、重建（`CUE=n`）、再来一遍。把片段串成整章——`.mp4` 就出来了。

这是一个 cue 的完整呈现——`script.md` 里描述的单个镜头，经构建加上旁白、字幕和动画：

<figure>
  <video controls preload="metadata" playsinline width="100%" style="border-radius:8px"
         poster="/blog/assets/flying-tigers-clip01-cue03.jpg">
    <source src="/blog/assets/flying-tigers-clip01-cue03.mp4" type="video/mp4">
    你的浏览器无法播放该片段——<a href="/blog/assets/flying-tigers-clip01-cue03.mp4">下载</a>。
  </video>
  <figcaption>来自 Clip 01 的一个 cue——志愿者抵达缅甸，AVG 成军。约 42 秒。</figcaption>
</figure>

## 它带来了什么

那条三人流水线坍缩成一个人。编剧保留自己的位置；设计师和剪辑师的活儿被机器吸收，剧本一要求，画面就构建出来。没有交接——于是没有什么在传递中流失，也没有什么排队等待。

迭代从几小时降到几秒。在时间线里重剪一镜意味着重新导入、重打关键帧、重新导出。这里，你在 `script.md` 改一行，只重建那一个 cue——片子其余部分纹丝不动，从不重渲染。给同一张照片试五种取景，是五条小命令，而不是在剪辑软件里来回五趟。

而且真实来源从不移动。每一次改动都是一个文本文件的 diff：可审查、可回退、像代码一样用 git 管理。没有 `final_v3_REAL.prproj`——剧本**就是**项目，视频只是它当前的构建产物。

来点粗略的数字。本章约 9 分 44 秒，由 **41 张照片、7 段档案影像、20 条旁白和约 67 次剪辑操作**——Ken Burns 运镜、字幕、聚光揭示、交叉淡入——构成。这正是上文那个 **1 万到 4 万美元以上、三个人、好几周**的活儿。而这里是一个人指挥 Claude Code，以**天而非周**为单位迭代——设计与剪辑这两项通常占预算大头的开销，缩到接近零的边际成本：一份 Claude Code 订阅，加上几美元的文字转语音，而不是按天计费的摄制组。*（这里的工作量是从成片估算的，并非记录在案的工时表。）*

## 为什么要重造轮子？

好问题。简短的回答：这不是为了造轮子而造轮子——而是为了造一个**更好的**轮子，并让"造轮子"这件事本身更高效。我先试过现成的工具；每一个都很接近，又都差了一口气。

**Descript** —— 我喜欢它的方向：通过编辑文字来编辑视频。但它把开发者和编剧两套思维方式糅在一起，那个混合不合我的用途。接近，但不到位。

<img src="/blog/assets/logo-capcut.svg" alt="" height="22" style="vertical-align:-5px"> **CapCut（剪映）** —— 社交媒体视频里数一数二的好工具，模板库很深。但这恰恰是问题：它为大批量产出和快速周转而生，不是为独一无二的创意作品。它的前 AI 时代设计意味着工作流仍然依赖大量人工照看——没法交给 agent 去驱动和串流，也没有可编程的入口可挂。

<img src="/blog/assets/logo-elevenlabs.svg" alt="" height="20" style="vertical-align:-4px"> <img src="/blog/assets/logo-fishaudio.svg" alt="" height="20" style="vertical-align:-4px"> **文字转语音（ElevenLabs 对比 Fish Audio）** —— 两个都能用，也都达到了"可接受"的水准。我选 Fish Audio，因为它把中文旁白处理得更好。两者目前都还难以推到"足够像真人"；但 Fish Audio 正在积极完善它的可编程 API——当整件事的重点就是一条可自动化的流水线时，这一点恰恰最要紧，所以我更看好它。

共同的线索：现成工具要么不可编程，要么不是为 AI 端到端驱动而设计的。这道缺口，正是"剧本即源代码"这套思路要填上的。

## 写在最后

值得老实说一句：什么**没有**变。

历史依然来之不易。一部声称准确的纪录片，靠的还是老办法去赢得这份准确：找到对的档案照片、确定新闻片的年代、核实画面里的人是不是字幕所说的那位。AI 缩短了机械的部分——下载影像、抓取自动字幕作翻译源、起草一段检索——但什么是真的、什么值得呈现，这份判断仍归人类。Vibe coding 让剧本编译得更快，它并不替你做研究。

而创意内核原封未动——因为那才是全部意义所在。一次揭示的节奏、一句正中要害的旁白、在一张脸上多停一拍的决定：那是编剧的手艺，也正是这条流水线要**保护**的东西。机器接手了编剧从来不想干的部分——打关键帧、反复导出、来回交接——好让只有人能做的部分得到全部注意力。顶级作品从来不是卡在剪辑上，而是卡在讲故事上，现在依然如此。

这就是值得做的交换。写作、编译、交付——把省下来的时间花在故事上。

---

**观看成片**（约 9 分 44 秒）：

<figure>
  <video controls preload="metadata" playsinline width="100%" style="border-radius:8px"
         poster="/blog/assets/flying-tigers-chapter01.jpg">
    <source src="/blog/assets/flying-tigers-chapter01-480p.mp4" type="video/mp4">
    你的浏览器无法播放该视频——<a href="/blog/assets/flying-tigers-chapter01-480p.mp4">下载</a>，或<a href="https://youtu.be/oBjQTPtJdLE">在 YouTube 观看</a>。
  </video>
  <figcaption>《飞虎出征》——第一章，约 9 分 44 秒（480p；<a href="https://youtu.be/oBjQTPtJdLE">YouTube 高清</a>）。</figcaption>
</figure>

<p class="built-with"><strong>构建工具</strong>
  <img src="/blog/assets/logo-claude-code.svg" alt="Claude Code" height="28">
  <a href="https://github.com/nidmgh/video-production-kit"><code>video-production-kit</code></a>
  <img src="/blog/assets/logo-ffmpeg.svg" alt="ffmpeg" height="28">
  <img src="/blog/assets/logo-python.svg" alt="Python + Pillow" height="28">
  <img src="/blog/assets/logo-fishaudio.svg" alt="Fish Audio" height="28">
  <img src="/blog/assets/logo-ytdlp.svg" alt="yt-dlp" height="28">
  <img src="/blog/assets/logo-git.svg" alt="git" height="28">
</p>
