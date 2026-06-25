/**
 * Unblind — 写入配置到 settings.json
 * 被 install.sh / install.ps1 调用
 * 用法: node install-write.js <settings.json 路径> <base_url> <model> <api_key> <provider_order>
 */
const fs = require('fs');
const [, , settingsPath, baseUrl, model, apiKey, providerOrder] = process.argv;

let s = {};
try { s = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch {}

// 合并 env
if (!s.env) s.env = {};
s.env.UNBLIND_OPENAI_BASE_URL = baseUrl;
s.env.UNBLIND_OPENAI_VISION_MODEL = model;
s.env.UNBLIND_OPENAI_API_KEY = apiKey;
s.env.UNBLIND_PROVIDER_ORDER = providerOrder;

// 添加 Bash 权限
const perm = 'Bash(*~/.claude/skills/unblind/scripts/unblind.mjs*)';
if (!s.permissions) s.permissions = { allow: [] };
if (!Array.isArray(s.permissions.allow)) s.permissions.allow = [];
if (!s.permissions.allow.some(r => r.includes('unblind'))) {
  s.permissions.allow.push(perm);
}

fs.writeFileSync(settingsPath, JSON.stringify(s, null, 2) + '\n');
console.log('[OK] 配置已写入');
