import {
  createEnvelope,
  type JsonValue,
  type ProtocolEnvelope,
} from "../../../services/room-service/src/protocol";

export type CompanionPhase =
  | "idle"
  | "joining"
  | "pending_approval"
  | "privacy_gate"
  | "private_revealed"
  | "submitting"
  | "reconnecting"
  | "disconnected";

export interface StoredConnection {
  readonly roomCode: string;
  readonly roomId: string;
  readonly clientId: string;
  readonly seatClaim: number;
  readonly resumeCapability: string;
}

export interface CompanionStorage {
  load(): StoredConnection | null;
  save(value: StoredConnection): void;
  clear(): void;
}

export interface CompanionTransport {
  connect(roomCode: string, authentication: Readonly<Record<string, JsonValue>>): Promise<void>;
  send(envelope: ProtocolEnvelope): void;
  disconnect(): void;
  setReceiver(receiver: (message: ProtocolEnvelope | ServiceStatus) => void): void;
}

export interface ServiceStatus {
  readonly accepted: boolean;
  readonly code: string;
}

export interface CompanionSnapshot {
  readonly phase: CompanionPhase;
  readonly status: string;
  readonly roomCode: string;
  readonly roomId: string;
  readonly seatClaim: number;
  readonly seatIdentity: Readonly<Record<string, JsonValue>>;
  readonly publicView: Readonly<Record<string, JsonValue>>;
  readonly privateView: Readonly<Record<string, JsonValue>>;
  readonly privateVisible: boolean;
  readonly lastAcknowledgement: string;
  readonly canResume: boolean;
}

export class CompanionAppModel {
  private phase: CompanionPhase = "idle";
  private status = "Enter the room code shown on the shared screen.";
  private roomCode = "";
  private roomId = "";
  private clientId = "";
  private seatClaim = 0;
  private resumeCapability = "";
  private authoritativeRevision = 0;
  private requestOrdinal = 0;
  private seatIdentity: Readonly<Record<string, JsonValue>> = {};
  private publicView: Readonly<Record<string, JsonValue>> = {};
  private privateView: Readonly<Record<string, JsonValue>> = {};
  private privateVisible = false;
  private lastAcknowledgement = "";
  private listener: (() => void) | undefined;

  constructor(
    private readonly transport: CompanionTransport,
    private readonly storage: CompanionStorage,
    private readonly clientIdFactory: () => string,
  ) {
    transport.setReceiver((message) => this.receive(message));
  }

  subscribe(listener: () => void): void {
    this.listener = listener;
  }

  snapshot(): CompanionSnapshot {
    return {
      phase: this.phase,
      status: this.status,
      roomCode: this.roomCode,
      roomId: this.roomId,
      seatClaim: this.seatClaim,
      seatIdentity: this.seatIdentity,
      publicView: this.publicView,
      privateView: this.privateVisible ? this.privateView : {},
      privateVisible: this.privateVisible,
      lastAcknowledgement: this.lastAcknowledgement,
      canResume: this.storage.load() !== null,
    };
  }

  async join(rawCode: string): Promise<void> {
    const code = rawCode.trim().toUpperCase();
    if (!/^[A-Z2-9]{4,8}$/.test(code)) {
      this.setStatus("Room codes use 4–8 letters and numerals without 0, 1, I, or O.");
      return;
    }
    this.clearPrivateMemory();
    this.phase = "joining";
    this.roomCode = code;
    this.clientId = this.clientIdFactory();
    this.setStatus("Connecting to the room…");
    try {
      await this.transport.connect(code, { operation: "join", clientId: this.clientId });
      this.phase = "pending_approval";
      this.setStatus("Connected. Waiting for the host to approve a stable seat.");
    } catch {
      this.phase = "disconnected";
      this.setStatus("The room could not be reached. Local shared-screen play is unaffected.");
    }
  }

  async resume(): Promise<void> {
    const stored = this.storage.load();
    if (!stored) {
      this.setStatus("No resumable room is stored on this browser.");
      return;
    }
    this.clearPrivateMemory();
    this.phase = "reconnecting";
    this.roomCode = stored.roomCode;
    this.roomId = stored.roomId;
    this.clientId = stored.clientId;
    this.seatClaim = stored.seatClaim;
    this.resumeCapability = stored.resumeCapability;
    this.setStatus(`Reconnecting to Seat ${stored.seatClaim}…`);
    try {
      await this.transport.connect(stored.roomCode, {
        operation: "resume",
        clientId: stored.clientId,
        seatClaim: stored.seatClaim,
        resumeCapability: stored.resumeCapability,
      });
    } catch {
      this.phase = "disconnected";
      this.setStatus("Reconnect failed. The room may be closed, expired, or unavailable.");
    }
  }

  revealPrivate(): void {
    if (this.phase !== "privacy_gate" || Object.keys(this.privateView).length === 0) return;
    this.privateVisible = true;
    this.phase = "private_revealed";
    this.setStatus("Private content is visible. Obscure it before sharing this screen.");
  }

  obscurePrivate(): void {
    if (this.seatClaim === 0) return;
    this.privateVisible = false;
    this.phase = "privacy_gate";
    this.setStatus("Private content is obscured.");
  }

  submitPrompt(optionIds: string[]): void {
    const rulesPrivate = isRecord(this.privateView.rulesPrivate) ? this.privateView.rulesPrivate : null;
    const prompt = rulesPrivate && isRecord(rulesPrivate.prompt)
      ? rulesPrivate.prompt
      : isRecord(this.privateView.prompt)
        ? this.privateView.prompt
        : null;
    const promptRevision = typeof prompt?.revision === "number" ? prompt.revision : -1;
    this.submit("prompt_choice_submit", { optionIds, promptRevision });
  }

  submitRoleAction(actionId: string, targets: number[]): void {
    this.submit("role_action_submit", { actionId, targets });
  }

  disconnectForReconnect(): void {
    this.transport.disconnect();
    this.clearPrivateMemory();
    this.phase = "disconnected";
    this.setStatus("Disconnected safely. Resume will request only the previously approved seat.");
  }

  leaveAndClear(): void {
    this.transport.disconnect();
    this.storage.clear();
    this.roomCode = "";
    this.roomId = "";
    this.clientId = "";
    this.seatClaim = 0;
    this.resumeCapability = "";
    this.publicView = {};
    this.seatIdentity = {};
    this.clearPrivateMemory();
    this.phase = "idle";
    this.setStatus("Local room and resume data cleared from this browser.");
  }

  receive(message: ProtocolEnvelope | ServiceStatus): void {
    if (!("messageType" in message)) {
      if (!message.accepted) {
        this.phase = "disconnected";
        this.setStatus(safeStatus(message.code));
      }
      return;
    }
    this.authoritativeRevision = Math.max(this.authoritativeRevision, message.authoritativeRevision);
    switch (message.messageType) {
      case "seat_claim_requested":
        this.phase = "pending_approval";
        this.setStatus("Waiting for the host to approve a stable seat.");
        break;
      case "seat_claim_approved":
        this.acceptClaim(message);
        break;
      case "seat_claim_rejected":
        this.storage.clear();
        this.clearPrivateMemory();
        this.phase = "disconnected";
        this.setStatus(message.acknowledgement === "revoked" ? "This seat claim was revoked." : "The host did not approve this seat claim.");
        break;
      case "public_view_update":
        this.publicView = message.payload;
        this.setStatus("Public room view refreshed.");
        break;
      case "seat_private_view_update":
        if (message.seatClaim !== this.seatClaim || this.seatClaim === 0) {
          this.setStatus("A wrong-seat private update was blocked.");
          break;
        }
        this.privateView = message.payload;
        if (isRecord(message.payload.seatIdentity)) this.seatIdentity = message.payload.seatIdentity;
        this.privateVisible = false;
        this.phase = "privacy_gate";
        this.setStatus("Private content is ready behind the privacy screen.");
        break;
      case "faction_private_view_update":
        if (message.seatClaim !== this.seatClaim) this.setStatus("An unauthorized faction update was blocked.");
        break;
      case "acknowledgement":
        if (message.payload.relayAccepted === true) {
          this.lastAcknowledgement = "relayed";
          this.phase = "submitting";
          this.setStatus("Intent relayed. Waiting for the authoritative native host.");
          break;
        }
        this.lastAcknowledgement = message.acknowledgement || "accepted";
        if (this.seatClaim > 0) this.phase = this.privateVisible ? "private_revealed" : "privacy_gate";
        this.setStatus(message.acknowledgement === "accepted" ? "Action accepted by the authoritative host." : safeStatus(message.acknowledgement));
        break;
      case "rejection":
        this.lastAcknowledgement = message.acknowledgement;
        if (this.seatClaim > 0) this.phase = this.privateVisible ? "private_revealed" : "privacy_gate";
        this.setStatus(safeStatus(message.acknowledgement));
        break;
      case "reconnect_resume":
        if (message.seatClaim !== this.seatClaim) {
          this.phase = "disconnected";
          this.setStatus("Reconnect was denied for the requested seat.");
        } else {
          this.phase = "privacy_gate";
          this.setStatus(`Reconnected to Seat ${this.seatClaim}. Private content remains obscured.`);
        }
        break;
      case "room_closed":
      case "room_expired":
        this.storage.clear();
        this.clearPrivateMemory();
        this.phase = "disconnected";
        this.setStatus("The room is closed or expired. The native game can continue locally.");
        break;
      default:
        break;
    }
  }

  private acceptClaim(message: ProtocolEnvelope): void {
    const capability = message.payload.resumeCapability;
    const roomId = message.roomId;
    if (message.seatClaim < 1 || typeof capability !== "string" || !capability || !roomId) {
      this.phase = "disconnected";
      this.setStatus("The seat approval was incomplete and was rejected.");
      return;
    }
    this.roomId = roomId;
    this.seatClaim = message.seatClaim;
    this.resumeCapability = capability;
    const identity = message.payload.seatIdentity;
    this.seatIdentity = isRecord(identity) ? identity : { numeral: String(message.seatClaim) };
    this.storage.save({
      roomCode: this.roomCode,
      roomId: this.roomId,
      clientId: this.clientId,
      seatClaim: this.seatClaim,
      resumeCapability: this.resumeCapability,
    });
    this.privateVisible = false;
    this.phase = "privacy_gate";
    this.setStatus(`Seat ${this.seatClaim} approved. Private content remains obscured.`);
  }

  private submit(messageType: "prompt_choice_submit" | "role_action_submit", payload: Readonly<Record<string, JsonValue>>): void {
    if (this.seatClaim < 1 || !this.roomId || !this.privateVisible) {
      this.setStatus("Reveal the authorized private view before submitting an action.");
      return;
    }
    this.requestOrdinal += 1;
    const envelope = createEnvelope(this.roomId, messageType, `client_${this.requestOrdinal}`, payload, {
      seatClaim: this.seatClaim,
      authoritativeRevision: this.authoritativeRevision,
    });
    this.phase = "submitting";
    this.setStatus("Submitting a bounded intent to the authoritative host…");
    this.transport.send(envelope);
  }

  private clearPrivateMemory(): void {
    this.privateView = {};
    this.privateVisible = false;
    this.lastAcknowledgement = "";
  }

  private setStatus(value: string): void {
    this.status = value;
    this.listener?.();
  }
}

export class LocalCompanionStorage implements CompanionStorage {
  private static readonly key = "terror_turn_companion_v1";

  load(): StoredConnection | null {
    const raw = localStorage.getItem(LocalCompanionStorage.key);
    if (!raw) return null;
    try {
      const value: unknown = JSON.parse(raw);
      if (!isRecord(value) || typeof value.roomCode !== "string" || typeof value.roomId !== "string" || typeof value.clientId !== "string" || typeof value.seatClaim !== "number" || typeof value.resumeCapability !== "string") return null;
      return value as unknown as StoredConnection;
    } catch {
      return null;
    }
  }

  save(value: StoredConnection): void {
    localStorage.setItem(LocalCompanionStorage.key, JSON.stringify(value));
  }

  clear(): void {
    localStorage.removeItem(LocalCompanionStorage.key);
  }
}

function safeStatus(code: string): string {
  const statuses: Record<string, string> = {
    stale: "The action was stale. Refresh the authoritative view and try again.",
    duplicate: "That request was already handled; it was not applied twice.",
    unauthorized: "This browser is not authorized for that request.",
    wrong_seat: "This browser cannot act for that stable seat.",
    malformed: "The request was malformed and was not sent to gameplay.",
    rate_limited: "Too many requests were sent. Wait and try again.",
    unsupported_version: "This companion version is not supported by the room.",
    expired: "The room or claim has expired.",
    revoked: "This seat claim was revoked by the host.",
    disconnected: "Disconnected safely. Private content was removed from memory.",
  };
  return statuses[code] ?? "The request was safely rejected.";
}

function isRecord(value: unknown): value is Readonly<Record<string, JsonValue>> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
