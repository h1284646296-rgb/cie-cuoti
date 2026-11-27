# CIE 错题整理助手（cie-cuoti）

把「上传一份带红笔批改的试卷/练习册扫描件 → 产出一份可打印的错题 PDF」的整套流程固化成了一个 AI Agent **Skill**。

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
└── prompt/
    └── CIE错题整理助手提示词.txt    ← 纯提示词版（不装 Skill 也能用，见下文方案 B）
```

## 怎么装（二选一）

### 方案 A：装成 Skill（推荐，效果完整）

适用：你电脑上装了 DeepSeek Harness（DSH）或 Claude Code 这类支持 `SKILL.md` 格式的 Agent 工具。

```bash
git clone https://github.com/h1284646296-rgb/cie-cuoti.git
# DSH：
mkdir -p ~/.dsh/skills
cp -R cie-cuoti/skill/cie-cuoti ~/.dsh/skills/
# Claude Code 同理：cp -R 到 ~/.claude/skills/
```

然后在 Agent 会话里上传你的试卷 PDF/照片，说一句：

> 用 cie-cuoti 帮我整理这份 9701 化学卷子的错题，出重做卷

它就会自动走完整流程：识别红笔错题 → 核对卷面代码与官方试卷的对应关系 → 找 Mark Scheme → LaTeX 编译 → 交付 PDF。

**依赖（一次性准备）：**

- LaTeX：任意 `xelatex` 发行版即可（推荐免费的 [TinyTeX](https://yihui.org/tinytex/)），需要 `ctex`、`tcolorbox`、`fancyhdr`、`booktabs`、`tabularx` 这几个宏包（TinyTeX 首次缺包时会自动装）。
- Python：`pymupdf`（即 `fitz`）和 `pillow`，用来渲染扫描页、裁图放大：`pip install pymupdf pillow`。
- 没有 TinyTeX/pylibs 也能跑：SKILL.md 会先探测 `$PATH` 里的 `xelatex`，没有就提示。

### 方案 B：只用提示词（最省事）

把 `prompt/CIE错题整理助手提示词.txt` 连同你的试卷照片/扫描件，一起发给任何能读文件、能执行代码的 AI 助手（DSH / Claude / ChatGPT / 百炼 等），即可按同样的流程产出重做卷。

> 提示词版没有 Skill 里的模板和「踩坑经验」（练习册代码错位、加密字体位移解码、LaTeX 转义等），成品质量波动更大；追求稳定请用方案 A。

## 关于 Mark Scheme（重要）

**本仓库不包含任何 CIE 真题/Mark Scheme 文件** —— 它们是剑桥国际考评部（Cambridge University Press & Assessment, UCLES）的版权材料，不允许在这里分发。

Skill 采用的策略是：

1. 首次使用时自动在 `~/Documents/CIE-ms/` 建立你本人的缓存目录；
2. 需要某份 Mark Scheme 时优先查本地缓存，没有则按 SKILL.md 中的说明自行获取，之后长期复用；
3. 找不到就明确标「未找到官方 Mark Scheme」，**绝不编造评分标准**。

获取渠道、合规边界由使用者自行把握（不少学校有 Official 下载渠道；Cambridge 官网近年也已公开部分历年真题）。

## 使用小技巧

- 拍照/扫描时保证红笔批改痕迹清晰，缺页会被列入「待补拍」而不是瞎猜。
- 第一次用的时候告诉它科目代码（9701 化学 / 9702 生物 / 9709 数学 / 0620 IGCSE 化学等），能少一轮确认。
- 双面打印重做卷 = 题卡与评分标准一一对应的纸质错题本。

## 版权声明

- 本仓库中的 SKILL.md、LaTeX 模板、提示词、README 等原创内容以 **MIT License** 开源。
- Cambridge International (AS & A Level / IGCSE) 的 Question Papers、Mark Scheme 及一切试题内容版权归 **Cambridge University Press & Assessment** 所有，不在本仓库许可证范围内；本仓库未包含亦不打算分发上述材料。
- 「蜜蜂试卷」等第三方教辅的内容版权归其原权利人所有。

## 反馈

有问题直接在本仓库提 Issue，或找到作者本人。祝考试顺利 🍀
