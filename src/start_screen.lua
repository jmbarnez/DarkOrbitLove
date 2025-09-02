local Input = require("src.input")

local Start = {}
Start.__index = Start

-- Start screen input handler
local startScreenHandler = function(self, x, y, button)
  if button ~= 1 then return false end
  local r = self.button._rect
  if not r then return false end
  if x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
    return true -- signal start
  end
  return false
end

local function genSkyStars(sw, sh, count)
  local stars = {}
  for i = 1, count do
    stars[i] = {
      x = math.random() * sw,
      y = math.random() * sh,
      s = 0.14 + math.random() * 0.22,
      a = 0.06 + math.random() * 0.06,
      tw = 0.35 + math.random() * 0.55,
      ph = math.random() * math.pi * 2,
    }
  end
  return stars
end

local function genScreenStars(sw, sh, count)
  local stars = {}
  for i = 1, count do
    stars[i] = { x = math.random() * sw, y = math.random() * sh, s = 0.28 + math.random() * 0.36 }
  end
  return stars
end

function Start.new()
  local self = setmetatable({}, Start)
  self.w, self.h = love.graphics.getWidth(), love.graphics.getHeight()
  local scale = (self.w * self.h) / (1920 * 1080)
  self.sky = genSkyStars(self.w, self.h, math.floor(300 * math.max(1, scale)))
  self.layers = {
    { p = 0.040, stars = genScreenStars(self.w, self.h, math.floor(120 * math.max(1, scale))) },
    { p = 0.015, stars = genScreenStars(self.w, self.h, math.floor(80  * math.max(1, scale))) },
  }
  self.button = { x = 0, y = 0, w = 260, h = 64 }
  return self
end

function Start:resize(w, h)
  self.w, self.h = w, h
  local scale = (self.w * self.h) / (1920 * 1080)
  self.sky = genSkyStars(self.w, self.h, math.floor(300 * math.max(1, scale)))
  self.layers[1].stars = genScreenStars(self.w, self.h, math.floor(120 * math.max(1, scale)))
  self.layers[2].stars = genScreenStars(self.w, self.h, math.floor(80  * math.max(1, scale)))
end

local function uiScale()
  return math.min(love.graphics.getWidth() / 1920, love.graphics.getHeight() / 1080)
end

function Start:draw()
  local w, h = self.w, self.h
  love.graphics.clear(8/255, 10/255, 18/255)
  -- Static sky
  local t = love.timer.getTime()
  for i = 1, #self.sky do
    local s = self.sky[i]
    local alpha = s.a + 0.04 * math.sin(t * s.tw + s.ph)
    love.graphics.setColor(1,1,1, math.max(0, alpha))
    love.graphics.circle('fill', math.floor(s.x)+0.5, math.floor(s.y)+0.5, s.s)
  end
  -- Parallax stars
  for li = 1, #self.layers do
    local layer = self.layers[li]
    local p = layer.p
    -- No camera yet; drift slightly to add life
    local ox = (t * 4 * p) % w
    local oy = (t * 2 * p) % h
    local alpha = math.min(0.26, 0.10 + 1.6 * p)
    love.graphics.setColor(1,1,1, alpha)
    for i = 1, #layer.stars do
      local s = layer.stars[i]
      local sx = s.x + ox
      local sy = s.y + oy
      if sx >= w then sx = sx - w end
      if sy >= h then sy = sy - h end
      if sx < 0 then sx = sx + w end
      if sy < 0 then sy = sy + h end
      love.graphics.circle('fill', math.floor(sx)+0.5, math.floor(sy)+0.5, s.s)
    end
  end
  -- Title + Button (scaled)
  local s = uiScale()
  local bw, bh = self.button.w * s, self.button.h * s
  local bx = math.floor((w - bw) * 0.5)
  local by = math.floor(h * 0.56)
  self.button._rect = { x = bx, y = by, w = bw, h = bh }
  love.graphics.setColor(0,0,0,0.24)
  love.graphics.rectangle('fill', bx + 4, by + 6, bw, bh, 10, 10)
  local mx, my = love.mouse.getPosition()
  local hover = mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
  love.graphics.setColor(hover and {0.16,0.18,0.24,1.0} or {0.12,0.13,0.19,1.0})
  love.graphics.rectangle('fill', bx, by, bw, bh, 10, 10)
  love.graphics.setColor(0.27, 0.55, 0.98, 1.0)
  love.graphics.rectangle('line', bx, by, bw, bh, 10, 10)
  -- Title
  love.graphics.setColor(0.92, 0.95, 1.00, 0.96)
  love.graphics.printf('Love Universe', 0, math.floor(h * 0.34), w, 'center')
  -- Button label
  love.graphics.printf('New Game', bx, by + math.floor(18 * s), bw, 'center')
  -- Version button bottom-left
  local vbw, vbh = 100 * s, 34 * s
  local vbx, vby = math.floor(16 * s), math.floor(h - vbh - 16 * s)
  love.graphics.setColor(0,0,0,0.24)
  love.graphics.rectangle('fill', vbx + 3, vby + 4, vbw, vbh, 8, 8)
  love.graphics.setColor(0.12,0.13,0.19,1.0)
  love.graphics.rectangle('fill', vbx, vby, vbw, vbh, 8, 8)
  love.graphics.setColor(0.27,0.55,0.98,1.0)
  love.graphics.rectangle('line', vbx, vby, vbw, vbh, 8, 8)
  love.graphics.setColor(0.92, 0.95, 1.00, 0.96)
  love.graphics.printf('v0.1', vbx, vby + math.floor(8 * s), vbw, 'center')
end

function Start:mousepressed(x, y, button)
  return startScreenHandler(self, x, y, button)
end

return Start
