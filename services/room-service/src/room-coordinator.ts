import {
  createEnvelope,
  parseEnvelope,
  PROTOCOL_VERSION,
  SERVICE_VERSION,
  validateEnvelope,
  type JsonValue,
  type ProtocolEnvelope,
  type RejectionCode,
} from "./protocol";

export interface RoomLimits {
  readonly maxClients: number;
  readonly maxPendingClients: number;
  readonly maxQueueDepth: number;
  readonly maxAckCache: number;
  readonly idleExpiryMs: number;
  readonly hostLossGraceMs: number;
  readonly rateWindowMs: number;
  readonly acknowledgementExpiryMs: number;
  readonly maxMessagesPerWindow: number;
}

export const DEFAULT_LIMITS: RoomLimits = {
  maxClients: 8,
  maxPendingClients: 8,
  maxQueueDepth: 32,
  maxAckCache: 32,
  idleExpiryMs: 10 * 60_000,
  hostLossGraceMs: 30_000,
  rateWindowMs: 1_000,
  acknowledgementExpiryMs: 2 * 60_000,
  maxMessagesPerWindow: 16,
};

export interface RoomResult {
  readonly accepted: boolean;
  readonly code: "accepted" | RejectionCode;
  readonly envelope?: ProtocolEnvelope;
}

interface CachedAcknowledgement {
  readonly envelope: ProtocolEnvelope;
  readonly cachedAtMs: number;
}

interface ClientRecord {
  readonly clientId: string;
  pending: boolean;
  connected: boolean;
  revoked: boolean;
  seatClaim: number;
  resumeCapability: string;
  lastSeenAtMs: number;
  rateWindowStartedAtMs: number;
  rateCount: number;
  readonly inbox: ProtocolEnvelope[];
  readonly acknowledgementCache: Map<string, CachedAcknowledgement>;
  readonly acknowledgementOrder: string[];
}

interface SnapshotClient extends Omit<ClientRecord, "acknowledgementCache"> {
  readonly acknowledgementCache: ReadonlyArray<readonly [string, CachedAcknowledgement]>;
}

export interface EphemeralRoomSnapshot {
  readonly snapshotVersion: 2;
  readonly roomId: string;
  readonly joinCode: string;
  readonly limits: RoomLimits;
  readonly hostCapability: string;
  readonly clients: readonly SnapshotClient[];
  readonly hostInbox: readonly ProtocolEnvelope[];
  readonly sequence: number;
  readonly currentTimeMs: number;
  readonly lastActivityAtMs: number;
  readonly lastHostAtMs: number;
  readonly state: "open" | "closed" | "expired";
  readonly capabilityOrdinal: number;
  readonly lastMessageType: string;
  readonly lastRequestDisplay: string;
  readonly lastResult: string;
  readonly counters: Readonly<Record<string, number>>;
}

export interface SanitizedRoomDiagnostics {
  readonly protocolVersion: number;
  readonly serviceVersion: string;
  readonly roomState: "open" | "closed" | "expired";
  readonly roomCode: string;
  readonly elapsedMs: number;
  readonly inactivityExpiryInMs: number;
  readonly hostLossExpiryInMs: number;
  readonly hostPresent: boolean;
  readonly connectedClients: number;
  readonly pendingClients: number;
  readonly claimedSeats: number[];
  readonly sequence: number;
  readonly queueDepth: number;
  readonly lastMessageType: string;
  readonly lastRequestDisplay: string;
  readonly lastResult: string;
  readonly counters: Readonly<Record<string, number>>;
  readonly privacy: "no_capabilities_no_payloads";
}

export type CapabilityFactory = (scope: "host" | "resume", ordinal: number) => string;
export type MonotonicClock = () => number;

const clientIdPattern = /^[a-z0-9][a-z0-9_-]{0,63}$/;
const intentTypes = new Set(["prompt_choice_submit", "role_action_submit", "private_reveal_ack"]);
const hostRelayTypes = new Set(["public_view_update", "seat_private_view_update", "faction_private_view_update", "acknowledgement", "rejection"]);

export class EphemeralRoom {
  readonly roomId: string;
  readonly joinCode: string;
  readonly limits: RoomLimits;
  private hostCapabilityValue: string;
  private readonly capabilityFactory: CapabilityFactory;
  private readonly clock: MonotonicClock;
  private readonly clients = new Map<string, ClientRecord>();
  private readonly hostInbox: ProtocolEnvelope[] = [];
  private sequence = 0;
  private currentTimeMs: number;
  private lastActivityAtMs: number;
  private lastHostAtMs: number;
  private state: "open" | "closed" | "expired" = "open";
  private capabilityOrdinal = 1;
  private lastMessageType = "room_created";
  private lastRequestDisplay = "-";
  private lastResult = "accepted";
  private readonly counters: Record<string, number> = {
    duplicate: 0,
    stale: 0,
    malformed: 0,
    unauthorized: 0,
    rate_limited: 0,
    reconnect: 0,
  };

  constructor(
    roomId: string,
    joinCode: string,
    capabilityFactory: CapabilityFactory = defaultCapabilityFactory,
    limits: RoomLimits = DEFAULT_LIMITS,
    clock: MonotonicClock = Date.now,
  ) {
    if (!clientIdPattern.test(roomId) || !/^[A-Z2-9]{4,8}$/.test(joinCode) || !validLimits(limits)) {
      throw new Error("Invalid ephemeral room configuration");
    }
    this.roomId = roomId;
    this.joinCode = joinCode;
    this.capabilityFactory = capabilityFactory;
    this.limits = { ...limits };
    this.clock = clock;
    this.currentTimeMs = sanitizeTime(clock());
    this.lastActivityAtMs = this.currentTimeMs;
    this.lastHostAtMs = this.currentTimeMs;
    this.hostCapabilityValue = capabilityFactory("host", 0);
  }

  get hostCapability(): string {
    return this.hostCapabilityValue;
  }

  snapshot(): EphemeralRoomSnapshot {
    return {
      snapshotVersion: 2,
      roomId: this.roomId,
      joinCode: this.joinCode,
      limits: { ...this.limits },
      hostCapability: this.hostCapabilityValue,
      clients: [...this.clients.values()].map((client) => ({
        ...client,
        inbox: [...client.inbox],
        acknowledgementCache: [...client.acknowledgementCache.entries()].map(([key, cached]) => [key, {
          envelope: cached.envelope,
          cachedAtMs: cached.cachedAtMs,
        }] as const),
        acknowledgementOrder: [...client.acknowledgementOrder],
      })),
      hostInbox: [...this.hostInbox],
      sequence: this.sequence,
      currentTimeMs: this.currentTimeMs,
      lastActivityAtMs: this.lastActivityAtMs,
      lastHostAtMs: this.lastHostAtMs,
      state: this.state,
      capabilityOrdinal: this.capabilityOrdinal,
      lastMessageType: this.lastMessageType,
      lastRequestDisplay: this.lastRequestDisplay,
      lastResult: this.lastResult,
      counters: { ...this.counters },
    };
  }

  static restore(
    snapshot: EphemeralRoomSnapshot,
    capabilityFactory: CapabilityFactory = defaultCapabilityFactory,
    clock: MonotonicClock = Date.now,
  ): EphemeralRoom {
    if (!validSnapshot(snapshot)) throw new Error("Invalid or unsupported room snapshot");
    const room = new EphemeralRoom(snapshot.roomId, snapshot.joinCode, capabilityFactory, snapshot.limits, clock);
    room.hostCapabilityValue = snapshot.hostCapability;
    for (const client of snapshot.clients) {
      room.clients.set(client.clientId, {
        ...client,
        inbox: [...client.inbox],
        acknowledgementCache: new Map(client.acknowledgementCache.map(([key, cached]) => [key, {
          envelope: cached.envelope,
          cachedAtMs: cached.cachedAtMs,
        }])),
        acknowledgementOrder: [...client.acknowledgementOrder],
      });
    }
    room.hostInbox.push(...snapshot.hostInbox);
    room.sequence = snapshot.sequence;
    room.currentTimeMs = snapshot.currentTimeMs;
    room.lastActivityAtMs = snapshot.lastActivityAtMs;
    room.lastHostAtMs = snapshot.lastHostAtMs;
    room.state = snapshot.state;
    room.capabilityOrdinal = snapshot.capabilityOrdinal;
    room.lastMessageType = snapshot.lastMessageType;
    room.lastRequestDisplay = snapshot.lastRequestDisplay;
    room.lastResult = snapshot.lastResult;
    for (const key of Object.keys(room.counters)) delete room.counters[key];
    Object.assign(room.counters, snapshot.counters);
    room.updateTime();
    return room;
  }

  updateTime(observedTimeMs = this.clock()): ProtocolEnvelope | undefined {
    this.currentTimeMs = Math.max(this.currentTimeMs, sanitizeTime(observedTimeMs));
    this.pruneAcknowledgements();
    if (this.state !== "open") return undefined;
    if (this.currentTimeMs - this.lastHostAtMs >= this.limits.hostLossGraceMs) {
      return this.expire("host_lost");
    }
    if (this.currentTimeMs - this.lastActivityAtMs >= this.limits.idleExpiryMs) {
      return this.expire("inactive");
    }
    return undefined;
  }

  nextExpiryAtMs(): number | undefined {
    if (this.state !== "open") return undefined;
    return Math.min(
      this.lastHostAtMs + this.limits.hostLossGraceMs,
      this.lastActivityAtMs + this.limits.idleExpiryMs,
    );
  }

  join(clientId: string): RoomResult {
    this.updateTime();
    if (!this.isOpen()) return this.reject("expired", "client_joined", clientId);
    if (!clientIdPattern.test(clientId)) return this.reject("malformed", "client_joined", clientId);
    const existing = this.clients.get(clientId);
    if (existing?.revoked) return this.reject("revoked", "client_joined", clientId);
    if (existing) return this.reject("duplicate", "client_joined", clientId);
    const pendingCount = [...this.clients.values()].filter((client) => client.pending).length;
    if (this.clients.size >= this.limits.maxClients || pendingCount >= this.limits.maxPendingClients) {
      return this.reject("room_full", "client_joined", clientId);
    }
    const client: ClientRecord = {
      clientId,
      pending: true,
      connected: true,
      revoked: false,
      seatClaim: 0,
      resumeCapability: "",
      lastSeenAtMs: this.currentTimeMs,
      rateWindowStartedAtMs: this.currentTimeMs,
      rateCount: 0,
      inbox: [],
      acknowledgementCache: new Map(),
      acknowledgementOrder: [],
    };
    this.clients.set(clientId, client);
    this.touchClient(client);
    const envelope = this.nextEnvelope("seat_claim_requested", `join_${clientId}`, { clientId, clientDisplay: displayId(clientId) });
    this.enqueue(this.hostInbox, envelope);
    return this.accept(envelope);
  }

  approveClaim(hostCapability: string, clientId: string, seatClaim: number): RoomResult {
    this.updateTime();
    if (!this.authorizeHost(hostCapability)) return this.reject("unauthorized", "seat_claim_approved", clientId);
    const client = this.clients.get(clientId);
    if (!client || !client.pending || client.revoked || !Number.isInteger(seatClaim) || seatClaim < 1 || seatClaim > 8) {
      return this.reject("unauthorized", "seat_claim_approved", clientId);
    }
    const seatAlreadyClaimed = [...this.clients.values()].some((other) => (
      other.clientId !== clientId && !other.pending && !other.revoked && other.seatClaim === seatClaim
    ));
    if (seatAlreadyClaimed) return this.reject("wrong_seat", "seat_claim_approved", clientId);
    client.pending = false;
    client.seatClaim = seatClaim;
    client.resumeCapability = this.capabilityFactory("resume", this.capabilityOrdinal++);
    this.touchHost();
    const envelope = this.nextEnvelope(
      "seat_claim_approved",
      `claim_${clientId}`,
      { seat: seatClaim, resumeCapability: client.resumeCapability },
      seatClaim,
    );
    this.enqueue(client.inbox, envelope);
    return this.accept(this.nextEnvelope("acknowledgement", `claim_ack_${clientId}`, { claimApproved: true }, seatClaim, "accepted"));
  }

  denyClaim(hostCapability: string, clientId: string): RoomResult {
    this.updateTime();
    if (!this.authorizeHost(hostCapability)) return this.reject("unauthorized", "seat_claim_rejected", clientId);
    const client = this.clients.get(clientId);
    if (!client || !client.pending) return this.reject("unauthorized", "seat_claim_rejected", clientId);
    client.pending = false;
    client.connected = false;
    client.revoked = true;
    client.resumeCapability = "";
    const envelope = this.nextEnvelope("seat_claim_rejected", `deny_${clientId}`, {}, 0, "unauthorized");
    this.enqueue(client.inbox, envelope);
    this.touchHost();
    return this.accept(envelope);
  }

  disconnect(clientId: string): RoomResult {
    this.updateTime();
    const client = this.clients.get(clientId);
    if (!this.isOpen() || !client || !client.connected) return this.reject("unauthorized", "client_left", clientId);
    client.connected = false;
    const envelope = this.nextEnvelope("client_left", `leave_${clientId}`, { clientId, clientDisplay: displayId(clientId) }, client.seatClaim);
    this.enqueue(this.hostInbox, envelope);
    this.touchClient(client);
    return this.accept(envelope);
  }

  resume(clientId: string, seatClaim: number, resumeCapability: string): RoomResult {
    this.updateTime();
    if (!this.isOpen()) return this.reject("expired", "reconnect_resume", clientId);
    const client = this.clients.get(clientId);
    if (!client || client.pending || client.revoked || client.connected || !resumeCapability || client.resumeCapability !== resumeCapability) {
      return this.reject("unauthorized", "reconnect_resume", clientId);
    }
    if (client.seatClaim !== seatClaim) return this.reject("wrong_seat", "reconnect_resume", clientId);
    client.connected = true;
    this.counters.reconnect = (this.counters.reconnect ?? 0) + 1;
    const envelope = this.nextEnvelope("reconnect_resume", `resume_${clientId}`, { restored: true }, seatClaim, "accepted");
    this.enqueue(client.inbox, envelope);
    this.enqueue(this.hostInbox, envelope);
    this.touchClient(client);
    return this.accept(envelope);
  }

  revokeClaim(hostCapability: string, clientId: string): RoomResult {
    this.updateTime();
    if (!this.authorizeHost(hostCapability)) return this.reject("unauthorized", "seat_claim_rejected", clientId);
    const client = this.clients.get(clientId);
    if (!client) return this.reject("unauthorized", "seat_claim_rejected", clientId);
    client.connected = false;
    client.revoked = true;
    client.resumeCapability = "";
    client.acknowledgementCache.clear();
    client.acknowledgementOrder.length = 0;
    const envelope = this.nextEnvelope("seat_claim_rejected", `revoke_${clientId}`, { revoked: true }, 0, "revoked");
    this.enqueue(client.inbox, envelope);
    this.touchHost();
    return this.accept(envelope);
  }

  relayClientRaw(clientId: string, raw: string): RoomResult {
    this.updateTime();
    const parsed = parseEnvelope(raw);
    if (!parsed.accepted || !parsed.envelope) return this.reject(parsed.code === "accepted" ? "malformed" : parsed.code, "rejection", clientId);
    return this.relayClientEnvelope(clientId, parsed.envelope);
  }

  relayClientEnvelope(clientId: string, envelope: ProtocolEnvelope): RoomResult {
    this.updateTime();
    const client = this.clients.get(clientId);
    if (!this.isOpen()) return this.reject("expired", envelope.messageType, envelope.requestId);
    if (!client || !client.connected || client.pending || client.revoked) return this.reject("unauthorized", envelope.messageType, envelope.requestId);
    if (!this.consumeRate(client)) return this.reject("rate_limited", envelope.messageType, envelope.requestId);
    if (envelope.roomId !== this.roomId || envelope.seatClaim !== client.seatClaim) {
      return this.reject("wrong_seat", envelope.messageType, envelope.requestId);
    }
    if (!intentTypes.has(envelope.messageType)) return this.reject("unsupported_type", envelope.messageType, envelope.requestId);
    const cached = client.acknowledgementCache.get(envelope.requestId);
    if (cached) {
      this.counters.duplicate = (this.counters.duplicate ?? 0) + 1;
      this.record(envelope.messageType, envelope.requestId, "duplicate");
      this.touchClient(client);
      return { accepted: true, code: "accepted", envelope: cached.envelope };
    }
    const relayed = this.nextEnvelope(
      envelope.messageType,
      envelope.requestId,
      envelope.payload,
      client.seatClaim,
      "",
      envelope.authoritativeRevision,
    );
    this.enqueue(this.hostInbox, relayed);
    const ack = this.nextEnvelope("acknowledgement", envelope.requestId, { relayAccepted: true }, client.seatClaim, "accepted", envelope.authoritativeRevision);
    this.cacheAcknowledgement(client, envelope.requestId, ack);
    this.enqueue(client.inbox, ack);
    this.touchClient(client);
    return this.accept(ack);
  }

  relayHostEnvelope(hostCapability: string, clientId: string, envelope: ProtocolEnvelope): RoomResult {
    this.updateTime();
    if (!this.authorizeHost(hostCapability)) return this.reject("unauthorized", envelope.messageType, envelope.requestId);
    if (!hostRelayTypes.has(envelope.messageType) || envelope.roomId !== this.roomId) {
      return this.reject("unsupported_type", envelope.messageType, envelope.requestId);
    }
    const client = this.clients.get(clientId);
    if (!client || !client.connected || client.pending || client.revoked) return this.reject("unauthorized", envelope.messageType, envelope.requestId);
    if (envelope.seatClaim !== 0 && envelope.seatClaim !== client.seatClaim) {
      return this.reject("wrong_seat", envelope.messageType, envelope.requestId);
    }
    const relayed = this.nextEnvelope(
      envelope.messageType,
      envelope.requestId,
      envelope.payload,
      envelope.seatClaim,
      envelope.acknowledgement,
      envelope.authoritativeRevision,
    );
    if (envelope.messageType === "acknowledgement" || envelope.messageType === "rejection") {
      this.cacheAcknowledgement(client, envelope.requestId, relayed);
    }
    this.enqueue(client.inbox, relayed);
    this.touchHost();
    return this.accept(relayed);
  }

  heartbeat(hostCapability: string): RoomResult {
    this.updateTime();
    if (!this.authorizeHost(hostCapability)) return this.reject("unauthorized", "host_heartbeat", "heartbeat");
    this.touchHost();
    return this.accept(this.nextEnvelope("host_heartbeat", `heartbeat_${this.currentTimeMs}`, { alive: true }));
  }

  close(hostCapability: string): RoomResult {
    this.updateTime();
    if (!this.authorizeHost(hostCapability)) return this.reject("unauthorized", "room_closed", "close");
    const envelope = this.nextEnvelope("room_closed", `close_${this.currentTimeMs}`, { reason: "host_closed" });
    this.destroy("closed");
    return this.accept(envelope);
  }

  drainHostInbox(hostCapability: string): ProtocolEnvelope[] {
    this.updateTime();
    if (!this.authorizeHost(hostCapability)) return [];
    this.touchHost();
    return this.hostInbox.splice(0, this.hostInbox.length);
  }

  drainClientInbox(clientId: string): ProtocolEnvelope[] {
    this.updateTime();
    const client = this.clients.get(clientId);
    if (!client) return [];
    this.touchClient(client);
    return client.inbox.splice(0, client.inbox.length);
  }

  diagnostics(): SanitizedRoomDiagnostics {
    this.updateTime();
    const connected = [...this.clients.values()].filter((client) => client.connected && !client.pending && !client.revoked);
    const pending = [...this.clients.values()].filter((client) => client.pending && !client.revoked);
    return {
      protocolVersion: PROTOCOL_VERSION,
      serviceVersion: SERVICE_VERSION,
      roomState: this.state,
      roomCode: this.joinCode,
      elapsedMs: this.currentTimeMs,
      inactivityExpiryInMs: Math.max(0, this.limits.idleExpiryMs - (this.currentTimeMs - this.lastActivityAtMs)),
      hostLossExpiryInMs: Math.max(0, this.limits.hostLossGraceMs - (this.currentTimeMs - this.lastHostAtMs)),
      hostPresent: this.state === "open" && this.currentTimeMs - this.lastHostAtMs < this.limits.hostLossGraceMs,
      connectedClients: connected.length,
      pendingClients: pending.length,
      claimedSeats: connected.map((client) => client.seatClaim).sort((a, b) => a - b),
      sequence: this.sequence,
      queueDepth: this.hostInbox.length + [...this.clients.values()].reduce((sum, client) => sum + client.inbox.length, 0),
      lastMessageType: this.lastMessageType,
      lastRequestDisplay: this.lastRequestDisplay,
      lastResult: this.lastResult,
      counters: { ...this.counters },
      privacy: "no_capabilities_no_payloads",
    };
  }

  private expire(reason: "host_lost" | "inactive"): ProtocolEnvelope {
    const envelope = this.nextEnvelope("room_expired", `expiry_${this.currentTimeMs}`, { reason }, 0, "expired");
    this.destroy("expired");
    return envelope;
  }

  private destroy(finalState: "closed" | "expired"): void {
    this.state = finalState;
    this.hostInbox.length = 0;
    for (const client of this.clients.values()) {
      client.resumeCapability = "";
      client.acknowledgementCache.clear();
      client.acknowledgementOrder.length = 0;
      client.inbox.length = 0;
    }
    this.clients.clear();
    this.hostCapabilityValue = "";
  }

  private authorizeHost(capability: string): boolean {
    return this.state === "open" && capability.length > 0 && this.hostCapabilityValue === capability;
  }

  private isOpen(): boolean {
    return this.state === "open";
  }

  private touchClient(client: ClientRecord): void {
    client.lastSeenAtMs = this.currentTimeMs;
    this.lastActivityAtMs = this.currentTimeMs;
  }

  private touchHost(): void {
    this.lastHostAtMs = this.currentTimeMs;
    this.lastActivityAtMs = this.currentTimeMs;
  }

  private consumeRate(client: ClientRecord): boolean {
    if (this.currentTimeMs - client.rateWindowStartedAtMs >= this.limits.rateWindowMs) {
      client.rateWindowStartedAtMs = this.currentTimeMs;
      client.rateCount = 0;
    }
    client.rateCount += 1;
    if (client.rateCount > this.limits.maxMessagesPerWindow) {
      this.counters.rate_limited = (this.counters.rate_limited ?? 0) + 1;
      return false;
    }
    return true;
  }

  private nextEnvelope(
    messageType: ProtocolEnvelope["messageType"],
    requestId: string,
    payload: Readonly<Record<string, JsonValue>>,
    seatClaim = 0,
    acknowledgement: ProtocolEnvelope["acknowledgement"] = "",
    authoritativeRevision = 0,
  ): ProtocolEnvelope {
    this.sequence += 1;
    return createEnvelope(this.roomId, messageType, sanitizeRequestId(requestId), payload, {
      serverSequence: this.sequence,
      authoritativeRevision,
      seatClaim,
      acknowledgement,
    });
  }

  private enqueue(queue: ProtocolEnvelope[], envelope: ProtocolEnvelope): void {
    queue.push(envelope);
    while (queue.length > this.limits.maxQueueDepth) queue.shift();
  }

  private cacheAcknowledgement(client: ClientRecord, requestId: string, envelope: ProtocolEnvelope): void {
    const existing = client.acknowledgementCache.has(requestId);
    client.acknowledgementCache.set(requestId, { envelope, cachedAtMs: this.currentTimeMs });
    if (!existing) client.acknowledgementOrder.push(requestId);
    while (client.acknowledgementOrder.length > this.limits.maxAckCache) {
      const oldest = client.acknowledgementOrder.shift();
      if (oldest !== undefined) client.acknowledgementCache.delete(oldest);
    }
  }

  private pruneAcknowledgements(): void {
    for (const client of this.clients.values()) {
      for (const requestId of [...client.acknowledgementOrder]) {
        const cached = client.acknowledgementCache.get(requestId);
        if (!cached || this.currentTimeMs - cached.cachedAtMs >= this.limits.acknowledgementExpiryMs) {
          client.acknowledgementCache.delete(requestId);
          const index = client.acknowledgementOrder.indexOf(requestId);
          if (index >= 0) client.acknowledgementOrder.splice(index, 1);
        }
      }
    }
  }

  private accept(envelope: ProtocolEnvelope): RoomResult {
    this.record(envelope.messageType, envelope.requestId, "accepted");
    return { accepted: true, code: "accepted", envelope };
  }

  private reject(code: RejectionCode, messageType: string, requestId: string): RoomResult {
    if (code in this.counters) this.counters[code] = (this.counters[code] ?? 0) + 1;
    this.record(messageType, requestId, code);
    return { accepted: false, code };
  }

  private record(messageType: string, requestId: string, result: string): void {
    this.lastMessageType = messageType.slice(0, 64);
    this.lastRequestDisplay = displayId(requestId);
    this.lastResult = result;
  }
}

export class DeterministicRoomRegistry {
  private readonly roomsByCode = new Map<string, EphemeralRoom>();
  private roomOrdinal = 1;

  constructor(
    private readonly codeFactory: (attempt: number) => string,
    private readonly capabilityFactory: CapabilityFactory,
    private readonly limits: RoomLimits = DEFAULT_LIMITS,
    private readonly clock: MonotonicClock = Date.now,
  ) {}

  create(maxAttempts = 8): EphemeralRoom {
    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      const code = this.codeFactory(attempt);
      if (!this.roomsByCode.has(code)) {
        const room = new EphemeralRoom(`room_${this.roomOrdinal++}`, code, this.capabilityFactory, this.limits, this.clock);
        this.roomsByCode.set(code, room);
        return room;
      }
    }
    throw new Error("Join code collision retry limit reached");
  }

  get(code: string): EphemeralRoom | undefined {
    return this.roomsByCode.get(code);
  }

  destroy(code: string): void {
    this.roomsByCode.delete(code);
  }

  get size(): number {
    return this.roomsByCode.size;
  }
}

function defaultCapabilityFactory(scope: "host" | "resume", ordinal: number): string {
  return `${scope}_${ordinal}_${crypto.randomUUID().replaceAll("-", "")}`;
}

function displayId(value: string): string {
  if (!value) return "-";
  return value.replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 8);
}

function sanitizeRequestId(value: string): string {
  const sanitized = value.toLowerCase().replace(/[^a-z0-9_-]/g, "_").slice(0, 64);
  return sanitized || "request";
}

function sanitizeTime(value: number): number {
  if (!Number.isFinite(value) || value < 0) throw new Error("Room clock must return a nonnegative finite timestamp");
  return Math.floor(value);
}

function validLimits(limits: RoomLimits): boolean {
  return Object.values(limits).every((value) => Number.isInteger(value) && value > 0)
    && limits.maxClients <= 8
    && limits.maxPendingClients <= 8;
}

function validSnapshot(value: EphemeralRoomSnapshot): boolean {
  if (!value || value.snapshotVersion !== 2 || !clientIdPattern.test(value.roomId) || !/^[A-Z2-9]{4,8}$/.test(value.joinCode)) return false;
  if (!validLimits(value.limits) || !["open", "closed", "expired"].includes(value.state)) return false;
  if (![value.sequence, value.currentTimeMs, value.lastActivityAtMs, value.lastHostAtMs, value.capabilityOrdinal].every((item) => Number.isInteger(item) && item >= 0)) return false;
  if (value.lastActivityAtMs > value.currentTimeMs || value.lastHostAtMs > value.currentTimeMs || !Array.isArray(value.clients) || !Array.isArray(value.hostInbox)) return false;
  if (value.clients.length > value.limits.maxClients || value.hostInbox.length > value.limits.maxQueueDepth) return false;
  if (!value.hostInbox.every((envelope) => validStoredEnvelope(envelope, value.roomId))) return false;
  if (value.state === "open" && (!value.hostCapability || value.hostCapability.length > 256)) return false;
  if (value.state !== "open" && (value.hostCapability || value.clients.length > 0 || value.hostInbox.length > 0)) return false;
  const ids = new Set<string>();
  for (const client of value.clients) {
    if (!clientIdPattern.test(client.clientId) || ids.has(client.clientId) || client.inbox.length > value.limits.maxQueueDepth) return false;
    if (![client.lastSeenAtMs, client.rateWindowStartedAtMs, client.rateCount, client.seatClaim].every((item) => Number.isInteger(item) && item >= 0)) return false;
    if (client.lastSeenAtMs > value.currentTimeMs || client.rateWindowStartedAtMs > value.currentTimeMs) return false;
    if (typeof client.pending !== "boolean" || typeof client.connected !== "boolean" || typeof client.revoked !== "boolean") return false;
    if (typeof client.resumeCapability !== "string" || client.resumeCapability.length > 256) return false;
    if (client.seatClaim > 8 || client.acknowledgementCache.length > value.limits.maxAckCache || client.acknowledgementOrder.length > value.limits.maxAckCache) return false;
    if (!client.inbox.every((envelope: unknown) => validStoredEnvelope(envelope, value.roomId))) return false;
    const acknowledgementKeys = new Set<string>();
    for (const entry of client.acknowledgementCache) {
      if (!Array.isArray(entry) || entry.length !== 2) return false;
      const [requestId, cached] = entry;
      if (typeof requestId !== "string" || acknowledgementKeys.has(requestId)) return false;
      if (!cached || !Number.isInteger(cached.cachedAtMs) || cached.cachedAtMs < 0 || cached.cachedAtMs > value.currentTimeMs) return false;
      if (!validStoredEnvelope(cached.envelope, value.roomId) || cached.envelope.requestId !== requestId) return false;
      acknowledgementKeys.add(requestId);
    }
    if (new Set(client.acknowledgementOrder).size !== client.acknowledgementOrder.length) return false;
    if (client.acknowledgementOrder.some((requestId: unknown) => typeof requestId !== "string" || !acknowledgementKeys.has(requestId))) return false;
    ids.add(client.clientId);
  }
  return true;
}

function validStoredEnvelope(value: unknown, roomId: string): value is ProtocolEnvelope {
  const validation = validateEnvelope(value);
  return validation.accepted && validation.envelope?.roomId === roomId;
}
