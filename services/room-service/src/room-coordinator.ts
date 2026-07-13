import {
  createEnvelope,
  parseEnvelope,
  PROTOCOL_VERSION,
  SERVICE_VERSION,
  type JsonValue,
  type ProtocolEnvelope,
  type RejectionCode,
} from "./protocol";

export interface RoomLimits {
  readonly maxClients: number;
  readonly maxPendingClients: number;
  readonly maxQueueDepth: number;
  readonly maxAckCache: number;
  readonly idleExpirySteps: number;
  readonly hostLossGraceSteps: number;
  readonly rateWindowSteps: number;
  readonly maxMessagesPerWindow: number;
}

export const DEFAULT_LIMITS: RoomLimits = {
  maxClients: 8,
  maxPendingClients: 8,
  maxQueueDepth: 32,
  maxAckCache: 32,
  idleExpirySteps: 120,
  hostLossGraceSteps: 20,
  rateWindowSteps: 10,
  maxMessagesPerWindow: 16,
};

export interface RoomResult {
  readonly accepted: boolean;
  readonly code: "accepted" | RejectionCode;
  readonly envelope?: ProtocolEnvelope;
}

interface ClientRecord {
  readonly clientId: string;
  pending: boolean;
  connected: boolean;
  revoked: boolean;
  seatClaim: number;
  resumeCapability: string;
  lastSeenStep: number;
  rateWindowStart: number;
  rateCount: number;
  readonly inbox: ProtocolEnvelope[];
  readonly acknowledgementCache: Map<string, ProtocolEnvelope>;
  readonly acknowledgementOrder: string[];
}

export interface EphemeralRoomSnapshot {
  readonly snapshotVersion: 1;
  readonly roomId: string;
  readonly joinCode: string;
  readonly limits: RoomLimits;
  readonly hostCapability: string;
  readonly clients: ReadonlyArray<Readonly<Omit<ClientRecord, "acknowledgementCache">> & {
    readonly acknowledgementCache: ReadonlyArray<readonly [string, ProtocolEnvelope]>;
  }>;
  readonly hostInbox: readonly ProtocolEnvelope[];
  readonly sequence: number;
  readonly currentStep: number;
  readonly lastActivityStep: number;
  readonly lastHostStep: number;
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
  readonly step: number;
  readonly expiryInSteps: number;
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

const clientIdPattern = /^[a-z0-9][a-z0-9_-]{0,63}$/;
const intentTypes = new Set(["prompt_choice_submit", "role_action_submit", "private_reveal_ack"]);
const hostRelayTypes = new Set(["public_view_update", "seat_private_view_update", "faction_private_view_update", "acknowledgement", "rejection"]);

export class EphemeralRoom {
  readonly roomId: string;
  readonly joinCode: string;
  readonly limits: RoomLimits;
  readonly hostCapability: string;
  private readonly capabilityFactory: CapabilityFactory;
  private readonly clients = new Map<string, ClientRecord>();
  private readonly hostInbox: ProtocolEnvelope[] = [];
  private sequence = 0;
  private currentStep = 0;
  private lastActivityStep = 0;
  private lastHostStep = 0;
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
  ) {
    if (!clientIdPattern.test(roomId) || !/^[A-Z2-9]{4,8}$/.test(joinCode)) {
      throw new Error("Invalid synthetic room identity");
    }
    this.roomId = roomId;
    this.joinCode = joinCode;
    this.capabilityFactory = capabilityFactory;
    this.limits = limits;
    this.hostCapability = capabilityFactory("host", 0);
  }

  snapshot(): EphemeralRoomSnapshot {
    return {
      snapshotVersion: 1,
      roomId: this.roomId,
      joinCode: this.joinCode,
      limits: { ...this.limits },
      hostCapability: this.hostCapability,
      clients: [...this.clients.values()].map((client) => ({
        ...client,
        inbox: [...client.inbox],
        acknowledgementCache: [...client.acknowledgementCache.entries()],
        acknowledgementOrder: [...client.acknowledgementOrder],
      })),
      hostInbox: [...this.hostInbox],
      sequence: this.sequence,
      currentStep: this.currentStep,
      lastActivityStep: this.lastActivityStep,
      lastHostStep: this.lastHostStep,
      state: this.state,
      capabilityOrdinal: this.capabilityOrdinal,
      lastMessageType: this.lastMessageType,
      lastRequestDisplay: this.lastRequestDisplay,
      lastResult: this.lastResult,
      counters: { ...this.counters },
    };
  }

  static restore(snapshot: EphemeralRoomSnapshot): EphemeralRoom {
    if (snapshot.snapshotVersion !== 1) throw new Error("Unsupported room snapshot");
    const capabilityFactory: CapabilityFactory = (scope, ordinal) => scope === "host"
      ? snapshot.hostCapability
      : defaultCapabilityFactory(scope, ordinal);
    const room = new EphemeralRoom(snapshot.roomId, snapshot.joinCode, capabilityFactory, snapshot.limits);
    for (const client of snapshot.clients) {
      room.clients.set(client.clientId, {
        ...client,
        inbox: [...client.inbox],
        acknowledgementCache: new Map(client.acknowledgementCache),
        acknowledgementOrder: [...client.acknowledgementOrder],
      });
    }
    room.hostInbox.push(...snapshot.hostInbox);
    room.sequence = snapshot.sequence;
    room.currentStep = snapshot.currentStep;
    room.lastActivityStep = snapshot.lastActivityStep;
    room.lastHostStep = snapshot.lastHostStep;
    room.state = snapshot.state;
    room.capabilityOrdinal = snapshot.capabilityOrdinal;
    room.lastMessageType = snapshot.lastMessageType;
    room.lastRequestDisplay = snapshot.lastRequestDisplay;
    room.lastResult = snapshot.lastResult;
    for (const key of Object.keys(room.counters)) delete room.counters[key];
    Object.assign(room.counters, snapshot.counters);
    return room;
  }

  join(clientId: string): RoomResult {
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
      lastSeenStep: this.currentStep,
      rateWindowStart: this.currentStep,
      rateCount: 0,
      inbox: [],
      acknowledgementCache: new Map(),
      acknowledgementOrder: [],
    };
    this.clients.set(clientId, client);
    this.touch();
    const envelope = this.nextEnvelope("seat_claim_requested", `join_${clientId}`, { clientId, clientDisplay: displayId(clientId) });
    this.enqueue(this.hostInbox, envelope);
    return this.accept(envelope);
  }

  approveClaim(hostCapability: string, clientId: string, seatClaim: number): RoomResult {
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
    client.lastSeenStep = this.currentStep;
    this.touch(true);
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
    if (!this.authorizeHost(hostCapability)) return this.reject("unauthorized", "seat_claim_rejected", clientId);
    const client = this.clients.get(clientId);
    if (!client || !client.pending) return this.reject("unauthorized", "seat_claim_rejected", clientId);
    client.pending = false;
    client.connected = false;
    client.revoked = true;
    const envelope = this.nextEnvelope("seat_claim_rejected", `deny_${clientId}`, {}, 0, "unauthorized");
    this.enqueue(client.inbox, envelope);
    this.touch(true);
    return this.accept(envelope);
  }

  disconnect(clientId: string): RoomResult {
    const client = this.clients.get(clientId);
    if (!client || !client.connected) return this.reject("unauthorized", "client_left", clientId);
    client.connected = false;
    client.lastSeenStep = this.currentStep;
    const envelope = this.nextEnvelope("client_left", `leave_${clientId}`, { clientDisplay: displayId(clientId) }, client.seatClaim);
    this.enqueue(this.hostInbox, envelope);
    this.touch();
    return this.accept(envelope);
  }

  resume(clientId: string, seatClaim: number, resumeCapability: string): RoomResult {
    if (!this.isOpen()) return this.reject("expired", "reconnect_resume", clientId);
    const client = this.clients.get(clientId);
    if (!client || client.pending || client.revoked || client.connected || !resumeCapability || client.resumeCapability !== resumeCapability) {
      return this.reject("unauthorized", "reconnect_resume", clientId);
    }
    if (client.seatClaim !== seatClaim) return this.reject("wrong_seat", "reconnect_resume", clientId);
    client.connected = true;
    client.lastSeenStep = this.currentStep;
    this.counters.reconnect = (this.counters.reconnect ?? 0) + 1;
    const envelope = this.nextEnvelope("reconnect_resume", `resume_${clientId}`, { restored: true }, seatClaim, "accepted");
    this.enqueue(client.inbox, envelope);
    this.enqueue(this.hostInbox, envelope);
    this.touch();
    return this.accept(envelope);
  }

  revokeClaim(hostCapability: string, clientId: string): RoomResult {
    if (!this.authorizeHost(hostCapability)) return this.reject("unauthorized", "seat_claim_rejected", clientId);
    const client = this.clients.get(clientId);
    if (!client) return this.reject("unauthorized", "seat_claim_rejected", clientId);
    client.connected = false;
    client.revoked = true;
    client.resumeCapability = "";
    const envelope = this.nextEnvelope("seat_claim_rejected", `revoke_${clientId}`, { revoked: true }, 0, "revoked");
    this.enqueue(client.inbox, envelope);
    this.touch(true);
    return this.accept(envelope);
  }

  relayClientRaw(clientId: string, raw: string): RoomResult {
    const parsed = parseEnvelope(raw);
    if (!parsed.accepted || !parsed.envelope) return this.reject(parsed.code === "accepted" ? "malformed" : parsed.code, "rejection", clientId);
    return this.relayClientEnvelope(clientId, parsed.envelope);
  }

  relayClientEnvelope(clientId: string, envelope: ProtocolEnvelope): RoomResult {
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
      return { accepted: true, code: "accepted", envelope: cached };
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
    this.touch();
    return this.accept(ack);
  }

  relayHostEnvelope(hostCapability: string, clientId: string, envelope: ProtocolEnvelope): RoomResult {
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
    this.enqueue(client.inbox, relayed);
    this.touch(true);
    return this.accept(relayed);
  }

  heartbeat(hostCapability: string): RoomResult {
    if (!this.authorizeHost(hostCapability)) return this.reject("unauthorized", "host_heartbeat", "heartbeat");
    this.lastHostStep = this.currentStep;
    this.touch(true);
    return this.accept(this.nextEnvelope("host_heartbeat", `heartbeat_${this.currentStep}`, { alive: true }));
  }

  advanceTo(step: number): void {
    if (!Number.isInteger(step) || step < this.currentStep) throw new Error("Room steps must be monotonic");
    this.currentStep = step;
    if (this.state !== "open") return;
    if (step - this.lastActivityStep >= this.limits.idleExpirySteps || step - this.lastHostStep >= this.limits.hostLossGraceSteps) {
      this.expire();
    }
  }

  close(hostCapability: string): RoomResult {
    if (!this.authorizeHost(hostCapability)) return this.reject("unauthorized", "room_closed", "close");
    if (!this.isOpen()) return this.reject("expired", "room_closed", "close");
    const envelope = this.nextEnvelope("room_closed", `close_${this.currentStep}`, { reason: "host_closed" });
    for (const client of this.clients.values()) this.enqueue(client.inbox, envelope);
    this.destroy("closed");
    return this.accept(envelope);
  }

  drainHostInbox(hostCapability: string): ProtocolEnvelope[] {
    if (!this.authorizeHost(hostCapability)) return [];
    return this.hostInbox.splice(0, this.hostInbox.length);
  }

  drainClientInbox(clientId: string): ProtocolEnvelope[] {
    const client = this.clients.get(clientId);
    if (!client) return [];
    return client.inbox.splice(0, client.inbox.length);
  }

  diagnostics(): SanitizedRoomDiagnostics {
    const connected = [...this.clients.values()].filter((client) => client.connected && !client.pending && !client.revoked);
    const pending = [...this.clients.values()].filter((client) => client.pending && !client.revoked);
    return {
      protocolVersion: PROTOCOL_VERSION,
      serviceVersion: SERVICE_VERSION,
      roomState: this.state,
      roomCode: this.joinCode,
      step: this.currentStep,
      expiryInSteps: Math.max(0, this.limits.idleExpirySteps - (this.currentStep - this.lastActivityStep)),
      hostPresent: this.state === "open" && this.currentStep - this.lastHostStep < this.limits.hostLossGraceSteps,
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

  private expire(): void {
    const envelope = this.nextEnvelope("room_expired", `expiry_${this.currentStep}`, { reason: "inactive_or_host_lost" }, 0, "expired");
    for (const client of this.clients.values()) this.enqueue(client.inbox, envelope);
    this.destroy("expired");
  }

  private destroy(finalState: "closed" | "expired"): void {
    this.state = finalState;
    this.hostInbox.length = 0;
    for (const client of this.clients.values()) {
      client.connected = false;
      client.resumeCapability = "";
      client.acknowledgementCache.clear();
      client.acknowledgementOrder.length = 0;
    }
  }

  private authorizeHost(capability: string): boolean {
    return this.state === "open" && capability.length > 0 && this.hostCapability === capability;
  }

  private isOpen(): boolean {
    return this.state === "open";
  }

  private touch(host = false): void {
    this.lastActivityStep = this.currentStep;
    if (host) this.lastHostStep = this.currentStep;
  }

  private consumeRate(client: ClientRecord): boolean {
    if (this.currentStep - client.rateWindowStart >= this.limits.rateWindowSteps) {
      client.rateWindowStart = this.currentStep;
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
    client.acknowledgementCache.set(requestId, envelope);
    client.acknowledgementOrder.push(requestId);
    while (client.acknowledgementOrder.length > this.limits.maxAckCache) {
      const oldest = client.acknowledgementOrder.shift();
      if (oldest !== undefined) client.acknowledgementCache.delete(oldest);
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
  ) {}

  create(maxAttempts = 8): EphemeralRoom {
    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      const code = this.codeFactory(attempt);
      if (!this.roomsByCode.has(code)) {
        const room = new EphemeralRoom(`room_${this.roomOrdinal++}`, code, this.capabilityFactory, this.limits);
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
