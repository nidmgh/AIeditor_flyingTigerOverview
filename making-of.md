# 《第一章 · 飞虎出征》开发总结

## 一句话介绍

第一章讲述二战「飞虎队」(Flying Tigers / AVG) 从 1941 年夏出征到番号传承的故事，全程通过 **vibe coding**（用自然语言指挥 Claude Code 完成剪辑流水线）制作而成。成片约 **9 分 44 秒**（584s），含片头、4 个片段、片尾。

## 技术栈

| 类别 | 工具 | 用途 |
|---|---|---|
| 开发环境 | **Claude Code**（CLI / claude.ai/code） | vibe coding 主环境，自然语言驱动 |
| 模型 | **Anthropic Opus 4.7 / 4.8** | 主力推理与脚本生成 |
| 旁白合成 | **Fish Audio** | 中文旁白语音合成 (TTS) |
| 视频流水线 | **video-production-kit**（Claude Code skill） | recipe 工具箱 + 自底向上流水线约定 |
| 音视频处理 | **ffmpeg / ffprobe** | 缩放平移、转场、合成、混音、探测时长 |
| 文本/图形渲染 | **Python 3 + Pillow (PIL)** | 字幕plate、聚光蒙版、金属标题、星战式 crawl |
| 档案素材获取 | **yt-dlp** | 下载档案新闻片片段、抓取 YouTube 自动字幕作翻译源 |
| 脚本编排 | **bash**（`set -euo pipefail`，兼容 macOS 自带 bash 3.2） | 串接 recipe 调用 |
| 字体 | **STHeiti Medium**（金属标题/crawl）、**Songti**（正文字幕/卡片）、**DIN Condensed Bold**（拉丁标题） | macOS 系统字体 |
| 版本管理 | **git / GitHub** | 版本控制（含历史改写、私有→公开） |

## 历史素材

| 类型 | 数量 | 说明 |
|---|---|---|
| 历史照片 | **41 张** | 报纸、机组合影、徽章、单机照等（jpg/png/webp） |
| 档案影像 | **7 个视频文件** | 源自 **2 段档案新闻片**：珍珠港海军新闻片（剪 3 段→合成）、飞虎队新闻片（原片 + 中文字幕版） |
| 旁白音轨 | **20 条** | 按 cue 切分的中文旁白（mp3） |
| 背景音乐 | 2 首 | 片头/片尾金属标题曲、章节铺底乐（`music-bed.mp3`，学习用占位音轨，可自行替换） |

各片段素材分布：clip01（11 图）、clip02（8 图 + 5 视频）、clip03（12 图）、clip04（10 图 + 2 视频）。

## SKILL 与 recipe 总结

基于 **video-production-kit** skill —— 一套「独立 bash recipe 工具箱 + 端到端流水线约定」。本章实际调用的 recipe（按使用次数）：

| Recipe | 次数 | 作用 |
|---|---|---|
| `caption_overlay.sh` | 27 | 下三分之一 / 角标字幕（图注、年份、人名、出处） |
| `ken_burns.sh` | 17 | 静态照片的缩放 / 平移（Ken Burns 运动） |
| `audio_attach.sh` | 17 | 把旁白贴合到静默画面，处理前导静音与时长对齐 |
| `crossfade.sh` | 12 | cue 与 clip 之间的交叉淡入淡出串接 |
| `subtitle_burn.sh` | 3 | 单条定时字幕烧录 |
| `lowres_frame.sh` | 3 | 低清档案影像的米色相框内嵌（「档案照」质感） |
| `title_card.sh` | 1 | 黑场标题卡（AVG 解散日期） |
| `text_spotlight.sh` | 1 | 长文档缓慢下移 + 段落聚光（报纸「飞虎队」揭示） |
| `srt_burn.sh` | 1 | 整条 SRT 一次性烧录（新闻片中文字幕） |
| `crawl.sh` | 1 | 星战式后退字幕（AVG→CATF→14AF→CACW 番号传承） |

章节级背景音乐床未直接调用 `music_bed.sh`，而是在 `build_chapter.sh` 内联实现 **按 cue 类型铺底**的规则（见下）。

## 脚本架构与 .sh 清单

**自底向上构建：cue（镜头）→ clip（片段）→ chapter（章节）。** 每层各自有 `output/`，中间产物在 `tmp/`、逐 cue 审核件在 `stage/`。

| 脚本 | 职责 |
|---|---|
| `clip0N/build_clip.sh` ×4 | 每片段一个：按 cue 分函数（`build_cue1`…）逐镜头渲染到 `stage/cues/`，再 `crossfade` 成 `output/clip.mp4`；支持 `CUE=n` 单独重建某 cue 以便审核 |
| `build_chapter.sh` | 串接 `opening → clip01→04 → ending`；按规则给每个片段叠加**连续音乐床**（−18dB）：**静态画面 + 旁白**的段落铺底乐，**档案视频**（珍珠港、新闻片）或**自带音效**（cue5 防空/飞机声）的段落跳过；音乐跨段落连续 seek，不重头 |
| `../opening/build_opening.sh` | 8 秒金属片头：暗场→「飞虎队 / FLYING TIGERS」点燃→末 3 秒淡入章节标题；可复用于各章 |
| `../opening/build_ending.sh` | 片尾卡（「本章完 / 下一章…」），暖银文字风格 |
| `../opening/make_*.py` | Pillow 生成金属标题 / 章节标题 / 片尾 / 星空等 plate |

**关键约定**：产物只进 `./tmp` 与 `./output`（不进 `/tmp`）；音轨时长 == 视频时长（保证 `crossfade` 不丢同步）；recipe 全部独立、位置参数 + 环境变量微调。
