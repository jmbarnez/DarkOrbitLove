local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(x, y, angle, friendly, opts)
  local self = setmetatable({}, Bullet)
  self.x, self.y = x, y
  self.prevx, self.prevy = x, y
  self.kind = opts and opts.kind or "gun"
  local speed = 700
  if self.kind == "gun" then speed = 900 end
  if self.kind == "missile" then speed = 380 end
  if self.kind == "laser" then speed = 0 end
  self.vx = math.cos(angle) * speed
  self.vy = math.sin(angle) * speed
  self.radius = (self.kind == "missile") and 6 or (self.kind == "gun" and 2 or 4)
  self.life = (opts and opts.life) or 1.2
  self.dead = false
  self.friendly = friendly ~= false
  self.damage = (opts and opts.damage) or (self.friendly and 16 or 10)
  if self.kind == "laser" then
    self.color = {0.30, 0.85, 1.00}
  elseif self.kind == "missile" then
    self.color = {1.00, 0.65, 0.25}
  else -- gun default: tiny yellow
    self.color = {1.00, 0.95, 0.30}
  end
  if opts and opts.color then self.color = opts.color end
  self.visual = opts and opts.visual or false
  self.hit = opts and opts.hit or false
  self.length = opts and opts.length or 0
  self.angle = angle
  self.tracerWidth = (opts and opts.tracerWidth) or 1
  if opts and opts.coreRadius and self.kind == "gun" then self.radius = opts.coreRadius end
  self.impact = opts and opts.impact or nil
  return self
end

function Bullet:update(dt)
  if self.kind ~= "laser" then
    self.prevx, self.prevy = self.x, self.y
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
  end
  self.life = self.life - dt
  if self.life <= 0 then self.dead = true end
end

function Bullet:draw()
  local r,g,b = self.color[1], self.color[2], self.color[3]
  if self.kind == "laser" then
    love.graphics.setColor(r, g, b, 0.12)
    love.graphics.setLineWidth(6)
    love.graphics.line(self.x, self.y, self.x + math.cos(self.angle) * self.length, self.y + math.sin(self.angle) * self.length)
    love.graphics.setColor(r, g, b, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.line(self.x, self.y, self.x + math.cos(self.angle) * self.length, self.y + math.sin(self.angle) * self.length)
    love.graphics.setLineWidth(1)
  elseif self.kind == "missile" then
    -- missile body
    love.graphics.setColor(r, g, b, 0.95)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    -- exhaust
    love.graphics.setColor(1.0, 0.5, 0.2, 0.35)
    love.graphics.circle("fill", self.x - math.cos(self.angle) * 8, self.y - math.sin(self.angle) * 8, self.radius + 2)
  else
    -- gun: tiny yellow core + thin tracer line
    local lx = math.cos(self.angle)
    local ly = math.sin(self.angle)
    love.graphics.setColor(r, g, b, 0.35)
    love.graphics.setLineWidth(self.tracerWidth or 1)
    love.graphics.line(self.x - lx * 6, self.y - ly * 6, self.x + lx * 10, self.y + ly * 10)
    love.graphics.setColor(r, g, b, 0.95)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setLineWidth(1)
  end
end

return Bullet
