-- Pokemon Platinum Live Location Bridge (file-based, no LuaSocket needed)
-- Reads the confirmed single-integer "current map ID" value from RAM every
-- frame and writes it to a JSON file whenever it changes. A separate
-- Node.js bridge server polls that file and serves it over HTTP, which the
-- tracker's web page polls in turn.
--
-- Confirmed address: 0x27F3A4, Word (2 bytes), unsigned, domain "Main RAM"
-- Verified to update simultaneously with 9 other mirror copies across three
-- independently confirmed locations (Route 207 = 353, Oreburgh City = 45,
-- Eterna City = 65) -- see platinum_mapname_reference.txt for the full
-- decoded location list this ID maps into.
--
-- SETUP (most people -- no editing needed):
-- 1. Put this script in whatever folder you like.
-- 2. Open it in BizHawk's Lua Console while Platinum is running.
-- 3. Run platinum_bridge_server_file.js from THAT SAME FOLDER (no path
--    argument needed) -- it'll find the output file automatically.
--
-- SETUP (custom output location):
-- If you'd rather the output file live somewhere specific, create a plain
-- text file named "platinum_bridge_config.txt" in the same folder as this
-- script, and put the full path you want on its own line inside it, e.g.:
--     E:\Website\Live Tracking\Tracking\platinum_bridge_output.json
-- No Lua editing required -- this script checks for that config file every
-- time it starts and uses the path inside it if present. Just remember to
-- point platinum_bridge_server_file.js at that same path when you run it.

local DEFAULT_OUTPUT_PATH = "platinum_bridge_output.json"
local CONFIG_FILE = "platinum_bridge_config.txt"
local MAP_ID_ADDRESS = 0x27F3A4
local MAP_ID_DOMAIN = "Main RAM"

local function trim(s)
  return s and s:match("^%s*(.-)%s*$") or s
end

local function resolveOutputPath()
  local cfg = io.open(CONFIG_FILE, "r")
  if cfg then
    local line = cfg:read("*l")
    cfg:close()
    line = trim(line)
    if line and line ~= "" then
      console.log("[Platinum Bridge] Using custom path from " .. CONFIG_FILE .. ":")
      return line
    end
    console.log("[Platinum Bridge] Found " .. CONFIG_FILE .. " but it was empty -- using the default path instead.")
  end
  return DEFAULT_OUTPUT_PATH
end

local OUTPUT_PATH = resolveOutputPath()

local lastMapId = nil
local lastWriteFailed = false

local function writeOutput(mapId, frame)
  local f = io.open(OUTPUT_PATH, "w")
  if not f then
    if not lastWriteFailed then
      console.log("[Platinum Bridge] WARNING: could not open output file for writing:")
      console.log("  " .. OUTPUT_PATH)
      console.log("  If you're using " .. CONFIG_FILE .. ", double check that folder actually exists.")
      console.log("  Otherwise, this should just work -- try running BizHawk from a folder you have write access to.")
      lastWriteFailed = true
    end
    return
  end
  lastWriteFailed = false
  f:write(string.format('{"frame":%d,"mapId":%d}', frame, mapId))
  f:close()
end

console.log("[Platinum Bridge] Started. Watching address 0x" .. string.format("%X", MAP_ID_ADDRESS) ..
  " (" .. MAP_ID_DOMAIN .. "). Writing to:")
console.log("  " .. OUTPUT_PATH)
console.log("[Platinum Bridge] (To use a different location, create " .. CONFIG_FILE .. " next to this script -- see the comments at the top of this file.)")

while true do
  local mapId = memory.read_u16_le(MAP_ID_ADDRESS, MAP_ID_DOMAIN)
  if mapId ~= lastMapId then
    writeOutput(mapId, emu.framecount())
    lastMapId = mapId
  end
  emu.frameadvance()
end
