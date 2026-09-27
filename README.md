# CS2 Discord RPC

Show your Counter-Strike 2 match in Discord: **map, mode, CT/T score, and team**, with matching artwork. The app runs quietly in the Windows system tray.

**[Download the latest Windows installer](https://github.com/beatsbyluca/CS2-Discord-RPC/releases/latest)**

## Get started

1. Download and run `CS2-Discord-RPC-Setup.exe` from the link above.
2. Follow the setup wizard. It finds CS2, configures game state integration, and can create a desktop shortcut. If Node.js is missing, it installs a portable copy for this app.
3. Open the Discord desktop app. Restart CS2 if it was open during setup.
4. Launch **CS2 Discord RPC** from the desktop shortcut or `%LOCALAPPDATA%\CS2 RPC\start.cmd`.

Look for the **CS2** icon in the notification area, possibly behind the **^** arrow. Right-click it to **restart the RPC**, **open logs**, or **exit**. The app reconnects when Discord opens later.

## Start automatically with Windows

The app starts when **you sign in**, without needing to launch the desktop shortcut each time.

1. Install the app using the EXE above.
2. Press **Win + R**, enter `shell:startup`, and press **Enter**.
3. In the folder that opens, right-click an empty area and choose **New → Shortcut**.
4. Paste this as the shortcut location:

   ```text
   %LOCALAPPDATA%\CS2 RPC\src\start.vbs
   ```

5. Name it **CS2 Discord RPC** and select **Finish**. The VBS starter launches the tray app without a console window.

To turn autostart off, open `shell:startup` again and delete **only that shortcut**. This does not uninstall the app. If you installed to a different folder, use that folder's `src\start.vbs` in step 4. See [Microsoft's Startup folder guide](https://support.microsoft.com/en-us/windows/experience/startup-boot/configure-startup-applications-in-windows) for the Windows steps.

## What Discord shows

| Part | Example |
| --- | --- |
| Details | `Competitive · Mirage` |
| Score | `CT 8 : 6 T` |
| Menu | `In Menu` · `Waiting for a match` |
| Images | Current map and your CT/T team icon |

Map and team images load from this repository; you do not need to upload Discord artwork. CS2 reports both Premier and standard Competitive as `competitive`, so both appear as **Competitive**. The app clears its Discord activity after 90 seconds without game data or when you exit from the tray.

## Troubleshooting

| Problem | Try this |
| --- | --- |
| No tray icon | Check the notification area's **^** menu. Then open `%LOCALAPPDATA%\CS2 RPC\logs\error.log`. |
| No Discord activity | Open the Discord desktop app and CS2. If CS2 was running during setup, restart it. |
| Two CS2 activities | Disable Discord's automatic CS2 detection under **Registered Games**. |
| Need to update | Exit the tray app, then run the latest installer again. |

The app receives CS2 data only on `127.0.0.1`. Its settings are in `%LOCALAPPDATA%\CS2 RPC\config.json`; logs are in the adjacent `logs` folder.

<details>
<summary>Running from source</summary>

The source checkout does not include the installer wizard. Install Node.js 18 or newer, create a `config.json` in the project root, and add a CS2 game state integration file in CS2's `game\csgo\cfg` folder. The [v1.1.0 release](https://github.com/beatsbyluca/CS2-Discord-RPC/releases/tag/v1.1.0) includes the guided setup if you prefer it.

```json
{
  "discordApplicationId": "1553835774737252462",
  "port": 31982,
  "imageBaseUrl": "https://raw.githubusercontent.com/beatsbyluca/CS2-Discord-RPC/refs/heads/main/assets"
}
```

Save this as `gamestate_integration_discord_presence.cfg` in CS2's `game\csgo\cfg` folder:

```text
"CS2 Discord Presence"
{
    "uri" "http://127.0.0.1:31982/"
    "timeout" "5.0"
    "buffer" "0.1"
    "throttle" "1.0"
    "heartbeat" "30.0"
    "data"
    {
        "map" "1"
        "player_id" "1"
    }
}
```

Run `start.cmd` for the tray app, or `npm start` for a console session. Keep the project folder in place if you add `src\start.vbs` to Windows autostart.

</details>
