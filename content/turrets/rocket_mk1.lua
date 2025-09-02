return {
  id = "rocket_mk1",
  type = "missile",
  -- Visuals: warm orange rocket + exhaust
  tracer = { color = {1.00, 0.70, 0.25}, width = 2, coreRadius = 6 },
  impact = {
    shield = { spanDeg = 70, color1 = {1.0, 0.75, 0.35, 0.55}, color2 = {1.0, 0.55, 0.25, 0.40} },
    hull = { spark = {1.0, 0.55, 0.15, 0.6}, ring = {1.0, 0.35, 0.05, 0.5} },
  },
  -- Long range
  optimal = 720, falloff = 320, tracking = 0.5, sigRes = 140,
  damageMin = 1, damageMax = 2, cycle = 4.0, capCost = 0, turnRate = 2.2,
}

