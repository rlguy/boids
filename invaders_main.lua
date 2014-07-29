math.randomseed(os.time())
for i=1,5 do math.random() end

function love.keypressed(key, unicode)

  if key == "escape" then
    love.event.push('quit')
  end
  
  if DEBUG and key == '1' then
    FREEZE = not FREEZE
  end

  INVADERS:keypressed(key)
end
function love.keyreleased(key)
  INVADERS:keyreleased(key)
end
function love.mousepressed(x, y, button)
  local mpos = MOUSE_INPUT:get_position()
  INVADERS:mousepressed(mpos.x, mpos.y, button)
end
function love.mousereleased(x, y, button)
  local mpos = MOUSE_INPUT:get_position()
  INVADERS:mousereleased(mpos.x, mpos.y, button)
end

function love.load(args)
  -- GLOBALS -------------------------------------------------------------------
  lg = love.graphics
  lw = love.window
  lf = love.filesystem
  lk = love.keyboard
  li = love.image
  
  ARGS = args
  DEBUG = true
  FREEZE = false
  SCR_WIDTH  = args[1]
  SCR_HEIGHT = args[2]
  FULLSCREEN = args[3]
  MOUSE_INPUT = nil
  TILE_WIDTH = 42
  TILE_HEIGHT = 42
  CELL_WIDTH = 64                       -- collider cell width
  CELL_HEIGHT = 64
  MAX_IMAGE_WIDTH = 2048                  -- in pixels
  MAX_IMAGE_HEIGHT = 2048
  ACTIVE_AREA_WIDTH = 2920
  ACTIVE_AREA_HEIGHT= 2080
  RED, GREEN, BLUE, ALPHA = 1, 2, 3, 4
  
  -- assets
  require("invaders_utils")
  require("invaders_math")
  require("table_utils")
  SHADERS = require("shader_loader")
  local object_loader = require("object_loader")
  object_loader.load_objects()
  FONTS = require("font_loader")
  
  MASTER_TIMER = master_timer:new()
  MOUSE_INPUT = mouse_input:new()
  love.mouse.setVisible(false)

  -- states
  local states = require('state_loader')
  INVADERS = state_manager:new()
  INVADERS:add_state(states.main_menu_load_state, "main_menu_load_state")
  INVADERS:add_state(states.main_menu_state, "main_menu_state")
  INVADERS:add_state(states.level1_load_state, "level1_load_state")
  INVADERS:add_state(states.level1_game_state, "level1_game_state")
  INVADERS:load_state("main_menu_load_state")

end

function love.update(dt)
  if DEBUG then
    if FREEZE then
      return
    end
  
    if love.keyboard.isDown('z') then dt = dt / 16 end
    if love.keyboard.isDown('x') then dt = dt * 3 end
  end

  MASTER_TIMER:update(dt)
  MOUSE_INPUT:update(dt)
  INVADERS:update(dt)
end

function love.draw()
  lg.setPointStyle("rough")

  INVADERS:draw()
  MOUSE_INPUT:draw()
  
  lg.setFont(FONTS.courier_small)
  if DEBUG then
    lg.setColor(255, 0, 0, 255)
    lg.print("FPS "..love.timer.getFPS(), 0, 0)
  end
end











