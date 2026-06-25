# Unblind — Windows 一键安装脚本（PowerShell）
# 使用 UTF-8 BOM 编码以兼容 Windows PowerShell 5.1
#
# JSON 写入使用 Node.js 处理（绕开 PS5.1 JSON 兼容性问题）
param()

$ErrorActionPreference = "Stop"

$SkillName = "unblind"
$SkillDir = Join-Path $env:USERPROFILE ".claude\skills\$SkillName"
$AgentsDir = Join-Path $env:USERPROFILE ".agents\skills\$SkillName"
$SettingsFile = Join-Path $env:USERPROFILE ".claude\settings.json"

# 检测是否在仓库根目录
if (-not (Test-Path ".\SKILL.md")) {
    Write-Host "[ERROR] 错误: 未找到 SKILL.md。请在 unblind 仓库根目录运行此脚本。" -ForegroundColor Red
    exit 1
}
$SourceDir = (Get-Location).Path

# 部署函数
function Deploy($dir) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    Copy-Item "$SourceDir\SKILL.md" "$dir\"
    Copy-Item "$SourceDir\README.md" "$dir\"

    New-Item -ItemType Directory -Path "$dir\scripts\lib\providers" -Force | Out-Null
    Copy-Item "$SourceDir\scripts\unblind.mjs" "$dir\scripts\"
    Copy-Item "$SourceDir\scripts\lib\*.js" "$dir\scripts\lib\"
    Copy-Item "$SourceDir\scripts\lib\providers\*.js" "$dir\scripts\lib\providers\"

    # 按需资源（忽略不存在的情况）
    if (Test-Path "$SourceDir\templates") {
        Copy-Item "$SourceDir\templates" "$dir\" -Recurse -Force
    }
    if (Test-Path "$SourceDir\resources") {
        Copy-Item "$SourceDir\resources" "$dir\" -Recurse -Force
    }

    # 清理旧版残留
    Remove-Item "$dir\unblind.mjs" -ErrorAction SilentlyContinue
}

Write-Host "Unblind - 部署中..." -ForegroundColor Cyan
Deploy $SkillDir
Deploy $AgentsDir

# Node.js 版本检查
$nodeOk = $false
try {
    $nodeVer = node --version
    # node --version 输出: v18.15.0
    $majorStr = ($nodeVer -replace '^v', '' -replace '\..*$', '')
    $major = [int]$majorStr
    if ($major -ge 18) {
        Write-Host "[OK] Node.js $nodeVer" -ForegroundColor Green
        $nodeOk = $true
    } else {
        Write-Host "[WARN] Node.js $nodeVer (需要 >= 18)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] 未检测到 Node.js, 请安装 Node.js >= 18" -ForegroundColor Red
}

Write-Host ""
Write-Host "配置 OpenAI 兼容 API" -ForegroundColor Cyan
Write-Host "按回车接受默认值, 或输入自定义值。" -ForegroundColor Yellow
Write-Host ""

# 交互式输入 4 个环境变量
$inputUrl = Read-Host "API Base URL [http://127.0.0.1:8080/v1]"
if ([string]::IsNullOrEmpty($inputUrl)) { $inputUrl = "http://127.0.0.1:8080/v1" }

$inputModel = Read-Host "视觉模型名 [gpt-4o]"
if ([string]::IsNullOrEmpty($inputModel)) { $inputModel = "gpt-4o" }

$inputKey = ""
while ($true) {
    $inputKey = Read-Host "API Key (必填)"
    if (-not [string]::IsNullOrEmpty($inputKey)) { break }
    Write-Host "API Key 不能为空, 请重新输入" -ForegroundColor Red
}

$inputOrder = Read-Host "Provider 顺序 [openai]"
if ([string]::IsNullOrEmpty($inputOrder)) { $inputOrder = "openai" }

# 写入 settings.json — 使用 Node.js 处理 JSON（绕开 PS5.1 JSON 兼容性问题）
Write-Host ""
Write-Host "写入配置到 $SettingsFile ..." -ForegroundColor Cyan

# 把用户输入写入临时文件，Node.js 读取它来合并
$envFile = Join-Path $env:TEMP "unblind_env.json"
@"
{
  "UNBLIND_OPENAI_BASE_URL": "$inputUrl",
  "UNBLIND_OPENAI_VISION_MODEL": "$inputModel",
  "UNBLIND_OPENAI_API_KEY": "$inputKey",
  "UNBLIND_PROVIDER_ORDER": "$inputOrder"
}
"@ | Set-Content $envFile -Encoding UTF8

# 确保 settings.json 所在目录存在
New-Item -ItemType Directory -Path (Split-Path $SettingsFile -Parent) -Force | Out-Null

# 把路径里的 \ 转成 /，Node.js 在 Windows 上也识别
$settingsFwd = $SettingsFile -replace '\\', '/'
$envFwd = $envFile -replace '\\', '/'

# 写 Node.js 脚本到临时文件（避免 -e 内联的转义问题）
$jsFile = Join-Path $env:TEMP "unblind_merge.js"
@"
const fs = require('fs');

// 读取用户输入
const newEnv = JSON.parse(fs.readFileSync('$envFwd', 'utf8'));

// 读取已有配置
let s = {};
try { s = JSON.parse(fs.readFileSync('$settingsFwd', 'utf8')); } catch {}

// 合并 env
if (!s.env) s.env = {};
Object.assign(s.env, newEnv);

// 添加 Bash 权限（如果不存在）
const perm = 'Bash(*~/.claude/skills/unblind/scripts/unblind.mjs*)';
if (!s.permissions) s.permissions = { allow: [] };
if (!Array.isArray(s.permissions.allow)) s.permissions.allow = [];
if (!s.permissions.allow.some(r => r.includes('unblind'))) {
  s.permissions.allow.push(perm);
}

fs.writeFileSync('$settingsFwd', JSON.stringify(s, null, 2) + '\n');
console.log('[OK] 配置已写入');
"@ | Set-Content $jsFile -Encoding UTF8

# 执行 Node.js 脚本
$result = node $jsFile 2>&1
$exitCode = $LASTEXITCODE

# 清理临时文件
Remove-Item $jsFile -ErrorAction SilentlyContinue
Remove-Item $envFile -ErrorAction SilentlyContinue

if ($exitCode -eq 0) {
    Write-Host $result -ForegroundColor Green
} else {
    Write-Host "[ERROR] 写入配置失败: $result" -ForegroundColor Red
}

Write-Host ""
Write-Host "[OK] Unblind 已部署并配置完成" -ForegroundColor Green
Write-Host "  Skill:  $SkillDir"
Write-Host "  Agents: $AgentsDir"
Write-Host "  Config: $SettingsFile"
Write-Host ""
Write-Host "发送任意图片给 Claude Code 即可开始使用。"
