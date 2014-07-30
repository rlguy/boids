local flockmates_demo_state = state:new()
flockmates_demo_state.label = 'flockmates_demo_state'
local state = flockmates_demo_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function flockmates_demo_state.keypressed(key)
  state.flock:keypressed(key)
  
  if key == "return" then
    INVADERS:load_next_state()
  end
end
function flockmates_demo_state.keyreleased(key)
  state.flock:keyreleased(key)
end
function flockmates_demo_state.mousepressed(x, y, button)
  state.flock:mousepressed(x, y, button)
end
function flockmates_demo_state.mousereleased(x, y, button)
  state.flock:mousereleased(x, y, button)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function flockmates_demo_state.load(level)
  state.level = level
  
  local x, y, width, height = state.level:get_camera():get_viewport()
  local tpad = 2
  local depth = 1500
  state.flock = flock:new(state.level, x, y, width, height, depth)
  state.flock:set_gradient(require("gradients/named/blue"))
  state.flock:set_camera_tracking_off()
  state.flock.user_interface.debug = true
  
  local x, y, z = x + SCR_WIDTH / 2, y + 200, 500
  local dx, dy, dz = 0, 1, 0.5
  local r = 200
  state.emitter = boid_emitter:new(state.level, state.flock, x, y, z, dx, dy, dz, r)
  state.emitter:set_emission_rate(30)
  state.emitter:set_boid_limit(50)
  state.emitter:start_emission()
  
end


--#########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local t = 0
function flockmates_demo_state.update(dt)
  state.emitter:update(dt)
  state.flock:update(dt)
  state.level:update(dt)
  
end
  

--########################################d##################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function flockmates_demo_state.draw()
  state.level:draw()
  
  local x, y = 20, 20
  lg.setFont(FONTS.bebas_text)
  lg.print("Select a boid to view it's local flockmates", x, y)
  
  -- draw boids
  lg.setFont(FONTS.bebas_small)
  state.level.camera:set()
  state.flock:draw()
  state.level.camera:unset()
  
end

return flockmates_demo_state












