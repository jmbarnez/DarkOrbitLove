local Util = require("src.util")

local UI = {}

local function bar(x, y, w, h, value, max, color)
  love.graphics.setColor(0.1, 0.1, 0.14, 0.8)
  love.graphics.rectangle("fill", x, y, w, h, 6, 6)
  local pct = math.max(0, math.min(1, value / math.max(1, max)))
  love.graphics.setColor(color)
  love.graphics.rectangle("fill", x + 2, y + 2, (w - 4) * pct, h - 4, 6, 6)
end

-- Vertical status bar with label
local function vbar(x, yBottom, w, h, value, max, color)
  local pct = math.max(0, math.min(1, value / math.max(1, max)))
  local fillH = math.floor((h - 4) * pct)
  -- background (deep dark, subtle)
  love.graphics.setColor(0.07, 0.08, 0.12, 0.9)
  love.graphics.rectangle("fill", x, yBottom - h, w, h, 6, 6)
  -- inner glow/fill gradient
  local gx, gy, gw, gh = x + 2, yBottom - 2 - fillH, w - 4, fillH
  if gh > 0 then
    -- base fill
    love.graphics.setColor(color[1]*0.8, color[2]*0.8, color[3]*0.8, 0.85)
    love.graphics.rectangle("fill", gx, gy, gw, gh, 4, 4)
    -- top highlight
    love.graphics.setColor(1,1,1,0.08)
    love.graphics.rectangle("fill", gx, gy, gw, math.min(8, gh), 4, 4)
  end
  -- border (very low-contrast)
  love.graphics.setColor(0.16, 0.18, 0.24, 0.9)
  love.graphics.rectangle("line", x, yBottom - h, w, h, 6, 6)
end

local function minimap(player, world, enemies)
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local s = math.min(sw / 1920, sh / 1080)
  local w, h = math.floor(220 * s), math.floor(160 * s)
  local pad = math.floor(16 * s)
  local x, y = sw - w - pad, pad
  love.graphics.setColor(0.1, 0.1, 0.14, 0.8)
  love.graphics.rectangle("fill", x, y, w, h, 8, 8)
  love.graphics.setColor(0.25, 0.5, 0.9)
  love.graphics.rectangle("line", x + 8, y + 8, w - 16, h - 16, 6, 6)
  local mw, mh = w - 16, h - 16
  local sx = mw / world.width
  local sy = mh / world.height
  local ox, oy = x + 8, y + 8
  love.graphics.setColor(1, 0.4, 0.4)
  for _, e in ipairs(enemies) do
    love.graphics.rectangle("fill", ox + e.x * sx - 2, oy + e.y * sy - 2, 4, 4)
  end
  love.graphics.setColor(0.2, 1, 0.8)
  love.graphics.rectangle("fill", ox + player.x * sx - 3, oy + player.y * sy - 3, 6, 6)

  -- FPS counter just below the minimap
  local fps = love.timer.getFPS and love.timer.getFPS() or 0
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.print(string.format("FPS: %d", fps), x + 10, y + h + 8)
end

local function drawTargetPanel(player)
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local s = math.min(sw / 1920, sh / 1080)
  if not player.target then return end
  local t = player.target
  local w = math.floor(360 * s)
  local hasShield = ((t.maxShield or 0) > 0) or ((t.shield or 0) > 0)
  local h = hasShield and math.floor(110 * s) or math.floor(86 * s)
  local x = math.floor((sw - w) * 0.5)
  local y = math.floor(16 * s)
  love.graphics.setColor(0.1, 0.1, 0.14, 0.8)
  love.graphics.rectangle("fill", x, y, w, h, 8, 8)
  love.graphics.setColor(1,1,1)
  love.graphics.print("Target", x + 10, y + 8)
  local dist = math.floor(math.sqrt((t.x - player.x)^2 + (t.y - player.y)^2))
  love.graphics.print(string.format("Dist: %d", dist), x + 10, y + 28)
  local lockPct = player.lockTime > 0 and math.min(1, player.lockProgress / player.lockTime) or 0
  love.graphics.print(player.locked and "Lock: ENGAGED" or string.format("Locking: %d%%", math.floor(lockPct * 100)), x + 180, y + 8)
  -- Bars: Hull (always) and Shield (conditional)
  bar(x + math.floor(10*s), y + math.floor(50*s), w - math.floor(20*s), math.floor(14*s), t.hp, t.maxHP or 50, {0.90, 0.22, 0.28})
  if hasShield then
    bar(x + math.floor(10*s), y + math.floor(70*s), w - math.floor(20*s), math.floor(14*s), t.shield or 0, t.maxShield or 0, {0.26, 0.62, 1.00})
  end
end

-- Hotbar drawing and input
local function pointInRect(px, py, r)
  return px >= r.x and py >= r.y and px <= r.x + r.w and py <= r.y + r.h
end

local function drawTurretIcon(kind, tracerColor, x, y, size)
  local c = tracerColor or {1,1,1,0.9}
  local cx, cy = x + size*0.5, y + size*0.5
  if kind == 'laser' then
    -- Prism + beam
    love.graphics.setColor(0.12,0.13,0.19,0.95)
    love.graphics.rectangle('fill', x+10, cy-10, size-20, 20, 4, 4)
    love.graphics.setColor(c[1], c[2], c[3], 0.85)
    love.graphics.rectangle('fill', cx-3, y+8, 6, size-16, 2, 2)
    love.graphics.setColor(1,1,1,0.10)
    love.graphics.rectangle('fill', cx-3, y+8, 6, 4, 2, 2)
  elseif kind == 'missile' then
    -- Rocket body + fins
    love.graphics.setColor(0.85,0.86,0.92,0.95)
    love.graphics.ellipse('fill', cx, cy, 10, 16)
    love.graphics.setColor(0.75,0.25,0.22,0.95)
    love.graphics.polygon('fill', cx-12, cy+6, cx-4, cy+2, cx-4, cy+10)
    love.graphics.polygon('fill', cx-12, cy-6, cx-4, cy-2, cx-4, cy-10)
    love.graphics.setColor(c[1], c[2], c[3], 0.6)
    love.graphics.circle('fill', cx+10, cy, 3)
  else
    -- Gun: receiver + barrel
    love.graphics.setColor(0.82,0.84,0.90,0.95)
    love.graphics.rectangle('fill', cx-12, cy-8, 18, 16, 3, 3)
    love.graphics.setColor(c[1], c[2], c[3], 0.85)
    love.graphics.rectangle('fill', cx+6, cy-3, 12, 6, 2, 2)
    love.graphics.setColor(1,1,1,0.12)
    love.graphics.rectangle('fill', cx-10, cy-6, 10, 2)
  end
end

local function drawHotbar(player)
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local slots, size, gap = 4, 52, 10
  local w = slots * size + (slots - 1) * gap
  local x = math.floor((sw - w) * 0.5)
  local y = sh - 16 - size

  for i = 1, slots do
    local rx = x + (i - 1) * (size + gap)
    local ry = y
    local rect = { x = rx, y = ry, w = size, h = size }
    -- Determine slot binding from player's turrets
    local binding = nil
    if player.turrets and i <= #player.turrets then
      local slot = player.turrets[i]
      binding = {
        kind = slot.turret.kind or slot.turret.type,
        color = (slot.turret.tracer and slot.turret.tracer.color) or nil,
        enabled = slot.enabled ~= false,
        has = slot.turret ~= nil,
        cooldown = slot.turret and slot.turret.cooldown or 0,
        cycle = slot.turret and slot.turret.cycle or 1,
      }
    end

    local mx, my = love.mouse.getPosition()
    local hover = pointInRect(mx, my, rect)
    local bg = {0.10, 0.11, 0.16, 0.92}
    local border = {0.22, 0.24, 0.32, 1.0}
    local accent = {0.27, 0.55, 0.98, 1.0}
    local offTint = {0.55, 0.58, 0.72, 0.28}

    -- Slot background
    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.rectangle("fill", rx + 3, ry + 5, size, size, 10, 10)
    love.graphics.setColor(bg)
    love.graphics.rectangle("fill", rx, ry, size, size, 8, 8)
    love.graphics.setColor(border)
    love.graphics.rectangle("line", rx, ry, size, size, 8, 8)

    -- Cooldown fill (inside button)
    if binding and binding.has then
      local cd = math.max(0, math.min(1, (binding.cooldown or 0) / math.max(0.0001, binding.cycle or 1)))
      if cd > 0 then
        local fh = math.floor((size - 6) * cd)
        love.graphics.setColor(accent[1], accent[2], accent[3], 0.22)
        love.graphics.rectangle("fill", rx + 3, ry + size - 3 - fh, size - 6, fh, 6, 6)
      end
    end

    -- Hover effect
    if hover then
      love.graphics.setColor(1, 1, 1, 0.06)
      love.graphics.rectangle("fill", rx, ry, size, size, 8, 8)
    end

    -- Icon per turret kind
    if binding and binding.has then
      drawTurretIcon(binding.kind, binding.color, rx + 4, ry + 4, size - 8)
    else
      love.graphics.setColor(1, 1, 1, 0.22)
      love.graphics.print("-", rx + size * 0.5 - 3, ry + size * 0.5 - 6)
    end

    -- Enabled indicator / disabled tint
    if binding and binding.has then
      if not binding.enabled then
        love.graphics.setColor(offTint)
        love.graphics.rectangle("fill", rx, ry, size, size, 8, 8)
      end
      -- small status LED
      love.graphics.setColor(binding.enabled and {0.20, 1.0, 0.68, 0.95} or {0.95, 0.35, 0.35, 0.95})
      love.graphics.circle("fill", rx + size - 10, ry + 10, 4)
    else
      -- empty slot
      love.graphics.setColor(1, 1, 1, 0.08)
      love.graphics.circle("line", rx + size * 0.5, ry + size * 0.5, 10)
    end
  end
end

function UI.hotbarMousePressed(player, mx, my, button)
  if button ~= 1 then return false end
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local slots, size, gap = 4, 52, 10
  local w = slots * size + (slots - 1) * gap
  local x = math.floor((sw - w) * 0.5)
  local y = sh - 16 - size
  for i = 1, slots do
    local rx = x + (i - 1) * (size + gap)
    local ry = y
    local rect = { x = rx, y = ry, w = size, h = size }
    if pointInRect(mx, my, rect) then
      if player.turrets and i <= #player.turrets then
        local slot = player.turrets[i]
        slot.enabled = not (slot.enabled ~= false)
        return true
      end
      return false
    end
  end
  return false
end

local Chat = require("src.chat")

function UI.drawHUD(player, world, enemies)
  love.graphics.origin()
  -- Bottom-left vertical bars HUD (HP, Shield, Energy)
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local s = math.min(sw / 1920, sh / 1080)
  local pad = math.floor(16 * s)
  -- Move bars to bottom-right
  local bw, bh, gap = math.floor(20 * s), math.floor(148 * s), math.floor(10 * s)
  local baseX = sw - pad - (3 * bw + 2 * gap)
  local baseY = sh - pad
  -- muted sci-fi hues
  vbar(baseX, baseY, bw, bh, player.hp, player.maxHP, {0.90, 0.22, 0.28})
  vbar(baseX + (bw + gap), baseY, bw, bh, player.shield, player.maxShield, {0.26, 0.62, 1.00})
  vbar(baseX + 2*(bw + gap), baseY, bw, bh, player.energy, player.maxEnergy, {0.22, 1.00, 0.68})
  drawTargetPanel(player)
  minimap(player, world, enemies)
  drawHotbar(player)
  -- Chat panel bottom-left
  Chat.draw()
end

return UI
