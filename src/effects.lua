local Util = require("src.util")

local Effects = {}

-- Internal containers
local fx = {}
local impacts = {}

-- Public accessors (if other systems need to inspect)
function Effects.getFx()
  return fx
end

function Effects.getImpacts()
  return impacts
end

-- Add a generic FX particle
function Effects.add(part)
  table.insert(fx, part)
end

-- Spawn a detonation visual burst
function Effects.spawnDetonation(x, y, kind, color)
  Effects.add({ type = 'ring', x = x, y = y, r0 = 6, r1 = 90, w0 = 6, w1 = 1, t = 0, life = 0.45,
    color = color or {1.0, 0.7, 0.3, 0.5} })
  for i=1,6 do
    local a = math.random() * math.pi * 2
    local r = 8 + math.random()*14
    Effects.add({ type = 'smoke', x = x + math.cos(a)*r, y = y + math.sin(a)*r, r0 = 6, rg = 56 + math.random()*26,
      t = 0, life = 0.8 + math.random()*0.4, color = {0.4,0.4,0.4,0.35} })
  end
  for i=1,10 do
    local a = math.random() * math.pi * 2
    local s = 160 + math.random()*140
    Effects.add({ type = 'spark', x = x, y = y, vx = math.cos(a)*s, vy = math.sin(a)*s, t = 0,
      life = 0.35 + math.random()*0.25, color = {1.0,0.7,0.25,0.9}, size = 2 })
  end
end

-- Spawn an impact (shield or hull) and optional bulletKind-specific flair
function Effects.spawnImpact(kind, cx, cy, r, hx, hy, angle, style, bulletKind)
  local life = (kind == 'shield' and 0.18) or 0.22
  local spanDeg = 60
  local shieldColors = {
    {0.26, 0.62, 1.0, 0.55},
    {0.50, 0.80, 1.0, 0.35},
  }
  if style and style.shield then
    spanDeg = style.shield.spanDeg or spanDeg
    if style.shield.color1 then shieldColors[1] = style.shield.color1 end
    if style.shield.color2 then shieldColors[2] = style.shield.color2 end
  end
  local hullColors = {
    spark = {1.0, 0.6, 0.1, 0.6},
    ring  = {1.0, 0.3, 0.0, 0.4},
  }
  if style and style.hull then
    hullColors.spark = style.hull.spark or hullColors.spark
    hullColors.ring  = style.hull.ring  or hullColors.ring
  end
  table.insert(impacts, {
    kind = kind,
    cx = cx, cy = cy, r = r,
    x = hx, y = hy, angle = angle,
    t = 0, life = life,
    span = math.rad(spanDeg),
    shield = { colors = shieldColors },
    hull = hullColors,
  })

  if kind == 'hull' then
    local n = 6 + math.random(4)
    for i=1,n do
      local a = angle + (math.random()*2-1) * math.pi*0.35
      local s = 180 + math.random()*120
      Effects.add({ type='spark', x=hx, y=hy, vx=math.cos(a)*s, vy=math.sin(a)*s, t=0, life=0.25+math.random()*0.25,
        color = {1.0,0.85,0.2,0.9}, size = 1.6 })
    end
    Effects.add({ type='ring', x=hx, y=hy, r0=2, r1=24, w0=3, w1=1, t=0, life=0.25, color={1,0.5,0.1,0.45} })
    if bulletKind == 'laser' then
      Effects.add({ type='ring', x=hx, y=hy, r0=1, r1=18, w0=2, w1=1, t=0, life=0.2, color={0.6,0.9,1.0,0.6} })
    elseif bulletKind == 'missile' then
      for i=1,6 do
        local a = angle + (math.random()*2-1) * math.pi
        local s = 120 + math.random()*180
        Effects.add({ type='spark', x=hx, y=hy, vx=math.cos(a)*s, vy=math.sin(a)*s, t=0, life=0.3+math.random()*0.25,
          color={1.0,0.7,0.3,0.9}, size=2 })
      end
      Effects.add({ type='smoke', x=hx, y=hy, r0=10, rg=70, t=0, life=0.9, color={0.35,0.35,0.35,0.35} })
    end
  else -- shield
    Effects.add({ type='ring', x=hx, y=hy, r0=12, r1=38, w0=2, w1=1, t=0, life=0.20, color={0.5,0.9,1.0,0.35} })
    for i=1,5 do
      local a = angle + (math.random()*2-1) * math.pi*0.5
      local s = 140 + math.random()*60
      Effects.add({ type='spark', x=hx, y=hy, vx=math.cos(a)*s, vy=math.sin(a)*s, t=0, life=0.15+math.random()*0.15,
        color = {0.7,0.95,1.0,0.8}, size = 1.2 })
    end
    if bulletKind == 'laser' then
      Effects.add({ type='ring', x=hx, y=hy, r0=8, r1=42, w0=1.5, w1=0.8, t=0, life=0.18, color={0.6,0.95,1.0,0.45} })
    elseif bulletKind == 'missile' then
      Effects.add({ type='ring', x=hx, y=hy, r0=16, r1=56, w0=3, w1=1.5, t=0, life=0.22, color={1.0,0.75,0.35,0.35} })
    end
  end
end

function Effects.update(dt)
  -- Update impacts lifetimes
  for i = #impacts, 1, -1 do
    local p = impacts[i]
    p.t = p.t + dt
    if p.t >= p.life then table.remove(impacts, i) end
  end
  -- Update FX particles
  for i = #fx, 1, -1 do
    local f = fx[i]
    f.t = f.t + dt
    if f.t >= f.life then
      table.remove(fx, i)
    else
      if f.type == 'spark' then
        f.x = f.x + (f.vx or 0) * dt
        f.y = f.y + (f.vy or 0) * dt
        f.vx = (f.vx or 0) * 0.90
        f.vy = (f.vy or 0) * 0.90 + 18 * dt
      elseif f.type == 'smoke' then
        f.y = f.y - 8 * dt
      end
    end
  end
end

function Effects.draw()
  -- Draw impacts
  for k = #impacts, 1, -1 do
    local p = impacts[k]
    local a = 1 - (p.t / p.life)
    if a <= 0 then table.remove(impacts, k) else
      if p.kind == 'shield' then
        local span = p.span or math.rad(60)
        local a0 = p.angle - span * 0.6
        local a1 = p.angle + span * 0.6
        love.graphics.setLineWidth(2)
        local c1 = p.shield.colors[1]
        local c2 = p.shield.colors[2]
        love.graphics.setColor(c1[1], c1[2], c1[3], (c1[4] or 0.6) * a)
        love.graphics.arc('line', p.cx, p.cy, p.r + 8, a0, a1)
        love.graphics.setColor(c2[1], c2[2], c2[3], (c2[4] or 0.4) * a)
        love.graphics.arc('line', p.cx, p.cy, p.r + 12, a0, a1)
        love.graphics.setLineWidth(1)
      else
        local sc = p.hull.spark
        local rc = p.hull.ring
        love.graphics.setColor(sc[1], sc[2], sc[3], (sc[4] or 0.6) * a)
        love.graphics.circle('fill', p.x, p.y, 3)
        love.graphics.setColor(rc[1], rc[2], rc[3], (rc[4] or 0.4) * a)
        love.graphics.circle('line', p.x, p.y, 6)
      end
    end
  end
  -- Draw FX particles
  for i = #fx, 1, -1 do
    local f = fx[i]
    local a = 1 - (f.t / f.life)
    if a <= 0 then table.remove(fx, i) else
      if f.type == 'spark' then
        love.graphics.setColor(f.color[1], f.color[2], f.color[3], (f.color[4] or 1) * a)
        love.graphics.circle('fill', f.x, f.y, f.size or 2)
      elseif f.type == 'ring' then
        local rr = Util.lerp(f.r0 or 2, f.r1 or 24, f.t / f.life)
        local lw = Util.lerp(f.w0 or 2, f.w1 or 1, f.t / f.life)
        love.graphics.setLineWidth(lw)
        local c=f.color or {1,1,1,0.4}
        love.graphics.setColor(c[1],c[2],c[3], (c[4] or 0.4) * a)
        love.graphics.circle('line', f.x, f.y, rr)
        love.graphics.setLineWidth(1)
      elseif f.type == 'smoke' then
        local rr = Util.lerp(f.r0 or 6, (f.r0 or 6) + (f.rg or 40), f.t / f.life)
        local c=f.color or {0.4,0.4,0.4,0.4}
        love.graphics.setColor(c[1],c[2],c[3], (c[4] or 0.4) * a)
        love.graphics.circle('fill', f.x, f.y, rr)
      end
    end
  end
end

return Effects

