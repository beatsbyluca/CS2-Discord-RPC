const test = require('node:test');
const assert = require('node:assert/strict');
const { activityFromGsi } = require('../src/format');

test('shows map, mode, and team scores', () => {
  assert.deepEqual(activityFromGsi({ map: {
    name: 'de_mirage', mode: 'competitive',
    team_ct: { score: 8 }, team_t: { score: 6 }
  }}), {
    details: 'Competitive · Mirage', state: 'CT 8 : 6 T',
    assets: { large_image: 'de_mirage', large_text: 'Mirage' }
  });
});

test('handles the menu and a match without team scores', () => {
  assert.deepEqual(activityFromGsi({}), { details: 'In Menu', state: 'Waiting for a match' });
  assert.deepEqual(activityFromGsi({ map: { name: 'de_dust2', mode: 'deathmatch' } }),
    { details: 'Deathmatch · Dust II', state: 'Match in progress',
      assets: { large_image: 'de_dust2', large_text: 'Dust II' } });
});

test('does not use an unrelated image for an unknown map', () => {
  assert.deepEqual(activityFromGsi({ map: { name: 'workshop_custom', mode: 'competitive' } }),
    { details: 'Competitive · Workshop Custom', state: 'Match in progress' });
});

test('uses a shared public image URL', () => {
  const activity = activityFromGsi({ map: { name: 'de_mirage', mode: 'competitive' } },
    'https://raw.githubusercontent.com/example/cs2-discord-presence/main/assets/');
  assert.deepEqual(activity.assets, {
    large_image: 'https://raw.githubusercontent.com/example/cs2-discord-presence/main/assets/de_mirage.png',
    large_text: 'Mirage'
  });
});

test('shows the player team as a small image and omits it while spectating', () => {
  const data = { map: { name: 'de_mirage', mode: 'competitive' }, player: { team: 'CT' } };
  assert.equal(activityFromGsi(data, 'https://example.com/assets').assets.small_image,
    'https://example.com/assets/ct_logo.png');
  assert.equal(activityFromGsi(data).assets.small_text, 'Counter-Terrorists');
  data.player.team = 'T';
  assert.equal(activityFromGsi(data, 'https://example.com/assets').assets.small_image,
    'https://example.com/assets/t_logo.png');
  data.player.team = 'SPECTATOR';
  assert.equal(activityFromGsi(data).assets.small_image, undefined);
});
