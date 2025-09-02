return {
  id = "basic_frigate",
  name = "Basic Frigate",
  class = "Frigate",
  hull = { hp = 10, shield = 0, cap = 100 },
  engine = { accel = 500, maxSpeed = 320, drag = 0.92, mass = 9000 },
  sig = 100,
  cargo = { capacity = 120 },
  description = "A reliable yard-line frigate used for patrol and training. Balanced defenses and modest firepower.",
  visuals = {
    size = 1.0,
    -- Realistic naval-grey palette with blue accents
    hullColor = {0.48, 0.51, 0.55, 1.0},     -- steel grey
    panelColor = {0.32, 0.35, 0.39, 1.0},    -- darker panels
    accentColor = {0.20, 0.60, 0.95, 0.9},   -- blue accent lines
    cockpitColor = {0.55, 0.85, 1.0, 0.28},  -- glass tint
    engineColor = {0.25, 0.75, 1.0},         -- thruster blue
    -- Declarative shape list for a simple frigate silhouette
    shapes = {
      -- Main dorsal hull
      { type = "rect", mode = "fill", color = {0.48, 0.51, 0.55, 1.0}, x = -28, y = -10, w = 58, h = 20, rx = 4 },
      -- Tapered bow
      { type = "polygon", mode = "fill", color = {0.48, 0.51, 0.55, 1.0}, points = { 30,-10, 46,0, 30,10 } },
      -- Ventral keel strip
      { type = "rect", mode = "fill", color = {0.36, 0.40, 0.46, 1.0}, x = -18, y = -4, w = 42, h = 8, rx = 2 },

      -- Side wings
      { type = "polygon", mode = "fill", color = {0.32, 0.35, 0.39, 1.0}, points = { -10,-12, 8,-18, 24,-12, 16,-8, -6,-8 } },
      { type = "polygon", mode = "fill", color = {0.32, 0.35, 0.39, 1.0}, points = { -10, 12, 8, 18, 24, 12, 16, 8, -6, 8 } },

      -- Engine nacelles
      { type = "rect", mode = "fill", color = {0.24, 0.27, 0.31, 1.0}, x = -42, y = -8, w = 10, h = 16, rx = 2 },
      { type = "rect", mode = "fill", color = {0.24, 0.27, 0.31, 1.0}, x = -42, y = -4, w = 10, h = 8, rx = 2 },

      -- Engine glow (soft overlays)
      { type = "rect", mode = "fill", color = {0.20, 0.70, 1.00, 0.18}, x = -52, y = -7, w = 8, h = 14, rx = 3 },
      { type = "rect", mode = "fill", color = {0.20, 0.70, 1.00, 0.38}, x = -50, y = -4, w = 6, h = 8, rx = 2 },

      -- Cockpit canopy
      { type = "circle", mode = "fill", color = {0.55, 0.85, 1.0, 0.28}, x = 6, y = 0, r = 6 },

      -- Paneling accents
      { type = "rect", mode = "fill", color = {0.32, 0.35, 0.39, 1.0}, x = -20, y = -9, w = 14, h = 18, rx = 2 },
      { type = "rect", mode = "fill", color = {0.32, 0.35, 0.39, 1.0}, x = -2,  y = -7, w = 10, h = 14, rx = 2 },

      -- Accent stripes
      { type = "rect", mode = "fill", color = {0.20, 0.60, 0.95, 0.70}, x = -24, y = -2, w = 20, h = 3 },
      { type = "rect", mode = "fill", color = {0.20, 0.60, 0.95, 0.70}, x = 4,   y = -2, w = 16, h = 3 },

      -- Hull outline
      { type = "polygon", mode = "line", color = {0.40, 0.70, 1.00, 0.65}, points = { -28,-10, 30,-10, 46,0, 30,10, -28,10 } },
      -- Wing outlines
      { type = "polygon", mode = "line", color = {0.35, 0.65, 1.00, 0.50}, points = { -10,-12, 8,-18, 24,-12, 16,-8, -6,-8 } },
      { type = "polygon", mode = "line", color = {0.35, 0.65, 1.00, 0.50}, points = { -10, 12, 8, 18, 24, 12, 16, 8, -6, 8 } },
    }
  },
  hardpoints = {
    turret = "basic_gun"
  },
}
