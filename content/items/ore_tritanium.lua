return {
  id = "ore_tritanium",
  name = "Tritanium Ore",
  type = "material",
  rarity = "Common",
  tier = 1,
  stack = 9999,
  value = 5,
  mass = 1.2,       -- kg per unit
  volume = 0.5,     -- m^3 per unit
  market = { buy = 4, sell = 6, volatility = 0.08 },
  tags = { "ore", "industrial", "hull-alloy" },
  description = "A ubiquitous, resilient ore refined into tritanium alloys for hull plating and bulkheads.",
  flavor = "Unremarkable alone, indispensable in fleets.",
  icon = nil, -- optionally set to a spritesheet key or image path
}
