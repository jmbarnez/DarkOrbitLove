local Util = require("src.util")
local EnemyRender = require("src.enemy_render")
local Turret = require("src.turret")
local Content = require("src.content")

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y)
  local self = setmetatable({}, Enemy)
  self.x, self.y = x, y
  self.vx, self.vy = 0, 0
  self.radius = 10
  self.sig = 80
  self.speed = 160
  self.hp = 3
  self.maxHP = 3
  self.bounty = 10
  self.shield = 0
  self.maxShield = 0
  -- Shared turret system: basic drones use laser for testing
  local turretId = "laser_mk1"
  local tDef = (Content.getTurret and Content.getTurret(turretId)) or (Content.getTurret and Content.getTurret("basic_gun"))
  self.turret = Turret.new(self, tDef or {
    type = "gun",
    optimal = 380, falloff = 260, tracking = 0.7, sigRes = 100,
    damageMin = 1, damageMax = 2, cycle = 3.6, capCost = 0, turnRate = 3.2
  })
  -- Behavior ranges
  local opt = self.turret.optimal or 380
  local fall = self.turret.falloff or 250
  self.aggroRange = opt + fall + 200 -- a bit further than turret range
  self.wanderDir = math.random() * math.pi * 2
  self.wanderTimer = 1 + math.random() * 2
  self.dead = false
  self.angle = 0
  -- Simple loot table (placeholder items)
  self.lootTable = {
    { id = "ore_tritanium", min = 1, max = 3, chance = 0.7 },
    { id = "ore_palladium", min = 1, max = 2, chance = 0.35 },
    { id = "repair_kit_basic", min = 1, max = 1, chance = 0.15 },
  }
  -- Visual definition: small drone
  self.visuals = {
    size = 0.8,
    shapes = {
      { type = "circle", mode = "fill", color = {0.42, 0.45, 0.50, 1.0}, x = 0, y = 0, r = 10 },
      { type = "circle", mode = "line", color = {0.20, 0.22, 0.26, 0.9}, x = 0, y = 0, r = 10 },
      { type = "circle", mode = "fill", color = {1.0, 0.35, 0.25, 0.9}, x = 3, y = 0, r = 3.2 },
      { type = "rect", mode = "fill", color = {0.32, 0.35, 0.39, 1.0}, x = -6, y = -12, w = 18, h = 4, rx = 1 },
      { type = "rect", mode = "fill", color = {0.32, 0.35, 0.39, 1.0}, x = -6, y = 8,  w = 18, h = 4, rx = 1 },
      { type = "rect", mode = "fill", color = {0.28, 0.30, 0.34, 1.0}, x = 8, y = -1, w = 8, h = 2, rx = 1 },
      { type = "circle", mode = "fill", color = {1.0, 0.25, 0.2, 0.8}, x = -6, y = -10, r = 1.5 },
      { type = "circle", mode = "fill", color = {1.0, 0.25, 0.2, 0.8}, x = -6, y = 10,  r = 1.5 },
    }
  }
  return self
end

function Enemy:hit(dmg)
  local s = math.min(self.shield or 0, dmg)
  self.shield = (self.shield or 0) - s
  local rem = dmg - s
  if rem > 0 then self.hp = self.hp - rem end
  if self.hp <= 0 then self.dead = true end
end

function Enemy:update(dt, player, shoot)
  local dx, dy = player.x - self.x, player.y - self.y
  local dist = math.sqrt(dx * dx + dy * dy)
  local engageRange = (self.turret.optimal or 380) + (self.turret.falloff or 250)
  local chase = dist < (self.aggroRange or (engageRange + 200))
  local ax, ay
  if chase then
    local nx, ny = dx / math.max(1, dist), dy / math.max(1, dist)
    local tx, ty = -ny, nx -- tangent for orbit
    local desired = self.turret.optimal or 420
    local dr = dist - desired
    local radialSign = dr < 0 and -1 or 1
    local radialMag = math.min(1.0, math.abs(dr) / math.max(60, desired * 0.6))
    -- Orbit while nudging inward/outward to maintain optimal distance
    ax, ay = Util.normalize(tx * 1.0 + nx * 0.6 * radialSign * radialMag, ty * 1.0 + ny * 0.6 * radialSign * radialMag)
  else
    self.wanderTimer = self.wanderTimer - dt
    if self.wanderTimer <= 0 then
      self.wanderDir = self.wanderDir + (math.random() - 0.5)
      self.wanderTimer = 1 + math.random() * 2
    end
    ax, ay = math.cos(self.wanderDir), math.sin(self.wanderDir)
  end
  self.vx = self.vx + ax * self.speed * dt
  self.vy = self.vy + ay * self.speed * dt
  local v = math.sqrt(self.vx * self.vx + self.vy * self.vy)
  local maxv = 220
  if v > maxv then
    local nx, ny = self.vx / v, self.vy / v
    self.vx, self.vy = nx * maxv, ny * maxv
  end
  self.x = self.x + self.vx * dt
  self.y = self.y + self.vy * dt
  self.vx, self.vy = self.vx * 0.95, self.vy * 0.95
  local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
  if speed > 2 then
    self.angle = (math.atan2 and math.atan2(self.vy, self.vx)) or math.atan(self.vy / math.max(1e-6, self.vx))
  else
    self.angle = (math.atan2 and math.atan2(dy, dx)) or math.atan(dy / math.max(1e-6, dx))
  end
  -- Use shared turret logic: lock when within turret effective range
  local locked = chase and dist <= engageRange
  self.turret:update(dt, player, locked, function(x, y, angle, friendly, kind, damage, dist2, style)
    -- Enemy shots: map to provided shoot(); downstream decides projectile type
    shoot(x, y, angle, false, kind, damage, dist2, style)
  end)
end

function Enemy:draw()
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(self.angle)
  EnemyRender.draw(self.visuals)
  love.graphics.pop()
end

return Enemy
