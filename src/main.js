const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { activityFromGsi } = require('./format');
const { DiscordRpc } = require('./discord');

const configPath = path.join(__dirname, '..', 'config.json');
if (!fs.existsSync(configPath)) {
  console.error('config.json fehlt. README.md erklärt die Einrichtung.');
  process.exit(1);
}
let config;
try { config = JSON.parse(fs.readFileSync(configPath, 'utf8').replace(/^\uFEFF/, '')); }
catch (error) { console.error(`config.json ungültig: ${error.message}`); process.exit(1); }
if (!/^\d{17,20}$/.test(String(config.discordApplicationId || ''))) {
  console.error('Bitte discordApplicationId in config.json eintragen.');
  process.exit(1);
}
const port = Number(config.port || 31982);
if (!Number.isInteger(port) || port < 1 || port > 65535) {
  console.error('Ungültiger Port in config.json.'); process.exit(1);
}
const imageBaseUrl = String(config.imageBaseUrl || '').trim();
if (imageBaseUrl && !/^https:\/\/[a-z0-9.-]+(?:\/[^\s]*)?$/i.test(imageBaseUrl)) {
  console.error('imageBaseUrl muss eine öffentliche HTTPS-Adresse sein.');
  process.exit(1);
}

const rpc = new DiscordRpc(String(config.discordApplicationId), message => console.log(message));
let lastActivity = '';
let lastGsiAt = 0;
function update(activity) {
  const key = JSON.stringify(activity);
  if (key === lastActivity) return;
  lastActivity = key;
  rpc.setActivity(activity);
  console.log(`Status: ${activity ? `${activity.details} | ${activity.state}` : 'ausgeblendet'}`);
}

const server = http.createServer((req, res) => {
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
  console.log(`Warte auf CS2 GSI auf http://127.0.0.1:${port}/`);
  rpc.start();
});
server.on('error', error => { console.error(`HTTP-Server: ${error.message}`); process.exit(1); });

setInterval(() => {
  if (lastGsiAt && Date.now() - lastGsiAt > 90000) {
    lastGsiAt = 0;
    update(null);
  }
}, 10000).unref();

process.on('SIGINT', () => { rpc.stop(); server.close(); });
process.on('SIGTERM', () => { rpc.stop(); server.close(); });
