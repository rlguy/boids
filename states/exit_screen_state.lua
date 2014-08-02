local exit_screen_state = state:new()
exit_screen_state.label = 'exit_screen_state'
local state = exit_screen_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function exit_screen_state.keypressed(key)
  if key == "return" then
    love.event.push("quit")
  end
end
function exit_screen_state.keyreleased(key)
end
function exit_screen_state.mousepressed(x, y, button)
end
function exit_screen_state.mousereleased(x, y, button)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function exit_screen_state.load(level)
  lg.setBackgroundColor(0, 0, 0, 255)
end


--#########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function exit_screen_state.update(dt)

end
  

--########################################d##################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function exit_screen_state.draw()
  local text = "End of Demo"
  local tw = FONTS.bebas_header:getWidth(text)
  local th = FONTS.bebas_header:getHeight(text)
  local x = 0.5 * SCR_WIDTH - 0.5 * tw 
  local y = 0.5 * SCR_HEIGHT - 0.5 * th - 100

  lg.setFont(FONTS.bebas_header)
  lg.setColor(251, 121, 0, 255)
  lg.print(text, x, y)
  
  lg.setFont(FONTS.bebas_smallest)
  local text = "http : //rlguy.com"
  local th = FONTS.bebas_smallest:getHeight(text)
  local x, y = 5, SCR_HEIGHT - th
  lg.setColor(255, 255, 255, 255)
  lg.print(text, x, y)
  
end

return exit_screen_state












