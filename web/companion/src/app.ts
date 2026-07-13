import "./styles.css";
import type { JsonValue } from "../../../services/room-service/src/protocol";
import { CompanionAppModel, LocalCompanionStorage, type CompanionSnapshot } from "./model";
import { RoomWebSocketTransport } from "./transport";

export function mountCompanionApp(root: HTMLElement, model: CompanionAppModel): void {
  root.replaceChildren(buildShell());
  const roomForm = required<HTMLFormElement>(root, "#room-form");
  const roomCode = required<HTMLInputElement>(root, "#room-code");
  const resume = required<HTMLButtonElement>(root, "#resume-button");
  const reveal = required<HTMLButtonElement>(root, "#reveal-button");
  const obscure = required<HTMLButtonElement>(root, "#obscure-button");
  const disconnect = required<HTMLButtonElement>(root, "#disconnect-button");
  const leave = required<HTMLButtonElement>(root, "#leave-button");

  roomForm.addEventListener("submit", (event) => {
    event.preventDefault();
    void model.join(roomCode.value);
  });
  resume.addEventListener("click", () => void model.resume());
  reveal.addEventListener("click", () => model.revealPrivate());
  obscure.addEventListener("click", () => model.obscurePrivate());
  disconnect.addEventListener("click", () => model.disconnectForReconnect());
  leave.addEventListener("click", () => model.leaveAndClear());
  model.subscribe(() => render(root, model));
  render(root, model);
}

function render(root: HTMLElement, model: CompanionAppModel): void {
  const snapshot = model.snapshot();
  required<HTMLElement>(root, "#status").textContent = snapshot.status;
  required<HTMLElement>(root, "#connection-state").textContent = friendlyPhase(snapshot.phase);
  required<HTMLElement>(root, "#room-state").textContent = snapshot.roomCode ? `Room ${snapshot.roomCode}` : "No room";
  const seatBadge = required<HTMLElement>(root, "#seat-badge");
  seatBadge.hidden = snapshot.seatClaim === 0;
  seatBadge.replaceChildren(...identityNodes(snapshot));
  const resume = required<HTMLButtonElement>(root, "#resume-button");
  resume.hidden = !snapshot.canResume || snapshot.phase !== "idle" && snapshot.phase !== "disconnected";
  const privacyGate = required<HTMLElement>(root, "#privacy-gate");
  privacyGate.hidden = snapshot.phase !== "privacy_gate";
  const privatePanel = required<HTMLElement>(root, "#private-panel");
  privatePanel.hidden = !snapshot.privateVisible;
  const privateContent = required<HTMLElement>(root, "#private-content");
  privateContent.replaceChildren();
  if (snapshot.privateVisible) privateContent.append(...jsonView(snapshot.privateView));
  const publicContent = required<HTMLElement>(root, "#public-content");
  publicContent.replaceChildren(...jsonView(snapshot.publicView));
  required<HTMLElement>(root, "#acknowledgement").textContent = snapshot.lastAcknowledgement
    ? `Last result: ${snapshot.lastAcknowledgement}`
    : "No action submitted yet.";
  renderActions(root, model, snapshot);
}

function renderActions(root: HTMLElement, model: CompanionAppModel, snapshot: CompanionSnapshot): void {
  const region = required<HTMLElement>(root, "#legal-actions");
  region.replaceChildren();
  if (!snapshot.privateVisible) return;
  const rulesPrivate = asRecord(snapshot.privateView.rulesPrivate);
  const prompt = rulesPrivate ? asRecord(rulesPrivate.prompt) : asRecord(snapshot.privateView.prompt);
  const options = Array.isArray(prompt?.options) ? prompt.options : [];
  for (const optionValue of options) {
    const option = asRecord(optionValue);
    if (!option || typeof option.id !== "string") continue;
    const button = document.createElement("button");
    button.type = "button";
    button.className = "action-button";
    button.textContent = typeof option.label === "string" ? option.label : option.id;
    button.addEventListener("click", () => model.submitPrompt([String(option.id)]));
    region.append(button);
  }
  const legalActions = Array.isArray(snapshot.privateView.legalActions) ? snapshot.privateView.legalActions : [];
  for (const actionValue of legalActions) {
    const action = asRecord(actionValue);
    if (!action || typeof action.actionId !== "string") continue;
    const button = document.createElement("button");
    button.type = "button";
    button.className = "action-button";
    button.textContent = typeof action.label === "string" ? action.label : "Use legal action";
    button.addEventListener("click", () => model.submitRoleAction(String(action.actionId), []));
    region.append(button);
  }
}

function buildShell(): HTMLElement {
  const shell = document.createElement("div");
  shell.className = "app-shell";
  shell.innerHTML = `
    <header class="masthead">
      <p class="eyebrow">Optional private companion · prototype v0.0.9</p>
      <h1 id="app-title">Terror Turn Companion</h1>
      <div class="status-row" aria-label="Connection summary">
        <span id="connection-state" class="status-chip">Not connected</span>
        <span id="room-state" class="status-chip status-chip--room">No room</span>
      </div>
      <div id="seat-badge" class="seat-badge" hidden aria-label="Authorized stable seat"></div>
    </header>
    <section class="card join-card" aria-labelledby="join-title">
      <h2 id="join-title">Join the room</h2>
      <form id="room-form">
        <label for="room-code">Room code</label>
        <div class="join-row">
          <input id="room-code" name="room-code" inputmode="text" autocomplete="off" autocapitalize="characters" minlength="4" maxlength="8" pattern="[A-HJ-NP-Z2-9]{4,8}" required aria-describedby="room-help" />
          <button type="submit">Join room</button>
        </div>
        <p id="room-help" class="help">Use the code shown on the shared host display. Joining does not grant a gameplay seat.</p>
      </form>
      <button id="resume-button" type="button" class="secondary" hidden>Resume approved seat</button>
    </section>
    <section class="card status-card" aria-labelledby="status-title">
      <h2 id="status-title">Room status</h2>
      <p id="status" role="status" aria-live="polite">Enter the room code shown on the shared screen.</p>
      <div id="public-content" class="summary-grid" aria-label="Public game view"></div>
    </section>
    <section id="privacy-gate" class="privacy-gate" hidden aria-labelledby="privacy-title">
      <div class="privacy-symbol" aria-hidden="true">◈</div>
      <h2 id="privacy-title">Privacy screen</h2>
      <p>Check that only the authorized player can see this display. A shared browser screen is not private.</p>
      <button id="reveal-button" type="button">Reveal my private view</button>
    </section>
    <section id="private-panel" class="card private-card" hidden aria-labelledby="private-title">
      <div class="private-heading">
        <div>
          <p class="eyebrow">Seat-authorized view</p>
          <h2 id="private-title">Private role and choices</h2>
        </div>
        <button id="obscure-button" type="button" class="danger">Obscure now</button>
      </div>
      <div id="private-content" class="summary-grid"></div>
      <div id="legal-actions" class="action-grid" aria-label="Legal companion actions"></div>
    </section>
    <section class="card controls-card" aria-labelledby="controls-title">
      <h2 id="controls-title">Connection controls</h2>
      <p id="acknowledgement" role="status">No action submitted yet.</p>
      <div class="action-grid">
        <button id="disconnect-button" type="button" class="secondary">Disconnect for reconnect</button>
        <button id="leave-button" type="button" class="secondary">Leave and clear room data</button>
      </div>
      <p class="help">This browser stores only the current room, client, approved stable seat, and opaque resume capability. Clear removes all of it.</p>
    </section>
    <footer>
      <p>Native Godot remains authoritative. This browser sends bounded intents, not state changes.</p>
      <p>Local development may use unencrypted <code>ws://</code>. Deployed transport requires platform TLS; this prototype is not end-to-end encrypted against the relay operator.</p>
    </footer>`;
  return shell;
}

function identityNodes(snapshot: CompanionSnapshot): Node[] {
  const identity = snapshot.seatIdentity;
  const numeral = typeof identity.numeral === "string" ? identity.numeral : String(snapshot.seatClaim);
  const symbol = typeof identity.symbol === "string" ? identity.symbol : "◆";
  const pattern = typeof identity.pattern === "string" ? identity.pattern : "striped";
  const strong = document.createElement("strong");
  strong.textContent = `Seat ${numeral}`;
  const details = document.createElement("span");
  details.textContent = `${symbol} · ${pattern}`;
  return [strong, details];
}

function jsonView(value: Readonly<Record<string, JsonValue>>): HTMLElement[] {
  const rows: HTMLElement[] = [];
  for (const [key, item] of Object.entries(value)) {
    if (key === "resumeCapability") continue;
    const row = document.createElement("div");
    row.className = "summary-row";
    const label = document.createElement("span");
    label.className = "summary-label";
    label.textContent = friendlyKey(key);
    const content = document.createElement("span");
    content.className = "summary-value";
    content.textContent = friendlyValue(item);
    row.append(label, content);
    rows.push(row);
  }
  return rows;
}

function friendlyValue(value: JsonValue): string {
  if (value === null) return "—";
  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") return String(value);
  if (Array.isArray(value)) return value.map((item) => friendlyValue(item)).join(" · ");
  return Object.entries(value).map(([key, item]) => `${friendlyKey(key)}: ${friendlyValue(item)}`).join(" · ");
}

function friendlyKey(value: string): string {
  return value.replace(/([a-z])([A-Z])/g, "$1 $2").replaceAll("_", " ").replace(/^./, (letter) => letter.toUpperCase());
}

function friendlyPhase(value: string): string {
  return friendlyKey(value);
}

function asRecord(value: JsonValue | undefined): Readonly<Record<string, JsonValue>> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value) ? value : null;
}

function required<T extends Element>(root: ParentNode, selector: string): T {
  const result = root.querySelector<T>(selector);
  if (!result) throw new Error(`Missing companion UI element ${selector}`);
  return result;
}

const root = document.querySelector<HTMLElement>("#main");
if (root) {
  const serviceBase = location.hostname === "localhost" ? "http://localhost:8787" : "http://127.0.0.1:8787";
  const model = new CompanionAppModel(
    new RoomWebSocketTransport(serviceBase),
    new LocalCompanionStorage(),
    () => `browser_${crypto.randomUUID().replaceAll("-", "").slice(0, 16)}`,
  );
  mountCompanionApp(root, model);
}
