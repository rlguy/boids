local main_screen_state = state:new()
main_screen_state.label = 'main_screen_state'
local state = main_screen_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function main_screen_state.keypressed(key)
  state.flock:keypressed(key)
  
  if key == " " then
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
  end
  
  if key == "return" then
    INVADERS:load_next_state()
  end
end
function main_screen_state.keyreleased(key)
  state.flock:keyreleased(key)
end
function main_screen_state.mousepressed(x, y, button)
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
end


--#########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local t = 0
function main_screen_state.update(dt)
  -- camera movement test
  local cam = state.level:get_camera()
  local cpos = cam:get_center()
  local target = vector2:new(cpos.x, cpos.y)
  local tx, ty = 0, 0
  local speed = 1000
  if lk.isDown("w") then
    ty = ty - speed * dt
  end
  if lk.isDown("a") then
    tx = tx - speed * dt
  end
  if lk.isDown("s") then
    ty = ty + speed * dt
  end
  if lk.isDown("d") then
    tx = tx + speed * dt
  end
  target.x, target.y = target.x + tx, target.y + ty
  cam:set_target(target, true)

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
  
end

return main_screen_state












