local Equipment = {}

local function panel(x, y, w, h, title)
  -- shadow
  love.graphics.setColor(0, 0, 0, 0.25)
  love.graphics.rectangle("fill", x + 4, y + 6, w, h, 10, 10)
  -- body
  love.graphics.setColor(0.12, 0.13, 0.19, 0.98)
  love.graphics.rectangle("fill", x, y, w, h, 10, 10)
  -- border
  love.graphics.setColor(0.22, 0.24, 0.32, 1.0)
  love.graphics.rectangle("line", x, y, w, h, 10, 10)
  -- title bar
  love.graphics.setColor(0.13, 0.14, 0.20, 1)
  love.graphics.rectangle("fill", x, y, w, 32, 10, 10)
  love.graphics.setColor(0.27, 0.55, 0.98, 0.6)
  love.graphics.rectangle("fill", x, y + 30, w, 2)
  love.graphics.setColor(0.92, 0.95, 1.00, 0.96)
  love.graphics.print(title or "Equipment", x + 12, y + 8)
end

function Equipment.draw(player)
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local w, h = 420, 200
  local x = math.floor((sw - w) * 0.5)
  local y = math.floor((sh - h) * 0.5)
  panel(x, y, w, h, "Equipment")

  -- Content
  local cx, cy = x + 16, y + 44
  love.graphics.setColor(0.75, 0.80, 0.95, 0.85)
  love.graphics.print("Ship:", cx, cy)
  love.graphics.setColor(0.92, 0.95, 1.00, 0.96)
  love.graphics.print((player.ship and player.ship.name) or "-", cx + 80, cy)
  cy = cy + 24

  -- Turret summary
  love.graphics.setColor(0.75, 0.80, 0.95, 0.85)
  love.graphics.print("Turret:", cx, cy)
  local t = player.turret
  love.graphics.setColor(0.92, 0.95, 1.00, 0.96)
  if t then
    local dmg = (t.damageMin ~= t.damageMax) and (t.damageMin .. "-" .. t.damageMax) or tostring(t.damageMin or t.damage)
    local line = string.format("%s  dmg:%s  cycle:%.1fs  optimal:%d  falloff:%d", t.kind or "gun", dmg, t.cycle or 0, t.optimal or 0, t.falloff or 0)
    love.graphics.print(line, cx + 80, cy)
    cy = cy + 24
    love.graphics.setColor(0.75, 0.80, 0.95, 0.85)
    love.graphics.print("Enabled:", cx, cy)
    love.graphics.setColor(0.92, 0.95, 1.00, 0.96)
    love.graphics.print((player.turretEnabled ~= false) and "Yes" or "No", cx + 80, cy)
  else
    love.graphics.print("-", cx + 80, cy)
  end
end

return Equipment

