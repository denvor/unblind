// tests/test-protocols.js
import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { PROTOCOLS } from "../scripts/lib/providers/protocols.js";

const IMAGE_1 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==";
const IMAGE_2 = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQg=";

describe("PROTOCOLS: openai-chat-completions", () => {
  const proto = PROTOCOLS["openai-chat-completions"];

  it("endpoint returns /chat/completions", () => {
    assert.equal(proto.endpoint("gpt-4o"), "/chat/completions");
  });

  it("auth returns Bearer header", () => {
    assert.deepStrictEqual(proto.auth("sk-test123"), { Authorization: "Bearer sk-test123" });
  });

  it("buildContent — single image", () => {
    const inputs = [{ type: "image", data: IMAGE_1, mimeType: "image/png" }];
    const content = proto.buildContent(inputs, "Describe this image");
    assert.equal(content.length, 2);
    assert.equal(content[0].type, "image_url");
    assert.equal(content[0].image_url.url, IMAGE_1);
    assert.equal(content[1].type, "text");
    assert.equal(content[1].text, "Describe this image");
  });

  it("buildContent — multiple images", () => {
    const inputs = [
      { type: "image", data: IMAGE_1, mimeType: "image/png" },
      { type: "image", data: IMAGE_2, mimeType: "image/jpeg" },
    ];
    const content = proto.buildContent(inputs, "Compare these");
    assert.equal(content.length, 3);
    assert.equal(content[0].type, "image_url");
    assert.equal(content[0].image_url.url, IMAGE_1);
    assert.equal(content[1].type, "image_url");
    assert.equal(content[1].image_url.url, IMAGE_2);
    assert.equal(content[2].type, "text");
  });

  it("buildContent — text input", () => {
    const inputs = [{ type: "text", data: "Previous analysis result" }];
    const content = proto.buildContent(inputs, "Compare with this");
    assert.equal(content.length, 2);
    assert.equal(content[0].type, "text");
    assert.equal(content[0].text, "Previous analysis result");
    assert.equal(content[1].text, "Compare with this");
  });

  it("buildContent — mixed image+text inputs", () => {
    const inputs = [
      { type: "image", data: IMAGE_1, mimeType: "image/png" },
      { type: "text", data: "Reference: sunny day" },
    ];
    const content = proto.buildContent(inputs, "Analyze");
    assert.equal(content.length, 3);
    assert.equal(content[0].type, "image_url");
    assert.equal(content[1].type, "text");
    assert.equal(content[1].text, "Reference: sunny day");
    assert.equal(content[2].type, "text");
    assert.equal(content[2].text, "Analyze");
  });

  it("buildBody — default options", () => {
    const body = proto.buildBody("gpt-4o", [{ type: "text", text: "Hello" }], {});
    assert.equal(body.model, "gpt-4o");
    assert.equal(body.max_tokens, 2048);
    assert.equal(body.messages.length, 1);
    assert.equal(body.messages[0].role, "user");
    assert.ok(Array.isArray(body.messages[0].content));
  });

  it("buildBody — custom maxTokens", () => {
    const body = proto.buildBody("gpt-4o", [], { maxTokens: 4096 });
    assert.equal(body.max_tokens, 4096);
  });

  it("buildBody — custom temperature", () => {
    const body = proto.buildBody("gpt-4o", [], { temperature: 0.7 });
    assert.equal(body.temperature, 0.7);
  });

  it("extractContent — valid response", () => {
    const data = { choices: [{ message: { content: "This is a cat" } }] };
    assert.equal(proto.extractContent(data), "This is a cat");
  });

  it("extractContent — empty choices should throw", () => {
    assert.throws(() => proto.extractContent({ choices: [] }), /No text content/);
  });

  it("extractContent — null message should throw", () => {
    assert.throws(() => proto.extractContent({ choices: [{}] }));
  });

  it("parseError — 401 maps to auth", () => {
    assert.deepStrictEqual(proto.parseError({ error: { message: "Unauthorized" } }, 401), { category: "auth" });
  });

  it("parseError — 403 maps to auth", () => {
    assert.deepStrictEqual(proto.parseError({}, 403), { category: "auth" });
  });

  it("parseError — 429 maps to rate_limit", () => {
    assert.deepStrictEqual(proto.parseError({ error: { message: "Rate limited" } }, 429), { category: "rate_limit" });
  });

  it("parseError — 500 maps to server", () => {
    assert.deepStrictEqual(proto.parseError({}, 500), { category: "server" });
  });

  it("parseError — 503 maps to server", () => {
    assert.deepStrictEqual(proto.parseError({}, 503), { category: "server" });
  });

  it("parseError — 400 maps to client with message", () => {
    const r = proto.parseError({ error: { message: "Bad request" } }, 400);
    assert.equal(r.category, "client");
    assert.equal(r.message, "Bad request");
  });
});
