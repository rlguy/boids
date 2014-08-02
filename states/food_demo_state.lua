local food_demo_state = state:new()
food_demo_state.label = 'food_demo_state'
local state = food_demo_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function food_demo_state.keypressed(key)
  state.flock:keypressed(key)
  
  if key == " " then
    state.emitter:start_emission()
    state.start_fade()
  end
  
  if key == "return" then
    BOIDS:load_next_state()
  end
  
  if key == "r" then
    state.reset()
    state.start_fade()
  end
  
end
function food_demo_state.keyreleased(key)
  state.flock:keyreleased(key)
end
function food_demo_state.mousepressed(x, y, button)
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
  
  -- mouse wheel up/down changes obstacle_size
  local min, max = 50, 1000
  local inc = 30
  if     button == "wu" then
    state.point_radius = state.point_radius + inc
    state.point_radius = math.min(max, state.point_radius)
  elseif button == "wd" then
    state.point_radius = state.point_radius - inc
    state.point_radius = math.max(min, state.point_radius)
  end
  
  if button == "l" and not state.emitter.is_active then
    local x, y = state.level:get_camera():get_viewport()
    local mpos = state.level:get_mouse():get_position()
    local mx, my = x + mpos.x, y + mpos.y
    local p = state.food_source:add_food(mx, my, state.point_radius)
    state.food_source:force_polygonizer_update()
    
    state.primitives[#state.primitives + 1] = p
    if #state.primitives == 1 then
      state.start_fade()
    end
  end
end
function food_demo_state.mousereleased(x, y, button)
  state.flock:mousereleased(x, y, button)
end

function food_demo_state.reset()
  for i=#state.primitives,1,-1 do
    state.food_source:remove_food_source(state.primitives[i])
    state.primitives[i] = nil
  end
  state.food_source:force_polygonizer_update()
  
  state.emitter:reset()
end

function food_demo_state.start_fade()
  if state.is_fade_active then return end
  state.is_fade_active = true
  state.current_time = 0
end

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function food_demo_state.load(level)
  state.level = level
  
  local tpad = 2
  local x, y = state.level.level_map.bbox.x + tpad * TILE_WIDTH, 
               state.level.level_map.bbox.y + tpad * TILE_HEIGHT
  local width, height = state.level.level_map.bbox.width - 2 * tpad * TILE_WIDTH, 
                        state.level.level_map.bbox.height - 2 * tpad * TILE_HEIGHT
  local depth = 1500
  state.flock = flock:new(state.level, x, y, width, height, depth)
  state.flock:set_gradient(require("gradients/named/whiteblack"))
  
  local x, y, z = 1200, 300, 500
  local dx, dy, dz = 0, 1, 0.5
  local r = 200
  state.emitter = boid_emitter:new(state.level, state.flock, x, y, z, dx, dy, dz, r)
  state.emitter:set_dead_zone( 0, 4000, 3000, 100)
  state.emitter:set_emission_rate(30)
  state.emitter:set_boid_limit(400)
  state.emitter:stop_emission()
  
  state.food_source = boid_food_source:new(state.level, state.flock)

  state.point_radius = 200
  state.polygonizer_threshold = 0.65
  state.primitives = {}
  state.primitive_bbox = bbox:new(0, 0, 0, 0)
  state.fade_time = 1
  state.is_fade_active = false
  state.current_time = 0
  state.fade_text = nil
  
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
function food_demo_state.update(dt)
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

  state.food_source:update(dt)
  state.emitter:update(dt)
  state.flock:update(dt)
  state.level:update(dt)

  local x, y = state.level:get_camera():get_viewport()
  local mpos = state.level:get_mouse():get_position()
  local mx, my = x + mpos.x, y + mpos.y
  local r = state.point_radius
  local b = state.primitive_bbox
  b.x, b.y = mx - r, my - r
  b.width, b.height = 2 * r, 2 * r
  
end
  

--########################################d##################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function state.draw_field_vector()
  local x, y = state.level:get_camera():get_viewport()
  local mpos = state.level:get_mouse():get_position()
  local mx, my = x + mpos.x, y + mpos.y
  local nx, ny, f = state.level.level_map:get_field_vector_at_position({x=mx, y=my})
  
  if f <= 0 then return end
  
  local len = 150
  local width = 10
  local perpx, perpy = -ny, nx
  local x1, y1 = mx - 0.5 * perpx * width, my - 0.5 * perpy * width
  local x2, y2 = mx + 0.5 * perpx * width, my + 0.5 * perpy * width
  local x3, y3 = x2 + len * nx, y2 + len * ny
  local x4, y4 = x1 + len * nx, y1 + len * ny
  
  lg.setColor(255, 255, 255, 255)
  lg.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
  
  local len = f * len
  local x5, y5 = x2 + len * nx, y2 + len * ny
  local x6, y6 = x1 + len * nx, y1 + len * ny
  
  lg.setColor(0, 255, 0, 255)
  lg.polygon("fill", x1, y1, x2, y2, x5, y5, x6, y6)
  lg.setColor(0, 0, 0, 255)
  lg.polygon("line", x1, y1, x2, y2, x3, y3, x4, y4)
end

function food_demo_state.draw()
  state.level:draw()

  -- draw boids
  state.level.camera:set()
  state.flock:draw()
  state.emitter:draw()
  
  if love.keyboard.isDown("f") then
    state.food_source.debug = true
  else
    state.food_source.debug = false
  end
  state.food_source:draw()
  
  if state.emitter.is_active then
    lg.setColor(0, 0, 0, 0)
  else
    lg.setColor(255, 255, 255, 255)
    if not state.level.level_map.bbox:contains(state.primitive_bbox) then
      lg.setColor(255, 0, 0, 255)
    end
  end
  
  -- obstacle radius
  local x, y = state.level:get_camera():get_viewport()
  local mpos = state.level:get_mouse():get_position()
  lg.circle("line", mpos.x + x, mpos.y + y, state.point_radius * (1-state.polygonizer_threshold))
  if state.emitter.is_active then
    lg.setColor(0, 0, 0, 0)
  else
    lg.setColor(255, 255, 255, 50)
    if not state.level.level_map.bbox:contains(state.primitive_bbox) then
      lg.setColor(255, 0, 0, 50)
    end
  end
  lg.circle("line", mpos.x + x, mpos.y + y, state.point_radius)
  
  state.draw_field_vector()
  state.level.camera:unset()
  
  
  -- intruction text
  local x, y = 20, 10
  lg.setColor(255, 255, 255, 255)
  lg.setFont(FONTS.bebas_text)
  local txt
  if #state.primitives == 0 then
    txt = "Click to add a food source"
  else
    if state.emitter.is_active then
      txt = "Press [ r ] to reset"
    else
      txt = "Press [ space ] to release boids"
    end
  end
  if not state.is_fade_active then
    state.fade_text = txt
    lg.print(txt, x, y)
  else
    state.current_time = state.current_time + love.timer.getDelta()
    local t = math.min(state.fade_time, state.current_time)
    if state.current_time > 2 * state.fade_time then
      state.is_fade_active = false
    end
    
    local prog = t / state.fade_time
    prog = 1 - prog * prog * (3 - 2 * prog)
    local min, max = 0, 255
    local alpha = lerp(min, max, prog)
    lg.setColor(255, 255, 255, alpha)
    lg.print(state.fade_text, x, y)
  end
  
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

return food_demo_state












