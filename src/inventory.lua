local Content = require("src.content")
local Input = require("src.input")

local Inventory = {
  dragging = false,
  dragDX = 0,
  dragDY = 0,
  closeDown = false,
}

-- Fluent-like dark theme
local Theme = {
  bg0 = {0.10, 0.11, 0.16, 0.98},   -- window base
  bg1 = {0.12, 0.13, 0.19, 1.00},   -- header base
  bg2 = {0.16, 0.17, 0.23, 1.00},   -- panel fill / hover
  border = {0.22, 0.24, 0.32, 1.00},
  outline = {0.06, 0.07, 0.11, 0.9}, -- outer hairline
  text = {0.92, 0.95, 1.00, 0.96},
  subtext = {0.75, 0.80, 0.95, 0.70},
  accent = {0.27, 0.55, 0.98, 1.00},
  danger = {0.95, 0.35, 0.35, 1.00},
  shadow = {0, 0, 0, 0.35},
}

local function setColor(c)
  love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end

local function vgrad(x, y, w, h, c0, c1, steps)
  steps = steps or 24
  for i = 0, steps - 1 do
    local t = i / (steps - 1)
    local r = c0[1] + (c1[1] - c0[1]) * t
    local g = c0[2] + (c1[2] - c0[2]) * t
    local b = c0[3] + (c1[3] - c0[3]) * t
    local a = (c0[4] or 1) + ((c1[4] or 1) - (c0[4] or 1)) * t
    love.graphics.setColor(r, g, b, a)
    local yy = y + math.floor(h * t)
    local hh = math.ceil(h / steps) + 1
    love.graphics.rectangle("fill", x, yy, w, hh)
  end
end

-- Draw a vertical gradient clipped to a rounded rectangle
local function roundedGrad(x, y, w, h, radius, c0, c1, steps)
  love.graphics.stencil(function()
    love.graphics.rectangle("fill", x, y, w, h, radius, radius)
  end, "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  vgrad(x, y, w, h, c0, c1, steps)
  love.graphics.setStencilTest()
end

local function getRects()
  local x, y, w, h = Input.getInventoryX(), Input.getInventoryY(), Input.getInventoryW(), Input.getInventoryH()
  local titleH = 36
  local closeW, closeH = 44, titleH -- button spans titlebar height like Windows
  local closeX = x + w - closeW
  local closeY = y
  local controlW = 140
  local controlH = 24
  local controlX = x + w - closeW - 12 - controlW
  local controlY = y + math.floor((titleH - controlH) * 0.5)
  -- View toggle button to the left of sort
  local viewW = 110
  local viewH = controlH
  local viewX = controlX - 10 - viewW
  local viewY = controlY
  return {
    title = {x = x, y = y, w = w, h = titleH},
    close = {x = closeX, y = closeY, w = closeW, h = closeH},
    sort = {x = controlX, y = controlY, w = controlW, h = controlH},
    view = {x = viewX, y = viewY, w = viewW, h = viewH},
  }
end

local function pointInRect(px, py, r)
  return px >= r.x and py >= r.y and px <= r.x + r.w and py <= r.y + r.h
end

local function drawCloseButton(rect)
  local mx, my = love.mouse.getPosition()
  local hover = pointInRect(mx, my, rect)
  -- Background
  if hover then
    setColor({Theme.danger[1], Theme.danger[2], Theme.danger[3], 0.18})
  else
    setColor({Theme.bg1[1], Theme.bg1[2], Theme.bg1[3], 0})
  end
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
  -- Glyph
  local cx1, cy1 = rect.x + 16, rect.y + 12
  local cx2, cy2 = rect.x + rect.w - 16, rect.y + rect.h - 12
  love.graphics.setLineWidth(2)
  setColor(hover and Theme.danger or Theme.text)
  love.graphics.line(cx1, cy1, cx2, cy2)
  love.graphics.line(cx1, cy2, cx2, cy1)
  love.graphics.setLineWidth(1)
end

local function drawShadow(x, y, w, h)
  -- Softer, smaller drop shadow to avoid looking like second panel
  setColor({0, 0, 0, 0.22})
  love.graphics.rectangle("fill", x + 4, y + 6, w, h, 10, 10)
end

local function drawTitleBar(x, y, w, title)
  local rects = getRects()
  -- Subtle vertical gradient on header
  vgrad(x, y, w, rects.title.h, {0.13,0.14,0.20,1}, {0.11,0.12,0.18,1}, 32)
  -- Accent line at bottom
  setColor({Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.6})
  love.graphics.rectangle("fill", x, y + rects.title.h - 2, w, 2)
  -- Title text
  setColor(Theme.text)
  love.graphics.print(title, x + 12, y + 10)
  -- Close button
  drawCloseButton(rects.close)
  -- Sort dropdown (collapsed)
  local s = rects.sort
  local mx, my = love.mouse.getPosition()
  local hover = pointInRect(mx, my, s)
  setColor(hover and Theme.bg2 or {Theme.bg1[1],Theme.bg1[2],Theme.bg1[3],0.85})
  love.graphics.rectangle("fill", s.x, s.y, s.w, s.h, 4, 4)
  setColor(Theme.border)
  love.graphics.rectangle("line", s.x, s.y, s.w, s.h, 4, 4)
  setColor(Theme.subtext)
  love.graphics.print("Sort:", s.x + 8, s.y + 5)
  setColor(Theme.text)
  love.graphics.print(Input.getInventorySortMode(), s.x + 48, s.y + 5)
  -- caret
  setColor(Theme.subtext)
  local cx = s.x + s.w - 14
  local cy = s.y + s.h * 0.5 + 2
  love.graphics.polygon("fill", cx-6, cy-6, cx+6, cy-6, cx, cy)
  -- View toggle button
  local v = rects.view
  local mx, my = love.mouse.getPosition()
  local vhover = pointInRect(mx, my, v)
  setColor(vhover and Theme.bg2 or {Theme.bg1[1],Theme.bg1[2],Theme.bg1[3],0.85})
  love.graphics.rectangle("fill", v.x, v.y, v.w, v.h, 4, 4)
  setColor(Theme.border)
  love.graphics.rectangle("line", v.x, v.y, v.w, v.h, 4, 4)
  setColor(Theme.subtext)
  love.graphics.print("View:", v.x + 8, v.y + 5)
  setColor(Theme.text)
  love.graphics.print(Input.getInventoryViewMode() or "Icons", v.x + 54, v.y + 5)
end

-- Item icon renderer using geometric primitives (no external assets)
local function drawItemIcon(item, x, y, size)
  local t = item and item.type or "generic"
  local tags = {}
  if item and item.tags then
    for _, v in ipairs(item.tags) do tags[v] = true end
  end
  local s = size
  local cx, cy = x + s * 0.5, y + s * 0.5
  if t == "material" or tags.ore then
    -- Ore: clustered mineral shards
    love.graphics.setColor(0.65, 0.72, 0.85, 0.95)
    love.graphics.polygon("fill", cx-10, cy+6, cx-6, cy-8, cx+2, cy-12, cx+8, cy-2, cx+4, cy+10)
    love.graphics.setColor(0.50, 0.58, 0.75, 0.95)
    love.graphics.polygon("fill", cx-16, cy+2, cx-10, cy-6, cx-2, cy-2, cx-4, cy+10)
    love.graphics.setColor(1, 1, 1, 0.08)
    love.graphics.line(cx-6, cy-6, cx+2, cy-10)
    love.graphics.line(cx-10, cy-2, cx-4, cy-8)
  elseif t == "consumable" or tags.repair then
    -- Repair kit: med cross on canister
    love.graphics.setColor(0.12, 0.13, 0.19, 0.98)
    love.graphics.rectangle("fill", x+4, y+6, s-8, s-12, 4, 4)
    love.graphics.setColor(0.16, 0.18, 0.24, 1)
    love.graphics.rectangle("line", x+4, y+6, s-8, s-12, 4, 4)
    love.graphics.setColor(0.95, 0.35, 0.35, 0.95)
    local cx1, cy1 = cx, cy
    love.graphics.rectangle("fill", cx1-3, cy1-9, 6, 18, 1, 1)
    love.graphics.rectangle("fill", cx1-9, cy1-3, 18, 6, 1, 1)
    love.graphics.setColor(1,1,1,0.08)
    love.graphics.rectangle("fill", x+6, y+8, s-12, 3, 2, 2)
  else
    -- Generic: hex module/chip
    local r = s*0.32
    local verts = {}
    for i=0,5 do
      local a = (math.pi/3)*i + math.pi/6
      table.insert(verts, cx + math.cos(a)*r)
      table.insert(verts, cy + math.sin(a)*r)
    end
    love.graphics.setColor(0.27, 0.55, 0.98, 0.25)
    love.graphics.polygon("fill", verts)
    love.graphics.setColor(0.27, 0.55, 0.98, 0.9)
    love.graphics.polygon("line", verts)
    love.graphics.setColor(1,1,1,0.08)
    love.graphics.line(cx-r*0.6, cy-r*0.2, cx+r*0.8, cy-r*0.6)
  end
end

local function drawWindow()
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local w, h = math.min(Input.getInventoryW(), sw - 40), math.min(Input.getInventoryH(), sh - 40)
  if not Input.getInventoryX() or not Input.getInventoryY() then
    -- Initialize window position and size
    local initW, initH = w, h
    local initX = math.floor((sw - w) * 0.5)
    local initY = math.floor((sh - h) * 0.5)
    Input.setInventorySize(initW, initH)
    Input.setInventoryPos(initX, initY)
  end
  local x, y = Input.getInventoryX() or math.floor((sw - w) * 0.5), Input.getInventoryY() or math.floor((sh - h) * 0.5)
  -- Shadow
  drawShadow(x, y, w, h)
  -- Background with soft vertical gradient, clipped to rounded rect
  roundedGrad(x, y, w, h, 10, {0.11,0.12,0.17,0.98}, {0.09,0.10,0.15,0.98}, 48)
  -- Rounded rect mask look
  setColor(Theme.border)
  love.graphics.rectangle("line", x, y, w, h, 10, 10)
  setColor(Theme.outline)
  love.graphics.rectangle("line", x-1, y-1, w+2, h+2, 12, 12)
  -- Header
  drawTitleBar(x, y, w, "Inventory")
end

function Inventory.mousepressed(x, y, button)
    if button ~= 1 then return false, false end
    local rects = getRects()
    -- Close button
    if pointInRect(x, y, rects.close) then
      Inventory.closeDown = true
      return true, false
    end
    -- Sort dropdown toggle
    if pointInRect(x, y, rects.sort) then
      Input.setInventorySortOpen(not Input.getInventorySortOpen())
      return true, false
    end
    -- View toggle
    if pointInRect(x, y, rects.view) then
      local mode = Input.getInventoryViewMode() == "Icons" and "List" or "Icons"
      Input.setInventoryViewMode(mode)
      return true, false
    end
    -- Header drag
    if pointInRect(x, y, rects.title) then
      Inventory.dragging = true
      Inventory.dragDX = (Input.getInventoryX() or 0) - x
      Inventory.dragDY = (Input.getInventoryY() or 0) - y
      return true, false
    end
    -- Sort options when open
    if Input.getInventorySortOpen() then
      local s = rects.sort
      local opts = {"Name","Quantity","Value","Type"}
      local ow, oh = s.w, #opts * (s.h + 2)
      local ox, oy = s.x, s.y + s.h + 4
      if x >= ox and x <= ox + ow and y >= oy and y <= oy + oh then
        local idx = math.floor((y - oy) / (s.h + 2)) + 1
        if idx >= 1 and idx <= #opts then
          Input.setInventorySortMode(opts[idx])
          Input.setInventorySortOpen(false)
          return true, false
        end
      else
        Input.setInventorySortOpen(false)
        return true, false
      end
    end
    return false, false
end

function Inventory.mousereleased(x, y, button)
    local consumed, shouldClose = false, false
    if button == 1 then
      if Inventory.dragging then
        Inventory.dragging = false
        consumed = true
      end
      if Inventory.closeDown then
        local rects = getRects()
        if pointInRect(x, y, rects.close) then
          shouldClose = true
        end
        Inventory.closeDown = false
        consumed = true
      end
    end
    return consumed, shouldClose
end

function Inventory.mousemoved(x, y, dx, dy)
    if Inventory.dragging then
      Input.setInventoryPos(x + Inventory.dragDX, y + Inventory.dragDY)
      return true
    end
    return false -- consumed
end

function Inventory.draw(player)
  drawWindow()

  -- Content area
  local pad = 16
  local titleH = 36
  local x, y, w = Input.getInventoryX(), Input.getInventoryY(), Input.getInventoryW()
  local cx = x + pad
  local cy = y + titleH + pad
  -- Section header
  setColor(Theme.subtext)
  love.graphics.print("Cargo", cx, cy - 4)
  setColor({0.18, 0.20, 0.28, 1})
  love.graphics.rectangle("fill", cx, cy + 14, w - pad*2, 1)
  cy = cy + 20

  -- Build sorted entries
  setColor(Theme.text)
  local inv = player.inventory or {}
  local entries = {}
  for id, qty in pairs(inv) do
    local item = Content.getItem(id)
    table.insert(entries, {
      id = id,
      qty = qty,
      item = item,
      name = item and item.name or id,
      value = item and (item.value or 0) or 0,
      type = item and (item.type or "") or "",
    })
  end
  table.sort(entries, function(a,b)
    local mode = Input.getInventorySortMode()
    if mode == "Quantity" then
      if a.qty == b.qty then return a.name < b.name end
      return a.qty > b.qty
    elseif mode == "Value" then
      if a.value == b.value then return a.name < b.name end
      return a.value > b.value
    elseif mode == "Type" then
      if a.type == b.type then return a.name < b.name end
      return a.type < b.type
    else
      return a.name < b.name
    end
  end)

  local view = Input.getInventoryViewMode() or "Icons"
  if #entries == 0 then
    setColor(Theme.subtext)
    love.graphics.print("Empty cargo hold", cx, cy)
  else
    -- Hover tooltips removed
    local mx, my = love.mouse.getPosition()
    if view == "Icons" then
      -- Grid layout
      local cell = 56
      local gap = 10
      local cols = math.max(1, math.floor((w - pad*2 + gap) / (cell + gap)))
      local gx, gy = cx, cy
      for index, e in ipairs(entries) do
        local col = (index - 1) % cols
        local row = math.floor((index - 1) / cols)
        local rx = gx + col * (cell + gap)
        local ry = gy + row * (cell + gap)
        local rect = {x = rx, y = ry, w = cell, h = cell}
        local isHover = mx >= rx and my >= ry and mx <= rx + cell and my <= ry + cell
        -- Cell background
        setColor(isHover and {Theme.bg2[1],Theme.bg2[2],Theme.bg2[3],0.9} or {Theme.bg1[1],Theme.bg1[2],Theme.bg1[3],0.6})
        love.graphics.rectangle("fill", rx, ry, cell, cell, 6, 6)
        setColor(Theme.border)
        love.graphics.rectangle("line", rx, ry, cell, cell, 6, 6)
        -- Icon using procedural shapes
        local ix, iy, isz = rx + 8, ry + 8, cell - 16
        drawItemIcon(e.item, ix, iy, isz)
        -- Quantity bottom-right
        setColor(Theme.text)
        love.graphics.printf(tostring(e.qty), rx, ry + cell - 16, cell - 6, "right")
        -- Tooltip hover removed
      end
    else
      -- List view
      local rowH = 28
      local colIconW = 36
      local colNameW = math.floor((w - pad*2) * 0.45)
      local colTypeW = math.floor((w - pad*2) * 0.20)
      local colQtyW  = math.floor((w - pad*2) * 0.15)
      local colValW  = (w - pad*2) - (colIconW + colNameW + colTypeW + colQtyW)
      -- Header row
      setColor({Theme.bg1[1],Theme.bg1[2],Theme.bg1[3],0.65})
      love.graphics.rectangle("fill", cx, cy, w - pad*2, rowH, 4, 4)
      setColor(Theme.subtext)
      love.graphics.print("Name", cx + colIconW + 8, cy + 6)
      love.graphics.print("Type", cx + colIconW + colNameW + 8, cy + 6)
      love.graphics.print("Qty",  cx + colIconW + colNameW + colTypeW + 8, cy + 6)
      love.graphics.print("Value",cx + colIconW + colNameW + colTypeW + colQtyW + 8, cy + 6)
      cy = cy + rowH + 4
      for _, e in ipairs(entries) do
        local rx, ry = cx, cy
        local rect = {x = rx, y = ry, w = w - pad*2, h = rowH}
        local isHover = mx >= rx and my >= ry and mx <= rx + rect.w and my <= ry + rect.h
        setColor(isHover and {Theme.bg2[1],Theme.bg2[2],Theme.bg2[3],0.9} or {Theme.bg1[1],Theme.bg1[2],Theme.bg1[3],0.4})
        love.graphics.rectangle("fill", rx, ry, rect.w, rect.h, 4, 4)
        setColor(Theme.border)
        love.graphics.rectangle("line", rx, ry, rect.w, rect.h, 4, 4)
        drawItemIcon(e.item, rx + 6, ry + 4, rowH - 8)
        setColor(Theme.text)
        love.graphics.print(e.name, rx + colIconW + 8, ry + 6)
        love.graphics.print(e.type ~= '' and e.type or '-', rx + colIconW + colNameW + 8, ry + 6)
        love.graphics.print(tostring(e.qty), rx + colIconW + colNameW + colTypeW + 8, ry + 6)
        love.graphics.printf(tostring(e.value), rx + colIconW + colNameW + colTypeW + colQtyW, ry + 6, colValW - 8, 'right')
        -- Tooltip hover removed
        cy = cy + rowH + 2
      end
    end
  end

  -- Credits (bottom-left)
  local by = Input.getInventoryY() + Input.getInventoryH() - pad - 18
  setColor({0.75, 0.85, 1, 0.9})
  love.graphics.print(string.format("Credits: %d", player.credits or 0), cx, by)

  -- Sort dropdown expanded content
  if Input.getInventorySortOpen() then
    local s = getRects().sort
    local opts = {"Name","Quantity","Value","Type"}
    local ow, oh = s.w, #opts * (s.h + 2)
    local ox, oy = s.x, s.y + s.h + 4
    setColor({Theme.bg1[1],Theme.bg1[2],Theme.bg1[3],0.98})
    love.graphics.rectangle("fill", ox, oy, ow, oh, 6, 6)
    setColor(Theme.border)
    love.graphics.rectangle("line", ox, oy, ow, oh, 6, 6)
    local mx, my = love.mouse.getPosition()
    for i, name in ipairs(opts) do
      local iy = oy + (i-1) * (s.h + 2)
      local r = {x=ox, y=iy, w=ow, h=s.h}
      local hov = pointInRect(mx, my, r)
      setColor(hov and Theme.bg2 or {0,0,0,0})
      love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 4, 4)
      setColor(Theme.text)
      love.graphics.print(name, r.x + 8, r.y + 5)
    end
  end

end


return Inventory

