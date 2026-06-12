import { log } from "./logger.js";

/**
 * 获取 API Key（从环境变量读取）
 * @returns {string}
 */
export function getApiKey() {
  return process.env.UNBLIND_OPENAI_API_KEY || "";
}

/**
 * 获取 API Base URL
 * @returns {string}
 */
export function getBaseUrl() {
  return process.env.UNBLIND_OPENAI_BASE_URL || "http://127.0.0.1:8080/v1";
}

/**
 * 生成 Auth Header（OpenAI 兼容 API 统一使用 Bearer 认证）
 * @param {string} apiKey
 * @returns {object}
 */
export function getAuthHeader(apiKey) {
  return { Authorization: `Bearer ${apiKey}` };
}

log("debug", "credentialManager", "module_loaded");
