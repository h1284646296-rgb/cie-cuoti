---
name: cie-cuoti
metadata:
  version: "1.0.0"
description: >-
  CIE 错题整理助手：从用户上传的试卷/练习册扫描件或文字中识别做错的题目（以红笔批改/订正为准），
  生成 LaTeX 排版的 PDF 交付件。支持两种产物：①错题重做卷（正面题目、反面官方 Mark Scheme，双面打印配对）；
  ②错题本卡片（题号/题目原文/来源/试卷类型/年份考季/分值/正确答案/答案来源/评分要点 九字段）。
  自动定位官方 Mark Scheme：优先本地缓存（~/Documents/CIE-ms/），缺失时经 Frank 的 CIE 工坊
  (cie.fraft.org) 下载，备用 dynamicpapers.com。触发词：错题、错题本、重做卷、Mark Scheme、蜜蜂试卷、CIE/IGCSE/A Level 改错。
  不用于纯出题、纯讲解或与 CIE 无关的作业整理。
---

# CIE 错题整理助手（cie-cuoti）

把「上传带红笔批改的试卷 → 产出可打印错题 PDF」的全流程固化，避免每次重复摸索。

## 资产与缓存约定

| 路径 | 用途 |
|---|---|
| `~/Documents/CIE-ms/` | **Mark Scheme / Question Paper 永久缓存**（PDF 原文件 + `index.json` 答案键索引）。跨会话复用，勿放临时工作区。 |
| `<workspace>/texroot/TinyTeX/bin/universal-darwin/xelatex` | LaTeX 编译器（本机已装 ctex/geometry/tcolorbox/fancyhdr/booktabs/tabularx；无 mhchem，化学式用 `\mathrm{}` 手写）。若不存在则先探测 `$PATH` 中的 xelatex。 |
| `<workspace>/pylibs` | Python 库：pymupdf(fitz)、PIL。渲染扫描页、裁剪放大、抽取 PDF 文本都靠它。 |

首次使用若缓存目录不存在：`mkdir -p ~/Documents/CIE-ms`（需要沙箱外写权限时用一次性提权并说明原因）。

## 环境自检（新机器第一次运行必做）

判题前先探测三样东西：
```bash
command -v xelatex || ls <workspace>/texroot/TinyTeX/bin/universal-darwin/xelatex 2>/dev/null
python3 -c "import pymupdf, PIL; print('PY-OK')" 2>/dev/null
```
缺什么按下面补（动手前先告诉用户要装什么、多大、大概多久，取得同意）：

- **缺 pymupdf/PIL**：`python3 -m pip install --user pymupdf pillow`（1 分钟内）。若连 `python3` 都没有：macOS 跑 `xcode-select --install`（弹窗确认，等 Command Line Tools 装完，约 5–10 分钟）。
- **缺 xelatex**：装 TinyTeX —— `curl -sL "https://yihui.org/tinytex/install-bin-universal.sh" | sh`，然后把 `$HOME/.TinyTeX/bin/universal-darwin` 加进本会话 PATH 再编译。⚠ 下载几百 MB、10 分钟起步，务必先征得同意；`ctex/tcolorbox` 等宏包缺时 tlmgr 会现场补。
- **用户拒绝安装或网络不通**：明确降级——只能产出 Markdown/纯文本版错题清单 + MS 原文摘录，**没有可打印 LaTeX PDF**；不要把没有编译验证过的 tex 当成品交付。
- 环境装好后本会话内记住新路径，不必反复探测；跨会话重新自检即可。

## 流程总览（按顺序执行）

### 0. 确认输入
- 用户给的是 PDF/图片：复制到工作区再处理；是文字：直接进入判题。
- 快速问清（缺信息才问，不要猜）：**科目代码**（如 9701/0620/9709）、学段、以及想要的产物（重做卷 / 错题本 / 两者）。用户历史偏好：默认输出「重做卷」（正面题目+反面 MS）。

### 1. 逐页识别（扫描件）
```python
import sys; sys.path.insert(0,'<workspace>/pylibs')
import pymupdf
doc = pymupdf.open('paper.pdf')          # 无文字层 ⇒ 纯扫描件
for i,p in enumerate(doc):
    p.get_pixmap(dpi=110).save(f'new_pages/p{i+1}.png')
```
用 read_image 逐页读图。判定规则（沿用用户确认过的标准）：
- **黑笔 = 学生作答，红笔 = 批改**。收录错题的依据：红笔叉号 ✗、红笔划掉旧选项改写新字母、红笔板书更正过程、空白但有红笔范答。
- 纯计算笔误且教师未判错的不收录；只有红勾/圈画但答案正确的不收录。
- 字迹不确定时，裁左边缘高 DPI 放大再读：
```python
pm = page.get_pixmap(dpi=230, clip=pymupdf.Rect(0,0,95,842))   # 每题左侧字母区
```
- 记录每题：卷面代码（如 `S19-11-12` = 考季-试卷-题号）、印刷页码、学生答案、红笔标注、是否存疑。
- 缺页/看不清的题列入「待补拍」，不要编造。

### 2. 核对卷面代码（必做，练习册代码常有印错）
卷面小代码只是线索，**必须与原卷比对题干关键词**确认真实出处（科目/考季/试卷/题号）。曾发现的错误类型：题号错位（w13-13-1 实为 Q11）、试卷号错（s20-11-2 实为 /12）、整串代码错（S21-12-13-2 实为 s21/13 Q2）。

### 3. 获取官方 Mark Scheme（最多尝试 2 次，禁止编造）
优先级：
1. **本地缓存** `~/Documents/CIE-ms/index.json` → 有对应 `{code}_{session}_ms_{paper}` 直接用。
2. **Frank 的 CIE 工坊**（首选远程）：
   `curl -m 60 -o out.pdf "https://cie.fraft.org/obj/Common/Fetch/redir/{code}_{sy}_ms_{p}.pdf"`
   （`sy` ∈ m/w/s + 两位年份，如 `s19`、`w21`、`m22`）
3. **dynamicpapers 兜底**：
   `curl -A "Mozilla/5.0" -m 60 -o out.pdf "https://dynamicpapers.com/wp-content/uploads/2015/09/{文件名}"`

校验与入库：
```bash
file out.pdf | grep -q PDF || echo FAIL     # fraft 失败会返回 HTML
```
成功后：移动到 `~/Documents/CIE-ms/`，并用下方脚本抽答案键合并进 `index.json`。
两跳都失败 ⇒ 该题在 PDF 中明确标注「**未找到官方 Mark Scheme**」，绝不编造评分标准。

提取选择题答案键（对加密字体的真题同样适用位移解码）：
```python
import re, json, glob, os
def unshift(t):
    best,bestc=t,t.count('Which')+t.count(' the ')
    for s in range(128):
        o=''.join(chr((ord(c)+s)%128) if ord(c)<128 else c for c in t)
        c=o.count('Which')+o.count(' the ')
        if c>bestc: best,bestc=o,c
    return re.sub(r'[\x00-\x08\x0b-\x1f]',' ',best)
idx={}
for f in sorted(glob.glob(os.path.expanduser('~/Documents/CIE-ms/*_ms_*.pdf'))):
    import pymupdf
    raw="\n".join(p.get_text() for p in pymupdf.open(f))
    key=os.path.basename(f)[:-4]; pairs={}
    def harvest(t):
        for m in re.finditer(r'(?<![\d.])(\d{1,2}) ([A-D])(?![a-zA-Z])', t):
            q=int(m.group(1))
            if 1<=q<=45 and q not in pairs: pairs[q]=m.group(2)
    harvest(re.sub(r'\s+',' ',raw))
    if len(pairs)<20: harvest(re.sub(r'\s+',' ',unshift(raw)))   # ⚠ 部分 MS（如 9701_m19_ms_12）文本层是移位字体，必须走这条兜底
    if len(pairs)>=20: idx[key]={str(k):v for k,v in sorted(pairs.items())}
json.dump(idx, open(os.path.expanduser('~/Documents/CIE-ms/index.json'),'w'), indent=1)
```
**入库后必做一次抽查**：随机取 3–5 个 (卷,题号)，与 MS 页面渲染目视比对，防止正则误抓正文里的 "N A/B/C/D" 片段。
非选择题（Paper 2/4 主观题）：MS 是逐步给分点，直接读 MS 原文摘录 scoring points，引用其具体表述。

### 4. 验算（防红笔错）
每道错题按 MS 答案独立验算一遍。**若卷面红笔订正与官方 Key 冲突，以官方为准并在 PDF 里 ⚠ 标注**（历史上发生过：Q34 红笔写 A、官方 D）。

### 5. 生成 LaTeX 并编译
模板在本 skill 的 `assets/` 目录，复制进工作区后填充内容：
- `assets/preamble.tex` — 导言区（ctex + a4 + tcolorbox + fancyhdr），两个模板共用。
- `assets/template_redo.tex` — **重做卷**：封面（含题目↔官方试卷映射表）→ 每题正面 `\qfront`（题干+选项+作答区 height fill，无答案）→ 反面 `\msback`（官方出处原文引用+正确答案+评分要点）。双面打印即题-MS 一一对应。
- `assets/template_notebook.tex` — **错题本**：九字段表格卡（题号/题目原文(LaTeX)/练习册来源/试卷类型/年份与考季/分值/正确答案/答案来源/评分要点），另加「待确认」「已判对未收录」附录框。

编译（跑两遍出交叉引用）：
```bash
export PATH="<workspace>/texroot/TinyTeX/bin/universal-darwin:$PATH"
xelatex -interaction=nonstopmode doc.tex && xelatex -interaction=nonstopmode doc.tex
grep -c '^!' doc.log        # 必须为 0
```

**LaTeX 硬性注意（踩过的坑）**：
- 单页卡片外层 tcolorbox **不要加 `breakable`**，内部不要用 `tabularx`——否则整盒被推下一页、版面崩坏。用定宽 `p{...}` tabular 或干脆不用表格。
- **正文/页眉里的下划线必须转义为 `\_`**（如文件名 `蜜蜂试卷\_XXXXXX.pdf`）；`\texttt{~/...}` 里的 `~` 是活跃字符会报 "Missing $ inserted"，写 `\texttt{$\sim$/...}`。填充占位符前先对文本做这两类转义。
- 化学式没有 mhchem：一律 `$\mathrm{CO_2}$`、`$n(\mathrm{H_2O})=\dfrac{...}{...}$`。
- 上下标同位素：`$\,^{16}_{\ 8}\mathrm{O}$`。
- 所有公式、符号、表达式必须是 LaTeX，正文中文用 ctex 直接写。
- 编译后除 `grep -c '^!' log` 外，还要用 pymupdf 检查「题目页不含 Answer/评分要点 等字样」防答案泄漏。

### 6. 质检与交付
```python
d=pymupdf.open('doc.pdf')
print(len(d))                                   # 页数符合预期（重做卷 = 1封面+2N）
for i in [0,1,2,len(d)-1]: d[i].get_pixmap(dpi=95).save(f'chk{i}.png')
```
read_image 抽查：题面无答案泄漏、MS 页与题号对应、无 Overfull 空白页。然后：
- 文件名：`错题重做卷_{科目}_{主题}_{特征}.pdf` / `错题本_{科目}_{主题}.pdf`
- 用 present 工具交付；最终回复里汇总：错题数、收录依据、MS 来源清单、红笔与官方冲突项、待补拍项。

## 常见坑速查
| 症状 | 处理 |
|---|---|
| PDF 无文字层 | 扫描件，走渲染+读图；不要 pdftotext 硬啃 |
| 真题文本是乱码移位 | 用上面 `unshift`（Cambridge 字体偏移，数字常丢失，需渲染页面目视核对） |
| fraft 返回 HTML 404 | 换 dynamicpapers；仍失败则该题标「未找到官方 Mark Scheme」 |
| 某卷只有 11/12/13 三种 P1 | IGCSE 0620 才有 Core/Extended 区分；AS 9701 的 /11 /12 /13 是同考季不同卷，都要试 |
| 学生答案涂写在选项上看不清 | 裁左边缘 + 选项行高 DPI 放大；实在无法辨认 → 列入「待确认」而非猜测 |
