local main_screen_state = state:new()
main_screen_state.label = 'main_screen_state'
local state = main_screen_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local spawn_boids = function()
  state.is_fading = true
  if not state.boids_spawned then
    local offx, offy, _, _ = state.level:get_camera():get_viewport()
    offx = offx + 0.5 * SCR_WIDTH - 0.5 * state.slide_img:getWidth()
    offy = offy + 0.5 * SCR_HEIGHT - 0.5 * state.slide_img:getHeight()
    local locations = state.boid_locations
    for i=1,#locations do
      local dx, dy = random_direction2()
      state.flock:add_boid(locations[i].x + offx, 
                           locations[i].y + offy, math.random(100, 400),
                           dx, dy, 0)
    end
    state.boids_spawned = true
  end
  state.emitter:start_emission()
  state.is_next_state_ready = true
end

function main_screen_state.keypressed(key)
  state.flock:keypressed(key)

  if key == "return" then
    if state.is_next_state_ready then
      BOIDS:load_next_state()
    else
      spawn_boids()
    end
  end
end
function main_screen_state.keyreleased(key)
  state.flock:keyreleased(key)
end
function main_screen_state.mousepressed(x, y, button)
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
function main_screen_state.mousereleased(x, y, button)
  state.flock:mousereleased(x, y, button)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function main_screen_state.load(level)
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
  --state.emitter:set_waypoint(x, 3000, z)
  state.emitter:set_boid_limit(200)
  state.emitter:stop_emission()
  
  state.slide_img = lg.newImage("images/boids_images/main_screen.png")
  state.fade_time = 0.25
  state.rect_fade_time = 5
  state.current_time = 0
  state.is_fading = false
  state.is_next_state_ready = false
  
  local imgdata = love.image.newImageData("images/boids_images/main_screen.png")
  local pixels = {}
  for j=0,imgdata:getHeight()-1 do
    for i=0,imgdata:getWidth()-1 do
      local r, g, b, a = imgdata:getPixel(i, j)
      if r == 255 and g == 255 and b == 255 and a == 255 then
        pixels[#pixels+1] = {x=i, y=j}
      end
    end
  end
  local n = 250
  local locations = {}
  for i=1,n do
    locations[i] = pixels[math.random(1,#pixels)]
  end
  state.boid_locations = locations
  
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
function main_screen_state.update(dt)
  -- camera movement test
  if state.boids_spawned then
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
  end
  
  local b = state.speedb
  if b.slow.state then dt = dt / 10 end
  if b.fast.state then dt = dt * 3 end
  if dt > 1/20 then dt = 1/20 end

  state.emitter:update(dt)
  state.flock:update(dt)
  state.level:update(dt)
  
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
function main_screen_state.draw()
  state.level:draw()

  -- draw background
  lg.setColor(251, 121, 0, alpha2)
  lg.rectangle("fill", 0, 0, SCR_WIDTH, SCR_HEIGHT)
  
  -- draw boids
  state.level.camera:set()
  state.flock:draw()
  state.emitter:draw()
  state.level.camera:unset()
   
  -- update slide fade
  local alpha = 255
  if state.is_fading then
    local min, max = 0, 255
    local t = state.current_time
    local prog = math.min(1, t / state.fade_time)
    prog = prog * prog * (3 - 2 * prog)
    alpha1 = lerp(max, min, prog)
    
    prog = math.min(1, t / state.rect_fade_time)
    prog = prog * prog * (3 - 2 * prog)
    alpha2 = lerp(max, min, prog)
  end
  
  -- draw slide
  local img = state.slide_img
  local x = 0.5 * SCR_WIDTH - 0.5 * img:getWidth()
  local y = 0.5 * SCR_HEIGHT - 0.5 * img:getHeight()
  lg.setColor(255, 255, 255, alpha1)
  lg.draw(img, x, y)
  
  -- draw speed buttons
  if not state.boids_spawned then return end
  
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

return main_screen_state












