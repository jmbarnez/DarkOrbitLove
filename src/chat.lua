local Chat = {}

local messages = {}
local maxMessages = 120

local state = {
  activeTab = "Chat", -- Chat | Debug
  scroll = 0,         -- lines offset from bottom
}

function Chat.add(kind, text)
  table.insert(messages, { kind = kind or "info", text = tostring(text), t = love.timer.getTime() })
  if #messages > maxMessages then
    table.remove(messages, 1)
  end
end

function Chat.info(text) Chat.add("info", text) end
function Chat.debug(text) Chat.add("debug", text) end

function Chat.setTab(tab)
  if tab == "Chat" or tab == "Debug" then
    state.activeTab = tab
    state.scroll = 0
  end
end

local function drawTabs(x, y, w, h)
  local tabW = 80
  local tabs = {"Chat", "Debug"}
  for i, name in ipairs(tabs) do
    local tx = x + (i-1) * (tabW + 6)
    local active = (state.activeTab == name)
    love.graphics.setColor(active and 0.16 or 0.12, active and 0.18 or 0.13, active and 0.24 or 0.19, 0.98)
    love.graphics.rectangle('fill', tx, y, tabW, 22, 6, 6)
    love.graphics.setColor(0.22, 0.24, 0.32, 1)
    love.graphics.rectangle('line', tx, y, tabW, 22, 6, 6)
    love.graphics.setColor(0.92, 0.95, 1.0, 0.96)
    love.graphics.printf(name, tx, y + 4, tabW, 'center')
  end
end

function Chat.draw()
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local w, h = 420, 180
  local pad = 14
  local x = pad
  local y = sh - h - pad
  -- shadow
  love.graphics.setColor(0,0,0,0.25)
  love.graphics.rectangle('fill', x + 4, y + 6, w, h, 10, 10)
  -- body
  love.graphics.setColor(0.12, 0.13, 0.19, 0.98)
  love.graphics.rectangle('fill', x, y, w, h, 10, 10)
  love.graphics.setColor(0.22, 0.24, 0.32, 1)
  love.graphics.rectangle('line', x, y, w, h, 10, 10)
  -- tabs
  drawTabs(x + 8, y + 6, w - 16, 22)
  -- list area
  local lx = x + 10
  local ly = y + 34
  local lh = h - 44
  local lineH = 16
  local count = math.floor(lh / lineH)
  local filtered = {}
  for _, m in ipairs(messages) do
    if state.activeTab == "Chat" and m.kind ~= "debug" then table.insert(filtered, m)
    elseif state.activeTab == "Debug" and m.kind == "debug" then table.insert(filtered, m) end
  end
  local maxOffset = math.max(0, #filtered - count)
  if state.scroll > maxOffset then state.scroll = maxOffset end
  local start = math.max(1, (#filtered - count + 1) - state.scroll)
  love.graphics.setScissor(lx, ly, w - 20, lh)
  for i = start, #filtered do
    local m = filtered[i]
    local idx = i - start
    local ty = ly + idx * lineH
    local col = (m.kind == 'debug') and {0.75,0.85,1.0,0.9} or {0.92,0.95,1.0,0.9}
    love.graphics.setColor(1,1,1,0.06)
    love.graphics.print(m.text, lx + 1, ty + 1)
    love.graphics.setColor(col)
    love.graphics.print(m.text, lx, ty)
  end
  love.graphics.setScissor()
end

-- Input handling
local function layout()
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local w, h = 420, 180
  local pad = 14
  local x = pad
  local y = sh - h - pad
  local lx, ly = x + 10, y + 34
  local lh = h - 44
  local lineH = 16
  return x, y, w, h, lx, ly, lh, lineH
end

local function pointIn(px, py, rx, ry, rw, rh)
  return px >= rx and py >= ry and px <= rx + rw and py <= ry + rh
end

function Chat.mousepressed(mx, my, button)
  if button ~= 1 then return false end
  local x, y, w, h = layout()
  if not pointIn(mx, my, x, y, w, h) then return false end
  -- Tabs
  local tabW, tabH = 80, 22
  local tx = x + 8
  local ty = y + 6
  local tabs = {"Chat", "Debug"}
  for i, name in ipairs(tabs) do
    local rx = tx + (i-1) * (tabW + 6)
    if pointIn(mx, my, rx, ty, tabW, tabH) then
      Chat.setTab(name)
      return true
    end
  end
  return true -- clicks inside panel are consumed
end

function Chat.wheelmoved(dx, dy)
  if dy == 0 then return false end
  local x, y, w, h, lx, ly, lh, lineH = layout()
  local mx, my = love.mouse.getPosition()
  if not pointIn(mx, my, lx, ly, w - 20, lh) then return false end
  local step = (dy > 0) and 1 or -1
  state.scroll = math.max(0, state.scroll + step * 3)
  return true
end

return Chat
