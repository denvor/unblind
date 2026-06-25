# Unblind 故障排查与修复指南

> Level 3 资源 — 仅在 Phase 0 检测到异常时加载

## API Key 设置 (Phase 0.2)

用户需在终端运行（替换 YOUR_KEY）：

```bash
node -e "const fs=require('fs');const os=require('os');const p=require('path').join(os.homedir(),'.claude','settings.json');const s=JSON.parse(fs.readFileSync(p,'utf8').replace(/^﻿/,''));s.env.UNBLIND_OPENAI_API_KEY='YOUR_KEY';fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n')"
```

Key 类型：OpenAI 兼容 API 的 Bearer Token / API Key。

## Base URL 修复 (Phase 0.3)

```bash
node -e "const fs=require('fs');const os=require('os');const p=require('path').join(os.homedir(),'.claude','settings.json');const s=JSON.parse(fs.readFileSync(p,'utf8').replace(/^﻿/,''));const u='http://127.0.0.1:8080/v1';if(!s.env.UNBLIND_OPENAI_BASE_URL){s.env.UNBLIND_OPENAI_BASE_URL=u;fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n')}"
```

## 权限修复 (Phase 0.4)

```bash
node -e "const fs=require('fs');const os=require('os');const p=require('path').join(os.homedir(),'.claude','settings.json');const s=JSON.parse(fs.readFileSync(p,'utf8').replace(/^﻿/,''));if(!s.permissions)s.permissions={allow:[]};const a=s.permissions.allow;if(!a.some(x=>x.includes('unblind'))){a.push('Bash(*~/.claude/skills/unblind/scripts/unblind.mjs*)');fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n')}"
```

## 模型选择 (Phase 0.5)

询问用户要使用的视觉模型名，然后写入 settings.json：

```bash
node -e "const fs=require('fs');const os=require('os');const p=require('path').join(os.homedir(),'.claude','settings.json');const s=JSON.parse(fs.readFileSync(p,'utf8').replace(/^﻿/,''));s.env.UNBLIND_OPENAI_VISION_MODEL='gpt-4o';fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n')"
```

替换 `gpt-4o` 为实际模型名。

## 模型切换 (Phase 0.6)

用户说 "切换模型" / "switch model" / "换个模型" → 显示当前模型 → 询问新模型名 → 写入 `UNBLIND_OPENAI_VISION_MODEL` → 确认。

## 版本检查 (Phase 0.7)

```bash
cd ~/.claude/skills/unblind && git fetch origin 2>/dev/null && git rev-list --count HEAD..origin/master 2>/dev/null || echo "0"
```

若 > 0：`Unblind 有新版本可用（落后 <N> 个提交）。运行 cd ~/.claude/skills/unblind && git pull 更新。`

## Node.js 检查 (Phase 0.8)

```bash
node --version
```

若失败或 < 18：`Unblind 需要 Node.js >= 18，请安装后重试。` 停止。

## 常见错误

| 错误 | 原因 | 解决 |
|------|------|------|
| `API Key 无效或被拒绝` (401) | Key 过期/错误 | 重新获取 Key，运行 Phase 0.2 命令 |
| `API 请求频率超限` (429) | 调用太频繁 | 等待后自动重试 |
| `服务端异常` (5xx) | API 服务故障 | 等待恢复，或更换 API 端点 |
| `文件内容与扩展名不匹配` | 文件损坏或格式错误 | 检查图片文件 |
| `图片文件为空` | 0 字节文件 | 提供有效图片 |
| `路径不是文件` | 传入了目录路径 | 指定图片文件路径 |
