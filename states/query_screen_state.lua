local query_screen_state = state:new()
query_screen_state.label = 'query_screen_state'
local state = query_screen_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function query_screen_state.keypressed(key)
  if key == "return" then
    BOIDS:load_next_state()
  end
end
function query_screen_state.keyreleased(key)
end
function query_screen_state.mousepressed(x, y, button)
end
function query_screen_state.mousereleased(x, y, button)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function query_screen_state.load(level)
  lg.setBackgroundColor(0, 0, 0, 255)
end


--#########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function query_screen_state.update(dt)

end
  

--########################################d##################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function query_screen_state.draw()
  local width, height = 1024, 768
  local xpad = 100
  local ypad = 60

  local x = 0.5 * SCR_WIDTH - 0.5 * width + xpad
  local y = 0.5 * SCR_HEIGHT - 0.5 * height + ypad

  lg.setFont(FONTS.bebas_header)
  lg.setColor(251, 121, 0, 255)
  lg.print("Querying Flockmates", x, y)
  
  local y = y + 200
  local x = x + 20
  local ystep = 100
  lg.setFont(FONTS.verdana_text)
  lg.setColor(255, 255, 255, 255)
  lg.print("Every boid is aware of its neighbours", x, y)
  
  y = y + ystep
  lg.print("Naive solution runs in O(n^2)", x, y)
  
  y = y + ystep
  lg.print("Use 2D fixed grid spatial partition for\nfast neighbour queries", x, y)
  
end

return query_screen_state












