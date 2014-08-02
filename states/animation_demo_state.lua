local animation_demo_state = state:new()
animation_demo_state.label = 'animation_demo_state'
local state = animation_demo_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function animation_demo_state.keypressed(key)
  state.flock:keypressed(key)
  
  if key == "return" then
    BOIDS:load_next_state()
  end
end
function animation_demo_state.keyreleased(key)
  state.flock:keyreleased(key)
end
function animation_demo_state.mousepressed(x, y, button)
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
function animation_demo_state.mousereleased(x, y, button)
  state.flock:mousereleased(x, y, button)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function animation_demo_state.load(level)
  state.level = level
  
  local tpad = 2
  local x, y = state.level.level_map.bbox.x + tpad * TILE_WIDTH, 
               state.level.level_map.bbox.y + tpad * TILE_HEIGHT
  local width, height = state.level.level_map.bbox.width - 2 * tpad * TILE_WIDTH, 
                        state.level.level_map.bbox.height - 2 * tpad * TILE_HEIGHT - 3000
  local depth = 1500
  state.flock = flock:new(state.level, x, y, width, height, depth)
  state.flock:set_gradient(require("gradients/named/whiteblack"))
  
  local x, y, z = 1200, 300, 500
  local dx, dy, dz = 0, 1, 0.5
  local r = 200
  state.emitter = boid_emitter:new(state.level, state.flock, x, y, z, dx, dy, dz, r)
  --state.emitter:set_dead_zone( 0, 4000, 3000, 100)
  state.emitter:set_emission_rate(30)
  --state.emitter:set_waypoint(x, 3000, z)
  state.emitter:set_boid_limit(400)
  state.emitter:start_emission()

  local spritesheet = love.graphics.newImage("images/animations/boidsheet.png")
  local data = require("images/animations/boidsheet_data")
  state.boid_hash = {}
  state.animation_set = animation_set:new(spritesheet, data)
  
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
function animation_demo_state.update(dt)
  -- camera movement test
  local cam = state.level:get_camera()
  local cpos = cam:get_center()
  local target = vector2:new(cpos.x, cpos.y)
  local tx, ty = 0, 0
  local speed = 1000
  if lk.isDown("w", "up") then
    ty = ty - speed * dt
  end
  if lk.isDown("a", "left") then
    tx = tx - speed * dt
  end
  if lk.isDown("s", "down") then
    ty = ty + speed * dt
  end
  if lk.isDown("d", "right") then
    tx = tx + speed * dt
  end
  target.x, target.y = target.x + tx, target.y + ty
  cam:set_target(target, true)
  
  local b = state.speedb
  if b.slow.state then dt = dt / 10 end
  if b.fast.state then dt = dt * 3 end
  if dt > 1/20 then dt = 1/20 end

  state.animation_set:update(dt)
  state.emitter:update(dt)
  state.flock:update(dt)
  state.level:update(dt)
  
  local boids = state.flock.active_boids
  for i=1,#boids do
    local b = boids[i]
    if not state.boid_hash[b] then
      state.boid_hash[b] = true
      b.animation = state.animation_set:get_animation()
      b.animation:play()
    end
    
    if not b.animation:is_running() then
      b.animation:_init()
      b.animation:play()
    end
    b.animation:set_position(b.position.x, b.position.y)
  end
  
  -- update fade
  if state.is_fading then
    state.current_time = state.current_time + dt
  end
end
  

--########################################d##################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function animation_demo_state.draw()
  state.level:draw()
  
  -- draw boids
  state.level.camera:set()
  --state.flock:draw()
  local boids = state.flock.active_boids
  for i=1,#boids do
    boids[i]:draw_shadow()
  end
  lg.setColor(255, 255, 255, 255)
  for i=1,#boids do
    boids[i].animation:draw()
  end
  
  state.emitter:draw()
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

return animation_demo_state












