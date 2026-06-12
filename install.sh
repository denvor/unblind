#!/bin/bash
# Unblind — 一键安装脚本（部署运行时文件 + 交互式配置）
set -euo pipefail

SKILL_NAME="unblind"
SKILL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
AGENTS_DIR="${HOME}/.agents/skills/${SKILL_NAME}"
SETTINGS_FILE="${HOME}/.claude/settings.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

if [ -f "./SKILL.md" ]; then SOURCE_DIR="$(pwd)"; else
  echo -e "${RED}❌ 错误：未找到 SKILL.md。请在 unblind 仓库根目录运行此脚本。${NC}"
  exit 1; fi

deploy() {
  local dir="$1"
  mkdir -p "$dir"

  # 核心文件
  cp "$SOURCE_DIR/SKILL.md" "$dir/"
  cp "$SOURCE_DIR/README.md" "$dir/"

  # 脚本（仅 lib 模块 + CLI 入口，不含 install.js、占位文件）
  mkdir -p "$dir/scripts/lib/providers"
  cp "$SOURCE_DIR/scripts/unblind.mjs" "$dir/scripts/"
  cp "$SOURCE_DIR/scripts/lib/"*.js "$dir/scripts/lib/"
  cp "$SOURCE_DIR/scripts/lib/providers/"*.js "$dir/scripts/lib/providers/"

  # 按需资源
  cp -r "$SOURCE_DIR/templates" "$dir/" 2>/dev/null || true
  cp -r "$SOURCE_DIR/resources" "$dir/" 2>/dev/null || true

  # 清理旧版本残留（Phase 1 前根目录的旧 unblind.mjs）
  rm -f "$dir/unblind.mjs" 2>/dev/null
}

echo -e "${CYAN}📸 Unblind — 部署中...${NC}"
deploy "$SKILL_DIR"
deploy "$AGENTS_DIR"

# Node.js 版本检查
if command -v node &> /dev/null; then
  NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
  [ "$NODE_VERSION" -ge 18 ] && echo -e "${GREEN}✅ Node.js $(node --version)${NC}" || echo -e "${YELLOW}⚠️ Node.js $(node --version) < 18${NC}"
else
  echo -e "${RED}❌ 未检测到 Node.js >= 18${NC}"
fi

echo ""
echo -e "${CYAN}⚙️  配置 OpenAI 兼容 API${NC}"
echo -e "${YELLOW}按回车接受默认值，或输入自定义值。${NC}"
echo ""

# 交互式输入 4 个环境变量
read -r -p "API Base URL [http://127.0.0.1:8080/v1]: " input_url
UNBLIND_OPENAI_BASE_URL="${input_url:-http://127.0.0.1:8080/v1}"

read -r -p "视觉模型名 [gpt-4o]: " input_model
UNBLIND_OPENAI_VISION_MODEL="${input_model:-gpt-4o}"

while true; do
  read -r -p "API Key (必填): " input_key
  if [ -n "$input_key" ]; then
    UNBLIND_OPENAI_API_KEY="$input_key"
    break
  fi
  echo -e "${RED}API Key 不能为空，请重新输入${NC}"
done

read -r -p "Provider 顺序 [openai]: " input_order
UNBLIND_PROVIDER_ORDER="${input_order:-openai}"

# 写入 settings.json
echo ""
echo -e "${CYAN}💾 写入配置到 ${SETTINGS_FILE}...${NC}"

# 读取现有 settings.json，合并 env 字段，添加权限
if [ -f "$SETTINGS_FILE" ]; then
  # 使用 Node.js 合并 JSON（bash 处理 JSON 容易出错）
  node -e "
    const fs = require('fs');
    const p = '$SETTINGS_FILE';
    let s = {};
    try { s = JSON.parse(fs.readFileSync(p, 'utf8')); } catch {}
    if (!s.env) s.env = {};
    s.env.UNBLIND_OPENAI_BASE_URL = '$UNBLIND_OPENAI_BASE_URL';
    s.env.UNBLIND_OPENAI_VISION_MODEL = '$UNBLIND_OPENAI_VISION_MODEL';
    s.env.UNBLIND_OPENAI_API_KEY = '$UNBLIND_OPENAI_API_KEY';
    s.env.UNBLIND_PROVIDER_ORDER = '$UNBLIND_PROVIDER_ORDER';

    // 添加 Bash 权限（如果不存在）
    const perm = 'Bash(*~/.claude/skills/unblind/scripts/unblind.mjs*)';
    if (!s.permissions) s.permissions = { allow: [] };
    if (!s.permissions.allow) s.permissions.allow = [];
    if (!s.permissions.allow.some(r => r.includes('unblind'))) {
      s.permissions.allow.push(perm);
    }

    fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
    console.log('✅ 配置已写入');
  "
else
  # settings.json 不存在，新建
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  node -e "
    const fs = require('fs');
    const s = {
      env: {
        UNBLIND_OPENAI_BASE_URL: '$UNBLIND_OPENAI_BASE_URL',
        UNBLIND_OPENAI_VISION_MODEL: '$UNBLIND_OPENAI_VISION_MODEL',
        UNBLIND_OPENAI_API_KEY: '$UNBLIND_OPENAI_API_KEY',
        UNBLIND_PROVIDER_ORDER: '$UNBLIND_PROVIDER_ORDER',
      },
      permissions: {
        allow: ['Bash(*~/.claude/skills/unblind/scripts/unblind.mjs*)'],
      },
    };
    fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(s, null, 2) + '\n');
    console.log('✅ 新配置文件已创建');
  "
fi

echo ""
echo -e "${GREEN}✅ Unblind 已部署并配置完成${NC}"
echo "  Skill:  ${SKILL_DIR}"
echo "  Agents: ${AGENTS_DIR}"
echo "  Config: ${SETTINGS_FILE}"
echo ""
echo -e "发送任意图片给 Claude Code 即可开始使用。"
