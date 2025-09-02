local Content = require("src.content")
local Chat = require("src.chat")

local Loot = {}

local drops = {}

function Loot.spawn(id, qty, x, y)
  if not id or qty == nil or qty <= 0 then return end
  table.insert(drops, {
    id = id,
    qty = qty,
    x = x + (math.random() - 0.5) * 24,
    y = y + (math.random() - 0.5) * 24,
    t = 0,
    life = 60, -- seconds before fade (optional future)
  })
end

function Loot.update(dt, player)
  for i = #drops, 1, -1 do
    local d = drops[i]
    d.t = d.t + dt
    local dx, dy = (player.x - d.x), (player.y - d.y)
    local r = (player.radius or 12) + 20
    if dx*dx + dy*dy <= r*r then
      -- Auto-pickup
      player.inventory = player.inventory or {}
      player.inventory[d.id] = (player.inventory[d.id] or 0) + (d.qty or 1)
      local item = Content.getItem and Content.getItem(d.id)
      local name = (item and item.name) or d.id
      local msg = "+" .. tostring(d.qty) .. " " .. tostring(name)
      Chat.info(msg)
      table.remove(drops, i)
    end
  end
end

local function drawItemGlyph(id, x, y, pulse)
  local item = Content.getItem and Content.getItem(id)
  local t = item and item.type or "generic"
  local a = 0.85
  if t == 'material' then
    love.graphics.setColor(0.65,0.72,0.85,a)
    love.graphics.circle('fill', x, y, 6 + pulse)
  elseif t == 'consumable' then
    love.graphics.setColor(0.95,0.35,0.35,a)
    love.graphics.rectangle('fill', x-6, y-6, 12, 12, 2, 2)
    love.graphics.setColor(1,1,1,0.85)
    love.graphics.rectangle('fill', x-1, y-4, 2, 8)
    love.graphics.rectangle('fill', x-4, y-1, 8, 2)
  else
    love.graphics.setColor(0.27,0.55,0.98,a)
    love.graphics.circle('line', x, y, 8 + pulse)
  end
end

function Loot.draw()
  for _, d in ipairs(drops) do
    local pulse = (math.sin(love.timer.getTime() * 4 + d.x * 0.01) + 1) * 0.5
    love.graphics.setColor(0,0,0,0.25)
    love.graphics.circle('fill', d.x + 2, d.y + 3, 10)
    drawItemGlyph(d.id, d.x, d.y, pulse)
    love.graphics.setColor(1,1,1,0.85)
    love.graphics.print(tostring(d.qty), d.x + 10, d.y + 6)
  end
end

return Loot
