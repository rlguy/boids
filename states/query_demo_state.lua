local query_demo_state = state:new()
query_demo_state.label = 'query_demo_state'
local state = query_demo_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function query_demo_state.keypressed(key)
  state.flock:keypressed(key)
  
  if key == "return" then
    BOIDS:load_next_state()
  end
end
function query_demo_state.keyreleased(key)
  state.flock:keyreleased(key)
end
function query_demo_state.mousepressed(x, y, button)
  state.flock:mousepressed(x, y, button)
end
function query_demo_state.mousereleased(x, y, button)
  state.flock:mousereleased(x, y, button)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
state.boids = nil
state.collider = nil
function query_demo_state.load(level)
  state.level = level
  
  local x, y, width, height = state.level:get_camera():get_viewport()
  local tpad = 2
  local depth = 1500
  state.flock = flock:new(state.level, x, y, width, height, depth)
  state.flock:set_gradient(require("gradients/named/blue"))
  state.flock:set_camera_tracking_off()
  
  local x, y, z = x + SCR_WIDTH / 2, y + 200, 500
  local dx, dy, dz = 0, 1, 0.5
  local r = 200
  state.emitter = boid_emitter:new(state.level, state.flock, x, y, z, dx, dy, dz, r)
  state.emitter:set_emission_rate(30)
  state.emitter:set_boid_limit(200)
  state.emitter:start_emission()
  
  state.collider = state.flock.collider
  state.boids = state.flock.free_boids
  state.collider_hash = {}
  local boids = state.boids
  for i=1,#boids do
    if math.random() < 0.02 then
      local b = boids[i]
      b.state_bbox = bbox:new(0, 0, 0, 0)
    end
  end
end


--#########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local t = 0
function query_demo_state.update(dt)
  local boids = state.flock.active_boids
  for i=1,#boids do
    local b = boids[i]
    if not state.collider_hash[b] then
      if b.state_bbox then
        local w, h = math.random(50, 250), math.random(50, 250)
        local bb = b.state_bbox
        local x, y = b.position.x, b.position.y
        bb.x, bb.y, bb.width, bb.height = x - 0.5 * w, y - 0.5 * h, w, h
        state.collider:add_object(bb, b)
      end
      state.collider_hash[b] = true
    else
      if b.state_bbox then
        local bb = b.state_bbox
        local x, y = b.position.x, b.position.y
        bb.x, bb.y = x - 0.5 * bb.width, y - 0.5 * bb.height
        state.collider:update_object(bb)
      end
    end
  end

  state.emitter:update(dt)
  state.flock:update(dt)
  state.level:update(dt)
  
end
  

--########################################d##################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function query_demo_state.draw()
  state.level:draw()
  
  -- draw boids
  lg.setFont(FONTS.bebas_small)
  state.level.camera:set()
  --state.flock:draw()
  state.flock.user_interface:draw()
  state.flock.collider.debug = true
  state.flock.collider:draw()
  state.level.camera:unset()
  
  
  local x, y = 20, 20
  lg.setColor(255, 255, 255, 255)
  lg.setFont(FONTS.bebas_text)
  lg.print("Fixed Grid Spatial Partition", x, y)
end

return query_demo_state












