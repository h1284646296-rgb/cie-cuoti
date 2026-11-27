#!/usr/bin/env python3
"""为 ~/Documents/CIE-ms/ 里的 *_ms_*.pdf 抽取选择题答案键，生成 index.json。

用法: python3 setup/build_index.py
依赖: pymupdf（先跑 setup/setup.sh 装好）
- 对 Cambridge 加密字体的 MS 自动做位移解码兜底；
- 只收录能抓到 >=20 个选项键的纯选择题卷（MS 11/12/13 类）；
- 入库后建议抽查 3-5 题与 MS 页面目视核对（见 SKILL.md 第 3 步）。
"""
import re, json, os, glob, sys

try:
    import pymupdf
except ImportError:
    sys.exit("缺少 pymupdf：请先运行 setup/setup.sh")

DIR = os.path.expanduser("~/Documents/CIE-ms")


def unshift(t: str) -> str:
    """Cambridge 私有字体是 ASCII 整体位移，穷举 128 种用英文词频选出正解。"""
    best, bestc = t, t.count("Which") + t.count(" the ")
    for s in range(128):
        o = "".join(chr((ord(c) + s) % 128) if ord(c) < 128 else c for c in t)
        c = o.count("Which") + o.count(" the ")
        if c > bestc:
            best, bestc = o, c
    return re.sub(r"[\x00-\x08\x0b-\x1f]", " ", best)


def harvest(t: str, pairs: dict) -> None:
    for m in re.finditer(r"(?<![\d.])(\d{1,2}) ([A-D])(?![a-zA-Z])", t):
        q = int(m.group(1))
        if 1 <= q <= 45 and q not in pairs:
            pairs[q] = m.group(2)


idx = {}
for f in sorted(glob.glob(os.path.join(DIR, "*_ms_*.pdf"))):
    try:
        raw = "\n".join(p.get_text() for p in pymupdf.open(f))
    except Exception as e:  # 空壳/损坏文件跳过
        print("SKIP", os.path.basename(f), e)
        continue
    key = os.path.basename(f)[:-4]
    pairs: dict = {}
    harvest(re.sub(r"\s+", " ", raw), pairs)
    if len(pairs) < 20:
        harvest(re.sub(r"\s+", " ", unshift(raw)), pairs)
    if len(pairs) >= 20:
        idx[key] = {str(k): v for k, v in sorted(pairs.items())}

with open(os.path.join(DIR, "index.json"), "w") as fp:
    json.dump(idx, fp, indent=1)
print(f"index.json 已生成：{len(idx)} 份选择题卷的答案键")
