local EnemyRender = {}

local function setColor(c, aOverride)
  if type(c) == "table" then
    local r,g,b,a = c[1] or 1, c[2] or 1, c[3] or 1, c[4]
    love.graphics.setColor(r, g, b, aOverride or a or 1)
  else
    love.graphics.setColor(1,1,1,1)
  end
end

local function drawShape(shape, S)
  local t = shape.type or "polygon"
  local mode = shape.mode or "fill"
  setColor(shape.color)
  if t == "polygon" and shape.points then
    local pts = {}
    for i = 1, #shape.points, 2 do
      pts[#pts+1] = S(shape.points[i])
      pts[#pts+1] = S(shape.points[i+1])
    end
    love.graphics.polygon(mode, pts)
  elseif t == "circle" then
    love.graphics.circle(mode, S(shape.x or 0), S(shape.y or 0), S(shape.r or 4))
  elseif t == "rect" or t == "rectangle" then
    love.graphics.rectangle(mode, S(shape.x or 0), S(shape.y or 0), S(shape.w or 4), S(shape.h or 4), S(shape.rx or 0), S(shape.ry or shape.rx or 0))
  elseif t == "line" and shape.points then
    local pts = {}
    for i = 1, #shape.points, 2 do
      pts[#pts+1] = S(shape.points[i])
      pts[#pts+1] = S(shape.points[i+1])
    end
    love.graphics.line(pts)
  end
end

function EnemyRender.draw(visuals)
  local v = visuals or {}
  local size = v.size or 1.0
  local function S(x) return x * size end

  if type(v.shapes) == "table" and #v.shapes > 0 then
    for _, shape in ipairs(v.shapes) do
      drawShape(shape, S)
    end
    return
  end

  -- Fallback: small drone puck with eye and fins
  setColor({0.35, 0.37, 0.40, 1.0})
  love.graphics.circle("fill", 0, 0, S(10))
  setColor({0.18, 0.20, 0.22, 1.0})
  love.graphics.circle("line", 0, 0, S(10))
  setColor({1.0, 0.3, 0.25, 0.85})
  love.graphics.circle("fill", S(3), 0, S(3.2))
end

return EnemyRender

