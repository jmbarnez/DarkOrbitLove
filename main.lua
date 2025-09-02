local Game = require("src.game")
local Start = require("src.start_screen")
local Input = require("src.input")

local screen = "start" -- start | game
local startScreen

function love.load()
  math.randomseed(os.time())
  startScreen = Start.new()
end

function love.update(dt)
  if screen == "game" then
    Game.update(dt)
  end
end

function love.draw()
  if screen == "start" then
    startScreen:draw()
  else
    Game.draw()
  end
end

function love.keypressed(key)
  if key == "f11" then
    local fs = love.window.getFullscreen()
    love.window.setFullscreen(not fs, "desktop")
    return
  end
  if screen == "game" then
    Input.keypressed(key)
  end
end

function love.mousepressed(x, y, button)
  if screen == "start" then
    local start = startScreen:mousepressed(x, y, button)
    if start then
      -- initialize game only now
      Game.load()
      screen = "game"
      return
    end
  else
    Input.mousepressed(x, y, button)
  end
end

function love.mousereleased(x, y, button)
  if screen == "game" then
    Input.mousereleased(x, y, button)
  end
end

function love.mousemoved(x, y, dx, dy, istouch)
  if screen == "game" then
    Input.mousemoved(x, y, dx, dy, istouch)
  end
end

function love.wheelmoved(dx, dy)
  if screen == "game" then
    Input.wheelmoved(dx, dy)
  end
end

function love.resize(w, h)
  if startScreen and screen == "start" then
    startScreen:resize(w, h)
  end
end
