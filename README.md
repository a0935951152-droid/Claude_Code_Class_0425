# Claude Code 一鍵安裝

Ubuntu / WSL2 上安裝 Claude Code 的最簡方式。  
使用 **Anthropic 官方 native binary**，不需要 Node.js。

## 安裝

```bash
git clone https://github.com/a0935951152-droid/Claude_Code_Class_0425
cd Claude_Code_Class_0425
./install.sh
```

安裝完成後：

```bash
source ~/.bashrc
claude
```

## 安裝了什麼

| 步驟 | 內容 | 說明 |
|------|------|------|
| 1 | `sudo apt install git curl` | 唯二需要的系統套件 |
| 2 | `curl -fsSL https://claude.ai/install.sh \| bash` | 官方 native binary，裝到 `~/.local/bin/claude` |
| 3 | API Key → `~/.claude/.env` | 權限 600，不進版控 |
| 4 | `~/.bashrc` 加兩行 | 自動載入 PATH + API Key |

**不需要 Node.js / npm / nvm。**  
Claude Code 自 2026 年起改為獨立 binary 發行，不再依賴 Node.js。

## 系統需求

- Ubuntu 22.04+ 或 WSL2（Windows 11）
- 可連外網路
- sudo 權限（裝 git/curl 用）

## API Key 取得

1. https://console.anthropic.com
2. 登入 → 左側 API Keys → Create Key
3. 複製（只顯示一次）

或者不用 API Key，啟動 `claude` 後走 OAuth 瀏覽器登入（需要 Pro / Max 訂閱）。

## 問題排除

```bash
# claude 找不到
source ~/.bashrc
# 或
export PATH="$HOME/.local/bin:$PATH"

# 重新安裝 / 更新
curl -fsSL https://claude.ai/install.sh | bash

# 環境診斷
claude doctor

# 手動設定 API Key
export ANTHROPIC_API_KEY=你的Key
```
