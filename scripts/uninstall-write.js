/**
 * Unblind — 从 settings.json 清理 UNBLIND 配置
 * 被 uninstall.sh / uninstall.ps1 调用
 * 用法: node uninstall-write.js <settings.json 路径>
 */
const fs = require('fs');
const [, , settingsPath] = process.argv;

let s = {};
try { s = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch { process.exit(0); }

const keys = [
  'UNBLIND_OPENAI_BASE_URL', 'UNBLIND_OPENAI_VISION_MODEL', 'UNBLIND_OPENAI_API_KEY',
  'UNBLIND_PROVIDER_ORDER', 'UNBLIND_MAX_IMAGE_SIZE', 'UNBLIND_JPEG_QUALITY',
  'UNBLIND_REQUEST_TIMEOUT', 'UNBLIND_CACHE_TTL', 'UNBLIND_DEFAULT_MODE',
];

let changed = false;
if (s.env) {
  for (const k of keys) {
    if (k in s.env) { delete s.env[k]; changed = true; }
  }
  if (Object.keys(s.env).length === 0) { delete s.env; changed = true; }
}

// 清理权限规则
if (s.permissions && Array.isArray(s.permissions.allow)) {
  const before = s.permissions.allow.length;
  s.permissions.allow = s.permissions.allow.filter(r => !r.includes('unblind'));
  if (s.permissions.allow.length !== before) changed = true;
  if (s.permissions.allow.length === 0) delete s.permissions.allow;
  if (Object.keys(s.permissions).length === 0) delete s.permissions;
}

if (changed) {
  fs.writeFileSync(settingsPath, JSON.stringify(s, null, 2) + '\n');
  console.log('cleaned');
} else {
  console.log('unchanged');
}
