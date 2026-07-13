export const PROTOCOL_VERSION = 1 as const;
export const SERVICE_VERSION = "0.0.9";
export const MAX_MESSAGE_BYTES = 8_192;
export const MAX_STRING_LENGTH = 256;
export const MAX_REQUEST_ID_LENGTH = 64;
export const MAX_COLLECTION_ITEMS = 64;
export const MAX_NESTING_DEPTH = 8;

export const MESSAGE_TYPES = [
  "room_created", "room_closed", "client_joined", "client_left",
  "seat_claim_requested", "seat_claim_approved", "seat_claim_rejected",
  "reconnect_resume", "public_view_update", "seat_private_view_update",
  "faction_private_view_update", "prompt_choice_submit", "role_action_submit",
  "private_reveal_ack", "acknowledgement", "rejection", "host_heartbeat",
  "room_expired",
] as const;

export const REJECTION_CODES = [
  "stale", "duplicate", "unauthorized", "malformed", "rate_limited",
  "unsupported_version", "unsupported_type", "expired", "room_full",
  "wrong_seat", "revoked", "host_missing", "body_too_large",
] as const;

export type MessageType = typeof MESSAGE_TYPES[number];
export type RejectionCode = typeof REJECTION_CODES[number];
export type JsonPrimitive = string | number | boolean | null;
export type JsonValue = JsonPrimitive | JsonValue[] | { [key: string]: JsonValue };

export interface ProtocolEnvelope {
  readonly protocolVersion: typeof PROTOCOL_VERSION;
  readonly roomId: string;
  readonly messageType: MessageType;
  readonly serverSequence: number;
  readonly authoritativeRevision: number;
  readonly requestId: string;
  readonly seatClaim: number;
  readonly payload: Readonly<Record<string, JsonValue>>;
  readonly acknowledgement: "" | "accepted" | RejectionCode;
}

export interface ValidationResult {
  readonly accepted: boolean;
  readonly code: "accepted" | RejectionCode;
  readonly envelope?: ProtocolEnvelope;
}

const stableIdPattern = /^[a-z0-9][a-z0-9_-]{0,63}$/;

export function parseEnvelope(raw: string): ValidationResult {
  if (new TextEncoder().encode(raw).byteLength > MAX_MESSAGE_BYTES) {
    return { accepted: false, code: "body_too_large" };
  }
  try {
    return validateEnvelope(JSON.parse(raw) as unknown);
  } catch {
    return { accepted: false, code: "malformed" };
  }
}

export function validateEnvelope(value: unknown): ValidationResult {
  if (!isRecord(value)) return { accepted: false, code: "malformed" };
  if (value.protocolVersion !== PROTOCOL_VERSION) {
    return { accepted: false, code: "unsupported_version" };
  }
  if (typeof value.messageType !== "string" || !MESSAGE_TYPES.includes(value.messageType as MessageType)) {
    return { accepted: false, code: "unsupported_type" };
  }
  if (!isBoundedId(value.roomId) || !isBoundedId(value.requestId, MAX_REQUEST_ID_LENGTH)) {
    return { accepted: false, code: "malformed" };
  }
  if (!isNonNegativeInteger(value.serverSequence) || !isNonNegativeInteger(value.authoritativeRevision)) {
    return { accepted: false, code: "malformed" };
  }
  if (!Number.isInteger(value.seatClaim) || (value.seatClaim as number) < 0 || (value.seatClaim as number) > 8) {
    return { accepted: false, code: "malformed" };
  }
  if (!isRecord(value.payload) || !isBoundedJson(value.payload)) {
    return { accepted: false, code: "malformed" };
  }
  const acknowledgement = value.acknowledgement;
  if (acknowledgement !== "" && acknowledgement !== "accepted" && !REJECTION_CODES.includes(acknowledgement as RejectionCode)) {
    return { accepted: false, code: "malformed" };
  }
  return { accepted: true, code: "accepted", envelope: value as unknown as ProtocolEnvelope };
}

export function isBoundedJson(value: unknown, depth = 0): value is JsonValue {
  if (depth > MAX_NESTING_DEPTH) return false;
  if (value === null || typeof value === "boolean") return true;
  if (typeof value === "number") return Number.isFinite(value);
  if (typeof value === "string") return value.length <= MAX_STRING_LENGTH;
  if (Array.isArray(value)) {
    return value.length <= MAX_COLLECTION_ITEMS && value.every((item) => isBoundedJson(item, depth + 1));
  }
  if (!isRecord(value) || Object.keys(value).length > MAX_COLLECTION_ITEMS) return false;
  return Object.entries(value).every(([key, item]) => key.length <= MAX_STRING_LENGTH && isBoundedJson(item, depth + 1));
}

export function createEnvelope(
  roomId: string,
  messageType: MessageType,
  requestId: string,
  payload: Readonly<Record<string, JsonValue>> = {},
  options: { serverSequence?: number; authoritativeRevision?: number; seatClaim?: number; acknowledgement?: ProtocolEnvelope["acknowledgement"] } = {},
): ProtocolEnvelope {
  const envelope: ProtocolEnvelope = {
    protocolVersion: PROTOCOL_VERSION,
    roomId,
    messageType,
    serverSequence: options.serverSequence ?? 0,
    authoritativeRevision: options.authoritativeRevision ?? 0,
    requestId,
    seatClaim: options.seatClaim ?? 0,
    payload,
    acknowledgement: options.acknowledgement ?? "",
  };
  const validation = validateEnvelope(envelope);
  if (!validation.accepted) throw new Error(`Invalid protocol envelope: ${validation.code}`);
  return envelope;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isNonNegativeInteger(value: unknown): value is number {
  return Number.isInteger(value) && (value as number) >= 0;
}

function isBoundedId(value: unknown, maximum = 64): value is string {
  return typeof value === "string" && value.length <= maximum && stableIdPattern.test(value);
}
