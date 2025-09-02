local DesignLoader = {}

-- Utility to safely require a module and return nil on failure
local function safe_require(name)
  local ok, mod = pcall(require, name)
  if ok then return mod end
  return nil, mod -- second value is error for optional logging
end

-- Lists Lua module names under a directory using love.filesystem
-- dir: e.g. "content/ships"; modulePrefix: e.g. "content.ships"
local function list_modules(dir, modulePrefix)
  local mods = {}
  if not love or not love.filesystem or not love.filesystem.getDirectoryItems then
    return mods
  end
  if not love.filesystem.getInfo(dir) then
    return mods
  end
  for _, item in ipairs(love.filesystem.getDirectoryItems(dir)) do
    -- Only plain .lua files, skip index.lua
    if item:sub(-4) == ".lua" and item ~= "index.lua" then
      local base = item:sub(1, -5) -- strip .lua
      table.insert(mods, modulePrefix .. "." .. base)
    end
  end
  table.sort(mods)
  return mods
end

-- Public: discover item and ship definitions.
-- Returns tables: itemDefs (raw def tables), shipDefs (raw def tables)
function DesignLoader.discover()
  local itemDefs, shipDefs, turretDefs = {}, {}, {}

  -- Items
  for _, modName in ipairs(list_modules("content/items", "content.items")) do
    local def = safe_require(modName)
    if type(def) == "table" then
      table.insert(itemDefs, def)
    end
  end

  -- Ships
  for _, modName in ipairs(list_modules("content/ships", "content.ships")) do
    local def = safe_require(modName)
    if type(def) == "table" then
      table.insert(shipDefs, def)
    end
  end

  -- Turrets
  for _, modName in ipairs(list_modules("content/turrets", "content.turrets")) do
    local def = safe_require(modName)
    if type(def) == "table" then
      table.insert(turretDefs, def)
    end
  end

  return itemDefs, shipDefs, turretDefs
end

return DesignLoader
