# CS2 Discord RPC

Show your current Counter-Strike 2 map, mode, CT/T score, and team in Discord Rich Presence. Map and team images load from this public repository, so users do not need to upload Discord art assets.

## Easy setup on Windows

1. Download **`CS2-Discord-RPC-Setup.exe`** from the [latest release](https://github.com/beatsbyluca/CS2-Discord-RPC/releases/latest).
2. Run the EXE. It installs the app to `%LOCALAPPDATA%\CS2 RPC` and opens a console wizard. The wizard finds CS2 in your Steam libraries, offers the shared Discord Application ID, and creates a desktop shortcut. If Node.js is missing, it downloads a portable LTS copy from the official Node.js site and verifies its SHA-256 checksum.
3. Restart CS2 if it was open during setup. Open the Discord desktop app.
4. Double-click **CS2 Discord RPC** on your desktop, or run `start.cmd` in the project folder. The app runs in the Windows notification area. Right-click its **CS2** icon to restart the RPC, open logs, or exit. Windows may hide the icon behind the notification area's up arrow.

The wizard stores your settings in `config.json` and writes `gamestate_integration_discord_presence.cfg` into CS2's config folder. Exit the tray app before running the installer again to update it. No administrator rights are needed for the normal setup.

If you run from source, keep the folder in place and use `start.cmd` or `src/start.vbs` after creating `config.json` and the CS2 GSI configuration.

## What it shows

- Example text: `Competitive · Mirage` and `CT 8 : 6 T`.
- The large image is the map. The small image is your CT or T logo. No team logo appears in the menu or while spectating.
- CS2 reports both Premier and standard Competitive as `competitive` through GSI, so both display as **Competitive**.

## Files and troubleshooting

- Logs for the current run are in `logs/app.log` and `logs/error.log` inside the project folder.
- The portable Node.js runtime, when needed, is stored in `runtime/`.
- `config.json`, logs, and the downloaded runtime are local files and are excluded from Git.
- The app listens for CS2 data only on `127.0.0.1`. It clears the Discord activity after 90 seconds without game data and reconnects to Discord automatically.
- Exiting from the tray stops the local server and clears the Discord activity.
- If Discord shows two CS2 activities, disable its automatic CS2 game detection under **Registered Games**.

For developers, `npm start` runs the same app with a system Node.js installation. The image URL is configured through `imageBaseUrl` in `config.json`; it defaults to this repository's public `assets/` directory.
