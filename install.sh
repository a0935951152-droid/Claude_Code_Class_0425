#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  Claude Code 一鍵安裝腳本（Native Binary 版）
#  適用：Ubuntu 22.04 / 24.04 / WSL2
#
#  用法：
#    git clone https://github.com/你的帳號/claude-code-installer.git
#    cd claude-code-installer
#    ./install.sh
#
#  安裝內容：
#    1. 系統基礎套件（git / curl）
#    2. Claude Code native binary（不需要 Node.js）
#    3. API Key 設定
#    4. Shell 環境寫入
#
#  完成後直接輸入 claude 即可使用
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
echo -e "${C}╔════════════════════════════════════════════╗${N}"
echo -e "${C}║${N}  ${B}Claude Code Installer${N}                     ${C}║${N}"
echo -e "${C}║${N}  Native Binary · 不需要 Node.js            ${C}║${N}"
echo -e "${C}╚════════════════════════════════════════════╝${N}"
echo ""
echo -e "${B}系統檢查...${N}"

[ -f /etc/os-release ] && { . /etc/os-release; echo -e "  OS:  ${C}${PRETTY_NAME}${N}"; }
grep -qi microsoft /proc/version 2>/dev/null && echo -e "  環境: ${C}WSL2${N}" || echo -e "  環境: ${C}原生 Linux${N}"
echo "$HOME" | grep -qP '[[:space:]]' 2>/dev/null && fail "HOME 路徑含空格: $HOME"
ok "路徑安全"

# ═══ Step 1: 系統套件 ═══
step "安裝系統基礎套件（git / curl）"
sudo apt-get update -qq 2>/dev/null
sudo apt-get install -y -qq curl git 2>/dev/null
ok "git $(git --version 2>/dev/null | cut -d' ' -f3)"
ok "curl ready"

# ═══ Step 2: Claude Code Native Binary ═══
step "安裝 Claude Code（Native Binary — 不需要 Node.js）"

if command -v claude &>/dev/null; then
  ok "Claude Code 已安裝: $(claude --version 2>/dev/null || echo 'installed')"
  echo -e "  ${Y}要更新到最新版嗎？ [y/N]${N}"
  read -r UPD
  if [[ "$UPD" =~ ^[Yy]$ ]]; then
    curl -fsSL https://claude.ai/install.sh | bash 2>&1 | tail -3
    ok "已更新"
  fi
else
  echo -e "  ${C}來源: https://claude.ai/install.sh（Anthropic 官方）${N}"
  echo ""
  curl -fsSL https://claude.ai/install.sh | bash
  echo ""
  export PATH="$HOME/.local/bin:$PATH"
  command -v claude &>/dev/null && ok "安裝完成: $(which claude)" || fail "安裝失敗，請手動: curl -fsSL https://claude.ai/install.sh | bash"
fi

export PATH="$HOME/.local/bin:$PATH"

# ═══ Step 3: API Key ═══
step "設定 Anthropic API Key"

if [ -n "$ANTHROPIC_API_KEY" ]; then
  ok "API Key 已在環境變數中"
elif [ -f "$HOME/.claude/.env" ] && grep -q "ANTHROPIC_API_KEY" "$HOME/.claude/.env" 2>/dev/null; then
  ok "API Key 已在 ~/.claude/.env"
else
  echo ""
  echo -e "  ${B}請輸入你的 Anthropic API Key${N}"
  echo -e "  ${C}取得: https://console.anthropic.com → API Keys${N}"
  echo -e "  ${Y}輸入不顯示字元。沒有 Key 可直接 Enter 跳過${N}"
  echo ""
  read -s -p "  API Key: " API_KEY; echo ""
  if [ -z "$API_KEY" ]; then
    warn "已跳過。可用以下方式補設："
    echo -e "  ${C}export ANTHROPIC_API_KEY=你的Key${N}"
    echo -e "  ${C}或啟動 claude 後走 OAuth 瀏覽器登入${N}"
  else
    mkdir -p "$HOME/.claude"
    echo "ANTHROPIC_API_KEY=$API_KEY" > "$HOME/.claude/.env"
    chmod 600 "$HOME/.claude/.env"
    export ANTHROPIC_API_KEY="$API_KEY"
    ok "已儲存至 ~/.claude/.env（權限 600）"
  fi
fi

# ═══ Step 4: Shell 環境 ═══
step "設定 Shell 環境（~/.bashrc）"

MARKER="# ── claude-code-installer ──"
if grep -q "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
  ok "已設定，跳過"
else
  cat >> "$HOME/.bashrc" << 'EOF'

# ── claude-code-installer ──
export PATH="$HOME/.local/bin:$PATH"
[ -f "$HOME/.claude/.env" ] && { set -a; source "$HOME/.claude/.env"; set +a; }
EOF
  ok "已寫入 ~/.bashrc"
fi

# ═══ 驗證 ═══
echo ""
echo -e "${B}════════════════════════════════════════════${N}"
echo -e "${B}  安裝驗證${N}"
echo -e "${B}════════════════════════════════════════════${N}"

OK=true
chk() { command -v "$1" &>/dev/null && echo -e "  ${G}✅${N} $2  ${C}$($3 2>/dev/null)${N}" || { echo -e "  ${R}❌${N} $2"; OK=false; }; }
chk git     "git    " "git --version"
chk curl    "curl   " "curl --version | head -1 | cut -d' ' -f2"
chk claude  "claude " "claude --version"

if [ -n "$ANTHROPIC_API_KEY" ] || { [ -f "$HOME/.claude/.env" ] && grep -q "ANTHROPIC_API_KEY" "$HOME/.claude/.env" 2>/dev/null; }; then
  echo -e "  ${G}✅${N} API Key"
else
  echo -e "  ${Y}⚠️${N}  API Key  未設定（可用 OAuth 登入）"
fi

command -v node &>/dev/null && echo -e "  ${C}ℹ️${N}  node     $(node -v)（非必要，Claude Code 已不需要 Node.js）"

echo ""
if [ "$OK" = true ]; then
  echo -e "${G}╔══════════════════════════════════════════════╗${N}"
  echo -e "${G}║${N}                                              ${G}║${N}"
  echo -e "${G}║${N}  🎉 ${B}安裝完成！${N}                               ${G}║${N}"
  echo -e "${G}║${N}                                              ${G}║${N}"
  echo -e "${G}║${N}  ${B}下一步：${N}                                     ${G}║${N}"
  echo -e "${G}║${N}    ${C}source ~/.bashrc${N}                          ${G}║${N}"
  echo -e "${G}║${N}    ${C}claude${N}                                    ${G}║${N}"
  echo -e "${G}║${N}                                              ${G}║${N}"
  echo -e "${G}║${N}  ${Y}自動更新已啟用，會自動保持最新版${N}           ${G}║${N}"
  echo -e "${G}║${N}                                              ${G}║${N}"
  echo -e "${G}╚══════════════════════════════════════════════╝${N}"
else
  echo -e "${R}安裝未完成，請手動: curl -fsSL https://claude.ai/install.sh | bash${N}"
  exit 1
fi
