#!/usr/bin/env bash
# ===== cie-cuoti 一键环境配置（macOS，免 sudo，重复运行安全）=====
# 用法: bash setup.sh [--no-warm]     --no-warm = 跳过真题缓存预热
set -uo pipefail
NO_WARM=0; [ "${1:-}" = "--no-warm" ] && NO_WARM=1
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
say(){ printf '\n==> %s\n' "$*"; }

# ---------- 1/4 Command Line Tools (python3 / git) ----------
if command -v python3 >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
  say "1/4 Command Line Tools 已就绪 ✓"
else
  say "1/4 安装 Xcode Command Line Tools（提供 python3/git，约 5-10 分钟，无需点击）"
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  LABEL=$(softwareupdate -l 2>/dev/null | grep -o 'Command Line Tools[^-]*- [0-9.]*' | sort -u | tail -1)
  [ -n "$LABEL" ] && softwareupdate -i "$LABEL" || true
  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  if ! command -v python3 >/dev/null 2>&1; then
    xcode-select --install 2>/dev/null || true
    say "未找到可用更新标签，已弹出系统对话框：请点『安装』，完成后重跑本脚本"
    exit 1
  fi
fi

# ---------- 2/4 Python 库 ----------
say "2/4 安装 pymupdf / pillow（扫描页渲染用）"
python3 -m pip install --user --quiet pymupdf pillow 2>/dev/null \
  || python3 -m pip install --user --break-system-packages --quiet pymupdf pillow
python3 -c "import pymupdf, PIL" || { say "Python 库安装失败，请贴报错重跑"; exit 1; }

# ---------- 3/4 LaTeX ----------
if command -v xelatex >/dev/null 2>&1 || [ -x "$HOME/.TinyTeX/bin/universal-darwin/xelatex" ]; then
  say "3/4 xelatex 已就绪 ✓"
else
  say "3/4 安装 TinyTeX（LaTeX 引擎，约几百 MB，5-15 分钟，全程无人值守）"
  curl -fsSL https://yihui.org/tinytex/install-bin-universal.sh | sh
fi
# 统一 bin 目录名为 SKILL.md 约定的 universal-darwin（Intel/Apple Silicon 通用）
BIN=$(ls "$HOME/.TinyTeX/bin" 2>/dev/null | grep darwin | head -1)
if [ -n "${BIN:-}" ] && [ ! -e "$HOME/.TinyTeX/bin/universal-darwin" ]; then
  ln -s "$BIN" "$HOME/.TinyTeX/bin/universal-darwin"
fi
export PATH="$HOME/.TinyTeX/bin/universal-darwin:$PATH"
grep -q 'TinyTeX/bin/universal-darwin' "$HOME/.zshrc" 2>/dev/null || \
  echo 'export PATH="$HOME/.TinyTeX/bin/universal-darwin:$PATH"' >> "$HOME/.zshrc"
say "3/4 补齐宏包 ctex / tcolorbox / fancyhdr / booktabs / tabularx"
tlmgr install ctex tcolorbox fancyhdr booktabs tabularx >/dev/null 2>&1 || true

# ---------- 4/4 真题缓存 ----------
say "4/4 Mark Scheme 缓存目录 ~/Documents/CIE-ms"
mkdir -p "$HOME/Documents/CIE-ms"
if [ "$NO_WARM" = 0 ]; then
  bash "$SELF_DIR/warm_ms.sh"
  python3 "$SELF_DIR/build_index.py" || true
else
  say "4/4 已跳过预热（--no-warm），错题涉及新卷时按需下载"
fi

say "完成 ✓  xelatex: $(command -v xelatex || echo 未找到，请重开终端)"
say "现在在 DSH 里上传试卷说『用 cie-cuoti 整理错题』即可。"
