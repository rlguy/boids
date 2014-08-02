local flockmates_screen_state = state:new()
flockmates_screen_state.label = 'flockmates_screen_state'
local state = flockmates_screen_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function flockmates_screen_state.keypressed(key)
  if key == "return" then
    BOIDS:load_next_state()
  end
end
function flockmates_screen_state.keyreleased(key)
end
function flockmates_screen_state.mousepressed(x, y, button)
end
function flockmates_screen_state.mousereleased(x, y, button)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function flockmates_screen_state.load(level)
  lg.setBackgroundColor(0, 0, 0, 255)
end


--#########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function flockmates_screen_state.update(dt)

end
  

--########################################d##################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function flockmates_screen_state.draw()
  local width, height = 1024, 768
  local xpad = 100
  local ypad = 60

  local x = 0.5 * SCR_WIDTH - 0.5 * width + xpad
  local y = 0.5 * SCR_HEIGHT - 0.5 * height + ypad

  lg.setFont(FONTS.bebas_header)
  lg.setColor(251, 121, 0, 255)
  lg.print("What do boids do?", x, y)
  
  local y = y + 200
  local x = x + 20
  local ystep = 60
  lg.setFont(FONTS.verdana_text)
  lg.setColor(255, 255, 255, 255)
  lg.print("Boids react to local flockmates", x, y)
  
  x = x + 80
  y = y + ystep
  lg.setColor(200, 200, 200, 255)
  lg.print("- Limited sight radius", x, y)
  
  y = y + ystep
  lg.print("- Limited field of view", x, y)
  
end

return flockmates_screen_state












