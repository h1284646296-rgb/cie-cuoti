# ===== cie-cuoti 一键环境配置（Windows 10 1809+/11，免管理员，重复运行安全）=====
# 用法: powershell -ExecutionPolicy Bypass -File setup.ps1
#       跳过真题预热加 -NoWarm
param([switch]$NoWarm)
$ErrorActionPreference = 'Stop'

function Say($m){ Write-Host "`n==> $m" }
function RefreshPath {
  $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
}

# ---------- 1/4 Python ----------
if (Get-Command python -ErrorAction SilentlyContinue) {
  Say '1/4 Python 已就绪 ✓'
} else {
  Say '1/4 安装 Python 3（winget，约几分钟）'
  winget install -e --id Python.Python.3.12 --scope user --accept-source-agreements --accept-package-agreements --disable-interactivity
  RefreshPath
  if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Say '未找到 python（winget 未安装或失败）：请到 https://www.python.org/downloads/ 装 Python 后重跑本脚本'; exit 1
  }
}
python --version

# ---------- 2/4 Python 库 ----------
Say '2/4 安装 pymupdf / pillow（扫描页渲染用）'
python -m pip install --quiet --user pymupdf pillow
python -c "import pymupdf, PIL"

# ---------- 3/4 LaTeX (MiKTeX) ----------
RefreshPath
if (Get-Command xelatex -ErrorAction SilentlyContinue) {
  Say '3/4 xelatex 已就绪 ✓'
} else {
  Say '3/4 安装 MiKTeX（约几百 MB，10-20 分钟，全程无人值守）'
  winget install -e --id MiKTeX.MiKTeX --scope user --accept-source-agreements --accept-package-agreements --disable-interactivity
  RefreshPath
}
# 编译时缺宏包（ctex/tcolorbox 等）自动现场下载
initexmf --set-config-value "[MPM]AutoInstall=1" 2>$null
if (Get-Command xelatex -ErrorAction SilentlyContinue) {
  xelatex --version | Select-Object -First 1
} else {
  Say 'xelatex 仍不在 PATH：重开终端即可（MiKTeX 用户版目录 %LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64）'
}

# ---------- 4/4 真题缓存 ----------
$dir = Join-Path $HOME 'Documents/CIE-ms'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
if ($NoWarm) {
  Say '4/4 已跳过预热（-NoWarm），判题时按需下载'
} else {
  Say '4/4 预热全班常用真题缓存（134 份 ≈ 27MB，约 2-5 分钟）'
  $src = 'https://cie.fraft.org/obj/Common/Fetch/redir'
  $items = @(Get-Content (Join-Path $PSScriptRoot 'manifest.txt') | Where-Object { $_ })
  $ok=0; $skip=0; $fail=0; $failed=@(); $i=0
  foreach ($code in $items) {
    $i++
    $f = Join-Path $dir "$code.pdf"
    if ((Test-Path $f) -and ((Get-Item $f).Length -gt 10240)) { $skip++ }
    else {
      $tmp = "$f.tmp"
      try {
        Invoke-WebRequest -UseBasicParsing -TimeoutSec 90 -Uri "$src/$code.pdf" -OutFile $tmp
        $fs = [IO.File]::OpenRead($tmp); $b = New-Object byte[] 5; $fs.Read($b,0,5) | Out-Null; $fs.Close()
        if (([Text.Encoding]::ASCII.GetString($b) -eq '%PDF-') -and ((Get-Item $tmp).Length -gt 10240)) {
          Move-Item -Force $tmp $f; $ok++
        } else {
          Remove-Item -Force $tmp -ErrorAction SilentlyContinue; $fail++; $failed += $code
        }
      } catch {
        Remove-Item -Force $tmp -ErrorAction SilentlyContinue; $fail++; $failed += $code
      }
    }
    Write-Progress -Activity 'CIE 真题缓存预热' -Status "$code" -PercentComplete ($i * 100 / $items.Count)
  }
  Write-Progress -Activity 'CIE 真题缓存预热' -Completed
  if ($failed.Count) { $failed | Set-Content (Join-Path $dir '.warm_fail.txt') }
  Say ("缓存：新下载 $ok · 已有 $skip · 失败 $fail（失败项 Skill 判题时会再试）")
  python (Join-Path $PSScriptRoot 'build_index.py')
}

Say '完成 ✓ 上传试卷对你的 AI 助手说「用 cie-cuoti 整理错题」即可。'
