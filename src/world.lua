local World = {}
World.__index = World

local function genStars(w, h, count, parallax)
  local stars = {}
  for i = 1, count do
    -- Distant stars: tiny but slightly larger for visibility
    stars[i] = { x = math.random() * w, y = math.random() * h, p = parallax, s = 0.30 + math.random() * 0.40 }
  end
  return stars
end

-- Screen-space static sky stars (no parallax) to emphasize extreme distance
local function genSkyStars(sw, sh, count)
  local stars = {}
  for i = 1, count do
    stars[i] = {
      x = math.random() * sw,
      y = math.random() * sh,
      s = 0.14 + math.random() * 0.22,
      a = 0.06 + math.random() * 0.06,
      tw = 0.35 + math.random() * 0.55, -- twinkle speed
      ph = math.random() * math.pi * 2, -- twinkle phase
    }
  end
  return stars
end

-- Screen-space parallax stars (move with camera by a small factor)
local function genScreenStars(sw, sh, count)
  local stars = {}
  for i = 1, count do
    stars[i] = { x = math.random() * sw, y = math.random() * sh, s = 0.28 + math.random() * 0.36 }
  end
  return stars
end

-- Pre-baked faint nebula canvas (static, no parallax)
local function buildNebulaCanvas(w, h, seed)
  if not love.graphics.newCanvas then return nil end
  local canvas = love.graphics.newCanvas(w, h)
  local oldCanvas = love.graphics.getCanvas()
  love.graphics.push('all')
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setBlendMode('alpha', 'alphamultiply')
  math.randomseed(seed or os.time())
  local palettes = {
    { {0.30,0.65,1.00}, {0.15,0.35,0.80} },
    { {0.65,0.55,0.95}, {0.35,0.30,0.70} },
    { {0.25,0.90,0.70}, {0.10,0.50,0.45} },
  }
  local blobs = math.floor(12 + (w*h)/(1920*1080) * 8)
  for i = 1, blobs do
    local pal = palettes[1 + (i % #palettes)]
    local cx = math.random() * w
    local cy = math.random() * h
    local r = (math.min(w, h) * (0.16 + math.random() * 0.20))
    for k = 7, 1, -1 do
      local t = k / 7
      local rr = r * t
      local cr = pal[1][1] * t + pal[2][1] * (1 - t)
      local cg = pal[1][2] * t + pal[2][2] * (1 - t)
      local cb = pal[1][3] * t + pal[2][3] * (1 - t)
      local a = 0.006 * t
      love.graphics.setColor(cr, cg, cb, a)
      love.graphics.circle('fill', cx, cy, rr)
    end
  end
  love.graphics.setCanvas(oldCanvas)
  love.graphics.pop()
  return canvas
end

local function genPlanets(w, h, count)
  local planets = {}
  local function farEnough(x, y, r)
    for _, p in ipairs(planets) do
      local dx, dy = x - p.x, y - p.y
      local d2 = dx*dx + dy*dy
      local need = (r + p.r) * 2.2 + 800 -- enforce wide spacing
      if d2 < need * need then return false end
    end
    return true
  end
  for i = 1, count do
    -- assign depth/parallax with small range to feel far away
    local base = (count > 1) and ((i - 1) / (count - 1)) or 0.5
    local depthP = 0.05 + base * 0.17 + (math.random() * 0.03 - 0.015)
    depthP = math.max(0.04, math.min(0.25, depthP))
    local r = 80 + math.random(0, 180)
    local px, py
    local attempts = 0
    repeat
      attempts = attempts + 1
      px = math.random(r, w - r)
      py = math.random(r, h - r)
    until farEnough(px, py, r) or attempts > 200

    -- choose a planet theme
    local theme = (r > 180 and math.random() < 0.7) and "gas" or (math.random() < 0.5 and "rock" or "ice")
    local baseCol, atmo
    if theme == "gas" then
      baseCol = {0.82, 0.62, 0.36} -- warm gas giant
      if math.random() < 0.5 then baseCol = {0.55, 0.70, 0.95} end -- cool gas giant
      atmo = {baseCol[1]*0.6, baseCol[2]*0.7, baseCol[3], 0.35}
    elseif theme == "ice" then
      baseCol = {0.78, 0.85, 0.95}
      atmo = {0.75, 0.85, 1.0, 0.4}
    else -- rock
      baseCol = {0.62, 0.54, 0.42}
      atmo = {0.95, 0.80, 0.55, 0.25}
    end
    planets[i] = {
      x = px, y = py, r = r,
      p = depthP,
      theme = theme,
      color = baseCol,
      atmo = atmo,
      ring = (math.random() < 0.22 and theme ~= "ice") and { tilt = (math.random() - 0.5) * 0.9, inner = r * (1.15 + math.random() * 0.15), outer = r * (1.45 + math.random() * 0.25) } or nil,
      bands = math.random(4, 8),
      seed = math.random() * 1000,
    }
  end
  return planets
end

-- Pre-render a planet to a canvas to avoid any animated look while moving
local function buildPlanetCanvas(pl)
  if not (pl and pl.r) then return end
  local r = pl.r
  local pad = math.ceil(r * 0.3 + 12)
  local cw, ch = math.ceil(r * 2 + pad * 2), math.ceil(r * 2 + pad * 2)
  if not love.graphics.newCanvas then return end
  local canvas = love.graphics.newCanvas(cw, ch)
  local oldCanvas = love.graphics.getCanvas()
  love.graphics.push('all')
  -- Enable stencil writes while drawing to this canvas
  love.graphics.setCanvas({canvas, stencil = true})
  love.graphics.clear(0,0,0,0)
  love.graphics.translate(cw * 0.5, ch * 0.5)
  -- Mask all planet detail to circle via stencil
  love.graphics.stencil(function()
    love.graphics.circle('fill', 0, 0, r)
  end, 'replace', 1)
  love.graphics.setStencilTest('greater', 0)
  -- Base body
  love.graphics.setColor(pl.color)
  love.graphics.circle('fill', 0, 0, r)
  -- Texturing (no time-based terms)
  if pl.theme == 'gas' then
    local bands = pl.bands or 6
    for i = 0, bands do
      local bt = i / (bands)
      local y = (bt * 2 - 1) * r * 0.85
      local wob = math.sin((bt * 12 + (pl.seed or 0)) * 1.2) * r * 0.08
      local a = 0.06 + 0.05 * math.sin((bt * 8 + (pl.seed or 0)) * 2.0)
      local c = { pl.color[1]*0.9, pl.color[2]*0.9, pl.color[3]*0.9, a }
      love.graphics.setColor(c)
      love.graphics.ellipse('fill', wob, y, r * (1.05 + 0.06*math.sin(bt*10)), r * (0.12 + 0.04*math.cos(bt*9)))
    end
    -- subtle storm spot
    love.graphics.setColor(pl.color[1]*0.8, pl.color[2]*0.7, pl.color[3]*0.6, 0.12)
    love.graphics.circle('fill', r*0.25, r*0.1, r*0.18)
  else
    local patches = 18
    for i = 1, patches do
      local ang = (i / patches) * math.pi * 2 + (pl.seed or 0)
      local rr = r * (0.12 + 0.22 * math.random())
      local px = math.cos(ang) * (r * (0.2 + 0.65 * math.random()))
      local py = math.sin(ang) * (r * (0.2 + 0.65 * math.random()))
      local tint = 0.75 + 0.25 * math.random()
      local cr, cg, cb = pl.color[1]*tint, pl.color[2]*tint, pl.color[3]*tint
      if pl.theme == 'ice' then cr, cg, cb = 0.85, 0.92, 0.98 end
      love.graphics.setColor(cr, cg, cb, 0.18)
      love.graphics.ellipse('fill', px, py, rr * (1.4 - math.random()*0.5), rr * (0.9 - math.random()*0.3))
    end
    -- faint crater outlines
    love.graphics.setColor(0,0,0,0.08)
    for i = 1, 6 do
      local ang = math.random()*math.pi*2
      local cr = r*(0.05+0.12*math.random())
      love.graphics.circle('line', math.cos(ang)*r*0.6, math.sin(ang)*r*0.6, cr)
    end
  end
  -- Terminator shading
  local lightAngle = -0.7
  local dx = math.cos(lightAngle) * r * 0.7
  local dy = math.sin(lightAngle) * r * 0.7
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.circle('fill', -dx, -dy, r)
  love.graphics.setStencilTest()
  -- Atmosphere glow
  if pl.atmo then
    for k = 1, 5 do
      local rr = r + k * 2
      local a = (pl.atmo[4] or 0.35) * (0.18 / k)
      love.graphics.setColor(pl.atmo[1], pl.atmo[2], pl.atmo[3], a)
      love.graphics.circle('line', 0, 0, rr)
    end
  end
  -- Rings
  if pl.ring then
    love.graphics.push()
    love.graphics.rotate(pl.ring.tilt)
    love.graphics.setColor(1, 1, 1, 0.04)
    love.graphics.setLineWidth(6)
    love.graphics.circle('line', 0, 0, pl.ring.outer)
    love.graphics.setLineWidth(10)
    love.graphics.circle('line', 0, 0, pl.ring.inner)
    love.graphics.pop()
  end
  love.graphics.setCanvas(oldCanvas)
  love.graphics.pop()
  pl.canvas = canvas
  pl.cw, pl.ch = cw, ch
end

function World.new(width, height)
  local self = setmetatable({}, World)
  self.width = width
  self.height = height
  -- Screen-space star layers + static sky stars
  self.starLayers = {
    { p = 0.040, stars = {} }, -- far
    { p = 0.015, stars = {} }, -- very far
  }
  self.skyW, self.skyH = 0, 0
  self.skyStars = {}
  self.starW, self.starH = 0, 0
  self.nebulaW, self.nebulaH = 0, 0
  self.nebulaCanvas = nil
  self.planets = genPlanets(width, height, 3)
  -- Prebake planet canvases for static appearance
  for _, pl in ipairs(self.planets) do
    buildPlanetCanvas(pl)
  end
  -- Initial stars build
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  self.starW, self.starH = sw, sh
  local scale = (sw * sh) / (1920 * 1080)
  self.starLayers[1].stars = genScreenStars(sw, sh, math.floor(120 * math.max(1, scale)))
  self.starLayers[2].stars = genScreenStars(sw, sh, math.floor(80  * math.max(1, scale)))
  return self
end

function World:contains(x, y, r)
  return x > r and y > r and x < self.width - r and y < self.height - r
end

function World:drawBackground(camera)
  love.graphics.clear(8/255, 10/255, 18/255)
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  -- Rebuild nebula canvas on resolution change
  if (not self.nebulaCanvas) or self.nebulaW ~= w or self.nebulaH ~= h then
    self.nebulaW, self.nebulaH = w, h
    self.nebulaCanvas = buildNebulaCanvas(w, h, 12345)
  end
  if self.nebulaCanvas then
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(self.nebulaCanvas, 0, 0)
  end
  -- Regenerate static sky on resolution change
  if self.skyW ~= w or self.skyH ~= h or (#self.skyStars == 0) then
    self.skyW, self.skyH = w, h
    local scale = (w * h) / (1920 * 1080)
    -- Density tuned for 1080p base
    self.skyStars = genSkyStars(w, h, math.floor(300 * math.max(1, scale)))
  end
  -- Draw static sky (no parallax) with slow twinkle
  local t = (love.timer and love.timer.getTime and love.timer.getTime()) or 0
  for i = 1, #self.skyStars do
    local s = self.skyStars[i]
    local alpha = s.a + 0.05 * math.sin(t * s.tw + s.ph)
    love.graphics.setColor(1, 1, 1, math.max(0, alpha))
    local sx = math.floor(s.x) + 0.5
    local sy = math.floor(s.y) + 0.5
    love.graphics.circle('fill', sx, sy, s.s)
  end
  -- Rebuild parallax screen-space stars on resize
  if self.starW ~= w or self.starH ~= h then
    self.starW, self.starH = w, h
    local scale = (w * h) / (1920 * 1080)
    self.starLayers[1].stars = genScreenStars(w, h, math.floor(120 * math.max(1, scale)))
    self.starLayers[2].stars = genScreenStars(w, h, math.floor(80  * math.max(1, scale)))
  end
  -- Parallax stars: move slightly with camera and wrap on screen bounds
  for li = 1, #self.starLayers do
    local layer = self.starLayers[li]
    local p = layer.p or 0.02
    local ox = (-camera.x * p) % w
    local oy = (-camera.y * p) % h
    local alpha = math.min(0.28, 0.10 + 1.6 * p)
    love.graphics.setColor(1,1,1, alpha)
    for i = 1, #layer.stars do
      local s = layer.stars[i]
      local sx = s.x + ox
      local sy = s.y + oy
      if sx >= w then sx = sx - w end
      if sy >= h then sy = sy - h end
      if sx < 0 then sx = sx + w end
      if sy < 0 then sy = sy + h end
      local sxs = math.floor(sx) + 0.5
      local sys = math.floor(sy) + 0.5
      love.graphics.circle('fill', sxs, sys, s.s)
    end
  end
  -- Planets in front of stars
  if self.planets then
    for _, pl in ipairs(self.planets) do
      local sx = (pl.x - camera.x) * pl.p + w * 0.5
      local sy = (pl.y - camera.y) * pl.p + h * 0.5
      local margin = (pl.r or 100) + 50
      if sx > -margin and sx < w + margin and sy > -margin and sy < h + margin then
        if pl.canvas then
          local dx = (pl.cw or 0) * 0.5
          local dy = (pl.ch or 0) * 0.5
          love.graphics.setColor(1,1,1,1)
          love.graphics.draw(pl.canvas, sx - dx, sy - dy)
        end
      end
    end
  end
end

function World:drawBounds()
  love.graphics.setColor(0.2, 0.4, 0.8, 0.2)
  love.graphics.rectangle("line", 0, 0, self.width, self.height)
end

return World
