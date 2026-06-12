import { describe, it, beforeEach, afterEach } from "node:test";
import assert from "node:assert/strict";
import { loadProviders, REGISTRY } from "../scripts/lib/providers/registry.js";
import { PROTOCOLS } from "../scripts/lib/providers/protocols.js";

// 保存原始 env，测试结束后恢复
function withEnv(vars, fn) {
  const orig = {};
  for (const k of Object.keys(vars)) {
    orig[k] = process.env[k];
    if (vars[k] === null) delete process.env[k];
    else process.env[k] = vars[k];
  }
  try { fn(); }
  finally {
    for (const k of Object.keys(orig)) {
      if (orig[k] === undefined) delete process.env[k];
      else process.env[k] = orig[k];
    }
  }
}

describe("registry", () => {
  describe("loadProviders", () => {
    it("should return provider when UNBLIND_OPENAI_API_KEY is set", () => {
      withEnv({ UNBLIND_OPENAI_API_KEY: "sk-test" }, () => {
        const result = loadProviders("openai", { model: "gpt-4o", timeoutMs: 5000 });
        assert.equal(result.length, 1);
        assert.equal(result[0].name, "openai");
      });
    });

    it("should return empty array when no API key configured", () => {
      withEnv({ UNBLIND_OPENAI_API_KEY: null }, () => {
        const result = loadProviders("openai", { model: "test", timeoutMs: 5000 });
        assert.equal(result.length, 0, "no providers without keys");
      });
    });

    it("should handle empty order string gracefully", () => {
      withEnv({ UNBLIND_OPENAI_API_KEY: "sk-test" }, () => {
        const result = loadProviders("", { model: "test", timeoutMs: 5000 });
        assert.equal(result.length, 0);
      });
    });
  });

  describe("REGISTRY data integrity", () => {
    it("should have 1 entry", () => {
      assert.equal(REGISTRY.length, 1);
    });

    it("entry should have required fields", () => {
      const entry = REGISTRY[0];
      assert.equal(entry.name, "openai");
      assert.equal(entry.protocol, "openai-chat-completions");
      assert.equal(entry.envKey, "UNBLIND_OPENAI_API_KEY");
      assert.ok(typeof entry.baseUrl === "string");
      assert.ok(entry.model);
      assert.ok(entry.limits && typeof entry.limits === "object");
    });

    it("protocol reference should exist in PROTOCOLS", () => {
      for (const entry of REGISTRY) {
        assert.ok(PROTOCOLS[entry.protocol], `${entry.name} protocol "${entry.protocol}" exists`);
      }
    });

    it("all names must be unique", () => {
      const names = REGISTRY.map(e => e.name);
      assert.equal(new Set(names).size, names.length);
    });
  });
});
