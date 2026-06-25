# Unblind — Windows 一键安装脚本（PowerShell）
# 使用 UTF-8 BOM 编码以兼容 Windows PowerShell 5.1
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

# 写入 settings.json
Write-Host ""
Write-Host "写入配置到 $SettingsFile ..." -ForegroundColor Cyan

# 读取现有 settings.json 并合并
$settings = @{}
if (Test-Path $SettingsFile) {
    try {
        $settings = Get-Content $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    } catch {
        $settings = @{}
    }
}

if (-not $settings.ContainsKey("env")) { $settings["env"] = @{} }
$settings["env"]["UNBLIND_OPENAI_BASE_URL"] = $inputUrl
$settings["env"]["UNBLIND_OPENAI_VISION_MODEL"] = $inputModel
$settings["env"]["UNBLIND_OPENAI_API_KEY"] = $inputKey
$settings["env"]["UNBLIND_PROVIDER_ORDER"] = $inputOrder

# 添加 Bash 权限（如果不存在）
$perm = 'Bash(*~/.claude/skills/unblind/scripts/unblind.mjs*)'
if (-not $settings.ContainsKey("permissions")) { $settings["permissions"] = @{} }
if (-not $settings["permissions"].ContainsKey("allow")) { $settings["permissions"]["allow"] = @() }
$hasPerm = $false
foreach ($r in $settings["permissions"]["allow"]) {
    if ($r -match "unblind") { $hasPerm = $true; break }
}
if (-not $hasPerm) {
    $settings["permissions"]["allow"] += $perm
}

# 确保目录存在
New-Item -ItemType Directory -Path (Split-Path $SettingsFile -Parent) -Force | Out-Null
$settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8
Write-Host "[OK] 配置已写入" -ForegroundColor Green

Write-Host ""
Write-Host "[OK] Unblind 已部署并配置完成" -ForegroundColor Green
Write-Host "  Skill:  $SkillDir"
Write-Host "  Agents: $AgentsDir"
Write-Host "  Config: $SettingsFile"
Write-Host ""
Write-Host "发送任意图片给 Claude Code 即可开始使用。"
