const MODES = {
  competitive: 'Competitive',
  casual: 'Casual',
  deathmatch: 'Deathmatch',
  wingman: 'Wingman',
  armsrace: 'Arms Race',
  demolition: 'Demolition'
};

const fs = require('node:fs');
const path = require('node:path');
const assetKeys = new Set(
  fs.readdirSync(path.join(__dirname, '..', 'assets'))
    .filter(file => /^(ar|cs|de)_[a-z0-9_]+\.png$/.test(file))
    .map(file => path.basename(file, '.png'))
);

const MAPS = {
  de_dust2: 'Dust II', de_mirage: 'Mirage', de_inferno: 'Inferno',
  de_nuke: 'Nuke', de_ancient: 'Ancient', de_anubis: 'Anubis',
  de_vertigo: 'Vertigo', de_train: 'Train', de_overpass: 'Overpass',
  de_cache: 'Cache', de_cbble: 'Cobblestone', cs_office: 'Office',
  cs_italy: 'Italy'
};

function mapName(raw) {
  if (typeof raw !== 'string' || !raw) return 'Unknown Map';
  return MAPS[raw] || raw.replace(/^(de|cs)_/, '').replace(/_/g, ' ')
    .replace(/\b\w/g, char => char.toUpperCase());
}

function imageRef(key, imageBaseUrl) {
  return imageBaseUrl
    ? `${imageBaseUrl.replace(/\/+$/, '')}/${encodeURIComponent(key)}.png`
    : key;
}

function activityFromGsi(data, imageBaseUrl = '') {
  const map = data?.map;
  if (!map || typeof map !== 'object' || !map.name) {
    return { details: 'In Menu', state: 'Waiting for a match' };
  }
  const mode = MODES[map.mode] || (typeof map.mode === 'string' && map.mode
    ? map.mode : 'Unknown Mode');
  const name = mapName(map.name);
  const ct = map.team_ct?.score;
  const t = map.team_t?.score;
  const hasScore = Number.isInteger(ct) && Number.isInteger(t);
  const state = hasScore ? `CT ${ct} : ${t} T` : 'Match in progress';
  const activity = { details: `${mode} · ${name}`, state };
  const assets = {};
  if (assetKeys.has(map.name)) {
    assets.large_image = imageRef(map.name, imageBaseUrl);
    assets.large_text = name;
  }
  const team = typeof data.player?.team === 'string' ? data.player.team.toUpperCase() : '';
  if (team === 'CT' || team === 'T') {
    assets.small_image = imageRef(team === 'CT' ? 'ct_logo' : 't_logo', imageBaseUrl);
    assets.small_text = team === 'CT' ? 'Counter-Terrorists' : 'Terrorists';
  }
  if (Object.keys(assets).length) activity.assets = assets;
  return activity;
}

module.exports = { activityFromGsi, mapName };
