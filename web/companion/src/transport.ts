import { parseEnvelope, type JsonValue, type ProtocolEnvelope } from "../../../services/room-service/src/protocol";
import type { CompanionTransport, ServiceStatus } from "./model";

export class RoomWebSocketTransport implements CompanionTransport {
  private socket: WebSocket | undefined;
  private receiver: ((message: ProtocolEnvelope | ServiceStatus) => void) | undefined;

  constructor(private readonly serviceBaseUrl: string) {}

  setReceiver(receiver: (message: ProtocolEnvelope | ServiceStatus) => void): void {
    this.receiver = receiver;
  }

  connect(roomCode: string, authentication: Readonly<Record<string, JsonValue>>): Promise<void> {
    this.disconnect();
    const base = new URL(this.serviceBaseUrl);
    const scheme = base.protocol === "https:" ? "wss:" : "ws:";
    const socketUrl = `${scheme}//${base.host}/v1/rooms/${roomCode}/socket`;
    return new Promise((resolve, reject) => {
      const socket = new WebSocket(socketUrl);
      this.socket = socket;
      socket.addEventListener("open", () => {
        socket.send(JSON.stringify(authentication));
        resolve();
      }, { once: true });
      socket.addEventListener("error", () => reject(new Error("socket_unavailable")), { once: true });
      socket.addEventListener("message", (event) => this.receiveRaw(String(event.data)));
      socket.addEventListener("close", () => this.receiver?.({ accepted: false, code: "disconnected" }));
    });
  }

  send(envelope: ProtocolEnvelope): void {
    if (this.socket?.readyState !== WebSocket.OPEN) {
      this.receiver?.({ accepted: false, code: "disconnected" });
      return;
    }
    this.socket.send(JSON.stringify(envelope));
  }

  disconnect(): void {
    this.socket?.close(1000, "client_leave");
    this.socket = undefined;
  }

  private receiveRaw(raw: string): void {
    const parsed = parseEnvelope(raw);
    if (parsed.accepted && parsed.envelope) {
      this.receiver?.(parsed.envelope);
      return;
    }
    try {
      const value: unknown = JSON.parse(raw);
      if (typeof value === "object" && value !== null && "accepted" in value && "code" in value) {
        this.receiver?.({ accepted: Boolean(value.accepted), code: String(value.code) });
      }
    } catch {
      this.receiver?.({ accepted: false, code: "malformed" });
    }
  }
}
