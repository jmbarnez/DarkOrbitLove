local util = {}

function util.clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

function util.lerp(a, b, t)
  return a + (b - a) * t
end

function util.length(x, y)
  return math.sqrt(x * x + y * y)
end

function util.normalize(x, y)
  local l = util.length(x, y)
  if l == 0 then return 0, 0 end
  return x / l, y / l
end

function util.distance(x1, y1, x2, y2)
  local dx, dy = x2 - x1, y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

function util.angleTo(x1, y1, x2, y2)
  local dy, dx = (y2 - y1), (x2 - x1)
  if math.atan2 then
    return math.atan2(dy, dx)
  end
  if dx == 0 then
    return dy >= 0 and math.pi/2 or -math.pi/2
  end
  local a = math.atan(dy / dx)
  if dx < 0 then a = a + math.pi end
  return a
end

function util.approach(a, b, s)
  if a < b then return math.min(a + s, b) end
  return math.max(a - s, b)
end

function util.circleOverlap(x1, y1, r1, x2, y2, r2)
  local dx, dy = x2 - x1, y2 - y1
  return dx * dx + dy * dy <= (r1 + r2) * (r1 + r2)
end

return util
