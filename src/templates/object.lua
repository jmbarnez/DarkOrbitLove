-- Generic world object template for future content-driven objects.
local Object = {}
Object.__index = Object

function Object.new(props)
  local self = setmetatable({}, Object)
  self.x = props.x or 0
  self.y = props.y or 0
  self.radius = props.radius or 8
  self.hp = props.hp or 1
  self.maxHP = props.maxHP or self.hp
  self.sig = props.sig or 50
  self.dead = false
  return self
end

function Object:hit(dmg)
  self.hp = self.hp - (dmg or 0)
  if self.hp <= 0 then self.dead = true end
end

function Object:update(dt)
  -- no-op by default
end

function Object:draw()
  love.graphics.setColor(0.7, 0.7, 0.9)
  love.graphics.circle("line", self.x, self.y, self.radius)
end

return Object

