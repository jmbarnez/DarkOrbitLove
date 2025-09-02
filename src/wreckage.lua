local Wreckage = {}
Wreckage.__index = Wreckage

local function createWreckagePiece(x, y, vx, vy, pieceType, enemyVisuals, shipSize)
  local piece = setmetatable({}, Wreckage)

  piece.x = x
  piece.y = y
  piece.vx = vx or (math.random() - 0.5) * 200
  piece.vy = vy or (math.random() - 0.5) * 200
  piece.angle = math.random() * math.pi * 2

  -- Scale angular velocity by ship size (larger ships spin slower)
  local angularScale = math.max(0.5, 2.0 - (shipSize / 20))
  piece.angularVel = (math.random() - 0.5) * 4 * angularScale
  piece.type = pieceType
  piece.lifetime = 1800 -- 30 minutes
  piece.age = 0

  -- Scale piece size based on ship size (shipSize is radius * visualSize)
  -- Small drones (shipSize ~8-12) get small pieces, large ships get bigger pieces
  local sizeMultiplier = math.max(0.3, math.min(2.0, shipSize / 10))
  piece.size = sizeMultiplier * (0.6 + math.random() * 0.8)

  -- Generate visual shape based on type and scaled by ship size
  local baseScale = shipSize / 10 -- normalize to small drone size

  -- Base colors with some variation
  local hullColors = {
    {0.35, 0.38, 0.42, 1.0}, -- steel grey
    {0.32, 0.36, 0.40, 1.0}, -- darker steel
    {0.38, 0.42, 0.46, 1.0}  -- lighter steel
  }
  local engineColors = {
    {0.45, 0.25, 0.15, 1.0}, -- burnt metal
    {0.40, 0.30, 0.20, 1.0}, -- rusty metal
    {0.50, 0.35, 0.25, 1.0}  -- hot metal
  }
  local thrusterColors = {
    {0.55, 0.35, 0.25, 1.0}, -- thruster material
    {0.60, 0.40, 0.30, 1.0}, -- damaged thruster
    {0.50, 0.30, 0.20, 1.0}  -- burnt thruster
  }
  local wingColors = {
    {0.38, 0.42, 0.46, 1.0}, -- wing material
    {0.35, 0.40, 0.44, 1.0}, -- darker wing
    {0.42, 0.46, 0.50, 1.0}  -- lighter wing
  }
  local genericColors = {
    {0.4, 0.4, 0.4, 1.0}, -- generic metal
    {0.35, 0.35, 0.35, 1.0}, -- darker generic
    {0.45, 0.45, 0.45, 1.0}  -- lighter generic
  }

  if pieceType == "hull" then
    local baseW = 8 + math.random() * 12
    local baseH = 6 + math.random() * 10
    piece.shape = {
      type = "rect",
      color = hullColors[math.random(#hullColors)],
      w = baseW * baseScale,
      h = baseH * baseScale,
      rx = 2 * baseScale
    }
  elseif pieceType == "engine" then
    local baseR = 4 + math.random() * 6
    piece.shape = {
      type = "circle",
      color = engineColors[math.random(#engineColors)],
      r = baseR * baseScale
    }
  elseif pieceType == "thruster" then
    local baseW = 6 + math.random() * 8
    local baseH = 3 + math.random() * 4
    piece.shape = {
      type = "rect",
      color = thrusterColors[math.random(#thrusterColors)],
      w = baseW * baseScale,
      h = baseH * baseScale,
      rx = 1 * baseScale
    }
  elseif pieceType == "wing" then
    local baseVertices = {
      -8 - math.random() * 6, -2 - math.random() * 2,
      8 + math.random() * 6, -1 - math.random() * 1,
      6 + math.random() * 4, 2 + math.random() * 2,
      -6 - math.random() * 4, 1 + math.random() * 1
    }
    piece.shape = {
      type = "polygon",
      color = wingColors[math.random(#wingColors)],
      vertices = {}
    }
    -- Scale all vertices by the base scale
    for i = 1, #baseVertices do
      piece.shape.vertices[i] = baseVertices[i] * baseScale
    end
  else -- generic debris
    local baseR = 3 + math.random() * 4
    piece.shape = {
      type = "circle",
      color = genericColors[math.random(#genericColors)],
      r = baseR * baseScale
    }
  end

  return piece
end

function Wreckage.spawnFromEnemy(enemy, enemyVisuals)
  local pieces = {}

  -- Calculate ship size factors based on radius and visual size
  local shipRadius = enemy.radius or 10
  local shipVisualSize = enemyVisuals and enemyVisuals.size or 1.0
  local shipSize = shipRadius * shipVisualSize

  -- Scale number of pieces based on ship size
  -- Small drones (radius ~10) get 1 piece, larger ships get 2-3 pieces
  local basePieces = math.max(1, math.min(3, math.floor(shipSize / 8)))
  local numPieces = basePieces + (math.random() < 0.3 and 1 or 0) -- occasional extra piece

  -- Determine piece types based on enemy ship structure and size
  local pieceTypes
  if shipSize < 12 then
    -- Small drones: mostly hull and small components
    pieceTypes = {"hull", "thruster"}
  elseif shipSize < 20 then
    -- Medium ships: mix of components
    pieceTypes = {"hull", "engine", "thruster", "wing"}
  else
    -- Large ships: all component types
    pieceTypes = {"hull", "hull", "engine", "thruster", "wing", "wing"}
  end

  for i = 1, numPieces do
    local angle = (i / numPieces) * math.pi * 2 + math.random() * 0.5
    local speed = 60 + math.random() * 100 + (shipSize * 2) -- larger ships eject faster
    local vx = math.cos(angle) * speed
    local vy = math.sin(angle) * speed

    -- Add some explosion force scaled by ship size
    local explodeForce = 100 + math.random() * 80 + (shipSize * 5)
    vx = vx + math.cos(angle) * explodeForce
    vy = vy + math.sin(angle) * explodeForce

    local pieceType = pieceTypes[math.random(#pieceTypes)]
    local piece = createWreckagePiece(
      enemy.x + (math.random() - 0.5) * (shipRadius * 2),
      enemy.y + (math.random() - 0.5) * (shipRadius * 2),
      vx, vy, pieceType, enemyVisuals, shipSize
    )

    table.insert(pieces, piece)
  end

  return pieces
end

function Wreckage:update(dt)
  self.age = self.age + dt

  -- Apply physics
  self.x = self.x + self.vx * dt
  self.y = self.y + self.vy * dt
  self.angle = self.angle + self.angularVel * dt

  -- Scale physics based on piece size (larger pieces are heavier, more affected by drag/gravity)
  local massFactor = math.max(0.5, math.min(2.0, self.size))
  local dragFactor = 0.98 - (massFactor * 0.01) -- heavier pieces have more drag
  local gravityFactor = 15 + (massFactor * 5) -- heavier pieces fall faster

  -- Apply drag
  self.vx = self.vx * dragFactor
  self.vy = self.vy * dragFactor
  self.angularVel = self.angularVel * 0.96 -- angular drag is consistent

  -- Add gravity (scaled by mass)
  self.vy = self.vy + gravityFactor * dt

  -- Check if piece should be removed
  return self.age < self.lifetime
end

function Wreckage:draw()
  -- No fading - chunks remain fully visible until they disappear
  local alpha = 1.0

  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(self.angle)
  love.graphics.scale(self.size)

  local color = self.shape.color
  love.graphics.setColor(color[1], color[2], color[3], color[4] * alpha)

  if self.shape.type == "rect" then
    love.graphics.rectangle("fill",
      -self.shape.w/2, -self.shape.h/2,
      self.shape.w, self.shape.h,
      self.shape.rx or 0, self.shape.rx or 0
    )
    -- Add outline
    love.graphics.setColor(0.2, 0.22, 0.26, alpha * 0.8)
    love.graphics.rectangle("line",
      -self.shape.w/2, -self.shape.h/2,
      self.shape.w, self.shape.h,
      self.shape.rx or 0, self.shape.rx or 0
    )
  elseif self.shape.type == "circle" then
    love.graphics.circle("fill", 0, 0, self.shape.r)
    -- Add outline
    love.graphics.setColor(0.2, 0.22, 0.26, alpha * 0.8)
    love.graphics.circle("line", 0, 0, self.shape.r)
  elseif self.shape.type == "polygon" then
    love.graphics.polygon("fill", self.shape.vertices)
    -- Add outline
    love.graphics.setColor(0.2, 0.22, 0.26, alpha * 0.8)
    love.graphics.polygon("line", self.shape.vertices)
  end

  love.graphics.pop()
end

return Wreckage
