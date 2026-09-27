# CS2 Discord Presence

Zeigt Map, Spielmodus und CT/T-Spielstand aus Counter-Strike 2 in Discord Rich Presence an. Läuft lokal auf Windows mit Node.js, ohne zusätzliche Pakete.

## Einrichtung

1. Node.js 18 oder neuer und den Discord Desktop-Client installieren.
2. Auf https://discord.com/developers/applications eine Application erstellen und die **Application ID** unter **General Information** kopieren.
3. `config.example.json` als `config.json` kopieren und `discordApplicationId` eintragen. Der Application-Name ist der Titel der Discord-Aktivität.
4. `install.ps1` in PowerShell ausführen. Das Skript sucht CS2 in den Steam-Bibliotheken. Falls es den Ordner nicht findet: `./install.ps1 -Cs2CfgDir 'X:\...\game\csgo\cfg'`.
5. CS2 neu starten, Discord Desktop öffnen und `start.cmd` ausführen. Das Fenster während des Spielens geöffnet lassen.

Beispielanzeige: `Wettkampf · Mirage` / `CT 8 : 6 T`.

## Map-Bilder ohne Discord-Upload

Die 49 Map-Bilder liegen in `assets/`. `imageBaseUrl` in `config.json` zeigt auf den
öffentlichen `assets/`-Ordner dieses Repos. Das Programm sendet Discord für eine
Map wie `de_mirage` die URL `.../assets/de_mirage.png` als `large_image`. Nutzer
müssen die Bilder dadurch **nicht** in ihrer Discord Application hochladen.

Der Repo-Besitzer muss die Bilder einmal öffentlich bereitstellen. Wird das
Repo unter einem anderen GitHub-Namen oder Branch veröffentlicht, muss
`imageBaseUrl` in `config.example.json` entsprechend angepasst werden. Der
bereits eingetragene Pfad funktioniert erst, sobald dieses Repo dort öffentlich
ist. Ein anderer öffentlicher HTTPS-Bildhost kann genauso verwendet werden.

Ohne `imageBaseUrl` verwendet das Programm stattdessen den Dateinamen als
Discord-Art-Asset-Key. Das ist nur sinnvoll, wenn die Bilder bereits in der
Application hochgeladen wurden.

## Hinweise

- Die CS2 GSI liefert `competitive` als Modus. Premier und normaler Wettkampf lassen sich daraus nicht zuverlässig auseinanderhalten; deshalb zeigt das Programm in beiden Fällen **Wettkampf**.
- Wenn 90 Sekunden keine Daten aus CS2 eintreffen, wird die Aktivität entfernt. Discord-Verbindungsabbrüche werden automatisch erneut versucht.
- Die Verbindung zwischen CS2 und diesem Programm läuft nur über `127.0.0.1`.
- Falls Discord zwei Aktivitäten für CS2 zeigt, kannst du die automatische Spielanzeige für CS2 in Discord unter **Registrierte Spiele** deaktivieren.

## Test

`npm test` prüft die Formatierung und die Bild-URL anhand von Beispieldaten. Für einen echten Funktionstest müssen Discord Desktop und CS2 laufen und die Application ID eingetragen sein.
