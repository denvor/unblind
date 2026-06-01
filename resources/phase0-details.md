# Phase 0 详细流程

## 0.1 Silent health check

```bash
node -e "const fs=require('fs');const os=require('os');const p=require('path').join(os.homedir(),'.claude','settings.json');const s=JSON.parse(fs.readFileSync(p,'utf8'));const issues=[];if(!s.env?.MIMO_API_KEY) issues.push('KEY_MISSING');if(!s.env?.MIMO_VISION_MODEL||s.env.MIMO_VISION_MODEL==='mimo-v2.5-pro') issues.push('MODEL_MISSING');const a=s.permissions?.allow||[];if(!a.some(x=>x.includes('unblind'))) issues.push('PERM_MISSING');if(issues.length) console.log(issues.join(' '));" 2>/dev/null
```

- Empty → healthy, skip to Phase 1
- `KEY_MISSING` → 0.3 | `MODEL_MISSING` → 0.5 | `PERM_MISSING` → 0.4

## 0.2 Version check

```bash
cd ~/.claude/skills/unblind && git fetch 2>/dev/null && behind=$(git rev-list HEAD..origin/master --count 2>/dev/null) && [ "$behind" -gt 0 ] && echo "NEEDS_UPDATE $behind"
```

- Empty → up to date, skip to Phase 1
- `NEEDS_UPDATE <N>` → tell user:

```
🐌 unblind 有 N 个更新没拿... git pull 一下嘛~
```

Continue to Phase 1 (don't block — old version still works).

## 0.3-0.8 Repair procedures

See `resources/troubleshooting.md` for: API key setup, base URL repair, permission fix, model selection, Node.js check.

Key rules:
- API key: user runs command in own terminal. Never write it yourself.
- Model switch: user says "切换模型" → show prompt, write via Bash, confirm.

## CLI Quick Reference

```
node scripts/unblind.mjs <image> <mode>    分析图片
node scripts/unblind.mjs <a> <b> compare   多图对比
node scripts/unblind.mjs <img> --prompt "..."  自定义提示词
node scripts/unblind.mjs <img> --format json  结构化输出
node scripts/unblind.mjs --health           健康检查
node scripts/unblind.mjs --config           查看配置（Key已脱敏）
node scripts/unblind.mjs --set-model <m>    切换模型
node scripts/unblind.mjs --no-cache         跳过缓存
node scripts/unblind.mjs --cache-stats      缓存统计
```

## Edge Cases

- API key expired/missing → Phase 0.3 prompts user to set it
- Image >50MB → rejected with size limit + compression suggestion
- Unsupported format → rejected with list of 7 supported formats
- All providers fail → auto fallback, clean error if all down
- Malicious path input → metacharacter gate rejects before execution
- Model outdated → Phase 0.2 alerts with update hint (non-blocking)
