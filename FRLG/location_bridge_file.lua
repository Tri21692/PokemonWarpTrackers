--[[
  location_bridge_file.lua
  -------------------------
  File-based alternative to location_bridge.lua, for BizHawk builds that
  don't include LuaSocket. Writes the current mapNum/mapGroup to a small
  JSON file every time it changes. bridge_server_file.js watches that file
  and re-serves it over HTTP.

  SETUP (most people -- no editing needed):
  1. Put this script in whatever folder you like.
  2. Open it in BizHawk's Lua Console while FireRed/LeafGreen is running.
  3. Run bridge_server_file.js from THAT SAME FOLDER (no path argument
     needed) -- it'll find the output file automatically.

  SETUP (custom output location):
  If you'd rather the output file live somewhere specific, create a plain
  text file named "location_bridge_config.txt" in the same folder as this
  script, and put the full path you want on its own line inside it, e.g.:
      E:\Website\Live Tracking\Tracking\location_bridge_output.json
  No Lua editing required -- this script checks for that config file every
  time it starts and uses the path inside it if present. Just remember to
  point bridge_server_file.js at that same path when you run it.
]]

local MEMORY_DOMAIN = "EWRAM"
local DEFAULT_OUTPUT_FILE = "location_bridge_output.json"
local CONFIG_FILE = "location_bridge_config.txt"

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
      console.log("Using custom path from " .. CONFIG_FILE .. ":")
      return line
    end
    console.log("Found " .. CONFIG_FILE .. " but it was empty -- using the default path instead.")
  end
  return DEFAULT_OUTPUT_FILE
end

local OUTPUT_FILE = resolveOutputPath()

local FIELDS = {
  { name = "a", addr = 0x036DFD },
  { name = "b", addr = 0x036E01 },
  { name = "c", addr = 0x036E04 },
  { name = "d", addr = 0x036E05 },
  { name = "e", addr = 0x036E0E },
  { name = "f", addr = 0x036E0F },
  { name = "mapNum", addr = 0x031DBD },   -- confirmed: current map's mapNum
  { name = "mapGroup", addr = 0x031DBC }, -- confirmed: current map's mapGroup
}

local function readAll()
  local values = {}
  for _, field in ipairs(FIELDS) do
    values[field.name] = memory.read_u8(field.addr, MEMORY_DOMAIN)
  end
  return values
end

local function toJson(values, frame)
  return string.format(
    '{"frame":%d,"a":%d,"b":%d,"c":%d,"d":%d,"e":%d,"f":%d,"mapNum":%d,"mapGroup":%d}',
    frame, values.a, values.b, values.c, values.d, values.e, values.f, values.mapNum, values.mapGroup
  )
end

local function valuesEqual(x, y)
  for _, field in ipairs(FIELDS) do
    if x[field.name] ~= y[field.name] then return false end
  end
  return true
end

local function writeFile(json)
  local f = io.open(OUTPUT_FILE, "w")
  if f then
    f:write(json)
    f:close()
    return true
  end
  return false
end

local last = readAll()
console.log("Location bridge (file mode) started.")
if writeFile(toJson(last, emu.framecount())) then
  console.log("Writing to: " .. OUTPUT_FILE)
  console.log("(To use a different location, create " .. CONFIG_FILE .. " next to this script -- see the comments at the top of this file.)")
else
  console.log("Could not open " .. OUTPUT_FILE .. " for writing.")
  console.log("If you're using " .. CONFIG_FILE .. ", double check that folder actually exists.")
  console.log("Otherwise, this should just work -- try running BizHawk from a folder you have write access to.")
end

while true do
  local current = readAll()
  if not valuesEqual(current, last) then
    local msg = toJson(current, emu.framecount())
    if writeFile(msg) then
      console.log("[wrote] " .. msg)
    else
      console.log("[write failed] " .. msg)
    end
    last = current
  end
  emu.frameadvance()
end
