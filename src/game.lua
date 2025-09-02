local Util = require("src.util")
local Camera = require("src.camera")
local World = require("src.world")
local Player = require("src.player")
local Enemy = require("src.enemy")
local Bullet = require("src.bullet")
local UI = require("src.ui")
local Content = require("src.content")
local Inventory = require("src.inventory")
local Equipment = require("src.equipment")
local Bounty = require("src.bounty")
local Hub = require("src.hub")
local Input = require("src.input")
local Wreckage = require("src.wreckage")
local Effects = require("src.effects")
local Loot = require("src.loot")

local Game = {}

-- Internal state
local world
local camera
local player
local enemies = {}
local bullets = {}
-- Effects moved to src/effects.lua
local wreckage = {}
local clickMarkers = {}
local inventoryOpen = false
local equipmentOpen = false
local bountyOpen = false
local bounty = { uncollected = 0, entries = {} }


local hub
local spawnTimer = 0
local maxEnemies = 12

local function spawnEnemy()
  local margin = 300
  local x, y
  local attempts = 0
  repeat
    attempts = attempts + 1
    x = math.random(margin, world.width - margin)
    y = math.random(margin, world.height - margin)
  until (not hub) or (Util.distance(x, y, hub.x, hub.y) > (hub.radius or 0) + 50) or attempts > 200
  local e = Enemy.new(x, y)
  table.insert(enemies, e)
end

local function spawnBullet(x, y, angle, friendly)
  table.insert(bullets, Bullet.new(x, y, angle, friendly))
end



-- FX helpers now provided by Effects

local function updateBullets(dt)
  for i = #bullets, 1, -1 do
    local b = bullets[i]
    b:update(dt)
    if b.dead or not world:contains(b.x, b.y, b.radius) then
      -- Missile proximity detonation on expiry/out-of-bounds
      if b.kind == 'missile' then
        local explodeR = 48
        Effects.spawnDetonation(b.x, b.y, 'missile', {1.0,0.7,0.3,0.5})
        if b.friendly then
          for j = #enemies, 1, -1 do
            local e = enemies[j]
            local dx, dy = e.x - b.x, e.y - b.y
            if dx*dx + dy*dy <= (explodeR + (e.radius or 10))^2 then
              e:hit(b.damage or 12)
            end
          end
        else
          local dx, dy = player.x - b.x, player.y - b.y
          if dx*dx + dy*dy <= (explodeR + (player.radius or 12))^2 then
            player:hit(b.damage or 12)
          end
        end
      end
      table.remove(bullets, i)
    end
  end
end

local function updateEnemies(dt)
  for i = #enemies, 1, -1 do
    local e = enemies[i]
    e:update(dt, player, function(x, y, angle, friendly, kind, damage, dist, style)
      kind = kind or "gun"
      if kind == "laser" then
        local length = math.min(700, dist or 500)
        table.insert(bullets, Bullet.new(x, y, angle, false, {life = 0.06, kind = "laser", length = length, damage = damage or 18, color = style and style.tracer and style.tracer.color, impact = style and style.impact}))
      elseif kind == "missile" then
        table.insert(bullets, Bullet.new(x, y, angle, false, {life = 3.5, kind = "missile", damage = damage or 24, color = style and style.tracer and style.tracer.color, impact = style and style.impact}))
      else -- gun
        local tracerSpeed = 900
        local life = math.min(1.2, (dist or 600) / tracerSpeed)
        table.insert(bullets, Bullet.new(x, y, angle, false, {
          life = life, kind = "gun", damage = damage or 12,
          color = style and style.tracer and style.tracer.color,
          tracerWidth = style and style.tracer and style.tracer.width,
          coreRadius = style and style.tracer and style.tracer.coreRadius,
          impact = style and style.impact,
        }))
      end
    end)
    if e.dead then
      player:addXP(10)
      -- Queue bounty as uncollected (do not credit instantly)
      local reward = e.bounty or 10
      bounty.uncollected = (bounty.uncollected or 0) + reward
      table.insert(bounty.entries, { amount = reward })
      if #bounty.entries > 10 then table.remove(bounty.entries, 1) end

      -- Spawn wreckage pieces from destroyed enemy
      local newWreckage = Wreckage.spawnFromEnemy(e, e.visuals)
      for _, piece in ipairs(newWreckage) do
        table.insert(wreckage, piece)
      end

      -- Add explosion effects at enemy death location
      Effects.spawnDetonation(e.x, e.y, 'ship', {1.0, 0.8, 0.4, 0.6})

      -- Add additional debris particles
      for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2 + math.random() * 0.3
        local speed = 200 + math.random() * 150
        Effects.add({
          type = 'spark',
          x = e.x + (math.random() - 0.5) * 20,
          y = e.y + (math.random() - 0.5) * 20,
          vx = math.cos(angle) * speed,
          vy = math.sin(angle) * speed,
          t = 0,
          life = 0.6 + math.random() * 0.8,
          color = {1.0, 0.7, 0.3, 0.9},
          size = 3 + math.random() * 2
        })
      end

      -- Add smoke trails
      for i = 1, 3 do
        Effects.add({
          type = 'smoke',
          x = e.x + (math.random() - 0.5) * 15,
          y = e.y + (math.random() - 0.5) * 15,
          r0 = 8 + math.random() * 6,
          rg = 40 + math.random() * 20,
          t = 0,
          life = 1.2 + math.random() * 0.8,
          color = {0.3, 0.3, 0.3, 0.4}
        })
      end

      -- Roll loot drops
      local lt = e.lootTable or {
        { id = "ore_tritanium", min = 1, max = 2, chance = 0.5 },
      }
      for _, drop in ipairs(lt) do
        if math.random() < (drop.chance or 1) then
          local qmin = drop.min or 1
          local qmax = drop.max or qmin
          local qty = (qmax > qmin) and math.random(qmin, qmax) or qmin
          Loot.spawn(drop.id, qty, e.x, e.y)
        end
      end

      table.remove(enemies, i)
    end
  end
  spawnTimer = spawnTimer - dt
  if spawnTimer <= 0 and #enemies < maxEnemies then
    spawnEnemy()
    spawnTimer = 2 + math.random() * 2
  end
end

local function updateWreckage(dt)
  for i = #wreckage, 1, -1 do
    local piece = wreckage[i]
    if not piece:update(dt) then
      table.remove(wreckage, i)
    end
  end
end

local function handleCollisions()
  local function closestPointOnSeg(px, py, x1, y1, x2, y2)
    local vx, vy = x2 - x1, y2 - y1
    local wx, wy = px - x1, py - y1
    local c1 = vx*wx + vy*wy
    if c1 <= 0 then return x1, y1, 0 end
    local c2 = vx*vx + vy*vy
    if c2 <= c1 then return x2, y2, 1 end
    local t = c1 / c2
    return x1 + t*vx, y1 + t*vy, t
  end
  local function segCircleHit(x1, y1, x2, y2, cx, cy, r)
    local qx, qy, t = closestPointOnSeg(cx, cy, x1, y1, x2, y2)
    local dx, dy = qx - cx, qy - cy
    if dx*dx + dy*dy <= r*r then return true, qx, qy, t end
    return false
  end
  local function spawnImpact(kind, cx, cy, r, hx, hy, angle, style, bulletKind)
    Effects.spawnImpact(kind, cx, cy, r, hx, hy, angle, style, bulletKind)
  end
  for i = #bullets, 1, -1 do
    local b = bullets[i]
    if b.kind == "laser" then
      local x2 = b.x + math.cos(b.angle) * b.length
      local y2 = b.y + math.sin(b.angle) * b.length
      if b.friendly then
        for j = #enemies, 1, -1 do
          local e = enemies[j]
          local hit, hx, hy = segCircleHit(b.x, b.y, x2, y2, e.x, e.y, e.radius)
          if hit then
            local hadShield = (e.shield or 0) > 0
            local impactAngle = math.atan2(hy - e.y, hx - e.x)
            e:hit(b.damage)
            spawnImpact(hadShield and 'shield' or 'hull', e.x, e.y, e.radius, hx, hy, impactAngle, b.impact, b.kind)
            break
          end
        end
      else
        local hit, hx, hy = segCircleHit(b.x, b.y, x2, y2, player.x, player.y, player.radius)
        if hit then
          local impactAngle = math.atan2(hy - player.y, hx - player.y)
          player:hit(b.damage)
          spawnImpact(((player.shield or 0) > 0) and 'shield' or 'hull', player.x, player.y, player.radius, hx, hy, impactAngle, b.impact, b.kind)
        end
      end
    else
      local x1, y1 = b.prevx or b.x, b.prevy or b.y
      local x2, y2 = b.x, b.y
      if b.friendly then
        for j = #enemies, 1, -1 do
          local e = enemies[j]
          local er = (e.radius or 10) + 1.5
          local hit, hx, hy = segCircleHit(x1, y1, x2, y2, e.x, e.y, er)
          if not hit then
            local dx, dy = (x2 - e.x), (y2 - e.y)
            hit = (dx*dx + dy*dy) <= er*er
            hx, hy = x2, y2
          end
          if hit then
            local hadShield = (e.shield or 0) > 0
            local impactAngle = math.atan2(hy - e.y, hx - e.x)
            e:hit(b.damage or 1)
            spawnImpact(hadShield and 'shield' or 'hull', e.x, e.y, e.radius, hx, hy, impactAngle, b.impact, b.kind)
            table.remove(bullets, i)
            break
          end
        end
      else
        local pr = (player.radius or 12) + 1.5
        local hit, hx, hy = segCircleHit(x1, y1, x2, y2, player.x, player.y, pr)
        if not hit then
          local dx, dy = (x2 - player.x), (y2 - player.y)
          hit = (dx*dx + dy*dy) <= pr*pr
          hx, hy = x2, y2
        end
        if hit then
          local impactAngle = math.atan2(hy - player.y, hx - player.x)
          player:hit(b.damage or 1)
          spawnImpact(((player.shield or 0) > 0) and 'shield' or 'hull', player.x, player.y, player.radius, hx, hy, impactAngle, b.impact, b.kind)
          table.remove(bullets, i)
        end
      end
    end
  end
end

local function drawEntities()
  for _, e in ipairs(enemies) do e:draw() end
  for _, b in ipairs(bullets) do b:draw() end
  player:draw()
end

local function drawWreckage()
  for _, piece in ipairs(wreckage) do
    piece:draw()
  end
end

function Game.load()
  math.randomseed(os.time())
  -- Load data-driven content
  Content.load()
  world = World.new(6000, 6000)
  camera = Camera.new()
  local starterShip = Content.getShip("basic_frigate")
  player = Player.new(world.width * 0.5, world.height * 0.5, starterShip)
  -- Boost player speed/accel 5x for testing
  player.accel = (player.accel or 500) * 5
  player.maxSpeed = (player.maxSpeed or 320) * 5
  camera:setTarget(player)
  -- Central hub at world center
  hub = Hub.new(world.width * 0.5, world.height * 0.5, { radius = 1200, core = 720, regenHP = 12 })
  for i = 1, maxEnemies do spawnEnemy() end
  -- Give player some starter items/credits from content
  player.credits = 500
  player.inventory = {
    ore_tritanium = 20,
    ore_palladium = 5,
    repair_kit_basic = 2,
  }
  -- Initialize Input module with game state references
  Input.init({
    camera = camera,
    player = player,
    enemies = enemies,
    getInventoryOpen = function() return inventoryOpen end,
    setInventoryOpen = function(value) inventoryOpen = value end,
    getEquipmentOpen = function() return equipmentOpen end,
    setEquipmentOpen = function(value) equipmentOpen = value end,
    getBountyOpen = function() return bountyOpen end,
    setBountyOpen = function(value) bountyOpen = value end,
    clickMarkers = clickMarkers
  })
end

function Game.update(dt)
    local input = Input.getInputState()
  player:update(dt, input, function(x, y, angle, friendly, kind, damage, dist, style)
    kind = kind or "gun"
    if kind == "laser" then
      local length = math.min(700, dist or 500)
      table.insert(bullets, Bullet.new(x, y, angle, true, {life = 0.06, kind = "laser", length = length, damage = damage or 18, color = style and style.tracer and style.tracer.color, impact = style and style.impact}))
    elseif kind == "missile" then
      table.insert(bullets, Bullet.new(x, y, angle, true, {life = 3.5, kind = "missile", damage = damage or 24, color = style and style.tracer and style.tracer.color, impact = style and style.impact}))
    else -- gun
      local tracerSpeed = 900
      local life = math.min(1.2, (dist or 600) / tracerSpeed)
      table.insert(bullets, Bullet.new(x, y, angle, true, {
        life = life, kind = "gun", damage = damage or 16,
        color = style and style.tracer and style.tracer.color,
        tracerWidth = style and style.tracer and style.tracer.width,
        coreRadius = style and style.tracer and style.tracer.coreRadius,
        impact = style and style.impact,
      }))
    end
  end, world)
  updateEnemies(dt)
  updateBullets(dt)
  updateWreckage(dt)
  Loot.update(dt, player)
  handleCollisions()
  -- Update effects and impacts
  Effects.update(dt)
  camera:update(dt)
  -- Hub regeneration
  if hub and hub:contains(player.x, player.y) then
    if player.hp and player.maxHP then
      player.hp = math.min(player.maxHP, player.hp + (hub.regenHP or 0) * dt)
    end
    if hub.regenShield and hub.regenShield > 0 and player.maxShield and player.shield then
      player.shield = math.min(player.maxShield, player.shield + hub.regenShield * dt)
    end
    if hub.regenEnergy and hub.regenEnergy > 0 and player.maxEnergy and player.energy then
      player.energy = math.min(player.maxEnergy, player.energy + hub.regenEnergy * dt)
    end
  end
  -- Update click markers
  for i = #clickMarkers, 1, -1 do
    local m = clickMarkers[i]
    m.t = m.t + dt
    if m.t >= m.dur then table.remove(clickMarkers, i) end
  end
end

function Game.draw()
    world:drawBackground(camera)
  camera:apply()
  world:drawBounds()
  -- Draw hub behind ships/bullets but in world space
  if hub then hub:draw() end
  -- Move destination visuals
  if player.moveTarget then
    local mt = player.moveTarget
    local t = love.timer.getTime()
    local r = 12 + math.sin(t * 4) * 2
    love.graphics.setColor(0.2, 1, 0.8, 0.35)
    love.graphics.circle("line", mt.x, mt.y, r)
  end
  -- Fading ripple markers
  for _, m in ipairs(clickMarkers) do
    local k = math.max(0, math.min(1, m.t / m.dur))
    local r = Util.lerp(m.r0, m.r1, k)
    local a = (1 - k) * 0.6
    love.graphics.setColor(0.2, 1, 0.8, a)
    love.graphics.circle("line", m.x, m.y, r)
  end
  -- Target highlight: subtle corner brackets
  if player.target and not player.target.dead then
    local tgt = player.target
    local rr = tgt.radius + 12
    local l = 10
    local pulse = 0.55 + 0.35 * math.abs(math.sin(love.timer.getTime() * 3))
    local a = (player.locked and 0.9 or 0.55) * pulse
    love.graphics.setColor(0.2, 1.0, 0.8, a)
    love.graphics.setLineWidth(2)
    -- top-left
    love.graphics.line(tgt.x - rr, tgt.y - rr + l, tgt.x - rr, tgt.y - rr)
    love.graphics.line(tgt.x - rr, tgt.y - rr, tgt.x - rr + l, tgt.y - rr)
    -- top-right
    love.graphics.line(tgt.x + rr, tgt.y - rr + l, tgt.x + rr, tgt.y - rr)
    love.graphics.line(tgt.x + rr - l, tgt.y - rr, tgt.x + rr, tgt.y - rr)
    -- bottom-left
    love.graphics.line(tgt.x - rr, tgt.y + rr - l, tgt.x - rr, tgt.y + rr)
    love.graphics.line(tgt.x - rr, tgt.y + rr, tgt.x - rr + l, tgt.y + rr)
    -- bottom-right
    love.graphics.line(tgt.x + rr, tgt.y + rr - l, tgt.x + rr, tgt.y + rr)
    love.graphics.line(tgt.x + rr - l, tgt.y + rr, tgt.x + rr, tgt.y + rr)
    love.graphics.setLineWidth(1)
  end
  drawEntities()
  drawWreckage()
  -- Draw loot in world space
  Loot.draw()
  -- Draw impacts and FX particles
  Effects.draw()
  camera:reset()
  UI.drawHUD(player, world, enemies)
  if inventoryOpen then
    Inventory.draw(player)
  end
  if equipmentOpen then
    Equipment.draw(player)
  end
  if bountyOpen then
    Bounty.draw(bounty)
  end
end



return Game


