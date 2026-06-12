#!/bin/bash
# Unblind — 卸载脚本
set -euo pipefail

SKILL_NAME="unblind"
SKILL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
AGENTS_DIR="${HOME}/.agents/skills/${SKILL_NAME}"
SETTINGS_FILE="${HOME}/.claude/settings.json"
CACHE_DIR="${HOME}/.claude/unblind/cache"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}🧹 Unblind — 卸载脚本${NC}"
echo "==================================\n"

# 1. 删除部署文件
echo -e "${YELLOW}→ 删除已部署文件...${NC}"
if [ -d "$SKILL_DIR" ]; then
  rm -rf "$SKILL_DIR"
  echo -e "  ${GREEN}✓${NC} 已删除 ${SKILL_DIR}"
else
  echo -e "  ${YELLOW}⚠ 目录不存在，跳过: ${SKILL_DIR}${NC}"
fi

if [ -d "$AGENTS_DIR" ]; then
  rm -rf "$AGENTS_DIR"
  echo -e "  ${GREEN}✓${NC} 已删除 ${AGENTS_DIR}"
else
  echo -e "  ${YELLOW}⚠ 目录不存在，跳过: ${AGENTS_DIR}${NC}"
fi

# 2. 清理缓存
if [ -d "$CACHE_DIR" ]; then
  rm -rf "$CACHE_DIR"
  echo -e "  ${GREEN}✓${NC} 已删除缓存 ${CACHE_DIR}"
fi

# 3. 清理 settings.json 中的配置
if [ -f "$SETTINGS_FILE" ]; then
  echo -e "${YELLOW}→ 清理 settings.json 中的 UNBLIND 配置...${NC}"
  node -e "
    const fs = require('fs');
    const p = '$SETTINGS_FILE';
    let s = {};
    try { s = JSON.parse(fs.readFileSync(p, 'utf8')); } catch { process.exit(0); }

    const keys = ['UNBLIND_OPENAI_BASE_URL', 'UNBLIND_OPENAI_VISION_MODEL', 'UNBLIND_OPENAI_API_KEY', 'UNBLIND_PROVIDER_ORDER', 'UNBLIND_MAX_IMAGE_SIZE', 'UNBLIND_JPEG_QUALITY', 'UNBLIND_REQUEST_TIMEOUT', 'UNBLIND_CACHE_TTL', 'UNBLIND_DEFAULT_MODE'];
    let changed = false;
    if (s.env) {
      for (const k of keys) {
        if (k in s.env) { delete s.env[k]; changed = true; }
      }
      // 如果 env 变空了也清理掉
      if (Object.keys(s.env).length === 0) { delete s.env; changed = true; }
    }

    // 清理权限规则
    if (s.permissions?.allow) {
      const before = s.permissions.allow.length;
      s.permissions.allow = s.permissions.allow.filter(r => !r.includes('unblind'));
      if (s.permissions.allow.length !== before) changed = true;
      if (s.permissions.allow.length === 0) delete s.permissions.allow;
      if (Object.keys(s.permissions).length === 0) delete s.permissions;
    }

    if (changed) {
      fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
      console.log('  ${GREEN}✓${NC} 配置已清理');
    } else {
      console.log('  ${YELLOW}⚠ 未发现 UNBLIND 相关配置${NC}');
    }
  "
else
  echo -e "  ${YELLOW}⚠ settings.json 不存在，跳过配置清理${NC}"
fi

echo ""
echo -e "${GREEN}✅ Unblind 已卸载${NC}"
echo -e "  如需要重新安装，运行 install.sh 即可。"
