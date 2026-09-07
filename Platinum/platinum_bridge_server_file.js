/*
  platinum_bridge_server_file.js
  ----------------------
  File-watching bridge server for Pokemon Platinum, for use with
  platinum_location_bridge_file.lua (no LuaSocket required on the BizHawk side).

  Identical in every way to the FireRed/LeafGreen bridge_server_file.js,
  except for the default filename and port -- kept as a separate file so
  both trackers can run at the same time without a port conflict.

  Polls a JSON file on disk for changes and re-serves the latest data
  over plain HTTP, same as the UDP version -- the tracker-side code
  doesn't need to know or care which bridge variant is feeding it.

  Run it with:
    node platinum_bridge_server_file.js "FULL_PATH_TO\platinum_bridge_output.json"

  If you don't pass a path, it defaults to looking for
  "location_bridge_output.json" in the same folder you run this from --
  that only works if you also run BizHawk from that same folder, so
  passing the full path explicitly is the more reliable option.
*/

const fs = require("fs");
const path = require("path");
const http = require("http");

const WATCH_FILE = process.argv[2] || path.join(__dirname, "platinum_bridge_output.json");
const HTTP_PORT = 5557; // different port than the FR/LG bridge (5556) so both can run at once
const POLL_MS = 250;
const MAX_HISTORY = 300;
const WARN_AFTER_MISSES = 20; // ~5 seconds of failed polls before we say something

let latest = null;
let history = [];
let lastRaw = null;
let everFound = false;
let consecutiveMisses = 0;
let warnedAboutMissing = false;

if (process.argv.length > 3) {
  console.warn("WARNING: got more than one extra argument -- if your path has a space in it and wasn't wrapped in quotes, this is why. Extra args:", process.argv.slice(3));
}

function pollFile() {
  fs.readFile(WATCH_FILE, "utf8", (err, raw) => {
    if (err) {
      if (everFound) {
        console.error("Lost track of the file -- was it moved or deleted?", err.message);
        return;
      }
      consecutiveMisses++;
      if (consecutiveMisses === WARN_AFTER_MISSES && !warnedAboutMissing) {
        warnedAboutMissing = true;
        console.warn(`\nSTILL haven't found the file after ${WARN_AFTER_MISSES} tries. Watching exactly this path:`);
        console.warn("  " + WATCH_FILE);
        console.warn("If that path is wrong: check for a space in it without quotes around the whole thing,");
        console.warn("confirm the file actually exists there, and that BizHawk is still writing to that same location.\n");
      }
      return;
    }
    consecutiveMisses = 0;
    if (!everFound) {
      everFound = true;
      console.log("Found the file, watching for changes:", WATCH_FILE);
    }
    if (raw === lastRaw) return;
    lastRaw = raw;
    try {
      const data = JSON.parse(raw);
      data.receivedAt = Date.now();
      latest = data;
      history.push(data);
      if (history.length > MAX_HISTORY) history.shift();
      console.log("Updated:", data);
    } catch (e) {
      // BizHawk may have caught it mid-write; next poll will pick up the finished write.
    }
  });
}

setInterval(pollFile, POLL_MS);
console.log("Watching for:", WATCH_FILE);
console.log("(If this path is wrong, pass the correct one as an argument: node bridge_server_file.js \"C:\\path\\to\\location_bridge_output.json\")");

const httpServer = http.createServer((req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Content-Type", "application/json");

  if (req.url === "/latest") {
    res.end(JSON.stringify(latest));
  } else if (req.url === "/history") {
    res.end(JSON.stringify(history));
  } else if (req.url === "/clear") {
    history = [];
    latest = null;
    res.end(JSON.stringify({ status: "cleared" }));
  } else {
    res.end(JSON.stringify({
      status: "ok",
      watching: WATCH_FILE,
      hint: "GET /latest for the most recent reading, /history for recent readings, /clear to reset",
    }));
  }
});

httpServer.listen(HTTP_PORT, () => {
  console.log(`Tracker can fetch data from http://localhost:${HTTP_PORT}/latest`);
});
