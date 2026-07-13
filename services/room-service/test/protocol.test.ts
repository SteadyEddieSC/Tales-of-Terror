import { describe, expect, it } from "vitest";
import {
  MAX_MESSAGE_BYTES,
  createEnvelope,
  parseEnvelope,
  validateEnvelope,
} from "../src/protocol";

describe("companion protocol", () => {
  it("accepts the bounded versioned envelope", () => {
    const envelope = createEnvelope("room_1", "prompt_choice_submit", "request_1", { optionIds: ["listen"] }, {
      seatClaim: 1,
      authoritativeRevision: 7,
    });
    expect(validateEnvelope(envelope)).toMatchObject({ accepted: true, code: "accepted" });
    expect(parseEnvelope(JSON.stringify(envelope))).toMatchObject({ accepted: true, code: "accepted" });
  });

  it("fails closed on unsupported versions and message types", () => {
    const valid = createEnvelope("room_1", "host_heartbeat", "request_1");
    expect(validateEnvelope({ ...valid, protocolVersion: 99 })).toMatchObject({ accepted: false, code: "unsupported_version" });
    expect(validateEnvelope({ ...valid, messageType: "mutate_board" })).toMatchObject({ accepted: false, code: "unsupported_type" });
  });

  it("rejects malformed JSON, oversized strings, collections, depth, and bodies", () => {
    expect(parseEnvelope("{")).toMatchObject({ accepted: false, code: "malformed" });
    const valid = createEnvelope("room_1", "host_heartbeat", "request_1");
    expect(validateEnvelope({ ...valid, requestId: "x".repeat(65) })).toMatchObject({ accepted: false, code: "malformed" });
    expect(validateEnvelope({ ...valid, payload: { values: Array.from({ length: 65 }, () => 1) } })).toMatchObject({ accepted: false, code: "malformed" });
    let nested: Record<string, unknown> = {};
    for (let depth = 0; depth < 10; depth += 1) nested = { nested };
    expect(validateEnvelope({ ...valid, payload: nested })).toMatchObject({ accepted: false, code: "malformed" });
    expect(parseEnvelope("x".repeat(MAX_MESSAGE_BYTES + 1))).toMatchObject({ accepted: false, code: "body_too_large" });
  });
});
