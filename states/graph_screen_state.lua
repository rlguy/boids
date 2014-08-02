local graph_screen_state = state:new()
graph_screen_state.label = 'graph_screen_state'
local state = graph_screen_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function graph_screen_state.keypressed(key)
  if key == "return" then
    BOIDS:load_next_state()
  end
end
function graph_screen_state.keyreleased(key)
end
function graph_screen_state.mousepressed(x, y, button)
end
function graph_screen_state.mousereleased(x, y, button)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function graph_screen_state.load(level)
  lg.setBackgroundColor(0, 0, 0, 255)
end


--#########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function graph_screen_state.update(dt)

end
  

--########################################d##################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function graph_screen_state.draw()
  local width, height = 1024, 768
  local xpad = 100
  local ypad = 60

  local x = 0.5 * SCR_WIDTH - 0.5 * width + xpad
  local y = 0.5 * SCR_HEIGHT - 0.5 * height + ypad

  lg.setFont(FONTS.bebas_header)
  lg.setColor(251, 121, 0, 255)
  lg.print("Extra fun stuff", x, y)
  
  local y = y + 200
  local x = x + 20
  local ystep = 100
  lg.setFont(FONTS.verdana_text)
  lg.setColor(255, 255, 255, 255)
  lg.print("Neighbour graph of a flock", x, y)
  
end

return graph_screen_state












