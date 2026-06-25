# Unblind — Windows 卸载脚本（PowerShell）
# 使用 UTF-8 BOM 编码以兼容 Windows PowerShell 5.1
param()

# 兼容 PS5.1 / PS7 的 JSON 转 Hashtable 函数
function ConvertFrom-JsonToHashtable {
    param([string]$Json)
    $obj = $Json | ConvertFrom-Json
    return ConvertPSObjectToHashtable($obj)
}
function ConvertPSObjectToHashtable($obj) {
    if ($null -eq $obj) { return $null }
    if ($obj -is [array]) { return @($obj | ForEach-Object { ConvertPSObjectToHashtable $_ }) }
    if ($obj -is [System.Management.Automation.PSCustomObject]) {
        $ht = @{}
        $obj.PSObject.Properties | ForEach-Object { $ht[$_.Name] = ConvertPSObjectToHashtable $_.Value }
        return $ht
    }
    return $obj
}

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

# 3. 清理 settings.json 中的配置
if (Test-Path $SettingsFile) {
    Write-Host "-> 清理 settings.json 中的 UNBLIND 配置..." -ForegroundColor Yellow

    try {
        $settings = ConvertFrom-JsonToHashtable (Get-Content $SettingsFile -Raw -Encoding UTF8)
    } catch {
        Write-Host "  [WARN] settings.json 解析失败, 跳过" -ForegroundColor Yellow
        exit 0
    }

    $changed = $false
    $keys = @("UNBLIND_OPENAI_BASE_URL", "UNBLIND_OPENAI_VISION_MODEL", "UNBLIND_OPENAI_API_KEY", `
              "UNBLIND_PROVIDER_ORDER", "UNBLIND_MAX_IMAGE_SIZE", "UNBLIND_JPEG_QUALITY", `
              "UNBLIND_REQUEST_TIMEOUT", "UNBLIND_CACHE_TTL", "UNBLIND_DEFAULT_MODE")

    if ($settings.ContainsKey("env")) {
        foreach ($k in $keys) {
            if ($settings["env"].ContainsKey($k)) {
                $settings["env"].Remove($k)
                $changed = $true
            }
        }
        # 如果 env 变空了也清理掉
        if ($settings["env"].Count -eq 0) {
            $settings.Remove("env")
            $changed = $true
        }
    }

    # 清理权限规则
    if ($settings.ContainsKey("permissions") -and $settings["permissions"].ContainsKey("allow")) {
        $before = $settings["permissions"]["allow"].Count
        $settings["permissions"]["allow"] = @($settings["permissions"]["allow"] | Where-Object { $_ -notmatch "unblind" })
        if ($settings["permissions"]["allow"].Count -ne $before) { $changed = $true }
        if ($settings["permissions"]["allow"].Count -eq 0) { $settings["permissions"].Remove("allow") }
        if ($settings["permissions"].Count -eq 0) { $settings.Remove("permissions") }
    }

    if ($changed) {
        $settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8
        Write-Host "  [OK] 配置已清理" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] 未发现 UNBLIND 相关配置" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] settings.json 不存在, 跳过配置清理" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[OK] Unblind 已卸载" -ForegroundColor Green
Write-Host "  如需要重新安装, 运行 install.ps1 即可。"
