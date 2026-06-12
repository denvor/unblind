import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getApiKey, getBaseUrl } from "../scripts/lib/credentialManager.js";

describe("credentialManager", () => {
  describe("getApiKey", () => {
    it("should read from UNBLIND_OPENAI_API_KEY env", () => {
      process.env.UNBLIND_OPENAI_API_KEY = "sk-test-key";
      const key = getApiKey();
      assert.equal(key, "sk-test-key");
      delete process.env.UNBLIND_OPENAI_API_KEY;
    });

    it("should return empty string if not set", () => {
      delete process.env.UNBLIND_OPENAI_API_KEY;
      const key = getApiKey();
      assert.equal(key, "");
    });
  });

  describe("getBaseUrl", () => {
    it("should read from UNBLIND_OPENAI_BASE_URL env", () => {
      process.env.UNBLIND_OPENAI_BASE_URL = "https://custom.api.com/v1";
      const url = getBaseUrl();
      assert.equal(url, "https://custom.api.com/v1");
      delete process.env.UNBLIND_OPENAI_BASE_URL;
    });

    it("should return default URL when env not set", () => {
      delete process.env.UNBLIND_OPENAI_BASE_URL;
      const url = getBaseUrl();
      assert.equal(url, "http://127.0.0.1:8080/v1");
    });
  });
});
