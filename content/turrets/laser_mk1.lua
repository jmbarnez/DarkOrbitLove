return {
  id = "laser_mk1",
  type = "laser",
  -- Visuals: cool cyan beam, crisp shield arcs
  tracer = { color = {0.30, 0.85, 1.00}, width = 2, coreRadius = 2 },
  impact = {
    shield = { spanDeg = 80, color1 = {0.35, 0.85, 1.0, 0.65}, color2 = {0.65, 0.95, 1.0, 0.45} },
    hull = { spark = {0.85, 0.95, 1.0, 0.5}, ring = {0.55, 0.75, 1.0, 0.4} },
  },
  -- Medium range
  optimal = 480, falloff = 200, tracking = 0.85, sigRes = 100,
  damageMin = 1, damageMax = 2, cycle = 3.2, capCost = 0, turnRate = 3.0,
}

