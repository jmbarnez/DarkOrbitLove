local Item = require("src.templates.item")
local DesignLoader = require("src.design_loader")

local Content = {
  items = {},
  ships = {},
  turrets = {},
  byId = { item = {}, ship = {}, turret = {} },
}

function Content.load()
  -- Try auto-discovery first (preferred for easy content drops)
  local discoveredItems, discoveredShips, discoveredTurrets = DesignLoader.discover()

  local items = discoveredItems
  local ships = discoveredShips
  local turrets = discoveredTurrets

  -- Fallback to explicit index if discovery finds nothing
  if (#items == 0 and #ships == 0 and #turrets == 0) then
    local ok, idx = pcall(require, "content.index")
    if ok and type(idx) == "table" then
      items = idx.items or {}
      ships = idx.ships or {}
      turrets = idx.turrets or {}
    end
  end

  -- Items
  for _, def in ipairs(items or {}) do
    local item = Item.fromDef(def)
    table.insert(Content.items, item)
    if item and item.id then
      Content.byId.item[item.id] = item
    end
  end
  -- Ships (kept as raw defs for now)
  for _, def in ipairs(ships or {}) do
    table.insert(Content.ships, def)
    if def and def.id then
      Content.byId.ship[def.id] = def
    end
  end
  -- Turrets (raw defs)
  for _, def in ipairs(turrets or {}) do
    table.insert(Content.turrets, def)
    if def and def.id then
      Content.byId.turret[def.id] = def
    end
  end
end

function Content.getItem(id)
  return Content.byId.item[id]
end

function Content.getShip(id)
  return Content.byId.ship[id]
end

function Content.getTurret(id)
  return Content.byId.turret[id]
end

return Content
