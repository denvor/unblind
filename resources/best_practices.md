# Unblind 最佳实践 / Best Practices

## 选择合适的模型

视觉模型通过 `UNBLIND_OPENAI_VISION_MODEL` 配置。推荐选择支持多模态（图片输入）的模型。

常见选项：
- `gpt-4o` — OpenAI，综合能力强
- `gemini-2.5-flash` — Google，性价比高
- `llama-3.2-vision` / `llama-4-vision` — 开源，可本地部署

## 选择合适的分析模式

| 需求 | 模式 | 触发词 |
|------|------|--------|
| 通用图片理解 | `describe` | 默认 |
| 提取文字 | `ocr` | "提取文字"、"OCR"、"读取" |
| 设计评审 | `ui-review` | "评审"、"UI"、"界面" |
| 图表数据 | `chart-data` | "图表"、"数据"、"趋势" |
| 物体识别 | `object-detect` | "识别"、"检测"、"有什么" |

## Token 优化建议

1. **先压缩再发送**：大图（>1024px 长边）会被自动压缩，减少 token 消耗
2. **图片大小控制**：单图不超过 10MB，推荐控制在 2MB 以内
3. **避免重复发送**：同一张图片多次分析会使用缓存（基于内容哈希）
4. **选择合适的模式**：OCR 和 object-detect 模式通常比 describe 模式输出更短

## 调试技巧

### 检查配置状态

```bash
node scripts/unblind.mjs --health
```

### 清除图片缓存

```bash
node scripts/unblind.mjs --clear-cache
```

## 故障排查

| 症状 | 可能原因 | 解决方法 |
|------|----------|----------|
| "API error (401)" | API Key 无效或过期 | 检查 API 控制台，重新配置 Key |
| "API error (429)" | 请求频率超限 | 等待 30 秒后重试 |
| "API error (500)" | 服务端异常 | 等待后重试，或切换 API 端点 |
| 超时 | 网络问题或图片过大 | 检查网络，压缩图片后重试 |
| "Unsupported file extension" | 格式不支持 | 转换为 jpg/png/webp |
