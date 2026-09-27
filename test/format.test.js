const test = require('node:test');
const assert = require('node:assert/strict');
const { activityFromGsi } = require('../src/format');

test('zeigt Map, Modus und Teamstand', () => {
  assert.deepEqual(activityFromGsi({ map: {
    name: 'de_mirage', mode: 'competitive',
    team_ct: { score: 8 }, team_t: { score: 6 }
  }}), {
    details: 'Wettkampf · Mirage', state: 'CT 8 : 6 T',
    assets: { large_image: 'de_mirage', large_text: 'Mirage' }
  });
});

test('funktioniert im Menü und ohne Teamstand', () => {
  assert.deepEqual(activityFromGsi({}), { details: 'Im Menü', state: 'Wartet auf ein Match' });
  assert.deepEqual(activityFromGsi({ map: { name: 'de_dust2', mode: 'deathmatch' } }),
    { details: 'Deathmatch · Dust II', state: 'Match läuft',
      assets: { large_image: 'de_dust2', large_text: 'Dust II' } });
});

test('unbekannte Maps erhalten kein falsches Bild', () => {
  assert.deepEqual(activityFromGsi({ map: { name: 'workshop_custom', mode: 'competitive' } }),
    { details: 'Wettkampf · Workshop Custom', state: 'Match läuft' });
});

test('verwendet eine gemeinsame öffentliche Bild-URL', () => {
  const activity = activityFromGsi({ map: { name: 'de_mirage', mode: 'competitive' } },
    'https://raw.githubusercontent.com/example/cs2-discord-presence/main/assets/');
  assert.deepEqual(activity.assets, {
    large_image: 'https://raw.githubusercontent.com/example/cs2-discord-presence/main/assets/de_mirage.png',
    large_text: 'Mirage'
  });
});
