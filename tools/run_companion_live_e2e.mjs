#!/usr/bin/env node

import { spawn } from "node:child_process";
import { unstable_dev } from "wrangler";

const output = [];
const waiters = [];

async function main() {
  const godot = process.env.GODOT_BIN || "Godot_v4.7-stable_linux.x86_64";
  const worker = await unstable_dev("services/room-service/src/worker.ts", {
    config: "services/room-service/wrangler.jsonc",
    local: true,
    persist: false,
    logLevel: "none",
    experimental: { disableExperimentalWarning: true, disableDevRegistry: true },
  });
  const serviceUrl = `http://${worker.address}:${worker.port}`;
  let godotProcess;

  try {
  godotProcess = spawn(godot, [
    "--headless", "--path", "game", "--script", "res://tests/companion_live_host_test.gd",
    "--", "--service-url", serviceUrl,
  ], { cwd: process.cwd(), windowsHide: true, stdio: ["ignore", "pipe", "pipe"] });
  collectLines(godotProcess.stdout);
  collectLines(godotProcess.stderr);

  const roomLine = await waitForLine("COMPANION_E2E_ROOM:", 30_000);
  const room = JSON.parse(roomLine.slice("COMPANION_E2E_ROOM:".length));
  const first = await BrowserSocket.join(serviceUrl, room.joinCode, "browser_e2e");
  const approval = await first.nextEnvelope("seat_claim_approved");
  const resumeCapability = approval.payload.resumeCapability;
  if (typeof resumeCapability !== "string" || !resumeCapability) throw new Error("missing_resume_capability");
  await first.nextEnvelope("seat_private_view_update");
  first.close();
  await delay(100);

  const resumed = await BrowserSocket.resume(serviceUrl, room.joinCode, "browser_e2e", 1, resumeCapability);
  await resumed.nextEnvelope("reconnect_resume");
  const privateView = await resumed.nextEnvelope("seat_private_view_update");
  resumed.send({
    protocolVersion: 1,
    roomId: room.roomId,
    messageType: "prompt_choice_submit",
    serverSequence: 0,
    authoritativeRevision: privateView.authoritativeRevision,
    requestId: "browser_e2e_choice",
    seatClaim: 1,
    payload: { optionIds: ["listen"], promptRevision: 1 },
    acknowledgement: "",
  });
  await resumed.next((value) => value?.messageType === "acknowledgement" && value?.payload?.relayAccepted === true);
  const authoritative = await resumed.next((value) => value?.messageType === "acknowledgement" && value?.payload?.appliedOnce === true);
  if (authoritative.acknowledgement !== "accepted") throw new Error("authoritative_ack_rejected");
  const resultLine = await waitForLine("COMPANION_E2E_RESULT:", 15_000);
  const result = JSON.parse(resultLine.slice("COMPANION_E2E_RESULT:".length));
  if (result.accepted !== true) throw new Error(`native_result:${result.reason}`);
  const authorityLine = output.find((line) => line.startsWith("COMPANION_E2E_AUTHORITY:"));
  const reconnectLine = output.find((line) => line.startsWith("COMPANION_E2E_RECONNECT:"));
  if (!authorityLine || !reconnectLine) throw new Error("missing_native_authority_or_reconnect_evidence");
  const authority = JSON.parse(authorityLine.slice("COMPANION_E2E_AUTHORITY:".length));
  if (authority.historyDelta !== 1 || authority.appliedOnce !== true) throw new Error("action_not_applied_exactly_once");
  const serializedOutput = output.join("\n").toLowerCase();
  for (const forbidden of ["sealed_archive", "the sealed archive", "sealed_shelves", "archive_route", "archive_stairs", resumeCapability.toLowerCase()]) {
    if (serializedOutput.includes(forbidden)) throw new Error(`private_value_in_native_log:${forbidden}`);
  }
  resumed.close();
  process.stdout.write("Live companion E2E passed: browser protocol client -> room service -> native Godot authority -> authoritative browser ACK; reconnect preserved Seat 1; history delta 1.\n");
  } finally {
    godotProcess?.kill();
    await worker.stop();
  }
}

function collectLines(stream) {
  let buffer = "";
  stream.setEncoding("utf8");
  stream.on("data", (chunk) => {
    buffer += chunk;
    const lines = buffer.split(/\r?\n/);
    buffer = lines.pop() ?? "";
    for (const line of lines) {
      if (!line) continue;
      output.push(line);
      for (const waiter of [...waiters]) {
        if (line.startsWith(waiter.prefix)) {
          waiters.splice(waiters.indexOf(waiter), 1);
          clearTimeout(waiter.timer);
          waiter.resolve(line);
        }
      }
    }
  });
}

function waitForLine(prefix, timeoutMs) {
  const existing = output.find((line) => line.startsWith(prefix));
  if (existing) return Promise.resolve(existing);
  return new Promise((resolve, reject) => {
    const waiter = { prefix, resolve, timer: undefined };
    waiter.timer = setTimeout(() => {
      const index = waiters.indexOf(waiter);
      if (index >= 0) waiters.splice(index, 1);
      reject(new Error(`native_line_timeout:${prefix}:${output.join("|")}`));
    }, timeoutMs);
    waiters.push(waiter);
  });
}

class BrowserSocket {
  constructor(socket) {
    this.socket = socket;
    this.messages = [];
    socket.addEventListener("message", (event) => {
      try { this.messages.push(JSON.parse(String(event.data))); } catch { this.messages.push({ accepted: false, code: "malformed" }); }
    });
  }

  static async join(baseUrl, roomCode, clientId) {
    return BrowserSocket.connect(baseUrl, roomCode, { operation: "join", clientId });
  }

  static async resume(baseUrl, roomCode, clientId, seatClaim, resumeCapability) {
    return BrowserSocket.connect(baseUrl, roomCode, { operation: "resume", clientId, seatClaim, resumeCapability });
  }

  static async connect(baseUrl, roomCode, authentication) {
    const socket = new WebSocket(`${baseUrl.replace("http://", "ws://")}/v1/rooms/${roomCode}/socket`);
    const browser = new BrowserSocket(socket);
    await new Promise((resolve, reject) => {
      socket.addEventListener("open", resolve, { once: true });
      socket.addEventListener("error", () => reject(new Error("browser_socket_open_failed")), { once: true });
    });
    socket.send(JSON.stringify(authentication));
    await browser.next((value) => value?.accepted === true);
    return browser;
  }

  send(value) { this.socket.send(JSON.stringify(value)); }
  nextEnvelope(messageType) { return this.next((value) => value?.messageType === messageType); }
  async next(predicate, timeoutMs = 5_000) {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
      const index = this.messages.findIndex(predicate);
      if (index >= 0) return this.messages.splice(index, 1)[0];
      await delay(5);
    }
    throw new Error(`browser_message_timeout:${JSON.stringify(this.messages)}`);
  }
  close() { if (this.socket.readyState === WebSocket.OPEN) this.socket.close(1000, "e2e_reconnect"); }
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

await main();
