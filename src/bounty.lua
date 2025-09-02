local Bounty = {}

local function panel(x, y, w, h, title)
  love.graphics.setColor(0, 0, 0, 0.20)
  love.graphics.rectangle("fill", x + 3, y + 4, w, h, 8, 8)
  love.graphics.setColor(0.12, 0.13, 0.19, 0.98)
  love.graphics.rectangle("fill", x, y, w, h, 8, 8)
  love.graphics.setColor(0.22, 0.24, 0.32, 1.0)
  love.graphics.rectangle("line", x, y, w, h, 8, 8)
  love.graphics.setColor(0.92, 0.95, 1.00, 0.96)
  love.graphics.print(title or "Uncollected Bounty", x + 10, y + 8)
end

function Bounty.draw(state)
  state = state or { total = 0, entries = {} }
  local w, h = 220, 110
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  -- place just below minimap (which is 220x160 at top-right)
  local x, y = sw - w - 16, 16 + 160 + 12
  panel(x, y, w, h, "Uncollected Bounty")
  local cx, cy = x + 10, y + 34
  love.graphics.setColor(0.75, 0.85, 1, 0.9)
  love.graphics.print(string.format("Uncollected: %d cr", state.uncollected or 0), cx, cy)
  cy = cy + 22
  love.graphics.setColor(0.75, 0.80, 0.95, 0.85)
  love.graphics.print("Recent:", cx, cy)
  cy = cy + 18
  local shown = 0
  if state.entries then
    for i = #state.entries, 1, -1 do
      local e = state.entries[i]
      love.graphics.setColor(0.22, 1.0, 0.68, 0.95)
      love.graphics.print(string.format("+%d cr", e.amount or 0), cx, cy)
      cy = cy + 18
      shown = shown + 1
      if shown >= 3 then break end
    end
  end
end

return Bounty
