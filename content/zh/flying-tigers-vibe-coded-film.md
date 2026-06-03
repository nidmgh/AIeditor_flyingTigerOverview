---
title: "写作 · 编译 · 交付 —— 为视频而生"
date: 2026-06-01
published: true
lang: zh
slug: flying-tigers-vibe-coded-film
translated: true
author: 迈哥
---

![传统视频制作需要三个角色——编剧、设计师、剪辑师；而在这套流程里，创作者负责创造力想象力，其余交给机器。](/blog/assets/flying-tigers-hero_zh.jpg)

*用 vibe coding 做一部约 10 分钟的二战纪录片——剧本 == 源代码。*

## 要解决的问题？

编剧的工作，到剧本为止。对白、旁白、场景说明，偶尔来一句"这里在照片上缓缓推近"——这就是交付物。把这些纸面文字变成成片，向来是另一门手艺：剪辑师、时间线、NLE，外加好几天的拖拽素材和关键帧调试。

本项目目标是优化和自动化后期的重复性工序——要求编剧集中她他们的创造力和想象力，完成剧本，让AI将剧本编译成为满意的影像产品。

剧本始终是唯一的真实来源。在这个项目里就是 `script.md`，上面再加一份 `outline.md`：创作者照旧写下分镜、旁白和画面文字，需要时直接用行业术语——"Ken Burns 运镜""下三分之一字幕""交叉淡入淡出"。不用学新的创作工具，也不用学剪辑软件。

剩下的交给机器。Vibe coding 加上一套 SKILL，把这些人类语言翻译成可构建的 shell 脚本（`.sh`），脚本再执行成可发布的 `.mp4`。

这就是把开发者的循环套用到影片上。Java 程序员写 `.java`，编译器把它变成可运行的东西；这里，创作者的 `outline.md` 和 `script.md` 是源文件，项目把它们编译成 `.sh`，shell 一跑就产出视频。同一个形状——用人类可读的源文件创作，编译、执行、交付。

## 传统方式的投入成本

十分钟的成片可不是小事。行业经验法则的报价：最低端约**每分钟 1,000 美元**，比较现实的起步价是**每分钟 2,000–4,000 美元**，电视级则要 **10,000 美元以上**——所以单是一章约 10 分钟的片子，在还谈不上"专业级视频"之前，就已经是一个 **1 万到 4 万美元以上**的项目。

像本章这样以档案照片加旁白为主的片子省掉了摄制组，但预算只是换了个地方：花在**资料研究与档案授权**、一位**编剧**、一位**配音**，以及——重头戏——一位**动态图形剪辑师**，逐张照片做动画。剪辑通常**每小时 75–150 美元**，定制动画往往**超过 40 小时**——而十分钟的 Ken Burns 运镜、烧录字幕、聚光揭示和交叉淡入淡出，是一大堆定制动画。

它还需要**三个人**沿着流水线接力：编剧写、设计师做画面、剪辑师剪。每一次交接都有交流成本和意图损耗流失、周期被拉长成数周的地方。

<p class="sources"><em>成本基准（2025–2026）：每分钟成片的纪录片报价参考 <a href="https://courses.desktop-documentaries.com/courses/documentary-going-rates-handbook">Desktop Documentaries</a>、<a href="https://windsky.com.au/how-much-does-a-documentary-cost/">Wind &amp; Sky Productions</a> 和 <a href="https://www.academyvoices.com/blog/how-much-does-it-cost-to-make-a-documentary-a-complete-breakdown">Academy Voices</a>；剪辑与定制动画费率参考 <a href="https://vidico.com/news/video-production-cost/">Vidico</a>。</em></p>

## 新的AI方式

写一个分镜条目(cue)，让它构建，看片段。就这么个循环。

`script.md` 里的一个 cue，读起来就像编剧本来就会在旁边记下的东西：要出现的照片或影像、旁白台词、画面上的字幕，以及运动方式——"Ken Burns 向大桥推近""下三分之一字幕：1941 年夏 · 旧金山""交叉淡入下一镜"。大白话，加上编剧本就熟悉的行业术语。

然后你叫 Claude Code 去构建。Vibe coding 把这份 cue 表变成 `build_clip.sh`，跑一遍，交回 `clip.mp4`。第三镜不满意？改一句旁白，或把 "zoom-in" 换成 "pan-up"，只重建那一个 cue（`CUE=3 bash build_clip.sh`），几秒钟就能重看。把做好的片段串成整章，方法一样。

没有时间线，没有关键帧，不用把素材在设计师那里来回倒腾。创作者全程待在剧本里——画面只是不断追上文字。

底层是一条自底向上的流水线——镜头组成片段，片段组成成片：

<figure>
  <img src="/blog/assets/flying-tigers-pipeline_zh.jpg" alt="自底向上的构建流水线：你写 outline.md 和 script.md，vibe coding（Claude Code）生成构建脚本；镜头组成片段，片段组成章节，章节交付为 chapter.mp4——配上音乐床与片头/片尾。">
  <figcaption>自底向上的构建流水线——源文件向上编译，经镜头、片段、章节，汇成成片 <code>chapter.mp4</code>。</figcaption>
</figure>

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

## AI的新工作流

那条三人流水线坍缩成一个人。编剧保留自己的位置；设计师和剪辑师的活儿被机器吸收，剧本一要求，画面就构建出来。没有交接——于是没有什么在传递中流失，也没有什么排队等待。

迭代从几小时降到几秒。在时间线里重剪一镜意味着重新导入、重打关键帧、重新导出。这里，你在 `script.md` 改一行，只重建那一个 cue——片子其余部分纹丝不动，从不重渲染。给同一张照片试五种取景，是五条小命令，而不是在剪辑软件里来回五趟。

而且真实来源从不移动。每一次改动都是一个文本文件的 diff：可审查、可回退、像代码一样用 git 管理。没有 `final_v3_REAL.prproj`——剧本**就是**项目，视频只是它当前的构建产物。

来点粗略的数字。本章约 9 分 44 秒，由 **41 张照片、7 段档案影像、20 条旁白和约 67 次剪辑操作**——Ken Burns 运镜、字幕、聚光揭示、交叉淡入——构成。这正是上文那个 **1 万到 4 万美元以上、三个人、好几周**的活儿。而这里是一个人指挥 Claude Code，以**天而非周**为单位迭代——设计与剪辑这两项通常占预算大头的开销，缩到接近零的边际成本：一份 Claude Code 订阅，加上几美元的文字转语音，而不是按天计费的摄制组。*（这里的工作量是从成片估算的，并非记录在案的工时表。）*

## 为什么要重造轮子？

好问题。简短的回答：不是为了造轮子而造轮子——而是为了造一个**更好的**轮子，并让"造轮子"这件事本身更高效。我先试过现成的工具；每一个都很接近，又都差了一口气。

<img src="/blog/assets/logo-descript.png" alt="Descript" height="20" style="vertical-align:-4px"> **Descript** —— 我喜欢它的方向：通过编辑文字来编辑视频。但它把开发者和编剧两套思维方式糅在一起，那个混合不合我的用途。接近，但不到位。

<img src="/blog/assets/logo-capcut.svg" alt="" height="22" style="vertical-align:-5px"> **CapCut（剪映）** —— 社交媒体视频里数一数二的好工具，模板库很深。但这恰恰是问题：它为大批量产出和快速周转而生，不是为独一无二的创意作品。它的前 AI 时代设计意味着工作流仍然依赖大量人工照看——没法交给 agent 去驱动和串流，编程的入口还比较稚嫩，而且由于已有设计的考虑，比较难于从根本上适应2026的AI发展。

<img src="/blog/assets/logo-elevenlabs.svg" alt="" height="20" style="vertical-align:-4px"> <img src="/blog/assets/logo-fishaudio.svg" alt="" height="20" style="vertical-align:-4px"> **文字转语音（ElevenLabs 对比 Fish Audio）** —— 两个都能用，也都达到了"可接受"的水准。我选 Fish Audio，因为它把中文旁白处理得更好。两者目前都还难以推到"足够像真人"；但 Fish Audio 正在积极完善它的可编程 API——当整件事的重点就是一条可自动化的流水线时，这一点恰恰最要紧，所以我更看好它。

**Claude Design** —— Anthropic 刚发布的可视化创作工具（[research preview](https://www.anthropic.com/news/claude-design-anthropic-labs)，隶属 Anthropic Labs）：把需求说给它，它就生成设计稿、原型、幻灯片与宣传物料。我第一时间就上手试了——初见 demo 确实惊艳。但 Anthropic 自己也坦言，它还停在"research lab"阶段；用下来正是这种感觉：功能简陋、打磨不足，对我这条流水线而言，现阶段连最基本的要求都还谈不上满足。它是这几款里最"AI 原生"的一个，却也最早期——方向让人期待，但还没到能用的时候。

共同的线索：现成工具要么不可编程，要么不是为 AI 端到端驱动而设计的。这道缺口，正是"剧本即源代码"这套思路要填上的。

## 开源库

这里的一切都是开源的——有兴趣的话可以把如下github repo克隆下来，重建这部片子。

**[video-production-kit](https://github.com/nidmgh/video-production-kit)** —— 可复用的引擎。**20 个独立的 shell recipe**（`ken_burns.sh`、`caption_overlay.sh`、`crossfade.sh`、`subtitle_burn.sh`、`text_spotlight.sh` 等等）、**7 篇参考文档**（端到端流水线、cue 格式规范、ffmpeg/zoompan 与文本渲染的深入解析），外加一个项目脚手架——全部是零依赖的 bash。可以当工具箱做零散的镜头，也可以用来搭起一整个纪录片系列。

**[AIeditor · Flying Tigers](https://github.com/nidmgh/AIeditor_flyingTigerOverview)** —— 就是本文这个范例，也让你看到十分钟背后真实的复杂度：**41 张历史照片**、**7 段档案影像**（剪自 2 段新闻片）、**20 条旁白**、**2 段音乐床**，由 **7 个构建脚本**编排进 **4 个片段加片头片尾**——总共约 **67 次剪辑操作**。把它克隆到 kit 旁边，跑一遍构建，就能看着整部片子拼装出来。

## 写在最后

值得老实说一句：什么**没有**变。

本项目的例子是历史纪录片。一部高质量的纪录片，靠的还是老办法去赢得这份准确：找到合适的档案照片、确定新闻片的年代、核实画面里的人是不是字幕所说的那位。AI 缩短了机械的部分——下载影像、抓取自动字幕作翻译源、起草一段检索——但什么是真的、什么值得呈现，这份判断仍归人类。Vibe coding 让剧本编译得更快，它并不替需要创新，依赖人类灵光乍现的创造力的研究。

而创意内核原封未动——因为那才是全部意义所在。一次揭示的节奏、一句正中要害的旁白、在一张脸上多停一拍的决定：那是编剧的手艺，也正是这条流水线要**保护**的东西。机器接手了编剧从来不想干的部分——打关键帧、反复导出、来回交接——好让只有人能做的部分得到全部注意力。顶级作品从来不是卡在剪辑上，而是卡在讲故事上，现在依然如此。

这就是值得做的交换。写作、编译、交付——把省下来的时间花在故事上。

---

**观看成片**（约 9 分 44 秒）：

<figure>
  <div style="position:relative;padding-bottom:56.25%;height:0;overflow:hidden;border-radius:8px">
    <iframe src="https://www.youtube.com/embed/oBjQTPtJdLE" title="飞虎出征：第一章"
            style="position:absolute;top:0;left:0;width:100%;height:100%;border:0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
            allowfullscreen loading="lazy"></iframe>
  </div>
  <figcaption>《飞虎出征》——第一章，约 9 分 44 秒（<a href="https://youtu.be/oBjQTPtJdLE">在 YouTube 观看</a>）。</figcaption>
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
