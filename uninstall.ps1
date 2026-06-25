# Unblind — Windows 卸载脚本（PowerShell）
# 使用 UTF-8 BOM 编码以兼容 Windows PowerShell 5.1
#
# JSON 清理使用 Node.js 处理（绕开 PS5.1 JSON 兼容性问题）
param()

$SkillName = "unblind"
$SkillDir = Join-Path $env:USERPROFILE ".claude\skills\$SkillName"
$AgentsDir = Join-Path $env:USERPROFILE ".agents\skills\$SkillName"
$SettingsFile = Join-Path $env:USERPROFILE ".claude\settings.json"
$CacheDir = Join-Path $env:USERPROFILE ".claude\unblind\cache"

Write-Host "Unblind - 卸载脚本" -ForegroundColor Cyan
Write-Host "================================"
Write-Host ""

# 1. 删除部署文件
Write-Host "-> 删除已部署文件..." -ForegroundColor Yellow
if (Test-Path $SkillDir) {
    Remove-Item $SkillDir -Recurse -Force
    Write-Host "  [OK] 已删除 $SkillDir" -ForegroundColor Green
} else {
    Write-Host "  [WARN] 目录不存在, 跳过: $SkillDir" -ForegroundColor Yellow
}

if (Test-Path $AgentsDir) {
    Remove-Item $AgentsDir -Recurse -Force
    Write-Host "  [OK] 已删除 $AgentsDir" -ForegroundColor Green
} else {
    Write-Host "  [WARN] 目录不存在, 跳过: $AgentsDir" -ForegroundColor Yellow
}

# 2. 清理缓存
if (Test-Path $CacheDir) {
    Remove-Item $CacheDir -Recurse -Force
    Write-Host "  [OK] 已删除缓存 $CacheDir" -ForegroundColor Green
}

# 3. 清理 settings.json 中的配置 — 使用 Node.js 处理 JSON
if (Test-Path $SettingsFile) {
    Write-Host "-> 清理 settings.json 中的 UNBLIND 配置..." -ForegroundColor Yellow

    $settingsFwd = $SettingsFile -replace '\\', '/'
    $nodeScript = @"
const fs = require('fs');
const p = '$settingsFwd';
let s = {};
try { s = JSON.parse(fs.readFileSync(p, 'utf8')); } catch { process.exit(0); }

const keys = ['UNBLIND_OPENAI_BASE_URL', 'UNBLIND_OPENAI_VISION_MODEL', 'UNBLIND_OPENAI_API_KEY',
  'UNBLIND_PROVIDER_ORDER', 'UNBLIND_MAX_IMAGE_SIZE', 'UNBLIND_JPEG_QUALITY',
  'UNBLIND_REQUEST_TIMEOUT', 'UNBLIND_CACHE_TTL', 'UNBLIND_DEFAULT_MODE'];

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
  fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
  console.log('cleaned');
} else {
  console.log('unchanged');
}
"@

    $result = node -e $nodeScript 2>&1
    if ($LASTEXITCODE -eq 0) {
        if ($result -match "cleaned") {
            Write-Host "  [OK] 配置已清理" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] 未发现 UNBLIND 相关配置" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [WARN] settings.json 处理失败, 跳过" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] settings.json 不存在, 跳过配置清理" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[OK] Unblind 已卸载" -ForegroundColor Green
Write-Host "  如需要重新安装, 运行 install.ps1 即可。"
