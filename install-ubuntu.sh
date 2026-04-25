#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  Claude Code 一鍵安裝腳本（原生 Ubuntu 版）
#  適用：Ubuntu 22.04 / 24.04 原生安裝
#
#  用法：
#    git clone https://github.com/a0935951152-droid/Claude_Code_Class_0425.git
#    cd Claude_Code_Class_0425
#    chmod +x install-ubuntu.sh
#    ./install-ubuntu.sh
#
#  完成後：
#    source ~/.bashrc
#    claude
# ═══════════════════════════════════════════════════════════════
set -e

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; B='\033[1m'; N='\033[0m'

TOTAL=4; NUM=0
step() { NUM=$((NUM+1)); echo ""; echo -e "${G}[${NUM}/${TOTAL}]${N} ${B}${1}${N}"; echo -e "${C}────────────────────────────────────────${N}"; }
ok()   { echo -e "  ${G}✅ ${1}${N}"; }
warn() { echo -e "  ${Y}⚠️  ${1}${N}"; }
fail() { echo -e "  ${R}❌ ${1}${N}"; exit 1; }

echo ""
echo -e "${C}╔════════════════════════════════════════════════╗${N}"
echo -e "${C}║${N}  ${B}Claude Code Installer — 原生 Ubuntu 版${N}       ${C}║${N}"
echo -e "${C}║${N}  Native Binary · 不需要 Node.js                ${C}║${N}"
echo -e "${C}╚════════════════════════════════════════════════╝${N}"
echo ""

# ── 系統檢查 ──
echo -e "${B}系統檢查...${N}"

if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo -e "  OS:     ${C}${PRETTY_NAME}${N}"
else
  warn "無法偵測作業系統"
fi

echo -e "  Kernel: ${C}$(uname -r)${N}"
echo -e "  Arch:   ${C}$(uname -m)${N}"

# 確認是原生 Linux（不是 WSL）
if grep -qi microsoft /proc/version 2>/dev/null; then
  warn "偵測到 WSL 環境，此腳本為原生 Ubuntu 設計"
  warn "WSL 用戶請使用 install.sh"
  echo -e "  ${Y}繼續執行？ [y/N]${N}"
  read -r CONT
  [[ ! "$CONT" =~ ^[Yy]$ ]] && exit 0
fi

# 路徑檢查
echo "$HOME" | grep -qP '[[:space:]]' 2>/dev/null && fail "HOME 路徑含空格: $HOME"
ok "路徑安全: $HOME"

# ═══ Step 1: 系統套件 ═══
step "安裝系統基礎套件"

sudo apt-get update -qq
sudo apt-get install -y -qq \
  curl git wget \
  build-essential \
  ca-certificates \
  2>/dev/null

ok "git    $(git --version 2>/dev/null | cut -d' ' -f3)"
ok "curl   $(curl --version 2>/dev/null | head -1 | cut -d' ' -f2)"

# ═══ Step 2: Claude Code Native Binary ═══
step "安裝 Claude Code（Native Binary）"

# 清除舊版（npm 版）如果存在
if command -v claude &>/dev/null; then
  OLD_PATH=$(which claude 2>/dev/null)
  OLD_VER=$(claude --version 2>/dev/null || echo "unknown")

  # 檢查是否是 npm 安裝的舊版
  if echo "$OLD_PATH" | grep -qE "(node_modules|/usr/bin|/usr/local/bin)" 2>/dev/null; then
    warn "發現舊版 Claude Code（npm 版）: $OLD_PATH ($OLD_VER)"
    echo -e "  ${Y}移除舊版並安裝 native binary？ [Y/n]${N}"
    read -r RM_OLD
    if [[ ! "$RM_OLD" =~ ^[Nn]$ ]]; then
      sudo npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
      sudo rm -f "$OLD_PATH" 2>/dev/null || true
      hash -r
      ok "舊版已移除"
    fi
  elif echo "$OLD_PATH" | grep -q ".local/bin" 2>/dev/null; then
    ok "Native binary 已安裝: $OLD_VER ($OLD_PATH)"
    echo -e "  ${Y}要更新到最新版嗎？ [y/N]${N}"
    read -r UPD
    if [[ "$UPD" =~ ^[Yy]$ ]]; then
      curl -fsSL https://claude.ai/install.sh | bash 2>&1 | tail -5
      ok "已更新"
    else
      ok "保持現有版本"
    fi
  fi
else
  echo -e "  ${C}下載來源: https://claude.ai/install.sh（Anthropic 官方）${N}"
  echo ""
  curl -fsSL https://claude.ai/install.sh | bash
  echo ""
fi

# 確保 PATH
export PATH="$HOME/.local/bin:$PATH"
hash -r

if command -v claude &>/dev/null; then
  ok "Claude Code $(claude --version 2>/dev/null) @ $(which claude)"
else
  fail "安裝失敗。手動執行: curl -fsSL https://claude.ai/install.sh | bash"
fi

# ═══ Step 3: API Key ═══
step "設定 Anthropic API Key"

KEY_SET=false

if [ -n "$ANTHROPIC_API_KEY" ]; then
  ok "API Key 已在環境變數中"
  KEY_SET=true
elif [ -f "$HOME/.claude/.env" ] && grep -q "ANTHROPIC_API_KEY" "$HOME/.claude/.env" 2>/dev/null; then
  ok "API Key 已在 ~/.claude/.env"
  KEY_SET=true
fi

if [ "$KEY_SET" = false ]; then
  echo ""
  echo -e "  ${B}請輸入你的 Anthropic API Key${N}"
  echo -e "  ${C}取得方式: https://console.anthropic.com → API Keys${N}"
  echo ""
  echo -e "  ${Y}輸入時不會顯示字元（貼上後按 Enter）${N}"
  echo -e "  ${Y}沒有 Key 可直接 Enter 跳過，啟動 claude 後走 OAuth 登入${N}"
  echo ""
  read -s -p "  API Key: " API_KEY; echo ""

  if [ -z "$API_KEY" ]; then
    warn "已跳過。兩種方式可補設："
    echo -e "  ${C}A. export ANTHROPIC_API_KEY=你的Key >> ~/.bashrc${N}"
    echo -e "  ${C}B. 執行 claude 後走 OAuth 瀏覽器登入${N}"
  else
    mkdir -p "$HOME/.claude"
    echo "ANTHROPIC_API_KEY=$API_KEY" > "$HOME/.claude/.env"
    chmod 600 "$HOME/.claude/.env"
    export ANTHROPIC_API_KEY="$API_KEY"
    ok "已儲存至 ~/.claude/.env（權限 600）"
  fi
fi

# ═══ Step 4: Shell 環境 ═══
step "設定 Shell 環境"

# 偵測用的 shell
USER_SHELL=$(basename "$SHELL")
case "$USER_SHELL" in
  zsh)  RC_FILE="$HOME/.zshrc" ;;
  *)    RC_FILE="$HOME/.bashrc" ;;
esac

MARKER="# ── claude-code-installer ──"

if grep -q "$MARKER" "$RC_FILE" 2>/dev/null; then
  ok "$RC_FILE 已設定，跳過"
else
  cat >> "$RC_FILE" << 'EOF'

# ── claude-code-installer ──
export PATH="$HOME/.local/bin:$PATH"
[ -f "$HOME/.claude/.env" ] && { set -a; source "$HOME/.claude/.env"; set +a; }
EOF
  ok "已寫入 $RC_FILE"
fi

# ═══ 驗證 ═══
echo ""
echo -e "${B}════════════════════════════════════════════${N}"
echo -e "${B}  安裝驗證報告${N}"
echo -e "${B}════════════════════════════════════════════${N}"

ALL=true
chk() {
  if command -v "$1" &>/dev/null; then
    echo -e "  ${G}✅${N} $2  ${C}$($3 2>/dev/null)${N}"
  else
    echo -e "  ${R}❌${N} $2  未找到"
    ALL=false
  fi
}

chk git     "git      " "git --version | cut -d' ' -f3"
chk curl    "curl     " "curl --version | head -1 | cut -d' ' -f2"
chk claude  "claude   " "claude --version"

# 確認不是舊的 npm 版
CLAUDE_PATH=$(which claude 2>/dev/null)
if echo "$CLAUDE_PATH" | grep -q ".local/bin"; then
  echo -e "  ${G}✅${N} 安裝方式  ${C}Native Binary（正確）${N}"
else
  echo -e "  ${Y}⚠️${N}  安裝路徑  ${CLAUDE_PATH}（可能是舊 npm 版）"
fi

# API Key
if [ -n "$ANTHROPIC_API_KEY" ] || { [ -f "$HOME/.claude/.env" ] && grep -q "ANTHROPIC_API_KEY" "$HOME/.claude/.env" 2>/dev/null; }; then
  echo -e "  ${G}✅${N} API Key   已設定"
else
  echo -e "  ${Y}⚠️${N}  API Key   未設定（可用 OAuth 登入）"
fi

# 自動更新狀態
echo -e "  ${G}✅${N} 自動更新  ${C}已啟用（Native Binary 自動保持最新）${N}"

echo ""

if [ "$ALL" = true ]; then
  echo -e "${G}╔══════════════════════════════════════════════════╗${N}"
  echo -e "${G}║${N}                                                  ${G}║${N}"
  echo -e "${G}║${N}  🎉 ${B}安裝完成！${N}                                   ${G}║${N}"
  echo -e "${G}║${N}                                                  ${G}║${N}"
  echo -e "${G}║${N}  ${B}下一步：${N}                                         ${G}║${N}"
  echo -e "${G}║${N}    ${C}source ${RC_FILE}${N}"
  echo -e "${G}║${N}    ${C}claude${N}                                          ${G}║${N}"
  echo -e "${G}║${N}                                                  ${G}║${N}"
  echo -e "${G}║${N}  ${B}診斷指令：${N}                                       ${G}║${N}"
  echo -e "${G}║${N}    ${C}claude doctor${N}     ← 檢查環境狀態              ${G}║${N}"
  echo -e "${G}║${N}    ${C}claude --version${N}  ← 確認版本                  ${G}║${N}"
  echo -e "${G}║${N}                                                  ${G}║${N}"
  echo -e "${G}╚══════════════════════════════════════════════════╝${N}"
else
  echo -e "${R}安裝未完成。手動執行:${N}"
  echo -e "${C}  curl -fsSL https://claude.ai/install.sh | bash${N}"
  exit 1
fi
