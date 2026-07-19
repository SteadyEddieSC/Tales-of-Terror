import { DEFAULT_LIMITS, EphemeralRoom, type EphemeralRoomSnapshot, type RoomLimits } from "./room-coordinator";
import { MAX_MESSAGE_BYTES, parseEnvelope, SERVICE_VERSION } from "./protocol";

interface Env {
  readonly GAME_ROOMS: DurableObjectNamespace;
  readonly ALLOWED_ORIGINS: string;
  readonly ROOM_IDLE_EXPIRY_MS?: string;
  readonly ROOM_HOST_LOSS_GRACE_MS?: string;
  readonly ROOM_RATE_WINDOW_MS?: string;
  readonly ROOM_ACKNOWLEDGEMENT_EXPIRY_MS?: string;
  readonly ROOM_MAX_MESSAGES_PER_WINDOW?: string;
}

interface SocketAttachment {
  clientId: string;
  authenticated: boolean;
}

const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
  "x-content-type-options": "nosniff",
  "referrer-policy": "no-referrer",
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const originResponse = checkOrigin(request, env.ALLOWED_ORIGINS);
    if (originResponse) return originResponse;
    if (request.method === "OPTIONS") return corsResponse(request, env.ALLOWED_ORIGINS, new Response(null, { status: 204 }));
    const url = new URL(request.url);
    let response: Response;
    if (request.method === "GET" && url.pathname === "/v1/health") {
      response = responseJson({ status: "ok", serviceVersion: SERVICE_VERSION });
    } else if (request.method === "POST" && url.pathname === "/v1/rooms") {
      response = await createRoom(env);
    } else if (request.method === "POST" && url.pathname === "/v1/rooms/join") {
      response = await forwardByBody(request, env, "/join");
    } else if (request.method === "POST" && url.pathname === "/v1/rooms/host") {
      response = await forwardByBody(request, env, "/host");
    } else {
      const socketMatch = url.pathname.match(/^\/v1\/rooms\/([A-Z2-9]{4,8})\/socket$/);
      if (request.method === "GET" && socketMatch?.[1]) {
        const stub = env.GAME_ROOMS.get(env.GAME_ROOMS.idFromName(socketMatch[1]));
        response = await stub.fetch(new Request("https://room.internal/socket", request));
      } else {
        response = responseJson({ accepted: false, code: "not_found" }, 404);
      }
    }
    // A 101 response carries a Workers WebSocket endpoint that cannot be
    // reconstructed by the CORS wrapper without dropping the socket handle.
    if (response.status === 101) return response;
    return corsResponse(request, env.ALLOWED_ORIGINS, response);
  },
};

export class GameRoom implements DurableObject {
  private room: EphemeralRoom | undefined;
  private readonly sockets = new Map<WebSocket, SocketAttachment>();
  private readonly ready: Promise<void>;

  constructor(private readonly state: DurableObjectState) {
    this.ready = state.blockConcurrencyWhile(async () => {
      const snapshot = await state.storage.get<EphemeralRoomSnapshot>("room");
      if (!snapshot) return;
      try {
        const restored = EphemeralRoom.restore(snapshot);
        if (restored.nextExpiryAtMs() === undefined) {
          await state.storage.deleteAlarm();
          await state.storage.deleteAll();
        } else {
          this.room = restored;
        }
      } catch {
        this.room = undefined;
        await state.storage.deleteAlarm();
        await state.storage.deleteAll();
      }
    });
  }

  async fetch(request: Request): Promise<Response> {
    await this.ready;
    const url = new URL(request.url);
    await this.expireIfDue();
    if (url.pathname === "/create" && request.method === "POST") return this.create(request);
    if (url.pathname === "/join" && request.method === "POST") return this.join(request);
    if (url.pathname === "/host" && request.method === "POST") return this.host(request);
    if (url.pathname === "/socket" && request.headers.get("upgrade")?.toLowerCase() === "websocket") return this.socket();
    return responseJson({ accepted: false, code: "not_found" }, 404);
  }

  async webSocketMessage(socket: WebSocket, message: string | ArrayBuffer): Promise<void> {
    const raw = typeof message === "string" ? message : new TextDecoder().decode(message);
    if (await this.expireIfDue()) {
      socket.close(4000, "room_expired");
      return;
    }
    if (!this.room) {
      socket.send(JSON.stringify({ accepted: false, code: "expired" }));
      return;
    }
    if (new TextEncoder().encode(raw).byteLength > MAX_MESSAGE_BYTES) {
      socket.send(JSON.stringify({ accepted: false, code: "malformed" }));
      return;
    }
    const attachment = this.sockets.get(socket);
    if (!attachment?.authenticated) {
      await this.authenticateSocket(socket, raw);
      return;
    }
    const result = this.room.relayClientRaw(attachment.clientId, raw);
    await this.persistRoom();
    socket.send(JSON.stringify(publicResult(result)));
    this.flushSocketClient(socket, attachment.clientId);
  }

  async webSocketClose(socket: WebSocket): Promise<void> {
    const attachment = this.sockets.get(socket);
    if (attachment?.authenticated && this.room) this.room.disconnect(attachment.clientId);
    this.sockets.delete(socket);
    await this.persistRoom();
  }

  webSocketError(socket: WebSocket): void {
    void this.webSocketClose(socket);
  }

  async alarm(): Promise<void> {
    if (!await this.expireIfDue()) this.scheduleExpiry();
  }

  private async create(request: Request): Promise<Response> {
    const code = request.headers.get("x-room-code") ?? "";
    if (this.room?.diagnostics().roomState === "open") return responseJson({ accepted: false, code: "collision" }, 409);
    try {
      this.room = new EphemeralRoom(`room_${code.toLowerCase()}`, code, undefined, limitsFromHeaders(request.headers));
      await this.persistRoom();
      this.scheduleExpiry();
      const payload = {
        accepted: true,
        roomId: this.room.roomId,
        joinCode: this.room.joinCode,
        hostCapability: this.room.hostCapability,
        serviceVersion: SERVICE_VERSION,
      };
      return responseJson(payload, 201);
    } catch {
      return responseJson({ accepted: false, code: "malformed" }, 400);
    }
  }

  private async join(request: Request): Promise<Response> {
    if (!this.room) return responseJson({ accepted: false, code: "expired" }, 410);
    const body = await boundedJson(request);
    if (!body || typeof body.clientId !== "string") return responseJson({ accepted: false, code: "malformed" }, 400);
    const result = this.room.join(body.clientId);
    if (result.accepted) {
      await this.persistRoom();
      this.scheduleExpiry();
    }
    return responseJson(publicResult(result), result.accepted ? 202 : statusFor(result.code));
  }

  private async host(request: Request): Promise<Response> {
    if (!this.room) return responseJson({ accepted: false, code: "expired" }, 410);
    const capability = bearer(request);
    const body = await boundedJson(request);
    if (!body || typeof body.operation !== "string") return responseJson({ accepted: false, code: "malformed" }, 400);
    let result;
    switch (body.operation) {
      case "approve":
        result = typeof body.clientId === "string" && typeof body.seatClaim === "number"
          ? this.room.approveClaim(capability, body.clientId, body.seatClaim)
          : { accepted: false as const, code: "malformed" as const };
        break;
      case "deny":
        result = typeof body.clientId === "string"
          ? this.room.denyClaim(capability, body.clientId)
          : { accepted: false as const, code: "malformed" as const };
        break;
      case "revoke":
        result = typeof body.clientId === "string"
          ? this.room.revokeClaim(capability, body.clientId)
          : { accepted: false as const, code: "malformed" as const };
        break;
      case "heartbeat":
        result = this.room.heartbeat(capability);
        if (result.accepted) this.scheduleExpiry();
        break;
      case "close":
        result = this.room.close(capability);
        if (result.accepted) {
          for (const [socket, attachment] of this.sockets) {
            if (attachment.authenticated && result.envelope) socket.send(JSON.stringify(result.envelope));
            socket.close(4001, "room_closed");
          }
          this.room = undefined;
          await this.state.storage.deleteAlarm();
          await this.state.storage.deleteAll();
        }
        break;
      case "drain": {
        const messages = this.room.drainHostInbox(capability);
        await this.persistRoom();
        return responseJson({ accepted: messages.length > 0 || capability === this.room.hostCapability, messages });
      }
      case "diagnostics":
        if (capability !== this.room.hostCapability) return responseJson({ accepted: false, code: "unauthorized" }, 403);
        return responseJson({ accepted: true, diagnostics: this.room.diagnostics() });
      case "relay": {
        if (typeof body.clientId !== "string" || typeof body.envelope !== "string") {
          result = { accepted: false as const, code: "malformed" as const };
          break;
        }
        const parsed = parseEnvelope(body.envelope);
        result = parsed.accepted && parsed.envelope
          ? this.room.relayHostEnvelope(capability, body.clientId, parsed.envelope)
          : { accepted: false as const, code: parsed.code };
        break;
      }
      default:
        result = { accepted: false as const, code: "unsupported_type" as const };
    }
    if (result.accepted) {
      if (body.operation !== "close") {
        await this.persistRoom();
        this.scheduleExpiry();
      }
      if (
        typeof body.clientId === "string"
        && ["approve", "deny", "revoke", "relay"].includes(body.operation)
      ) {
        this.flushConnectedClient(body.clientId);
      }
    }
    return responseJson(publicResult(result), result.accepted ? 200 : statusFor(result.code));
  }

  private socket(): Response {
    const pair = new WebSocketPair();
    const client = pair[0];
    const server = pair[1];
    server.accept();
    this.sockets.set(server, { clientId: "", authenticated: false });
    server.addEventListener("message", (event) => void this.webSocketMessage(server, event.data));
    server.addEventListener("close", () => void this.webSocketClose(server));
    server.addEventListener("error", () => this.webSocketError(server));
    return new Response(null, { status: 101, webSocket: client });
  }

  private async authenticateSocket(socket: WebSocket, raw: string): Promise<void> {
    let value: unknown;
    try {
      value = JSON.parse(raw);
    } catch {
      socket.send(JSON.stringify({ accepted: false, code: "malformed" }));
      return;
    }
    if (!isRecord(value) || typeof value.operation !== "string" || typeof value.clientId !== "string") {
      socket.send(JSON.stringify({ accepted: false, code: "malformed" }));
      return;
    }
    let result;
    if (value.operation === "join") {
      result = this.room?.join(value.clientId) ?? { accepted: false as const, code: "expired" as const };
    } else if (value.operation === "resume" && typeof value.seatClaim === "number" && typeof value.resumeCapability === "string") {
      result = this.room?.resume(value.clientId, value.seatClaim, value.resumeCapability) ?? { accepted: false as const, code: "expired" as const };
    } else {
      result = { accepted: false as const, code: "malformed" as const };
    }
    socket.send(JSON.stringify(publicResult(result)));
    if (result.accepted) {
      this.sockets.set(socket, { clientId: value.clientId, authenticated: true });
      await this.persistRoom();
      this.scheduleExpiry();
      this.flushSocketClient(socket, value.clientId);
    }
  }

  private flushSocketClient(socket: WebSocket, clientId: string): void {
    for (const envelope of this.room?.drainClientInbox(clientId) ?? []) socket.send(JSON.stringify(envelope));
  }

  private flushConnectedClient(clientId: string): void {
    for (const [socket, attachment] of this.sockets) {
      if (attachment?.authenticated && attachment.clientId === clientId) {
        this.flushSocketClient(socket, clientId);
        return;
      }
    }
  }

  private scheduleExpiry(): void {
    const deadline = this.room?.nextExpiryAtMs();
    if (deadline !== undefined) void this.state.storage.setAlarm(Math.max(Date.now() + 1, deadline));
  }

  private async persistRoom(): Promise<void> {
    if (this.room) await this.state.storage.put("room", this.room.snapshot());
  }

  private async expireIfDue(): Promise<boolean> {
    const envelope = this.room?.updateTime();
    if (!envelope) return false;
    for (const socket of this.sockets.keys()) {
      socket.send(JSON.stringify(envelope));
      socket.close(4000, "room_expired");
    }
    this.sockets.clear();
    this.room = undefined;
    await this.state.storage.deleteAlarm();
    await this.state.storage.deleteAll();
    return true;
  }
}

async function createRoom(env: Env): Promise<Response> {
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const code = randomJoinCode();
    const stub = env.GAME_ROOMS.get(env.GAME_ROOMS.idFromName(code));
    const limits = limitsFromEnv(env);
    const headers = new Headers({ "x-room-code": code });
    headers.set("x-room-idle-expiry-ms", String(limits.idleExpiryMs));
    headers.set("x-room-host-loss-grace-ms", String(limits.hostLossGraceMs));
    headers.set("x-room-rate-window-ms", String(limits.rateWindowMs));
    headers.set("x-room-acknowledgement-expiry-ms", String(limits.acknowledgementExpiryMs));
    headers.set("x-room-max-messages-per-window", String(limits.maxMessagesPerWindow));
    const response = await stub.fetch("https://room.internal/create", { method: "POST", headers });
    if (response.status !== 409) return response;
  }
  return responseJson({ accepted: false, code: "collision_limit" }, 503);
}

async function forwardByBody(request: Request, env: Env, path: string): Promise<Response> {
  const raw = await request.text();
  if (new TextEncoder().encode(raw).byteLength > MAX_MESSAGE_BYTES) return responseJson({ accepted: false, code: "body_too_large" }, 413);
  let body: unknown;
  try {
    body = JSON.parse(raw);
  } catch {
    return responseJson({ accepted: false, code: "malformed" }, 400);
  }
  if (!isRecord(body) || typeof body.joinCode !== "string" || !/^[A-Z2-9]{4,8}$/.test(body.joinCode)) {
    return responseJson({ accepted: false, code: "malformed" }, 400);
  }
  const stub = env.GAME_ROOMS.get(env.GAME_ROOMS.idFromName(body.joinCode));
  const headers = new Headers({ "content-type": "application/json" });
  const authorization = request.headers.get("authorization");
  if (authorization) headers.set("authorization", authorization);
  return stub.fetch(`https://room.internal${path}`, { method: "POST", headers, body: raw });
}

async function boundedJson(request: Request): Promise<Record<string, unknown> | null> {
  const raw = await request.text();
  if (new TextEncoder().encode(raw).byteLength > MAX_MESSAGE_BYTES) return null;
  try {
    const value: unknown = JSON.parse(raw);
    return isRecord(value) ? value : null;
  } catch {
    return null;
  }
}

function publicResult(result: { accepted: boolean; code: string; envelope?: unknown }): Record<string, unknown> {
  return { accepted: result.accepted, code: result.code, ...(result.envelope === undefined ? {} : { envelope: result.envelope }) };
}

function randomJoinCode(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = new Uint8Array(6);
  crypto.getRandomValues(bytes);
  return [...bytes].map((value) => alphabet[value % alphabet.length] ?? "A").join("");
}

function bearer(request: Request): string {
  const value = request.headers.get("authorization") ?? "";
  return value.startsWith("Bearer ") ? value.slice(7) : "";
}

function responseJson(value: unknown, status = 200): Response {
  return new Response(JSON.stringify(value), { status, headers: jsonHeaders });
}

function statusFor(code: string): number {
  if (code === "expired" || code === "host_missing") return 410;
  if (code === "room_full" || code === "duplicate") return 409;
  if (code === "rate_limited") return 429;
  if (code === "body_too_large") return 413;
  if (code === "malformed" || code === "unsupported_type" || code === "unsupported_version") return 400;
  return 403;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function checkOrigin(request: Request, allowed: string): Response | null {
  const origin = request.headers.get("origin");
  if (!origin) return null;
  const allowedOrigins = allowed.split(",").map((value) => value.trim()).filter(Boolean);
  return allowedOrigins.includes(origin) ? null : responseJson({ accepted: false, code: "origin_denied" }, 403);
}

function corsResponse(request: Request, allowed: string, response: Response): Response {
  const origin = request.headers.get("origin");
  if (!origin || !allowed.split(",").map((value) => value.trim()).includes(origin)) return response;
  const headers = new Headers(response.headers);
  headers.set("access-control-allow-origin", origin);
  headers.set("access-control-allow-methods", "GET,POST,OPTIONS");
  headers.set("access-control-allow-headers", "authorization,content-type");
  headers.set("vary", "Origin");
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

function limitsFromEnv(env: Env): RoomLimits {
  return {
    ...DEFAULT_LIMITS,
    idleExpiryMs: boundedInteger(env.ROOM_IDLE_EXPIRY_MS, DEFAULT_LIMITS.idleExpiryMs),
    hostLossGraceMs: boundedInteger(env.ROOM_HOST_LOSS_GRACE_MS, DEFAULT_LIMITS.hostLossGraceMs),
    rateWindowMs: boundedInteger(env.ROOM_RATE_WINDOW_MS, DEFAULT_LIMITS.rateWindowMs),
    acknowledgementExpiryMs: boundedInteger(env.ROOM_ACKNOWLEDGEMENT_EXPIRY_MS, DEFAULT_LIMITS.acknowledgementExpiryMs),
    maxMessagesPerWindow: boundedInteger(env.ROOM_MAX_MESSAGES_PER_WINDOW, DEFAULT_LIMITS.maxMessagesPerWindow, 1, 128),
  };
}

function limitsFromHeaders(headers: Headers): RoomLimits {
  return {
    ...DEFAULT_LIMITS,
    idleExpiryMs: boundedInteger(headers.get("x-room-idle-expiry-ms"), DEFAULT_LIMITS.idleExpiryMs),
    hostLossGraceMs: boundedInteger(headers.get("x-room-host-loss-grace-ms"), DEFAULT_LIMITS.hostLossGraceMs),
    rateWindowMs: boundedInteger(headers.get("x-room-rate-window-ms"), DEFAULT_LIMITS.rateWindowMs),
    acknowledgementExpiryMs: boundedInteger(headers.get("x-room-acknowledgement-expiry-ms"), DEFAULT_LIMITS.acknowledgementExpiryMs),
    maxMessagesPerWindow: boundedInteger(headers.get("x-room-max-messages-per-window"), DEFAULT_LIMITS.maxMessagesPerWindow, 1, 128),
  };
}

function boundedInteger(value: string | null | undefined, fallback: number, minimum = 10, maximum = 24 * 60 * 60_000): number {
  if (!value || !/^\d+$/.test(value)) return fallback;
  const parsed = Number(value);
  return Number.isSafeInteger(parsed) && parsed >= minimum && parsed <= maximum ? parsed : fallback;
}
