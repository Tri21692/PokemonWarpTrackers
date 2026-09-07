# Tri's Warp Trackers

*Version 0.1*

Companion warp-randomizer trackers for **Pokémon Platinum** and **Pokémon FireRed / LeafGreen**. Log every warp connection as you discover it, with optional Live Tracking that auto-detects and fills in warps for you while you play in BizHawk.

> Please be aware that this project may include bugs.

## What's here

- **`index.html`** — the main menu / landing page. Open this first.
- **`platinum_warp_tracker.html`** — the Platinum tracker (Sinnoh).
- **`firered_leafgreen_warp_tracker.html`** — the FireRed/LeafGreen tracker (Kanto & Sevii).
- **`Platinum/`** — the two files needed for Platinum's Live Tracking (Lua script + Node bridge server).
- **`FRLG/`** — the same, for FireRed/LeafGreen.
- **`docs/platinum_mapname_reference.txt`** — research notes on Platinum's internal map ID scheme, kept for anyone who wants to help identify the handful of locations still unconfirmed.

## Using the trackers

Both trackers are fully self-contained, single HTML files. No build step, no server required — just open one in a browser. Progress is saved automatically in your browser's local storage.

Manual tracking works out of the box: log warps as you find them, tag notable ones, link both ends of a connection, and export/import your progress as JSON for backup.

## Live Tracking (optional)

Live Tracking watches your emulator's memory in [BizHawk](https://tasvideos.org/BizHawk) and automatically detects, names, and links warps as you walk through them.

**Setup:**
1. Put the two files for your game (from `Platinum/` or `FRLG/`) in the same folder.
2. Open the `.lua` file in BizHawk's Lua Console while your game is running.
3. Run the bridge server with [Node.js](https://nodejs.org/): `node bridge_server_file.js` (or the Platinum equivalent) — run it from that same folder, no path argument needed.
4. In the tracker page, click the 📡 **Live Tracking** toggle.

By default, both scripts write their tracking file right next to themselves — no configuration needed. If you'd rather it write somewhere specific, create a plain text file named `platinum_bridge_config.txt` (or `location_bridge_config.txt` for FR/LG) next to the Lua script, with your desired path on one line inside it.

Ports: FireRed/LeafGreen's bridge server runs on `5556`, Platinum's on `5557`, so both can run at once if you want.

Nothing here talks to the internet — Live Tracking is entirely `localhost` traffic between the Lua script, the bridge server, and the tracker page in your browser.

## Deploying (e.g. Netlify)

The site is just static files. Upload the whole repo root as-is — `index.html`'s download links expect the `Platinum/` and `FRLG/` folders to sit right next to it.

## Credits

Built with the assistance of Claude AI.
