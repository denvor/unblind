<h1 align="center">Unblind</h1>
<p align="center"><em>一个不会悄无声息挂掉的视觉 skill</em></p>
<p align="center">
  👁️ 自愈配置 · 熔断重试 · 安全沙箱 · 零依赖
  <br>
  🛠️ <b>OpenAI 兼容 API</b> · 适配本地部署模型
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0-blue" alt="version">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="license">
  <img src="https://img.shields.io/badge/node-%E2%89%A518-brightgreen" alt="node">
  <img src="https://img.shields.io/badge/dependencies-0-zero?labelColor=white" alt="zero deps">
</p>

---

## 📌 关于本项目

本项目 fork 自 [Santazuki/unblind](https://github.com/Santazuki/unblind)，原项目设计为支持 **7 个 Provider × 3 个协议家族**（Anthropic Messages、OpenAI Chat、Google Gen AI），配置项繁多。

由于本人使用 **DeepSeek (官方 API，v4 模型)** 和本地部署的 **Qwen3.6-35B-A3B**（OpenAI 兼容接口），实际只需要一个 OpenAI 兼容 Provider。因此按照自身环境做了精简：

- **去掉** 6 个 Provider 和 2 个协议，只保留 OpenAI Chat Completions
- **环境变量统一**为 `UNBLIND_` 前缀，不再散落 `MIMO_` / `OPENAI_` / `OLLAMA_` 等命名
- **安装脚本**改为交互式配置，不再需要手动编辑 JSON
- 核心防御机制（Phase 0 自愈、熔断重试、SHA256 缓存、魔数校验）全部保留

如果你也只需要对接一个 OpenAI 兼容 API（任一支持 `/v1/chat/completions` 的服务均可），这个分支更简单直接。

> 原项目链接：[https://github.com/Santazuki/unblind](https://github.com/Santazuki/unblind)
>
> 需要多 Provider 支持请使用原版。

---

## ✨ 这是什么

Unblind 是给 AI Agent 用的视觉后端——不是面向人类的 App，而是面向 Agent 的基础设施。把图片路由到视觉 API，返回文字描述，让没有多模态能力的模型（如 DeepSeek）能够"看图"。

和大多数视觉 skill 不同的是，它不是一层薄薄的 API 封装。每一步都有防御：

```
用户发图 → Phase 0 自检（静默）→ 魔数校验 → 缓存查询 → Provider → 返回描述
```

## 🚀 快速开始

```bash
# 从仓库安装
git clone <你的仓库地址> && cd unblind
bash install.sh    # 交互式配置 4 个参数
```

安装过程会提示输入：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `UNBLIND_OPENAI_BASE_URL` | API 地址 | `https://api.deepseek.com/v1` 或 `http://127.0.0.1:8080/v1` |
| `UNBLIND_OPENAI_VISION_MODEL` | 视觉模型名 | `gpt-4o` 或 `Qwen3.6-35B-A3B` |
| `UNBLIND_OPENAI_API_KEY` | API Key | `sk-...` |
| `UNBLIND_PROVIDER_ORDER` | Provider 顺序 | `openai`（目前唯一值，保留未来扩展） |

配置写入 `~/.claude/settings.json`，后续调用自动读取。

**开发者**：

```bash
git clone <你的仓库地址> && cd unblind
node --test tests/test-*.js   # 零依赖
```

## ⚙️ 工程特性

| 特性 | 说明 |
|------|------|
| 🩺 **Phase 0 自愈** | 每次调用静默检查环境，配置缺失当场修复，不打断用户 |
| 🔌 **熔断 + 指数退避** | Provider 独立 CircuitBreaker，失败 5 次熔断 60s |
| 💾 **SHA256 持久化缓存** | 内容寻址，TTL + LRU 1000，跨进程命中，`--no-cache` 跳过 |
| 🛡️ **魔数文件校验** | 读取文件头字节，拒绝伪装成图片的攻击文件 |
| 🔒 **安全沙箱** | 零 exec / child_process，API Key 不在任何输出中暴露 |
| 📐 **结构化输出** | `--format json|yaml|csv`，Agent 可编程调用 |
| 💬 **过程反馈** | 📖读取 → 🚀调用 → ✅完成，中英双语，自动检测系统语言 |
| 📦 **零依赖** | 只用 Node.js >= 18 内置模块，clone 即用 |

## 🔍 分析模式

| 模式 | 用途 | 示例 |
|------|------|------|
| `describe` | 通用描述 | `unblind.mjs image.png` |
| `ocr` | 文字提取 | `unblind.mjs scan.png ocr` |
| `ui-review` | UI/UX 评审 | `unblind.mjs mockup.png ui-review` |
| `chart-data` | 图表数据 | `unblind.mjs chart.png chart-data` |
| `object-detect` | 物体识别 | `unblind.mjs photo.png object-detect` |
| `compare` | 多图对比 | `unblind.mjs a.png b.png compare` |

## 🎯 视觉模型

支持任意 OpenAI 兼容 API。通过 `UNBLIND_` 环境变量配置，安装时一次配好即可使用：

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `UNBLIND_OPENAI_BASE_URL` | API 地址 | `http://127.0.0.1:8080/v1` |
| `UNBLIND_OPENAI_VISION_MODEL` | 视觉模型名 | `gpt-4o` |
| `UNBLIND_OPENAI_API_KEY` | API Key | — |

**典型场景：**

```json
// DeepSeek 官方 API
{
  "UNBLIND_OPENAI_BASE_URL": "https://api.deepseek.com/v1",
  "UNBLIND_OPENAI_VISION_MODEL": "deepseek-v4",
  "UNBLIND_OPENAI_API_KEY": "sk-xxx"
}

// 本地 Qwen3.6-35B-A3B（vLLM / ollama）
{
  "UNBLIND_OPENAI_BASE_URL": "http://127.0.0.1:8080/v1",
  "UNBLIND_OPENAI_VISION_MODEL": "Qwen3.6-35B-A3B",
  "UNBLIND_OPENAI_API_KEY": "sk-xxx"
}
```

## ⌨️ CLI

```bash
unblind.mjs <image> [mode]           # 分析图片
unblind.mjs <a.png> <b.png> compare  # 多图对比
unblind.mjs <img> --format json      # 结构化输出
unblind.mjs --health                 # 连通性诊断
unblind.mjs --config                 # 查看配置
unblind.mjs --cache-stats            # 缓存统计
unblind.mjs --clear-cache            # 清空缓存
```

## 🏗️ 架构

协议驱动——把 LLM API 的 Provider 层拆成协议（怎么发请求）和 Provider（连到哪），支持任意 OpenAI 兼容 API。

```
CLI → orchestrator (config → image → cache → provider → result)
        → providers/ (GenericProvider — 唯二类 → protocols 纯函数调度)
        → httpClient (fetch + 超时 + parseError 委托)
        → cache (SHA256 + TTL + LRU)
        → retry (指数退避 + CircuitBreaker)
        → errorHandler (ClientError / ServerError / NetworkError)
```

1 个协议对象（OpenAI Chat）+ 1 行注册表数据 = 完整 Provider。更换厂商只需修改注册表中的 baseUrl 和 envKey。

## 🧪 测试

```bash
node --test tests/test-*.js
```

需要 API Key 的测试在无 Key 时自动跳过。

## 📄 许可

MIT

---

<p align="center">
  <sub>基于 <a href="https://github.com/Santazuki/unblind">Santazuki/unblind</a> 按自身环境修改。</sub>
</p>
