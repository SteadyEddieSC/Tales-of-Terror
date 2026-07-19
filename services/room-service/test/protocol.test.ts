import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  MAX_MESSAGE_BYTES,
  createEnvelope,
  parseEnvelope,
  validateEnvelope,
} from "../src/protocol";

describe("companion protocol", () => {
  it("accepts the bounded versioned envelope", () => {
    const envelope = createEnvelope("room_1", "prompt_choice_submit", "request_1", { optionIds: ["listen"], promptRevision: 3 }, {
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

  it("validates the Godot-produced cross-runtime fixture and rejects mixed schemas", () => {
    const fixture = JSON.parse(readFileSync("game/tests/fixtures/companion_protocol_v1.json", "utf8")) as {
      typescriptProducedWire: unknown;
      godotProducedWire: unknown;
      malformedMixedEnvelopes: unknown[];
    };
    const producedByTypescript = createEnvelope("room_fixture", "prompt_choice_submit", "typescript_choice_1", {
      optionIds: ["listen", "wait"], promptRevision: 7,
    }, { serverSequence: 4, authoritativeRevision: 11, seatClaim: 3 });
    expect(producedByTypescript).toEqual(fixture.typescriptProducedWire);
    expect(validateEnvelope(fixture.godotProducedWire)).toMatchObject({ accepted: true, code: "accepted" });
    for (const malformed of fixture.malformedMixedEnvelopes) {
      expect(validateEnvelope(malformed)).toMatchObject({ accepted: false, code: "malformed" });
    }
  });

  it("fails closed on unknown envelope fields and mixed intent payload names", () => {
    const valid = createEnvelope("room_1", "prompt_choice_submit", "request_1", {
      optionIds: ["listen"], promptRevision: 1,
    });
    expect(validateEnvelope({ ...valid, room_id: "room_1" })).toMatchObject({ accepted: false, code: "malformed" });
    expect(validateEnvelope({
      ...valid,
      payload: { optionIds: ["listen"], option_ids: ["listen"], promptRevision: 1 },
    })).toMatchObject({ accepted: false, code: "malformed" });
    expect(validateEnvelope(createEnvelope("room_1", "public_view_update", "view_1", {
      board: { viewVersion: 1, revision: 0, spaces: [] },
    }))).toMatchObject({ accepted: true, code: "accepted" });
    const mixedView = {
      ...createEnvelope("room_1", "public_view_update", "view_2", {
        board: { viewVersion: 1, revision: 0, spaces: [] },
      }),
      payload: { board: { viewVersion: 1, view_version: 1, revision: 0, spaces: [] } },
    };
    expect(validateEnvelope(mixedView)).toMatchObject({ accepted: false, code: "malformed" });
  });
});
