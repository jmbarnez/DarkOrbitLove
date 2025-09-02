local Input = {}

-- Dependencies will be set up when initialized
local Util = require("src.util")
local UI = require("src.ui")
local Chat = require("src.chat")

-- Game state references (will be tables with the actual values)
local gameState = {}

-- Inventory UI state (position/size/sort/hover)
local invState = {
  x = nil,
  y = nil,
  w = 520,
  h = 360,
  sortMode = "Name",
  sortOpen = false,
  view = "Icons", -- Icons | List
}

-- Inventory state accessors
function Input.getInventoryX() return invState.x end
function Input.getInventoryY() return invState.y end
function Input.getInventoryW() return invState.w end
function Input.getInventoryH() return invState.h end
function Input.setInventoryPos(x, y) invState.x, invState.y = x, y end
function Input.setInventorySize(w, h) invState.w, invState.h = w, h end
function Input.getInventorySortMode() return invState.sortMode end
function Input.setInventorySortMode(mode) invState.sortMode = mode end
function Input.getInventorySortOpen() return invState.sortOpen end
function Input.setInventorySortOpen(open) invState.sortOpen = not not open end
-- Tooltips removed: always report no hover for inventory
-- Tooltips removed: no hover state kept
function Input.getInventoryViewMode() return invState.view end
function Input.setInventoryViewMode(mode)
  if mode == "Icons" or mode == "List" then invState.view = mode end
end

-- Input handling functions
local function handleInput()
    local mx, my = love.mouse.getPosition()
    local wx, wy = gameState.camera:screenToWorld(mx, my)
    return { aimx = wx, aimy = wy }
end

function Input.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "tab" then gameState.setInventoryOpen(not gameState.getInventoryOpen()) end
    if key == "g" then gameState.setEquipmentOpen(not gameState.getEquipmentOpen()) end
    if key == "b" then gameState.setBountyOpen(not gameState.getBountyOpen()) end
    if key == "f11" then
        local fs = love.window.getFullscreen()
        love.window.setFullscreen(not fs, "desktop")
    end
end

function Input.mousepressed(x, y, button)
    if gameState.getInventoryOpen() then
        local Inventory = require("src.inventory")
        local consumed, shouldClose = Inventory.mousepressed(x, y, button)
        if shouldClose then gameState.setInventoryOpen(false) end
        if consumed then return end
    end
    -- Chat panel tabs/area
    if Chat.mousepressed and Chat.mousepressed(x, y, button) then return end
    -- Hotbar toggle handling (UI overlay, consumes clicks inside)
    local consumedHotbar = UI.hotbarMousePressed and UI.hotbarMousePressed(gameState.player, x, y, button)
    if consumedHotbar then return end
    local wx, wy = gameState.camera:screenToWorld(x, y)
    if button == 1 then
        -- Select target under cursor
        local best, bestDist = nil, 99999
        for _, e in ipairs(gameState.enemies) do
            local d = Util.distance(wx, wy, e.x, e.y)
            if d < 36 and d < bestDist then
                best, bestDist = e, d
            end
        end
        gameState.player:setTarget(best)
    elseif button == 2 then
        -- Right click to move
        gameState.player:setMoveTarget(wx, wy)
        table.insert(gameState.clickMarkers, { x = wx, y = wy, t = 0, dur = 0.8, r0 = 6, r1 = 42 })
    end
end

function Input.mousereleased(x, y, button)
    if gameState.getInventoryOpen() then
        local Inventory = require("src.inventory")
        local consumed, shouldClose = Inventory.mousereleased(x, y, button)
        if shouldClose then gameState.setInventoryOpen(false) end
        if consumed then return end
    end
end

function Input.mousemoved(x, y, dx, dy, istouch)
    if gameState.getInventoryOpen() then
        local Inventory = require("src.inventory")
        local consumed = Inventory.mousemoved(x, y, dx, dy)
        if consumed then return end
    end
end

function Input.wheelmoved(dx, dy)
    -- Chat scroll when hovering chat panel
    if Chat.wheelmoved and Chat.wheelmoved(dx, dy) then return end
    -- Zoom towards cursor position with smoothing
    if dy == 0 then return end
    local mx, my = love.mouse.getPosition()
    local factor = (dy > 0) and 1.1 or 1/1.1
    gameState.camera:zoomAtFactor(factor, mx, my)
end

-- Initialize the Input module with game state references
function Input.init(state)
    gameState = state
end

-- Get current input state for player updates
function Input.getInputState()
    return handleInput()
end

return Input
