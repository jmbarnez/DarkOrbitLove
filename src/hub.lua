local Util = require("src.util")

local Hub = {}
Hub.__index = Hub

function Hub.new(x, y, opts)
  opts = opts or {}
  local self = setmetatable({}, Hub)
  self.x, self.y = x, y
  self.radius = opts.radius or 220
  self.core = opts.core or 64
  self.regenHP = opts.regenHP or 8      -- hp per second
  self.regenShield = opts.regenShield or 0
  self.regenEnergy = opts.regenEnergy or 0
  -- Station structure parameters
  self.stationLayers = 4  -- concentric layers of station structure
  -- Prebaked canvas for static rendering
  self.canvas, self.cw, self.ch = nil, 0, 0
  Hub.rebuildCanvas(self)
  return self
end

function Hub:contains(px, py)
  return Util.distance(px, py, self.x, self.y) <= self.radius
end


function Hub:rebuildCanvas()
  local core = self.core
  local pad = math.ceil(core * 0.5 + 24)
  local cw, ch = math.ceil(core * 2 + pad * 2), math.ceil(core * 2 + pad * 2)
  if not love.graphics.newCanvas then return end
  local canvas = love.graphics.newCanvas(cw, ch)
  local old = love.graphics.getCanvas()
  love.graphics.push('all')
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0,0,0,0)
  love.graphics.translate(cw * 0.5, ch * 0.5)
  -- Station structure layers (from outer to inner) - static
  for layer = self.stationLayers, 1, -1 do
    local layerRadius = core * (0.3 + layer * 0.18)
    local alpha = 0.7 - layer * 0.1
    love.graphics.setColor(0.15, 0.18, 0.25, alpha)
    love.graphics.setLineWidth(8 - layer)
    love.graphics.circle('line', 0, 0, layerRadius)
    if layer < self.stationLayers then
      love.graphics.setColor(0.25, 0.28, 0.35, alpha * 0.6)
      love.graphics.setLineWidth(2)
      for i = 0, 11 do
        local a = i * (math.pi / 6) + layer * 0.1
        local innerR = core * (0.3 + layer * 0.18)
        local outerR = core * (0.3 + (layer + 1) * 0.18)
        local x1, y1 = math.cos(a) * innerR, math.sin(a) * innerR
        local x2, y2 = math.cos(a) * outerR, math.sin(a) * outerR
        love.graphics.line(x1, y1, x2, y2)
      end
    end
  end
  -- Central core
  love.graphics.setColor(0.12, 0.13, 0.19, 0.95)
  love.graphics.circle('fill', 0, 0, core * 0.3)
  love.graphics.setColor(0.27, 0.55, 0.98, 0.45)
  love.graphics.setLineWidth(2)
  love.graphics.circle('line', 0, 0, core * 0.3)
  -- Station modules/pods + lights (static)
  for i = 0, 5 do
    local angle = i * (math.pi / 3)
    local moduleX, moduleY = math.cos(angle) * (core * 0.85), math.sin(angle) * (core * 0.85)
    love.graphics.setColor(0.2, 0.25, 0.35, 0.8)
    love.graphics.circle('fill', moduleX, moduleY, 20)
    love.graphics.setColor(0.15, 0.2, 0.3, 0.9)
    love.graphics.circle('fill', moduleX, moduleY, 12)
    love.graphics.setColor(0.0, 0.8, 1.0, 0.5)
    for j = 0, 2 do
      local lightAngle = angle + (j - 1) * 0.4
      local lightX = moduleX + math.cos(lightAngle) * 24
      local lightY = moduleY + math.sin(lightAngle) * 24
      love.graphics.circle('fill', lightX, lightY, 2)
    end
  end
  -- Communication arrays (static)
  for i = 0, 2 do
    local angle = i * (2 * math.pi / 3)
    local arrX, arrY = math.cos(angle) * (core * 0.6), math.sin(angle) * (core * 0.6)
    love.graphics.setColor(0.4, 0.45, 0.55, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.line(arrX, arrY, arrX + math.cos(angle) * 20, arrY + math.sin(angle) * 20)
    love.graphics.circle('fill', arrX + math.cos(angle) * 20, arrY + math.sin(angle) * 20, 4)
  end
  -- Power conduits (static)
  love.graphics.setColor(0.0, 0.8, 1.0, 0.35)
  love.graphics.setLineWidth(1)
  for i = 0, 5 do
    local a = i * (math.pi / 3)
    local x1, y1 = math.cos(a) * (core * 0.35), math.sin(a) * (core * 0.35)
    local x2, y2 = math.cos(a) * (core * 0.95), math.sin(a) * (core * 0.95)
    love.graphics.line(x1, y1, x2, y2)
  end
  love.graphics.setCanvas(old)
  love.graphics.pop()
  self.canvas, self.cw, self.ch = canvas, cw, ch
end

function Hub:draw()
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  -- Outer safe-zone ring
  love.graphics.setColor(0.20, 1.0, 0.68, 0.22)
  love.graphics.setLineWidth(2)
  love.graphics.circle('line', 0, 0, self.radius)
  love.graphics.setLineWidth(1)
  if self.canvas then
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(self.canvas, -self.cw * 0.5, -self.ch * 0.5)
  end
  love.graphics.pop()
end

return Hub
