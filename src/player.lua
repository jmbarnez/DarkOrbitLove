local Util = require("src.util")
local Turret = require("src.turret")
local ShipRender = require("src.ship_render")
local Content = require("src.content")

local Player = {}
Player.__index = Player

function Player.new(x, y, ship)
  local self = setmetatable({}, Player)
  self.x, self.y = x, y
  self.vx, self.vy = 0, 0
  self.angle = 0
  self.radius = 16
  -- Defaults (overridden by ship def if provided)
  self.accel = 500
  self.maxSpeed = 320
  self.drag = 0.92
  self.moveTarget = nil
  self.hp = 100
  self.shield = 100
  self.maxHP = 100
  self.maxShield = 100
  self.energy = 100
  self.maxEnergy = 100
  self.sig = 100
  -- Module toggles (per-turret when multiple)
  self.turretEnabled = true
  -- Targeting / lock
  self.target = nil
  self.lockTime = 0
  self.lockProgress = 0
  self.locked = false
  -- Weapon system: for testing, equip three turrets (gun, laser, rocket)
  self.turrets = {}
  local function addTurret(id)
    local def = Content.getTurret and Content.getTurret(id)
    local t = Turret.new(self, def or {
      type = "gun", optimal = 380, falloff = 260, tracking = 0.7, sigRes = 100,
      damageMin = 1, damageMax = 2, cycle = 3.6, capCost = 0, turnRate = 3.2
    })
    table.insert(self.turrets, { id = id, turret = t, enabled = true })
    return t
  end
  local primary = addTurret("basic_gun")
  addTurret("laser_mk1")
  addTurret("rocket_mk1")
  -- Primary reference (compat with existing code)
  self.turret = primary
  self.fireCooldown = 0 -- unused now
  self.fireRate = 0.15 -- unused now
  self.level = 1
  self.xp = 0
  self.credits = 0
  self.inventory = {}
  -- Apply ship definition if provided
  if ship then
    self.ship = ship
    if ship.engine then
      self.accel = ship.engine.accel or self.accel
      self.maxSpeed = ship.engine.maxSpeed or self.maxSpeed
      self.drag = ship.engine.drag or self.drag
    end
    if ship.hull then
      self.maxHP = ship.hull.hp or self.maxHP
      self.maxShield = ship.hull.shield or self.maxShield
      self.maxEnergy = ship.hull.cap or self.maxEnergy
      self.hp = self.maxHP
      self.shield = self.maxShield
      self.energy = self.maxEnergy
    end
    self.sig = ship.sig or self.sig
    -- Keep multi-turret testing loadout regardless of ship hardpoints
  end
  return self
end

function Player:setMoveTarget(x, y)
  self.moveTarget = {x = x, y = y}
end

function Player:addXP(x)
  self.xp = self.xp + x
  if self.xp >= self.level * 100 then
    self.xp = 0
    self.level = self.level + 1
    self.maxHP = self.maxHP + 10
    self.maxShield = self.maxShield + 10
    self.hp = self.maxHP
    self.shield = self.maxShield
  end
end

function Player:hit(dmg)
  local s = math.min(self.shield, dmg)
  self.shield = self.shield - s
  local rem = dmg - s
  if rem > 0 then self.hp = math.max(0, self.hp - rem) end
end

function Player:setTarget(target)
  if target == self.target then return end
  self.target = target
  self.locked = false
  self.lockProgress = 0
  if target then
    local sig = target.sig or 80
    -- Simple lock time: faster for larger targets
    self.lockTime = 0.6 + (self.turret.sigRes / math.max(20, sig)) * 0.5
  else
    self.lockTime = 0
  end
end


function Player:update(dt, input, spawnTracer, world)
  -- Click-to-move acceleration towards target
  if self.moveTarget then
    local dx, dy = self.moveTarget.x - self.x, self.moveTarget.y - self.y
    local dist = Util.length(dx, dy)
    if dist < 6 then
      self.moveTarget = nil
    else
      local nx, ny = Util.normalize(dx, dy)
      self.vx = self.vx + nx * self.accel * dt
      self.vy = self.vy + ny * self.accel * dt
    end
  end
  local speed = Util.length(self.vx, self.vy)
  if speed > self.maxSpeed then
    local nx, ny = Util.normalize(self.vx, self.vy)
    self.vx, self.vy = nx * self.maxSpeed, ny * self.maxSpeed
  end
  self.x = self.x + self.vx * dt
  self.y = self.y + self.vy * dt
  self.vx = self.vx * self.drag
  self.vy = self.vy * self.drag
  self.x = Util.clamp(self.x, self.radius, world.width - self.radius)
  self.y = Util.clamp(self.y, self.radius, world.height - self.radius)
  if speed > 1 then
    -- Face movement direction
    self.angle = (math.atan2 and math.atan2(self.vy, self.vx)) or Util.angleTo(0, 0, self.vx, self.vy)
  else
    -- Idle: face cursor
    self.angle = Util.angleTo(self.x, self.y, input.aimx, input.aimy)
  end
  -- Capacitor regen
  self.energy = math.min(self.maxEnergy, self.energy + 10 * dt)
  -- Target lock progression
  if self.target and not self.target.dead then
    self.lockProgress = math.min(self.lockTime, self.lockProgress + dt)
    self.locked = self.lockProgress >= self.lockTime
  else
    self.target = nil
    self.locked = false
    self.lockProgress = 0
  end
  -- Update all turrets (auto-fire when locked and per-slot enabled)
  if self.turrets and #self.turrets > 0 then
    for _, slot in ipairs(self.turrets) do
      local allow = self.locked and (slot.enabled ~= false)
      slot.turret:update(dt, self.target, allow, spawnTracer)
    end
  else
    local allowFire = self.locked and (self.turretEnabled ~= false)
    self.turret:update(dt, self.target, allowFire, spawnTracer)
  end
end

function Player:draw()
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(self.angle)
  if self.ship then
    ShipRender.draw(self.ship)
  else
    -- fallback simple dart
    love.graphics.setColor(0.1, 0.9, 1.0)
    love.graphics.polygon("fill", -18, -12, 18, 0, -18, 12)
  end
  love.graphics.pop()
end

return Player
