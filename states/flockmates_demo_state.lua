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
    BOIDS:load_next_state()
  end
end
function flockmates_demo_state.keyreleased(key)
  state.flock:keyreleased(key)
end
function flockmates_demo_state.mousepressed(x, y, button)
  if button == "l" then
    local b = state.speedb
    if b.slow.bbox:contains_coordinate(x, y) then
      b.slow.state = not b.slow.state
      b.fast.state = false
      return
    end
    if b.fast.bbox:contains_coordinate(x, y) then
      b.slow.state = false
      b.fast.state = not b.fast.state
      return
    end
  end

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
  
  -- speed up/slow down buttons
  local speedb = {}
  local text = "slow down"
  local tw1, th1 = FONTS.bebas_smallest:getWidth(text), FONTS.bebas_smallest:getHeight(text)
  local pad = 5
  local offx, offy = 5, 0
  local x, y = 0 + offx, SCR_HEIGHT - th1 + offy
  speedb.slow = {font = FONTS.bebas_smallest,
                 text = text,
                 state = false,
                 x = x,
                 y = y,
                 bbox = bbox:new(x-pad, y-pad, tw1 + 2*pad, th1 + 2*pad)}
  local text = "speed up"
  local tw2, th2 = FONTS.bebas_smallest:getWidth(text), FONTS.bebas_smallest:getHeight(text)
  local offx, offy = 10, 0
  local x, y = x + tw1 + offx, SCR_HEIGHT - th2 + offy
  speedb.fast = {font = FONTS.bebas_smallest,
                 text = text,
                 state = false,
                 x = x,
                 y = y,
                 bbox = bbox:new(x-pad, y-pad, tw2 + 2*pad, th2 + 2*pad)}
  state.speedb = speedb
end


--#########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local t = 0
function flockmates_demo_state.update(dt)
  local b = state.speedb
  if b.slow.state then dt = dt / 10 end
  if b.fast.state then dt = dt * 3 end
  if dt > 1/20 then dt = 1/20 end

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
  
  -- draw speed buttons
  local b = state.speedb
  if b.slow.state then
    lg.setColor(0, 255, 0, 255)
  else
    lg.setColor(0, 0, 0, 100)
  end
  lg.setFont(b.slow.font)
  lg.print(b.slow.text, b.slow.bbox.x, b.slow.bbox.y)
  
  if b.fast.state then
    lg.setColor(0, 255, 0, 255)
  else
    lg.setColor(0, 0, 0, 100)
  end
  lg.setFont(b.fast.font)
  lg.print(b.fast.text, b.fast.bbox.x, b.fast.bbox.y)
end

return flockmates_demo_state












