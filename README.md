# CIE 错题整理助手（cie-cuoti）

把「上传一份带红笔批改的试卷/练习册扫描件 → 产出一份可打印的错题 PDF」的整套流程固化成了一个 AI Agent **Skill**。macOS 和 Windows 都支持，**新同学零技术门槛：第一次用会全自动配好环境**。

它能做两件事：

1. **错题重做卷**（PDF，双面打印）：正面是一道道做错的题（题干+选项+作答区，无答案），反面是对应小题的**官方 Mark Scheme**（出处原文 + 正确答案 + 评分要点），一一对应。
2. **错题本卡片**（PDF）：每题一张九字段卡片——题号 / 题目原文 / 练习册来源 / 试卷类型 / 年份与考季 / 分值 / 正确答案 / 答案来源 / 评分要点。

判定错题的依据：**黑笔 = 学生作答，红笔 = 批改订正**。只收录红笔打叉/划改/更正过的小题，做对的不混入；红笔订正与官方答案冲突时以官方为准并在 PDF 里标 ⚠。

## 这个仓库里有什么

```
cie-cuoti/
├── README.md                        ← 本文件
├── LICENSE                          ← MIT（仅覆盖本仓库的代码/文本，见下方版权声明）
├── skill/
│   └── cie-cuoti/
│       ├── SKILL.md                 ← Skill 主文件（完整流程指令）
│       └── assets/
│           ├── preamble.tex         ← LaTeX 公共导言区（ctex + a4 + tcolorbox）
│           ├── template_redo.tex    ← 「重做卷」模板
│           └── template_notebook.tex← 「错题本」模板
├── prompt/
│   └── CIE错题整理助手提示词.txt    ← 纯提示词版（不装 Skill 也能用，见方案 B）
└── setup/
    ├── setup.sh                     ← macOS 一键环境配置
    ├── setup.ps1                    ← Windows 一键环境配置
    ├── warm_ms.sh + manifest.txt    ← 预热全班 134 份试卷缓存（两平台通用）
    └── build_index.py               ← 生成答案键索引 index.json
```

## 怎么装

### 方案 A：装成 Skill（推荐，效果完整）

适用：电脑上装了 DeepSeek Harness（DSH）或 Claude Code 这类支持 `SKILL.md` 格式的 Agent 工具。

**macOS（终端里逐行粘贴回车）：**

```bash
git clone https://github.com/h1284646296-rgb/cie-cuoti.git
mkdir -p ~/.dsh/skills && cp -R cie-cuoti/skill/cie-cuoti ~/.dsh/skills/
```

**Windows（PowerShell 窗口里逐行粘贴回车）：**

```powershell
git clone https://github.com/h1284646296-rgb/cie-cuoti.git
mkdir $HOME\.dsh\skills -Force; Copy-Item -Recurse cie-cuoti\skill\cie-cuoti $HOME\.dsh\skills\
```

> Claude Code 用户同理：把 `skill/cie-cuoti` 拷到 `~/.claude/skills/`。
> 没装 git 也没关系：浏览器打开仓库页 → Code → Download ZIP，解压后把 `skill/cie-cuoti` 文件夹拖进上面说的目录。

然后在 Agent 会话里上传你的试卷 PDF/照片，说一句：

> 用 cie-cuoti 帮我整理这份 9701 化学卷子的错题，出重做卷

### 一键自动配置：第一次跑会发生什么

**你不需要懂 TeX、Python、命令行这些词。** 第一次调用 Skill 时，它检测到环境没配好，会自己跑 `setup/setup.sh`（macOS）或 `setup/setup.ps1`（Windows），全程无人值守，约 10–20 分钟，依次完成：

| 步骤 | macOS | Windows |
|---|---|---|
| Python 3 | 装 Xcode Command Line Tools | `winget install Python` |
| PDF 处理库 | `pip install pymupdf pillow` | 同左 |
| LaTeX 引擎（出 PDF 用） | TinyTeX（几百 MB） | MiKTeX（几百 MB，缺宏包自动现装） |
| 真题缓存 | 按下表清单预热 `Documents/CIE-ms/`（134 份 ≈ 27MB，2–5 分钟） | 同左 |

配好后它才会开始判你的错题；之后每次都是秒开。脚本可重复跑（已装好的自动跳过），也可先手动跑一遍：`bash setup/setup.sh` / `powershell -File setup/setup.ps1`。

### 方案 B：只用提示词（最省事）

把 `prompt/CIE错题整理助手提示词.txt` 连同你的试卷照片/扫描件，一起发给任何能读文件、能执行代码的 AI 助手（DSH / Claude / ChatGPT / 百炼 等），即可按同样的流程产出重做卷。

> 提示词版没有 Skill 里的模板和「踩坑经验」（练习册代码错位、加密字体位移解码、LaTeX 转义等），成品质量波动更大；追求稳定请用方案 A。

## 关于 Mark Scheme（重要）

**本仓库不包含任何 CIE 真题/Mark Scheme 文件** —— 它们是剑桥国际考评部（Cambridge University Press & Assessment, UCLES）的版权材料，不允许在这里分发。仓库只提供自动化脚本，文件由各人本机自行获取。

预热清单（`setup/manifest.txt`）覆盖**本班常用科目 9701 化学 / 9702 生物 / 9709 数学的 134 份试卷**——初始化时一次性拉取缓存，本班同学的错题基本不再需要联网。清单之外的卷子（比如换了科目或年份）由 Skill 判题时按需获取并补进缓存；拿不到就明确标「未找到官方 Mark Scheme」，**绝不编造评分标准**。

获取渠道、合规边界由使用者自行把握（不少学校有 Official 下载渠道；Cambridge 官网近年也已公开部分历年真题）。

## 使用小技巧

- 拍照/扫描时保证红笔批改痕迹清晰，缺页会被列入「待补拍」而不是瞎猜。
- 第一次用的时候告诉它科目代码（9701 化学 / 9702 生物 / 9709 数学 / 0620 IGCSE 化学等），能少一轮确认。
- 双面打印重做卷 = 题卡与评分标准一一对应的纸质错题本。
- Windows 同学若 LaTeX 弹包下载中断，重跑一次 setup.ps1 即可（幂等）。

## 版权声明

- 本仓库中的 SKILL.md、LaTeX 模板、提示词、README 等原创内容以 **MIT License** 开源。
- Cambridge International (AS & A Level / IGCSE) 的 Question Papers、Mark Scheme 及一切试题内容版权归 **Cambridge University Press & Assessment** 所有，不在本仓库许可证范围内；本仓库未包含亦不打算分发上述材料。
- 「蜜蜂试卷」等第三方教辅的内容版权归其原权利人所有。

## 反馈

有问题直接在本仓库提 Issue，或找到作者本人。祝考试顺利 🍀
