const MODES = {
  competitive: 'Wettkampf',
  casual: 'Gelegenheitsspiel',
  deathmatch: 'Deathmatch',
  wingman: 'Wingman',
  armsrace: 'Wettrüsten',
  demolition: 'Zerstörung'
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
  if (typeof raw !== 'string' || !raw) return 'Unbekannte Map';
  return MAPS[raw] || raw.replace(/^(de|cs)_/, '').replace(/_/g, ' ')
    .replace(/\b\w/g, char => char.toUpperCase());
}

function activityFromGsi(data, imageBaseUrl = '') {
  const map = data?.map;
  if (!map || typeof map !== 'object' || !map.name) {
    return { details: 'Im Menü', state: 'Wartet auf ein Match' };
  }
  const mode = MODES[map.mode] || (typeof map.mode === 'string' && map.mode
    ? map.mode : 'Unbekannter Modus');
  const name = mapName(map.name);
  const ct = map.team_ct?.score;
  const t = map.team_t?.score;
  const hasScore = Number.isInteger(ct) && Number.isInteger(t);
  const state = hasScore ? `CT ${ct} : ${t} T` : 'Match läuft';
  const activity = { details: `${mode} · ${name}`, state };
  if (assetKeys.has(map.name)) {
    const image = imageBaseUrl
      ? `${imageBaseUrl.replace(/\/+$/, '')}/${encodeURIComponent(map.name)}.png`
      : map.name;
    activity.assets = { large_image: image, large_text: name };
  }
  return activity;
}

module.exports = { activityFromGsi, mapName };
