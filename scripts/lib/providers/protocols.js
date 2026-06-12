// scripts/lib/providers/protocols.js

/**
 * @fileoverview 协议定义 — 纯函数集合
 * 每个协议族对象包含 6 个方法，覆盖一个 API 家族的全部差异。
 * 所有方法均为纯函数：输入 → 输出，零副作用。
 */

/**
 * 通用 parseError — 各协议族共用。
 * 根据 HTTP status 和响应体将错误归入 auth / rate_limit / server / client。
 * @param {object} data - API 响应体
 * @param {number} status - HTTP 状态码
 * @returns {{category:string, message?:string}}
 */
function commonParseError(data, status) {
  const err = data.error || data;
  if (status === 401 || status === 403) return { category: "auth" };
  if (status === 429) return { category: "rate_limit" };
  if (status >= 500) return { category: "server" };
  return { category: "client", message: err.message };
}

/**
 * @typedef {Object} ProtocolMethods
 * @property {(model: string) => string} endpoint
 * @property {(apiKey: string) => Record<string,string>} auth
 * @property {(inputs: Array<{type:string,data:string,mimeType?:string}>, prompt: string) => Array<object>} buildContent
 * @property {(model: string, content: Array<object>, options: Object) => object} buildBody
 * @property {(data: object) => string} extractContent
 * @property {(data: object, status: number) => {category:string, message?:string}} parseError
 */

/** @type {Object<string, ProtocolMethods>} */
export const PROTOCOLS = {

  /** OpenAI Chat Completions API */
  "openai-chat-completions": {
    endpoint(_model) {
      return "/chat/completions";
    },

    auth(apiKey) {
      return { Authorization: `Bearer ${apiKey}` };
    },

    buildContent(inputs, prompt) {
      const content = [];
      for (const inp of inputs) {
        if (inp.type === "image") {
          content.push({ type: "image_url", image_url: { url: inp.data } });
        } else if (inp.type === "text") {
          content.push({ type: "text", text: inp.data });
        }
      }
      content.push({ type: "text", text: prompt });
      return content;
    },

    buildBody(model, content, options) {
      const body = {
        model,
        max_tokens: options.maxTokens || 2048,
        messages: [{ role: "user", content }],
      };
      if (options.temperature != null) body.temperature = options.temperature;
      return body;
    },

    extractContent(data) {
      const text = data.choices?.[0]?.message?.content;
      if (!text) throw new Error("No text content in response");
      return text;
    },

    parseError(data, status) { return commonParseError(data, status); },
  },
};
