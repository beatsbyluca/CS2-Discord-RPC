# CS2 Discord RPC

Show the current Counter-Strike 2 map, mode, CT/T score, and your team in Discord Rich Presence. The app runs locally on Windows with Node.js and has no package dependencies.

## Setup

1. Install Node.js 18 or newer and the Discord desktop app.
2. Create an application at https://discord.com/developers/applications. Copy its **Application ID** from **General Information**. The application name appears as the title of your Discord activity.
3. Copy `config.example.json` to `config.json` and set `discordApplicationId`.
4. Run `install.ps1` in PowerShell. It searches your Steam libraries for CS2. If it cannot find the game, run `./install.ps1 -Cs2CfgDir 'X:\...\game\csgo\cfg'` with the correct path.
5. Restart CS2, open Discord, and run `start.cmd`. Keep the window open while playing.

Example: `Competitive · Mirage` / `CT 8 : 6 T`.

## Images

The `assets/` directory contains 49 map images and two team logos. The app uses the public `imageBaseUrl` in `config.json` to send Discord an image URL such as `.../assets/de_mirage.png`. Users do not need to upload images to their own Discord applications.

The map is the large image. Your current team (CT or T) is the small image. The team badge is omitted in the menu and while spectating. The GSI configuration subscribes to `map` and `player_id` to get these details. Restart CS2 after changing the GSI configuration.

The default image URL points to this public GitHub repository. If you publish a fork under a different account or branch, update `imageBaseUrl` in `config.example.json`. You can also use another public HTTPS image host. If `imageBaseUrl` is empty, the app uses Discord art asset keys instead, which requires uploading the images to your application.

## Notes

- CS2 reports both Premier and standard Competitive as `competitive` through GSI, so the presence shows **Competitive** for both.
- The activity clears after 90 seconds without GSI data. Discord connections retry automatically.
- The CS2 data receiver listens only on `127.0.0.1`.
- If Discord shows two CS2 activities, you can disable its automatic CS2 game detection under **Registered Games**.

## Tests

Run `npm test` to check status formatting and image URLs. To verify the full integration, run CS2 and Discord with a valid Application ID.
