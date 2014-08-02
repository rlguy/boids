local obstacle_screen_state = state:new()
obstacle_screen_state.label = 'obstacle_screen_state'
local state = obstacle_screen_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function obstacle_screen_state.keypressed(key)
  if key == "return" then
    BOIDS:load_next_state()
  end
end
function obstacle_screen_state.keyreleased(key)
end
function obstacle_screen_state.mousepressed(x, y, button)
end
function obstacle_screen_state.mousereleased(x, y, button)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function obstacle_screen_state.load(level)
  lg.setBackgroundColor(0, 0, 0, 255)
end


--#########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function obstacle_screen_state.update(dt)

end
  

--########################################d##################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function obstacle_screen_state.draw()
  local width, height = 1024, 768
  local xpad = 100
  local ypad = 60

  local x = 0.5 * SCR_WIDTH - 0.5 * width + xpad
  local y = 0.5 * SCR_HEIGHT - 0.5 * height + ypad

  lg.setFont(FONTS.bebas_header)
  lg.setColor(251, 121, 0, 255)
  lg.print("Obstacle Avoidance", x, y)
  
  local y = y + 200
  local x = x + 20
  local ystep = 100
  lg.setFont(FONTS.verdana_text)
  lg.setColor(255, 255, 255, 255)
  lg.print("Create obstacles with implicit surface\npolygonizer\n", x, y)
  
  y = y + 1.5 * ystep
  lg.print("Field function values and normals aid\nboids in avoiding obstacles", x, y)
  
end

return obstacle_screen_state












