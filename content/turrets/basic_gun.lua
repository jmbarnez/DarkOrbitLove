return {
  id = "basic_gun",
  type = "gun",
  spread = { minDeg = 0.8, maxDeg = 7.5, decay = 550 },
  tracer = { color = {1.0, 0.95, 0.30}, width = 1, coreRadius = 2 },
  impact = {
    shield = { spanDeg = 70, color1 = {0.26, 0.62, 1.0, 0.55}, color2 = {0.50, 0.80, 1.0, 0.35} },
    hull = { spark = {1.0, 0.6, 0.1, 0.6}, ring = {1.0, 0.3, 0.0, 0.4} },
  },
  optimal = 380, falloff = 260, tracking = 0.7, sigRes = 100,
  damageMin = 1, damageMax = 2, cycle = 3.6, capCost = 0, turnRate = 3.2
}
