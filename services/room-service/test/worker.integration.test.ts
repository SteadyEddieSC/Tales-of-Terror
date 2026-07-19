import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { unstable_dev, type Unstable_DevWorker } from "wrangler";
import { createEnvelope } from "../src/protocol";

interface CreatedRoom {
  readonly roomId: string;
  readonly joinCode: string;
  readonly hostCapability: string;
}

class SocketInbox {
  readonly socket: WebSocket;
  private readonly messages: unknown[] = [];

  private constructor(socket: WebSocket) {
    this.socket = socket;
    socket.addEventListener("message", (event) => {
      try { this.messages.push(JSON.parse(String(event.data)) as unknown); } catch { this.messages.push({ code: "malformed" }); }
    });
  }

  static async join(baseUrl: string, roomCode: string, clientId: string): Promise<SocketInbox> {
    const socket = new WebSocket(`${baseUrl.replace("http://", "ws://")}/v1/rooms/${roomCode}/socket`);
    const inbox = new SocketInbox(socket);
    await new Promise<void>((resolve, reject) => {
      socket.addEventListener("open", () => resolve(), { once: true });
      socket.addEventListener("error", () => reject(new Error("websocket_open_failed")), { once: true });
    });
    socket.send(JSON.stringify({ operation: "join", clientId }));
    await inbox.next((value) => isRecord(value) && value.accepted === true);
    return inbox;
  }

  async next(predicate: (value: unknown) => boolean, timeoutMs = 2_000): Promise<unknown> {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
      const index = this.messages.findIndex(predicate);
      if (index >= 0) return this.messages.splice(index, 1)[0];
      await delay(5);
    }
    throw new Error(`socket_message_timeout:${JSON.stringify(this.messages)}`);
  }

  close(): void {
    if (this.socket.readyState === WebSocket.OPEN) this.socket.close(1000, "test_complete");
  }
}

let worker: Unstable_DevWorker;
let baseUrl: string;

beforeAll(async () => {
  worker = await unstable_dev("services/room-service/src/worker.ts", {
    config: "services/room-service/wrangler.jsonc",
    local: true,
    persist: false,
    logLevel: "none",
    vars: {
      ALLOWED_ORIGINS: "http://127.0.0.1:4173,http://localhost:4173",
      ROOM_IDLE_EXPIRY_MS: "100",
      ROOM_HOST_LOSS_GRACE_MS: "160",
      ROOM_RATE_WINDOW_MS: "40",
      ROOM_ACKNOWLEDGEMENT_EXPIRY_MS: "80",
      ROOM_MAX_MESSAGES_PER_WINDOW: "2",
    },
    experimental: { disableExperimentalWarning: true, disableDevRegistry: true },
  });
  baseUrl = `http://${worker.address}:${worker.port}`;
}, 60_000);

afterAll(async () => {
  await worker?.stop();
});

async function createRoom(): Promise<CreatedRoom> {
  const response = await fetch(`${baseUrl}/v1/rooms`, { method: "POST" });
  expect(response.status).toBe(201);
  return await response.json() as CreatedRoom;
}

async function host(room: CreatedRoom, body: Readonly<Record<string, unknown>>): Promise<Response> {
  return fetch(`${baseUrl}/v1/rooms/host`, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${room.hostCapability}` },
    body: JSON.stringify({ joinCode: room.joinCode, ...body }),
  });
}

async function approve(room: CreatedRoom, inbox: SocketInbox, clientId = "client_1"): Promise<Record<string, unknown>> {
  const response = await host(room, { operation: "approve", clientId, seatClaim: 1 });
  expect(response.status).toBe(200);
  const approval = await inbox.next((value) => isRecord(value) && value.messageType === "seat_claim_approved");
  if (!isRecord(approval)) throw new Error("malformed_seat_approval");
  return approval;
}

describe("Worker and Durable Object elapsed-time integration", () => {
  it("recovers a rate-limited client after the real configured window", async () => {
    const room = await createRoom();
    const inbox = await SocketInbox.join(baseUrl, room.joinCode, "client_rate");
    await approve(room, inbox, "client_rate");
    for (let index = 1; index <= 2; index += 1) {
      inbox.socket.send(JSON.stringify(createEnvelope(room.roomId, "private_reveal_ack", `rate_${index}`, {}, { seatClaim: 1 })));
      await inbox.next((value) => isRecord(value) && value.messageType === "acknowledgement" && value.requestId === `rate_${index}`);
    }
    inbox.socket.send(JSON.stringify(createEnvelope(room.roomId, "private_reveal_ack", "rate_3", {}, { seatClaim: 1 })));
    await expect(inbox.next((value) => isRecord(value) && value.code === "rate_limited")).resolves.toBeDefined();
    await delay(45);
    inbox.socket.send(JSON.stringify(createEnvelope(room.roomId, "private_reveal_ack", "rate_4", {}, { seatClaim: 1 })));
    await expect(inbox.next((value) => isRecord(value) && value.messageType === "acknowledgement" && value.requestId === "rate_4")).resolves.toBeDefined();
    inbox.close();
  });

  it("preserves a room with valid host heartbeats", async () => {
    const room = await createRoom();
    await delay(70);
    expect((await host(room, { operation: "heartbeat" })).status).toBe(200);
    await delay(70);
    const diagnostics = await host(room, { operation: "diagnostics" });
    expect(diagnostics.status).toBe(200);
    await expect(diagnostics.json()).resolves.toMatchObject({ accepted: true, diagnostics: { roomState: "open", hostPresent: true } });
  });

  it("does not let active client traffic prevent host-loss expiry", async () => {
    const room = await createRoom();
    const inbox = await SocketInbox.join(baseUrl, room.joinCode, "client_active");
    const approval = await approve(room, inbox, "client_active");
    const approvalPayload = isRecord(approval.payload) ? approval.payload : {};
    const resumeCapability = typeof approvalPayload.resumeCapability === "string" ? approvalPayload.resumeCapability : "";
    expect(resumeCapability).not.toBe("");
    for (let index = 0; index < 4; index += 1) {
      await delay(35);
      if (inbox.socket.readyState !== WebSocket.OPEN) break;
      inbox.socket.send(JSON.stringify(createEnvelope(room.roomId, "private_reveal_ack", `traffic_${index}`, {}, { seatClaim: 1 })));
    }
    await delay(40);
    const response = await host(room, { operation: "diagnostics" });
    expect(response.status).toBe(410);
    inbox.close();
    const expiredResume = new WebSocket(`${baseUrl.replace("http://", "ws://")}/v1/rooms/${room.joinCode}/socket`);
    await new Promise<void>((resolve) => expiredResume.addEventListener("open", () => resolve(), { once: true }));
    expiredResume.send(JSON.stringify({ operation: "resume", clientId: "client_active", seatClaim: 1, resumeCapability }));
    await new Promise<void>((resolve) => expiredResume.addEventListener("message", (event) => {
      expect(JSON.parse(String(event.data))).toMatchObject({ accepted: false, code: "expired" });
      resolve();
    }, { once: true }));
    expiredResume.close();
  });

  it("expires an ordinarily inactive room", async () => {
    const room = await createRoom();
    await delay(115);
    const response = await host(room, { operation: "diagnostics" });
    expect(response.status).toBe(410);
  });

  it("clears ephemeral membership and capabilities on explicit close", async () => {
    const room = await createRoom();
    const inbox = await SocketInbox.join(baseUrl, room.joinCode, "client_close");
    await approve(room, inbox, "client_close");
    expect((await host(room, { operation: "close" })).status).toBe(200);
    await expect(inbox.next((value) => isRecord(value) && value.messageType === "room_closed")).resolves.toBeDefined();
    expect((await host(room, { operation: "diagnostics" })).status).toBe(410);
    const reconnect = new WebSocket(`${baseUrl.replace("http://", "ws://")}/v1/rooms/${room.joinCode}/socket`);
    await new Promise<void>((resolve) => reconnect.addEventListener("open", () => resolve(), { once: true }));
    reconnect.send(JSON.stringify({ operation: "resume", clientId: "client_close", seatClaim: 1, resumeCapability: "expired" }));
    await new Promise<void>((resolve) => reconnect.addEventListener("message", (event) => {
      expect(JSON.parse(String(event.data))).toMatchObject({ accepted: false, code: "expired" });
      resolve();
    }, { once: true }));
    reconnect.close();
  });

  it("restores a live persisted room and fails closed after host loss across reload", async () => {
    const persistencePath = await mkdtemp(join(tmpdir(), "terror-turn-room-reload-"));
    let restarted: Unstable_DevWorker | undefined;
    const start = (): Promise<Unstable_DevWorker> => unstable_dev("services/room-service/src/worker.ts", {
      config: "services/room-service/wrangler.jsonc",
      local: true,
      persist: true,
      persistTo: persistencePath,
      logLevel: "none",
      vars: {
        ALLOWED_ORIGINS: "http://127.0.0.1:4173,http://localhost:4173",
        ROOM_IDLE_EXPIRY_MS: "10000",
        ROOM_HOST_LOSS_GRACE_MS: "5000",
      },
      experimental: { disableExperimentalWarning: true, disableDevRegistry: true },
    });
    try {
      restarted = await start();
      const restartedBase = `http://${restarted.address}:${restarted.port}`;
      const room = await (await fetch(`${restartedBase}/v1/rooms`, { method: "POST" })).json() as CreatedRoom;
      await restarted.stop();
      restarted = undefined;

      await delay(35);
      restarted = await start();
      const liveBase = `http://${restarted.address}:${restarted.port}`;
      const live = await fetch(`${liveBase}/v1/rooms/host`, {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${room.hostCapability}` },
        body: JSON.stringify({ joinCode: room.joinCode, operation: "diagnostics" }),
      });
      expect(live.status).toBe(200);
      await restarted.stop();
      restarted = undefined;

      await delay(5100);
      restarted = await start();
      const expiredBase = `http://${restarted.address}:${restarted.port}`;
      const expired = await fetch(`${expiredBase}/v1/rooms/host`, {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${room.hostCapability}` },
        body: JSON.stringify({ joinCode: room.joinCode, operation: "diagnostics" }),
      });
      expect(expired.status).toBe(410);
    } finally {
      await restarted?.stop();
      await rm(persistencePath, { recursive: true, force: true });
    }
  }, 30_000);
});

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}
