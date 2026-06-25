# Unblind — Windows 卸载脚本（PowerShell）
# 使用 UTF-8 BOM 编码以兼容 Windows PowerShell 5.1
param()

$SkillName = "unblind"
$SkillDir = Join-Path $env:USERPROFILE ".claude\skills\$SkillName"
$AgentsDir = Join-Path $env:USERPROFILE ".agents\skills\$SkillName"
$SettingsFile = Join-Path $env:USERPROFILE ".claude\settings.json"
$CacheDir = Join-Path $env:USERPROFILE ".claude\unblind\cache"

Write-Host "Unblind - 卸载脚本" -ForegroundColor Cyan
Write-Host "================================"
Write-Host ""

# 0. 找 uninstall-write.js（先清理配置，再删文件）
$writeScript = $null
$possiblePaths = @(
    "$SkillDir\scripts\uninstall-write.js"
    ".\scripts\uninstall-write.js"
)
foreach ($p in $possiblePaths) {
    if (Test-Path $p) { $writeScript = $p; break }
}

# 1. 清理 settings.json 中的配置
if ($writeScript -and (Test-Path $SettingsFile)) {
    Write-Host "-> 清理 settings.json 中的 UNBLIND 配置..." -ForegroundColor Yellow
    $result = node "$writeScript" "$SettingsFile" 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        if ($result -match "cleaned") {
            Write-Host "  [OK] 配置已清理" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] 未发现 UNBLIND 相关配置" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [WARN] settings.json 处理失败: $result" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] 未找到 uninstall-write.js 或 settings.json 不存在, 跳过配置清理" -ForegroundColor Yellow
}

# 2. 删除部署文件
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

# 3. 清理缓存
if (Test-Path $CacheDir) {
    Remove-Item $CacheDir -Recurse -Force
    Write-Host "  [OK] 已删除缓存 $CacheDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "[OK] Unblind 已卸载" -ForegroundColor Green
Write-Host "  如需要重新安装, 运行 install.ps1 即可。"
