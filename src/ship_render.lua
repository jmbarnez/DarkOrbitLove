local ShipRender = {}

-- Helper: set color from table {r,g,b,a?}
local function setColor(c, aOverride)
  if type(c) == "table" then
    local r,g,b,a = c[1] or 1, c[2] or 1, c[3] or 1, c[4]
    love.graphics.setColor(r, g, b, aOverride or a or 1)
  else
    love.graphics.setColor(1,1,1,1)
  end
end

-- Draw primitive shape description with scaling
local function drawShape(shape, S)
  local t = shape.type or "polygon"
  local mode = shape.mode or "fill"
  local color = shape.color
  setColor(color)
  if t == "polygon" and shape.points then
    local pts = {}
    for i = 1, #shape.points, 2 do
      table.insert(pts, S(shape.points[i]))
      table.insert(pts, S(shape.points[i+1]))
    end
    love.graphics.polygon(mode, pts)
  elseif t == "circle" then
    love.graphics.circle(mode, S(shape.x or 0), S(shape.y or 0), S(shape.r or 4))
  elseif t == "rect" or t == "rectangle" then
    love.graphics.rectangle(mode, S(shape.x or 0), S(shape.y or 0), S(shape.w or 4), S(shape.h or 4), S(shape.rx or 0), S(shape.ry or shape.rx or 0))
  elseif t == "line" and shape.points then
    local pts = {}
    for i = 1, #shape.points, 2 do
      table.insert(pts, S(shape.points[i]))
      table.insert(pts, S(shape.points[i+1]))
    end
    love.graphics.line(pts)
  end
end

-- Draws a generic frigate-like silhouette using colors from def.visuals
-- Expects transform (translate/rotate) to be set by caller.
function ShipRender.draw(def)
  local v = (def and def.visuals) or {}
  local size = v.size or 1.0
  local hull = v.hullColor or {0.16, 0.20, 0.28, 1}
  local panel = v.panelColor or {0.22, 0.26, 0.34, 1}
  local accent = v.accentColor or {0.1, 0.9, 1.0, 0.9}
  local cockpit = v.cockpitColor or {0.2, 1.0, 0.9, 0.25}
  local engine = v.engineColor or {0.2, 0.8, 1.0}

  local function S(x) return x * size end

  -- If a declarative shape list is provided, render it in order.
  if type(v.shapes) == "table" and #v.shapes > 0 then
    for _, shape in ipairs(v.shapes) do
      drawShape(shape, S)
    end
    return
  end

  -- Fallback: draw a generic frigate silhouette using color presets
  setColor(hull)
  love.graphics.polygon("fill", S(-20), S(-12), S(22), 0, S(-20), S(12))
  setColor(panel)
  love.graphics.polygon("fill", S(-10), S(-9), S(10), 0, S(-10), S(9))
  setColor(accent)
  love.graphics.polygon("line", S(-20), S(-12), S(22), 0, S(-20), S(12))
  setColor(cockpit)
  love.graphics.circle("fill", S(-4), 0, S(5))
  setColor({engine[1], engine[2], engine[3], 0.18})
  love.graphics.rectangle("fill", S(-24), S(-6), S(10), S(12), S(4), S(4))
  setColor({engine[1], engine[2], engine[3], 0.35})
  love.graphics.rectangle("fill", S(-22), S(-3), S(8), S(6), S(3), S(3))
end

return ShipRender
