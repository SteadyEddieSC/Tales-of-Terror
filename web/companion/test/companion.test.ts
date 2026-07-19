import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { createEnvelope, type JsonValue, type ProtocolEnvelope } from "../../../services/room-service/src/protocol";
import { mountCompanionApp } from "../src/app";
import {
  CompanionAppModel,
  type CompanionStorage,
  type CompanionTransport,
  type ServiceStatus,
  type StoredConnection,
} from "../src/model";

class MemoryStorage implements CompanionStorage {
  value: StoredConnection | null = null;
  load(): StoredConnection | null { return this.value; }
  save(value: StoredConnection): void { this.value = value; }
  clear(): void { this.value = null; }
}

class FakeTransport implements CompanionTransport {
  receiver: ((message: ProtocolEnvelope | ServiceStatus) => void) | undefined;
  readonly connections: Array<{ roomCode: string; authentication: Readonly<Record<string, JsonValue>> }> = [];
  readonly sent: ProtocolEnvelope[] = [];
  disconnects = 0;
  connect(roomCode: string, authentication: Readonly<Record<string, JsonValue>>): Promise<void> {
    this.connections.push({ roomCode, authentication });
    return Promise.resolve();
  }
  send(envelope: ProtocolEnvelope): void { this.sent.push(envelope); }
  disconnect(): void { this.disconnects += 1; }
  setReceiver(receiver: (message: ProtocolEnvelope | ServiceStatus) => void): void { this.receiver = receiver; }
  receive(message: ProtocolEnvelope | ServiceStatus): void { this.receiver?.(message); }
}

function fixture(): { model: CompanionAppModel; transport: FakeTransport; storage: MemoryStorage } {
  const transport = new FakeTransport();
  const storage = new MemoryStorage();
  return { model: new CompanionAppModel(transport, storage, () => "browser_synthetic"), transport, storage };
}

function approve(transport: FakeTransport): void {
  transport.receive(createEnvelope("room_1", "seat_claim_approved", "claim_1", {
    seat: 2,
    resumeCapability: "synthetic_resume_capability",
    seatIdentity: { numeral: "II", symbol: "◆", pattern: "double stripe", colorName: "amber" },
  }, { seatClaim: 2, serverSequence: 1 }));
}

function privateUpdate(transport: FakeTransport, seat = 2): void {
  transport.receive(createEnvelope("room_1", "seat_private_view_update", "private_1", {
    socialPrivate: { role: "Betrayer", faction: "Veiled", objectives: ["Synthetic secret objective"] },
    rulesPrivate: { prompt: { revision: 7, options: [{ id: "listen", label: "Listen at the threshold" }] } },
    legalActions: [{ actionId: "synthetic_action", label: "Place a quiet omen" }],
  }, { seatClaim: seat, authoritativeRevision: 7, serverSequence: 2 }));
}

describe("browser companion state machine", () => {
  it("joins without inferring a seat, then waits for host approval", async () => {
    const { model, transport } = fixture();
    await model.join("ghst27");
    expect(transport.connections[0]).toEqual({ roomCode: "GHST27", authentication: { operation: "join", clientId: "browser_synthetic" } });
    expect(model.snapshot()).toMatchObject({ phase: "pending_approval", seatClaim: 0, privateVisible: false });
  });

  it("rejects malformed room codes before transport", async () => {
    const { model, transport } = fixture();
    await model.join("bad 01");
    expect(transport.connections).toHaveLength(0);
    expect(model.snapshot().status).toContain("4–8");
  });

  it("stores only minimal ephemeral resume material after approval", async () => {
    const { model, transport, storage } = fixture();
    await model.join("GHST27");
    approve(transport);
    expect(model.snapshot()).toMatchObject({ phase: "privacy_gate", roomId: "room_1", seatClaim: 2, privateVisible: false });
    expect(storage.value).toEqual({
      roomCode: "GHST27",
      roomId: "room_1",
      clientId: "browser_synthetic",
      seatClaim: 2,
      resumeCapability: "synthetic_resume_capability",
    });
    expect(JSON.stringify(storage.value)).not.toContain("Betrayer");
  });

  it("blocks wrong-seat private updates and reveals only after privacy confirmation", async () => {
    const { model, transport } = fixture();
    await model.join("GHST27");
    approve(transport);
    privateUpdate(transport, 3);
    expect(JSON.stringify(model.snapshot())).not.toContain("Synthetic secret objective");
    privateUpdate(transport, 2);
    expect(model.snapshot().privateView).toEqual({});
    model.revealPrivate();
    expect(JSON.stringify(model.snapshot().privateView)).toContain("Synthetic secret objective");
    model.obscurePrivate();
    expect(JSON.stringify(model.snapshot())).not.toContain("Synthetic secret objective");
  });

  it("submits bounded prompt/action intents and handles acknowledgement", async () => {
    const { model, transport } = fixture();
    await model.join("GHST27");
    approve(transport);
    privateUpdate(transport);
    model.revealPrivate();
    model.submitPrompt(["listen"]);
    model.submitRoleAction("synthetic_action", []);
    expect(transport.sent).toHaveLength(2);
    expect(transport.sent[0]).toMatchObject({ messageType: "prompt_choice_submit", seatClaim: 2, authoritativeRevision: 7 });
    expect(transport.sent[1]).toMatchObject({ messageType: "role_action_submit", seatClaim: 2 });
    transport.receive(createEnvelope("room_1", "acknowledgement", "client_1", { relayAccepted: true }, {
      seatClaim: 2,
      acknowledgement: "accepted",
      authoritativeRevision: 7,
    }));
    expect(model.snapshot()).toMatchObject({ lastAcknowledgement: "relayed", phase: "submitting" });
    expect(model.snapshot().status).toContain("authoritative native host");
    transport.receive(createEnvelope("room_1", "acknowledgement", "client_2", { resultingRevision: 8 }, {
      seatClaim: 2,
      acknowledgement: "accepted",
      authoritativeRevision: 8,
    }));
    expect(model.snapshot()).toMatchObject({ lastAcknowledgement: "accepted" });
    expect(model.snapshot().status).toContain("authoritative host");
  });

  it("disconnects, resumes the same stable seat, and clears explicitly", async () => {
    const { model, transport, storage } = fixture();
    await model.join("GHST27");
    approve(transport);
    privateUpdate(transport);
    model.revealPrivate();
    model.disconnectForReconnect();
    expect(JSON.stringify(model.snapshot())).not.toContain("Synthetic secret objective");
    await model.resume();
    expect(transport.connections[1]).toEqual({
      roomCode: "GHST27",
      authentication: {
        operation: "resume",
        clientId: "browser_synthetic",
        seatClaim: 2,
        resumeCapability: "synthetic_resume_capability",
      },
    });
    transport.receive(createEnvelope("room_1", "reconnect_resume", "resume_1", { restored: true }, { seatClaim: 2 }));
    expect(model.snapshot()).toMatchObject({ phase: "privacy_gate", seatClaim: 2 });
    model.leaveAndClear();
    expect(storage.value).toBeNull();
    expect(model.snapshot()).toMatchObject({ phase: "idle", seatClaim: 0, roomCode: "" });
  });

  it("returns safely disconnected on expiry and unsupported service responses", async () => {
    const { model, transport, storage } = fixture();
    await model.join("GHST27");
    approve(transport);
    transport.receive(createEnvelope("room_1", "room_expired", "expiry_1", { reason: "inactive" }, { acknowledgement: "expired" }));
    expect(model.snapshot()).toMatchObject({ phase: "disconnected", privateVisible: false });
    expect(storage.value).toBeNull();
    transport.receive({ accepted: false, code: "unsupported_version" });
    expect(model.snapshot().status).toContain("not supported");
  });
});

describe("browser companion privacy and accessibility DOM", () => {
  it("never leaves secret content in the DOM while obscured", async () => {
    document.body.innerHTML = '<main id="test-root"></main>';
    const root = document.querySelector<HTMLElement>("#test-root");
    if (!root) throw new Error("missing test root");
    const { model, transport } = fixture();
    mountCompanionApp(root, model);
    await model.join("GHST27");
    approve(transport);
    privateUpdate(transport);
    expect(root.textContent).not.toContain("Synthetic secret objective");
    model.revealPrivate();
    expect(root.textContent).toContain("Synthetic secret objective");
    root.querySelector<HTMLButtonElement>("#obscure-button")?.click();
    expect(root.textContent).not.toContain("Synthetic secret objective");
    expect(root.innerHTML).not.toContain("synthetic_resume_capability");
  });

  it("provides semantic labels, keyboard buttons, live status, and touch-sized contracts", () => {
    document.body.innerHTML = '<main id="test-root"></main>';
    const root = document.querySelector<HTMLElement>("#test-root");
    if (!root) throw new Error("missing test root");
    mountCompanionApp(root, fixture().model);
    expect(root.querySelector('label[for="room-code"]')).not.toBeNull();
    expect(root.querySelector('[role="status"][aria-live="polite"]')).not.toBeNull();
    for (const button of root.querySelectorAll("button")) expect(["button", "submit"]).toContain(button.getAttribute("type"));
    const css = readFileSync("web/companion/src/styles.css", "utf8");
    expect(css).toContain("min-height: 48px");
    expect(css).toContain("@media (max-width: 430px)");
    expect(css).toContain("@media (prefers-reduced-motion: reduce)");
    const appSource = readFileSync("web/companion/src/app.ts", "utf8");
    expect(appSource).not.toContain("serviceWorker");
    expect(appSource).not.toContain("Notification");
  });

  it("does not retain hidden-board text from unauthorized, error, acknowledgement, or reconnect paths", async () => {
    const hidden = ["sealed_archive", "The Sealed Archive", "Sealed Archive", "sealed_shelves", "archive_route", "archive_stairs"];
    const { model, transport, storage } = fixture();
    await model.join("GHST27");
    approve(transport);
    transport.receive(createEnvelope("room_1", "public_view_update", "public_safe", {
      board: {
        spaces: ["lantern_hall", "gate_passage", "narrow_gallery", "flooded_vault"].map((id) => ({ id })),
      },
    }, { authoritativeRevision: 7 }));
    transport.receive(createEnvelope("room_1", "seat_private_view_update", "wrong_hidden", {
      socialPrivate: { note: hidden.join("|") },
    }, { seatClaim: 3, authoritativeRevision: 7 }));
    transport.receive(createEnvelope("room_1", "rejection", "rejected_hidden", {
      currentRevision: 7,
      refreshRequired: false,
    }, { seatClaim: 2, acknowledgement: "unauthorized", authoritativeRevision: 7 }));
    transport.receive(createEnvelope("room_1", "acknowledgement", "ack_hidden", {
      resultingRevision: 7,
      appliedOnce: true,
      authorityResult: "accepted",
    }, { seatClaim: 2, acknowledgement: "accepted", authoritativeRevision: 7 }));
    model.disconnectForReconnect();
    await model.resume();
    transport.receive(createEnvelope("room_1", "reconnect_resume", "resume_safe", { restored: true }, { seatClaim: 2 }));
    const retained = JSON.stringify({ snapshot: model.snapshot(), stored: storage.value });
    for (const term of hidden) expect(retained.toLowerCase()).not.toContain(term.toLowerCase());
    expect(readFileSync("web/companion/src/transport.ts", "utf8")).not.toContain("console.log");
  });
});
