import { GenericProvider } from "./generic-provider.js";
import { PROTOCOLS } from "./protocols.js";
import { log } from "../logger.js";

/**
 * Provider 注册表 — 纯数据
 * 新增 Provider = 加 1 行（不写逻辑代码）
 * 当前仅支持单一 OpenAI 兼容 Provider，通过 UNBLIND_ 环境变量配置。
 */
export const REGISTRY = [
  {
    name: "openai",
    protocol: "openai-chat-completions",
    envKey: "UNBLIND_OPENAI_API_KEY",
    baseUrl: "http://127.0.0.1:8080/v1",
    model: "gpt-4o",
    limits: { rpm: 500, tpm: 2000000 },
  },
];

/**
 * 加载已配置的 Provider，按 order 排序
 * @param {string} order — "openai"（可扩展）
 * @param {object} opts — { model, timeoutMs }
 * @returns {Array<{ provider: GenericProvider, name: string }>}
 */
export function loadProviders(order, opts = {}) {
  const { model, timeoutMs } = opts;
  const available = new Map();

  for (const entry of REGISTRY) {
    const key = process.env[entry.envKey] || "";
    if (!key) continue;

    const proto = PROTOCOLS[entry.protocol];
    if (!proto) {
      log("warn", "registry", "unknown_protocol", { provider: entry.name, protocol: entry.protocol });
      continue;
    }

    const baseUrl = process.env.UNBLIND_OPENAI_BASE_URL || entry.baseUrl;
    const providerModel = model || entry.model;

    try {
      available.set(entry.name, {
        provider: new GenericProvider({
          name: entry.name,
          protocol: proto,
          baseUrl,
          apiKey: key,
          model: providerModel,
          timeoutMs,
          overrides: entry.overrides || {},
        }),
        name: entry.name,
      });
    } catch (err) {
      log("warn", "registry", "provider_init_failed", { provider: entry.name, error: err.message });
    }
  }

  const ordered = order.split(",").map(s => s.trim());
  const result = [];
  for (const name of ordered) {
    if (available.has(name)) result.push(available.get(name));
  }

  log("debug", "registry", "providers_loaded", { order, count: result.length });
  return result;
}
