local Util = require("src.util")

local Turret = {}
Turret.__index = Turret

-- params: optimal, falloff, tracking, sigRes, damage, cycle, capCost
function Turret.new(owner, params)
  local self = setmetatable({}, Turret)
  self.owner = owner
  self.angle = 0
  self.cooldown = 0
  self.kind = params.type or params.kind or "gun" -- gun | laser | missile
  -- Visual and behavior customization
  self.tracer = params.tracer or {}      -- e.g., { color={r,g,b,a}, width=1, coreRadius=2 }
  self.impact = params.impact or {}      -- e.g., { shield={spanDeg=60, color1={...}, color2={...}}, hull={spark={...}, ring={...}} }
  -- Per-kind default spread if not provided
  if params.spread then
    self.spread = params.spread
  else
    if self.kind == 'laser' then
      self.spread = { minDeg = 0.05, maxDeg = 0.25, decay = 900 }
    elseif self.kind == 'missile' then
      self.spread = { minDeg = 0.4, maxDeg = 2.5, decay = 800 }
    else
      self.spread = { minDeg = 0.8, maxDeg = 8.0, decay = 600 }
    end
  end
  self.optimal = params.optimal or 350
  self.falloff = params.falloff or 250
  self.tracking = params.tracking or 0.6 -- rad/s
  self.sigRes = params.sigRes or 100
  -- damage can be a fixed number or a range via damageMin/Max
  self.damage = params.damage or 18
  self.damageMin = params.damageMin or self.damage
  self.damageMax = params.damageMax or self.damage
  self.cycle = params.cycle or 0.9
  self.capCost = params.capCost or 4
  self.turnRate = params.turnRate or 3.2 -- rad/s turret rotation animation
  self.lastChance = 0
  -- Default projectile speed per kind (used for predictive lead)
  self.projectileSpeed = params.projectileSpeed or ((self.kind == 'laser' and 10000)
      or (self.kind == 'missile' and 380) or 900)
  return self
end

local function calcAngular(owner, target)
  local dx, dy = target.x - owner.x, target.y - owner.y
  local dist = math.max(1, math.sqrt(dx*dx + dy*dy))
  local nx, ny = dx / dist, dy / dist
  local rvx, rvy = (target.vx or 0) - (owner.vx or 0), (target.vy or 0) - (owner.vy or 0)
  local transversal = math.abs(rvx * (-ny) + rvy * nx)
  local angular = transversal / dist
  return angular, dist
end

local function hitChance(self, owner, target)
  -- Reinterpret "chance" as spread-based accuracy only.
  local dx, dy = target.x - owner.x, target.y - owner.y
  local dist = math.max(1, math.sqrt(dx * dx + dy * dy))
  -- Compute the same spread model used during firing
  local decay = self.spread.decay or 600
  local t = 1 - math.exp(-math.max(0, dist) / decay)
  local minSpread = math.rad(self.spread.minDeg or 0.8)
  local maxSpread = math.rad(self.spread.maxDeg or 8)
  -- Tighten at close range
  local closeTighten = math.min(1, dist / 220)
  minSpread = minSpread * closeTighten
  local spread = minSpread + (maxSpread - minSpread) * t
  -- Probability of intersecting a circle at distance with uniform angular error [-spread, spread]
  local r = target.radius or 10
  local allowable = math.atan(r / dist)
  local chance
  if spread <= 1e-6 then
    chance = 1
  else
    chance = math.max(0, math.min(1, allowable / spread))
  end
  if chance ~= chance then chance = 0 end
  return chance, dist, 0
end

function Turret:update(dt, target, locked, spawnTracer)
  -- rotate towards target for visuals
  if target then
    local desired = (math.atan2 and math.atan2(target.y - self.owner.y, target.x - self.owner.x))
      or math.atan((target.y - self.owner.y) / math.max(1e-6, (target.x - self.owner.x)))
    local diff = (desired - self.angle + math.pi) % (2*math.pi) - math.pi
    local step = self.turnRate * dt
    if math.abs(diff) <= step then
      self.angle = desired
    else
      self.angle = self.angle + step * (diff > 0 and 1 or -1)
    end
  end

  self.cooldown = math.max(0, self.cooldown - dt)
  if not target or not locked then return end

  local chance, dist = hitChance(self, self.owner, target)
  self.lastChance = chance

  -- Determine available energy via optional owner hooks
  local ownerEnergy = (self.owner.getEnergy and self.owner:getEnergy()) or self.owner.energy
  local canSpendHook = (self.owner.canSpendEnergy and self.owner:canSpendEnergy(self.capCost)) or false
  if self.cooldown == 0 and (self.capCost <= 0 or canSpendHook or (ownerEnergy or 0) >= self.capCost) then
    -- Fire cycle
    if self.capCost > 0 then
      if self.owner.spendEnergy then
        self.owner:spendEnergy(self.capCost)
      else
        self.owner.energy = math.max(0, (self.owner.energy or 0) - self.capCost)
      end
    end
    self.cooldown = self.cycle
    -- Spawn a projectile; compute predictive aim with lead based on projectile speed
    local sx, sy = self.owner.x, self.owner.y
    local tx, ty = target.x, target.y
    local tvx, tvy = target.vx or 0, target.vy or 0
    -- projectile speed defaults per kind (can be overridden via params.projectileSpeed)
    local projSpeed = self.projectileSpeed or ((self.kind == 'laser' and 10000)
      or (self.kind == 'missile' and 380) or 900)
    local rx, ry = tx - sx, ty - sy
    local a = (tvx*tvx + tvy*tvy) - (projSpeed*projSpeed)
    local b = 2 * (rx*tvx + ry*tvy)
    local c = rx*rx + ry*ry
    local tHit = 0
    if math.abs(a) < 1e-6 then
      -- Linear solution when projectile much faster or target slow: t = -c/b (if b<0)
      if math.abs(b) > 1e-6 then tHit = math.max(0, -c / b) else tHit = 0 end
    else
      local disc = b*b - 4*a*c
      if disc >= 0 then
        local sdisc = math.sqrt(disc)
        local t1 = (-b - sdisc) / (2*a)
        local t2 = (-b + sdisc) / (2*a)
        if t1 > 1e-4 and t2 > 1e-4 then
          tHit = math.min(t1, t2)
        else
          tHit = math.max(t1, t2)
          if tHit < 0 then tHit = 0 end
        end
      else
        tHit = 0
      end
    end
    local px = tx + tvx * tHit
    local py = ty + tvy * tHit
    local angle = (math.atan2 and math.atan2(py - sy, px - sx))
      or math.atan((py - sy) / math.max(1e-6, (px - sx)))
    -- Add distance-based spread for guns; gradual, scales smoothly with distance
    if self.kind == "gun" or self.kind == "missile" or self.kind == "laser" then
      local decay = self.spread.decay or 600 -- larger = more gradual increase
      local t = 1 - math.exp(-math.max(0, dist) / decay) -- 0..1 asymptotically
      local minSpread = math.rad(self.spread.minDeg or 0.8)
      -- At close range, reduce the minimum spread further to improve accuracy
      local closeTighten = math.min(1, dist / 220) -- under ~220 units, tighten
      minSpread = minSpread * closeTighten
      local maxSpread = math.rad(self.spread.maxDeg or 8)
      local spread = minSpread + (maxSpread - minSpread) * t
      angle = angle + (math.random() * 2 - 1) * spread
    end
    if spawnTracer then
      local dmg
      if self.damageMin and self.damageMax then
        if self.damageMin == self.damageMax then
          dmg = self.damageMin
        else
          dmg = math.random(self.damageMin, self.damageMax)
        end
      else
        dmg = self.damage
      end
      spawnTracer(
        self.owner.x, self.owner.y, angle,
        self.owner == target and false or true,
        self.kind, dmg, dist,
        { tracer = self.tracer, impact = self.impact }
      )
    end
  end
end

return Turret
