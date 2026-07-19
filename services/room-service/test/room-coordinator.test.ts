import { describe, expect, it } from "vitest";
import { createEnvelope } from "../src/protocol";
import {
  DEFAULT_LIMITS,
  DeterministicRoomRegistry,
  EphemeralRoom,
  type CapabilityFactory,
  type EphemeralRoomSnapshot,
  type RoomLimits,
} from "../src/room-coordinator";

const capabilities: CapabilityFactory = (scope, ordinal) => `synthetic_${scope}_capability_${ordinal}`;

class TestClock {
  private value = 1_000;
  readonly read = (): number => this.value;
  advance(milliseconds: number): void { this.value += milliseconds; }
  set(value: number): void { this.value = value; }
}

function claimedRoom(
  clientCount = 1,
  limits: RoomLimits = DEFAULT_LIMITS,
): { room: EphemeralRoom; resumes: string[]; clock: TestClock } {
  const clock = new TestClock();
  const room = new EphemeralRoom("room_test", "GHST27", capabilities, limits, clock.read);
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
  return { room, resumes, clock };
}

function revealIntent(room: EphemeralRoom, requestId: string) {
  return createEnvelope(room.roomId, "private_reveal_ack", requestId, {}, { seatClaim: 1 });
}

describe("ephemeral room coordinator", () => {
  it("creates distinct join/host/resume material and retries code collisions", () => {
    const codes = ["GHST27", "GHST27", "DREAD8"];
    const registry = new DeterministicRoomRegistry((attempt) => codes[attempt] ?? "FINAL9", capabilities);
    const first = registry.create();
    const second = registry.create();
    expect(first.join("client_1").accepted).toBe(true);
    expect(first.approveClaim(first.hostCapability, "client_1", 1).accepted).toBe(true);
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
    expect(room.approveClaim(room.hostCapability, "client_1", 1)).toMatchObject({ accepted: true });
    const clientApproval = room.drainClientInbox("client_1").find((message) => message.messageType === "seat_claim_approved");
    const resume = typeof clientApproval?.payload.resumeCapability === "string" ? clientApproval.payload.resumeCapability : "";
    expect(room.revokeClaim(room.hostCapability, "client_1")).toMatchObject({ accepted: true });
    expect(room.resume("client_1", 1, resume)).toMatchObject({ accepted: false, code: "unauthorized" });

    const denied = new EphemeralRoom("room_deny", "NGHT28", capabilities);
    denied.join("client_2");
    expect(denied.denyClaim(denied.hostCapability, "client_2")).toMatchObject({ accepted: true });
    expect(denied.approveClaim(denied.hostCapability, "client_2", 2)).toMatchObject({ accepted: false });
  });

  it("allows one companion claim per stable seat and supports one through eight", () => {
    const room = new EphemeralRoom("room_claim", "CLAM7", capabilities);
    room.join("client_1");
    room.join("client_2");
    expect(room.approveClaim(room.hostCapability, "client_1", 1).accepted).toBe(true);
    expect(room.approveClaim(room.hostCapability, "client_2", 1)).toMatchObject({ accepted: false, code: "wrong_seat" });
    expect(room.approveClaim(room.hostCapability, "client_2", 2).accepted).toBe(true);
    const { room: full } = claimedRoom(8);
    expect(full.diagnostics()).toMatchObject({ connectedClients: 8, claimedSeats: [1, 2, 3, 4, 5, 6, 7, 8] });
    expect(full.join("client_9")).toMatchObject({ accepted: false, code: "room_full" });
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

  it("relays one intent and replaces the provisional receipt with the authoritative acknowledgement", () => {
    const { room } = claimedRoom();
    const intent = createEnvelope(room.roomId, "prompt_choice_submit", "choice_1", {
      optionIds: ["listen"], promptRevision: 4,
    }, { seatClaim: 1, authoritativeRevision: 4 });
    const first = room.relayClientEnvelope("client_1", intent);
    expect(first).toMatchObject({ accepted: true, envelope: { payload: { relayAccepted: true } } });
    const hostMessages = room.drainHostInbox(room.hostCapability);
    expect(hostMessages).toHaveLength(1);
    const authoritative = createEnvelope(room.roomId, "acknowledgement", "choice_1", {
      resultingRevision: 5, appliedOnce: true, authorityResult: "accepted",
    }, { seatClaim: 1, authoritativeRevision: 5, acknowledgement: "accepted" });
    expect(room.relayHostEnvelope(room.hostCapability, "client_1", authoritative).accepted).toBe(true);
    const duplicate = room.relayClientEnvelope("client_1", intent);
    expect(duplicate.envelope).toMatchObject({ payload: { appliedOnce: true }, authoritativeRevision: 5 });
    expect(room.drainHostInbox(room.hostCapability)).toHaveLength(0);
    expect(room.diagnostics().counters.duplicate).toBe(1);
  });

  it("rejects malformed, unsupported, wrong-seat, and rate-limited work", () => {
    const limits = { ...DEFAULT_LIMITS, maxMessagesPerWindow: 2 };
    const { room } = claimedRoom(1, limits);
    expect(room.relayClientRaw("client_1", "{")).toMatchObject({ accepted: false, code: "malformed" });
    const wrong = createEnvelope(room.roomId, "role_action_submit", "wrong_1", { actionId: "omen", targets: [] }, { seatClaim: 2 });
    expect(room.relayClientEnvelope("client_1", wrong)).toMatchObject({ accepted: false, code: "wrong_seat" });
    const unsupported = createEnvelope(room.roomId, "public_view_update", "unsupported_1", {}, { seatClaim: 1 });
    expect(room.relayClientEnvelope("client_1", unsupported)).toMatchObject({ accepted: false, code: "unsupported_type" });
    expect(room.relayClientEnvelope("client_1", revealIntent(room, "limited_1"))).toMatchObject({ accepted: false, code: "rate_limited" });
  });

  it("lets a rate-limited client recover and does not create a permanent limit during ordinary activity", () => {
    const limits = { ...DEFAULT_LIMITS, maxMessagesPerWindow: 2, rateWindowMs: 100 };
    const { room, clock } = claimedRoom(1, limits);
    expect(room.relayClientEnvelope("client_1", revealIntent(room, "rate_1")).accepted).toBe(true);
    expect(room.relayClientEnvelope("client_1", revealIntent(room, "rate_2")).accepted).toBe(true);
    expect(room.relayClientEnvelope("client_1", revealIntent(room, "rate_3"))).toMatchObject({ accepted: false, code: "rate_limited" });
    clock.advance(100);
    expect(room.relayClientEnvelope("client_1", revealIntent(room, "rate_4")).accepted).toBe(true);
    clock.advance(50);
    room.disconnect("client_1");
    clock.advance(50);
    expect(room.resume("client_1", 1, "synthetic_resume_capability_1").accepted).toBe(true);
    expect(room.relayClientEnvelope("client_1", revealIntent(room, "rate_5")).accepted).toBe(true);
  });

  it("keeps private payloads and capabilities out of diagnostics", () => {
    const { room, resumes } = claimedRoom();
    const hostCapability = room.hostCapability;
    const privateText = "synthetic_private_objective_do_not_log";
    const privateView = createEnvelope(room.roomId, "seat_private_view_update", "private_1", {
      socialPrivate: { objective: privateText },
    }, {
      seatClaim: 1,
      authoritativeRevision: 9,
    });
    expect(room.relayHostEnvelope(hostCapability, "client_1", privateView)).toMatchObject({ accepted: true });
    const diagnostics = JSON.stringify(room.diagnostics());
    expect(diagnostics).not.toContain(privateText);
    expect(diagnostics).not.toContain(hostCapability);
    expect(diagnostics).not.toContain(resumes[0]);
    expect(diagnostics).not.toContain('"payload":');
  });

  it("bounds queues, acknowledgement caches, and ordered sequences", () => {
    const limits = { ...DEFAULT_LIMITS, maxQueueDepth: 3, maxAckCache: 2, maxMessagesPerWindow: 20 };
    const { room } = claimedRoom(1, limits);
    for (let index = 0; index < 5; index += 1) room.relayClientEnvelope("client_1", revealIntent(room, `request_${index}`));
    const hostMessages = room.drainHostInbox(room.hostCapability);
    expect(hostMessages).toHaveLength(3);
    expect(hostMessages.map((item) => item.serverSequence)).toEqual([...hostMessages.map((item) => item.serverSequence)].sort((a, b) => a - b));
    expect(room.diagnostics().queueDepth).toBeLessThanOrEqual(3);
  });

  it("expires acknowledgement cache entries on persisted elapsed time", () => {
    const limits = { ...DEFAULT_LIMITS, acknowledgementExpiryMs: 100, hostLossGraceMs: 1_000 };
    const { room, clock } = claimedRoom(1, limits);
    const intent = revealIntent(room, "ack_expiry");
    expect(room.relayClientEnvelope("client_1", intent).accepted).toBe(true);
    expect(room.drainHostInbox(room.hostCapability)).toHaveLength(1);
    clock.advance(100);
    expect(room.heartbeat(room.hostCapability).accepted).toBe(true);
    expect(room.relayClientEnvelope("client_1", intent).accepted).toBe(true);
    expect(room.drainHostInbox(room.hostCapability)).toHaveLength(1);
  });

  it("uses independent host-loss and inactivity deadlines", () => {
    const limits = { ...DEFAULT_LIMITS, hostLossGraceMs: 100, idleExpiryMs: 1_000 };
    const { room, clock } = claimedRoom(1, limits);
    clock.advance(60);
    expect(room.heartbeat(room.hostCapability).accepted).toBe(true);
    clock.advance(60);
    expect(room.diagnostics()).toMatchObject({ roomState: "open", hostPresent: true });
    expect(room.relayClientEnvelope("client_1", revealIntent(room, "host_loss_traffic")).accepted).toBe(true);
    clock.advance(41);
    expect(room.relayClientEnvelope("client_1", revealIntent(room, "host_loss_cannot_extend"))).toMatchObject({ accepted: false, code: "expired" });
    expect(room.diagnostics()).toMatchObject({ roomState: "expired", connectedClients: 0 });
  });

  it("expires an ordinarily inactive room even when host-loss grace is longer", () => {
    const limits = { ...DEFAULT_LIMITS, hostLossGraceMs: 1_000, idleExpiryMs: 100 };
    const { room, clock } = claimedRoom(1, limits);
    clock.advance(100);
    expect(room.diagnostics()).toMatchObject({ roomState: "expired", connectedClients: 0 });
  });

  it("clears ephemeral membership and capabilities on close and expiry", () => {
    const closed = claimedRoom();
    const closedHost = closed.room.hostCapability;
    expect(closed.room.close(closedHost)).toMatchObject({ accepted: true });
    expect(closed.room.hostCapability).toBe("");
    expect(closed.room.snapshot()).toMatchObject({ clients: [], hostInbox: [], hostCapability: "", state: "closed" });
    expect(closed.room.resume("client_1", 1, closed.resumes[0] ?? "")).toMatchObject({ accepted: false, code: "expired" });

    const limits = { ...DEFAULT_LIMITS, hostLossGraceMs: 100 };
    const expired = claimedRoom(1, limits);
    expired.clock.advance(100);
    expired.room.updateTime();
    expect(expired.room.hostCapability).toBe("");
    expect(expired.room.snapshot()).toMatchObject({ clients: [], hostInbox: [], hostCapability: "", state: "expired" });
  });

  it("restores elapsed-time, rate, and acknowledgement state safely and rejects corrupt reloads", () => {
    const limits = { ...DEFAULT_LIMITS, rateWindowMs: 100, hostLossGraceMs: 1_000 };
    const original = claimedRoom(1, limits);
    const intent = revealIntent(original.room, "restart_once");
    expect(original.room.relayClientEnvelope("client_1", intent).accepted).toBe(true);
    const snapshot = original.room.snapshot();
    const restartedClock = new TestClock();
    restartedClock.set(snapshot.currentTimeMs - 500);
    const restored = EphemeralRoom.restore(snapshot, capabilities, restartedClock.read);
    expect(restored.diagnostics().elapsedMs).toBe(snapshot.currentTimeMs);
    expect(restored.relayClientEnvelope("client_1", intent).envelope).toMatchObject({ payload: { relayAccepted: true } });
    restartedClock.set(snapshot.currentTimeMs + 1_000);
    expect(restored.diagnostics().roomState).toBe("expired");

    const corrupt = { ...snapshot, snapshotVersion: 99 } as unknown as EphemeralRoomSnapshot;
    expect(() => EphemeralRoom.restore(corrupt, capabilities, restartedClock.read)).toThrow("Invalid or unsupported room snapshot");
    const corruptQueue = {
      ...snapshot,
      hostInbox: [{ ...intent, roomId: "room_tampered" }],
    } as EphemeralRoomSnapshot;
    expect(() => EphemeralRoom.restore(corruptQueue, capabilities, restartedClock.read)).toThrow("Invalid or unsupported room snapshot");
  });

  it("exposes no room enumeration API", () => {
    expect(Object.getOwnPropertyNames(DeterministicRoomRegistry.prototype)).not.toContain("list");
  });
});
