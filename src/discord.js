const net = require('node:net');
const { randomUUID } = require('node:crypto');

function frame(opcode, value) {
  const body = Buffer.from(JSON.stringify(value), 'utf8');
  const header = Buffer.alloc(8);
  header.writeUInt32LE(opcode, 0);
  header.writeUInt32LE(body.length, 4);
  return Buffer.concat([header, body]);
}

class DiscordRpc {
  constructor(clientId, onStatus = () => {}) {
    this.clientId = clientId;
    this.onStatus = onStatus;
    this.activity = null;
    this.socket = null;
    this.ready = false;
    this.stopped = false;
    this.retryTimer = null;
    this.retryDelay = 3000;
  }

  start() { this.connect(); }

  connect() {
    if (this.stopped) return;
    // Discord may use any of ten IPC slots.
    this.trySlot(0);
  }

  trySlot(slot) {
    if (this.stopped) return;
    if (slot > 9) {
      this.onStatus('Discord nicht erreichbar; neuer Versuch in 3 Sekunden.');
      this.scheduleRetry();
      return;
    }
    const socket = net.connect(`\\\\?\\pipe\\discord-ipc-${slot}`);
    let settled = false;
    socket.once('connect', () => {
      settled = true;
      this.socket = socket;
      this.ready = false;
      this.retryDelay = 3000;
      this.attach(socket);
      socket.write(frame(0, { v: 1, client_id: this.clientId }));
    });
    socket.once('error', error => {
      if (!settled) {
        settled = true;
        socket.destroy();
        this.trySlot(slot + 1);
      } else {
        this.onStatus(`Discord-Verbindung: ${error.message}`);
      }
    });
  }

  attach(socket) {
    let pending = Buffer.alloc(0);
    socket.on('data', chunk => {
      pending = Buffer.concat([pending, chunk]);
      while (pending.length >= 8) {
        const opcode = pending.readUInt32LE(0);
        const length = pending.readUInt32LE(4);
        if (length > 1024 * 1024) { socket.destroy(); return; }
        if (pending.length < 8 + length) break;
        const body = pending.subarray(8, 8 + length);
        pending = pending.subarray(8 + length);
        if (opcode === 3) { socket.write(Buffer.concat([frameHeader(4, length), body])); continue; }
        if (opcode === 2) { socket.destroy(); continue; }
        if (opcode !== 1) continue;
        let message;
        try { message = JSON.parse(body.toString('utf8')); } catch { continue; }
        if (message.evt === 'READY') {
          this.ready = true;
          this.onStatus('Mit Discord verbunden.');
          this.publish();
        } else if (message.evt === 'ERROR') {
          this.onStatus(`Discord-Fehler: ${message.data?.message || 'unbekannt'}`);
        }
      }
    });
    socket.on('close', () => {
      if (this.socket !== socket) return;
      this.socket = null;
      this.ready = false;
      if (!this.stopped) { this.onStatus('Discord getrennt.'); this.scheduleRetry(); }
    });
  }

  scheduleRetry() {
    if (this.retryTimer || this.stopped) return;
    this.retryTimer = setTimeout(() => {
      this.retryTimer = null;
      this.connect();
    }, this.retryDelay);
  }

  setActivity(activity) {
    this.activity = activity;
    this.publish();
  }

  publish() {
    if (!this.ready || !this.socket) return;
    this.socket.write(frame(1, {
      cmd: 'SET_ACTIVITY',
      args: { pid: process.pid, activity: this.activity },
      nonce: randomUUID()
    }));
  }

  stop() {
    this.stopped = true;
    clearTimeout(this.retryTimer);
    if (this.socket) {
      this.activity = null;
      this.publish();
      this.socket.end();
    }
  }
}

function frameHeader(opcode, length) {
  const header = Buffer.alloc(8);
  header.writeUInt32LE(opcode, 0);
  header.writeUInt32LE(length, 4);
  return header;
}

module.exports = { DiscordRpc };
