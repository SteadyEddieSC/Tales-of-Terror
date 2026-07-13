import { describe, expect, it } from "vitest";
import { createEnvelope } from "../src/protocol";
import {
  DEFAULT_LIMITS,
  DeterministicRoomRegistry,
  EphemeralRoom,
  type CapabilityFactory,
} from "../src/room-coordinator";

const capabilities: CapabilityFactory = (scope, ordinal) => `synthetic_${scope}_capability_${ordinal}`;

function claimedRoom(clientCount = 1): { room: EphemeralRoom; resumes: string[] } {
  const room = new EphemeralRoom("room_test", "GHST27", capabilities);
  const resumes: string[] = [];
  for (let index = 1; index <= clientCount; index += 1) {
    expect(room.join(`client_${index}`).accepted).toBe(true);
    const approval = room.approveClaim(room.hostCapability, `client_${index}`, index);
    expect(approval.accepted).toBe(true);
    const privateApproval = room.drainClientInbox(`client_${index}`).find((message) => message.messageType === "seat_claim_approved");
    resumes.push(typeof privateApproval?.payload.resumeCapability === "string" ? privateApproval.payload.resumeCapability : "");
  }
  room.drainHostInbox(room.hostCapability);
  for (let index = 1; index <= clientCount; index += 1) room.drainClientInbox(`client_${index}`);
  return { room, resumes };
}

describe("ephemeral room coordinator", () => {
  it("creates distinct join/host/resume material and retries code collisions", () => {
    const codes = ["GHST27", "GHST27", "DREAD8"];
    const registry = new DeterministicRoomRegistry((attempt) => codes[attempt] ?? "FINAL9", capabilities);
    const first = registry.create();
    const second = registry.create();
    const joined = first.join("client_1");
    const approved = first.approveClaim(first.hostCapability, "client_1", 1);
    expect(joined.accepted).toBe(true);
    expect(second.joinCode).toBe("DREAD8");
    expect(first.joinCode).not.toBe(first.hostCapability);
    const clientApproval = first.drainClientInbox("client_1").find((message) => message.messageType === "seat_claim_approved");
    const resume = clientApproval?.payload.resumeCapability;
    expect(resume).not.toBe(first.hostCapability);
    expect(resume).not.toBe(first.joinCode);
    expect(registry.size).toBe(2);
  });

  it("requires explicit host approval and denies or revokes claims safely", () => {
    const room = new EphemeralRoom("room_test", "GHST27", capabilities);
    expect(room.join("client_1")).toMatchObject({ accepted: true });
    expect(room.approveClaim("wrong_host", "client_1", 1)).toMatchObject({ accepted: false, code: "unauthorized" });
    const approved = room.approveClaim(room.hostCapability, "client_1", 1);
    const clientApproval = room.drainClientInbox("client_1").find((message) => message.messageType === "seat_claim_approved");
    const resume = typeof clientApproval?.payload.resumeCapability === "string" ? clientApproval.payload.resumeCapability : "";
    expect(approved).toMatchObject({ accepted: true });
    expect(room.revokeClaim(room.hostCapability, "client_1")).toMatchObject({ accepted: true });
    room.disconnect("client_1");
    expect(room.resume("client_1", 1, resume)).toMatchObject({ accepted: false, code: "unauthorized" });

    const denied = new EphemeralRoom("room_deny", "NGHT28", capabilities);
    denied.join("client_2");
    expect(denied.denyClaim(denied.hostCapability, "client_2")).toMatchObject({ accepted: true });
    expect(denied.approveClaim(denied.hostCapability, "client_2", 2)).toMatchObject({ accepted: false });
  });

  it("allows one companion claim per stable seat", () => {
    const room = new EphemeralRoom("room_claim", "CLAM7", capabilities);
    room.join("client_1");
    room.join("client_2");
    expect(room.approveClaim(room.hostCapability, "client_1", 1).accepted).toBe(true);
    expect(room.approveClaim(room.hostCapability, "client_2", 1)).toMatchObject({ accepted: false, code: "wrong_seat" });
    expect(room.approveClaim(room.hostCapability, "client_2", 2).accepted).toBe(true);
  });

  it("supports one through eight clients and fails closed on the ninth", () => {
    const { room } = claimedRoom(8);
    expect(room.diagnostics()).toMatchObject({ connectedClients: 8, claimedSeats: [1, 2, 3, 4, 5, 6, 7, 8] });
    expect(room.join("client_9")).toMatchObject({ accepted: false, code: "room_full" });
  });

  it("restores only the approved stable seat after disconnect", () => {
    const { room, resumes } = claimedRoom(2);
    expect(room.disconnect("client_1")).toMatchObject({ accepted: true });
    expect(room.resume("client_1", 2, resumes[0] ?? "")).toMatchObject({ accepted: false, code: "wrong_seat" });
    expect(room.resume("client_2", 2, resumes[0] ?? "")).toMatchObject({ accepted: false, code: "unauthorized" });
    expect(room.resume("client_1", 1, "missing_or_tampered")).toMatchObject({ accepted: false, code: "unauthorized" });
    expect(room.resume("client_1", 1, resumes[0] ?? "")).toMatchObject({ accepted: true });
    expect(room.resume("client_1", 1, resumes[0] ?? "")).toMatchObject({ accepted: false, code: "unauthorized" });
    expect(room.diagnostics().counters.reconnect).toBe(1);
  });

  it("relays bounded intents in order and acknowledges duplicates idempotently", () => {
    const { room } = claimedRoom();
    const intent = createEnvelope(room.roomId, "prompt_choice_submit", "choice_1", { optionIds: ["listen"] }, {
      seatClaim: 1,
      authoritativeRevision: 4,
    });
    const first = room.relayClientEnvelope("client_1", intent);
    const duplicate = room.relayClientEnvelope("client_1", intent);
    expect(first).toMatchObject({ accepted: true, envelope: { acknowledgement: "accepted" } });
    expect(duplicate.envelope).toEqual(first.envelope);
    const hostMessages = room.drainHostInbox(room.hostCapability);
    expect(hostMessages).toHaveLength(1);
    expect(hostMessages[0]).toMatchObject({ messageType: "prompt_choice_submit", seatClaim: 1, requestId: "choice_1" });
    expect(room.diagnostics().counters.duplicate).toBe(1);
  });

  it("rejects malformed, unsupported, wrong-seat, and rate-limited work", () => {
    const limits = { ...DEFAULT_LIMITS, maxMessagesPerWindow: 2 };
    const room = new EphemeralRoom("room_test", "GHST27", capabilities, limits);
    room.join("client_1");
    room.approveClaim(room.hostCapability, "client_1", 1);
    expect(room.relayClientRaw("client_1", "{")).toMatchObject({ accepted: false, code: "malformed" });
    const wrong = createEnvelope(room.roomId, "role_action_submit", "wrong_1", { actionId: "omen", targets: [] }, { seatClaim: 2 });
    expect(room.relayClientEnvelope("client_1", wrong)).toMatchObject({ accepted: false, code: "wrong_seat" });
    const unsupported = createEnvelope(room.roomId, "public_view_update", "unsupported_1", {}, { seatClaim: 1 });
    expect(room.relayClientEnvelope("client_1", unsupported)).toMatchObject({ accepted: false, code: "unsupported_type" });
    const limited = createEnvelope(room.roomId, "private_reveal_ack", "limited_1", {}, { seatClaim: 1 });
    expect(room.relayClientEnvelope("client_1", limited)).toMatchObject({ accepted: false, code: "rate_limited" });
  });

  it("keeps private payloads and capabilities out of diagnostics", () => {
    const { room, resumes } = claimedRoom();
    const privateText = "synthetic_private_objective_do_not_log";
    const privateView = createEnvelope(room.roomId, "seat_private_view_update", "private_1", { objective: privateText }, {
      seatClaim: 1,
      authoritativeRevision: 9,
    });
    expect(room.relayHostEnvelope(room.hostCapability, "client_1", privateView)).toMatchObject({ accepted: true });
    const diagnostics = JSON.stringify(room.diagnostics());
    expect(diagnostics).not.toContain(privateText);
    expect(diagnostics).not.toContain(room.hostCapability);
    expect(diagnostics).not.toContain(resumes[0]);
    expect(diagnostics).not.toContain('"payload":');
  });

  it("bounds queues, acknowledgement caches, rates, and ordered sequences", () => {
    const limits = { ...DEFAULT_LIMITS, maxQueueDepth: 3, maxAckCache: 2, maxMessagesPerWindow: 20 };
    const room = new EphemeralRoom("room_test", "GHST27", capabilities, limits);
    room.join("client_1");
    room.approveClaim(room.hostCapability, "client_1", 1);
    room.drainHostInbox(room.hostCapability);
    room.drainClientInbox("client_1");
    for (let index = 0; index < 5; index += 1) {
      const intent = createEnvelope(room.roomId, "private_reveal_ack", `request_${index}`, {}, { seatClaim: 1 });
      room.relayClientEnvelope("client_1", intent);
    }
    const hostMessages = room.drainHostInbox(room.hostCapability);
    expect(hostMessages).toHaveLength(3);
    expect(hostMessages.map((item) => item.serverSequence)).toEqual([...hostMessages.map((item) => item.serverSequence)].sort((a, b) => a - b));
    expect(room.diagnostics().queueDepth).toBeLessThanOrEqual(3);
  });

  it("expires on inactivity or host loss and destroys resume state", () => {
    const { room, resumes } = claimedRoom();
    room.disconnect("client_1");
    room.advanceTo(DEFAULT_LIMITS.hostLossGraceSteps);
    expect(room.diagnostics()).toMatchObject({ roomState: "expired", connectedClients: 0 });
    expect(room.resume("client_1", 1, resumes[0] ?? "")).toMatchObject({ accepted: false, code: "expired" });
    expect(room.heartbeat(room.hostCapability)).toMatchObject({ accepted: false, code: "unauthorized" });
  });

  it("closes explicitly and exposes no room enumeration API", () => {
    const { room, resumes } = claimedRoom();
    expect(room.close("wrong")).toMatchObject({ accepted: false, code: "unauthorized" });
    expect(room.close(room.hostCapability)).toMatchObject({ accepted: true });
    expect(room.diagnostics().roomState).toBe("closed");
    expect(room.resume("client_1", 1, resumes[0] ?? "")).toMatchObject({ accepted: false, code: "expired" });
    expect(Object.getOwnPropertyNames(DeterministicRoomRegistry.prototype)).not.toContain("list");
  });
});
