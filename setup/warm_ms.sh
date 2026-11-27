#!/usr/bin/env bash
# ===== 预热全班常用真题缓存（9701/9702/9709 共 134 份 ≈ 27MB）=====
# 按 manifest.txt 清单逐份从 Frank 的 CIE 工坊获取；已存在/有效的跳过。
# 跨平台：macOS zsh/bash 与 Windows Git Bash 通用（不依赖 file/stat 命令，用 %PDF- 文件头校验）。
# 单份失败不影响其余（Skill 判题时还会按需重试）。
set -uo pipefail
DIR="$HOME/Documents/CIE-ms"
SRC="https://cie.fraft.org/obj/Common/Fetch/redir"
MANIFEST="$(cd "$(dirname "$0")" && pwd)/manifest.txt"
mkdir -p "$DIR"
ok=0; skip=0; fail=0; FAILED=""
total=$(grep -c . "$MANIFEST")
say(){ printf '\r    [%d/%d] 新下 %d · 跳过 %d · 失败 %d' $((ok+skip+fail)) "$total" "$ok" "$skip" "$fail"; }
is_pdf(){ [ "$(head -c 5 "$1" 2>/dev/null)" = '%PDF-' ]; }
size(){ wc -c < "$1" 2>/dev/null | tr -d ' '; }
while IFS= read -r code; do
  [ -z "$code" ] && continue
  f="$DIR/$code.pdf"
  if [ -s "$f" ] && is_pdf "$f" && [ "$(size "$f")" -gt 10000 ]; then skip=$((skip+1)); say; continue; fi
  if curl -fsSL -m 90 -o "$f.tmp" "$SRC/$code.pdf" && is_pdf "$f.tmp" && [ "$(size "$f.tmp")" -gt 10000 ]; then
    mv "$f.tmp" "$f"; ok=$((ok+1))
  else
    rm -f "$f.tmp"; fail=$((fail+1)); FAILED="$FAILED $code"
  fi
  say
done < "$MANIFEST"
echo
[ "$fail" -gt 0 ] && echo "未取到:$FAILED" && echo "$FAILED" | tr ' ' '\n' | grep . > "$DIR/.warm_fail.txt"
echo "预热完成：新下载 $ok，已有 $skip，失败 $fail（失败项已记入 .warm_fail.txt，Skill 判题时会再试）"
exit 0
