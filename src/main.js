const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { activityFromGsi } = require('./format');
const { DiscordRpc } = require('./discord');

const configPath = path.join(__dirname, '..', 'config.json');
if (!fs.existsSync(configPath)) {
  console.error('config.json is missing. See README.md for setup instructions.');
  process.exit(1);
}
let config;
try { config = JSON.parse(fs.readFileSync(configPath, 'utf8').replace(/^\uFEFF/, '')); }
catch (error) { console.error(`Invalid config.json: ${error.message}`); process.exit(1); }
if (!/^\d{17,20}$/.test(String(config.discordApplicationId || ''))) {
  console.error('Set discordApplicationId in config.json.');
  process.exit(1);
}
const port = Number(config.port || 31982);
if (!Number.isInteger(port) || port < 1 || port > 65535) {
  console.error('Invalid port in config.json.'); process.exit(1);
}
const imageBaseUrl = String(config.imageBaseUrl || '').trim();
if (imageBaseUrl && !/^https:\/\/[a-z0-9.-]+(?:\/[^\s]*)?$/i.test(imageBaseUrl)) {
  console.error('imageBaseUrl must be a public HTTPS URL.');
  process.exit(1);
}

const rpc = new DiscordRpc(String(config.discordApplicationId), message => console.log(message));
let lastActivity = '';
let lastGsiAt = 0;
let shuttingDown = false;
function update(activity) {
  const key = JSON.stringify(activity);
  if (key === lastActivity) return;
  lastActivity = key;
  rpc.setActivity(activity);
  console.log(`Status: ${activity ? `${activity.details} | ${activity.state}` : 'hidden'}`);
}

const server = http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/quit' && process.env.CS2_RPC_TRAY_TOKEN) {
    const remote = req.socket.remoteAddress;
    if (!['127.0.0.1', '::1', '::ffff:127.0.0.1'].includes(remote) ||
        req.headers['x-tray-token'] !== process.env.CS2_RPC_TRAY_TOKEN) {
      res.writeHead(403).end(); return;
    }
    res.writeHead(200).end('Stopping', shutdown);
    return;
  }
  if (req.method !== 'POST' || req.url !== '/') { res.writeHead(404).end(); return; }
  const remote = req.socket.remoteAddress;
  if (!['127.0.0.1', '::1', '::ffff:127.0.0.1'].includes(remote)) {
    res.writeHead(403).end(); return;
  }
  let raw = '';
  req.on('data', chunk => {
    raw += chunk;
    if (raw.length > 1024 * 1024) req.destroy();
  });
  req.on('end', () => {
    let data;
    try { data = JSON.parse(raw); }
    catch { res.writeHead(400).end(); return; }
    lastGsiAt = Date.now();
    update(activityFromGsi(data, imageBaseUrl));
    res.writeHead(200).end('OK');
  });
});

server.listen(port, '127.0.0.1', () => {
  console.log(`Waiting for CS2 GSI at http://127.0.0.1:${port}/`);
  rpc.start();
});
server.on('error', error => { console.error(`HTTP-Server: ${error.message}`); process.exit(1); });

setInterval(() => {
  if (lastGsiAt && Date.now() - lastGsiAt > 90000) {
    lastGsiAt = 0;
    update(null);
  }
}, 10000).unref();

function shutdown() {
  if (shuttingDown) return;
  shuttingDown = true;
  rpc.stop();
  server.close();
  server.closeAllConnections();
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
