local rules_demo_state = state:new()
rules_demo_state.label = 'rules_demo_state'
local state = rules_demo_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function rules_demo_state.keypressed(key)
  state.flock:keypressed(key)
  
  if key == "return" then
    BOIDS:load_next_state()
  end
end
function rules_demo_state.keyreleased(key)
  state.flock:keyreleased(key)
end
function rules_demo_state.mousepressed(x, y, button)
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

  local buttons = state.buttons
  for i=1,#buttons do
    local b = buttons[i]
    if b.bbox:contains_coordinate(x, y) then
      rules_demo_state.toggle_button(b)
      return
    end
  end

  state.flock:mousepressed(x, y, button)
end
function rules_demo_state.mousereleased(x, y, button)
  state.flock:mousereleased(x, y, button)
end

rules_demo_state.toggle_button = function(b)
  local boids = state.flock.active_boids
  for i=1,#boids do
    local boid = boids[i]
    if     b.toggle == false then
      if     b.text == "Alignment" then
        boid.rule_weights[boid.alignment_vector] = state.rules[1]
      elseif b.text == "Cohesion" then
        boid.rule_weights[boid.cohesion_vector] = state.rules[2]
      elseif b.text == "Separation" then
        boid.rule_weights[boid.separation_vector] = state.rules[3]
      end
    elseif b.toggle == true then
      if     b.text == "Alignment" then
        boid.rule_weights[boid.alignment_vector] = 0
      elseif b.text == "Cohesion" then
        boid.rule_weights[boid.cohesion_vector] = 0
      elseif b.text == "Separation" then
        boid.rule_weights[boid.separation_vector] = 0
      end
    end
  end
  b.toggle = not b.toggle
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function rules_demo_state.load(level)
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
  state.emitter:set_boid_limit(100)
  state.emitter:set_random_direction_on()
  state.emitter:start_emission()
  
  state.buttons = {}
  state.buttons[1] = {text="Alignment", x = 250, y = 10, toggle = false, 
                      bbox = bbox:new(240, 10, 170, 50)}
  state.buttons[2] = {text="Cohesion", x = 430, y = 10, toggle = false, 
                      bbox = bbox:new(420, 10, 155, 50)}
  state.buttons[3] = {text="Separation", x = 590, y = 10, toggle = false, 
                      bbox = bbox:new(580, 10, 190, 50)}
                      
  state.rules = {0.5, 0.2, 3}
  
  for i=1,#state.flock.free_boids do
    local b = state.flock.free_boids[i]
    b.rule_weights[b.alignment_vector] = 0
    b.rule_weights[b.cohesion_vector] = 0
    b.rule_weights[b.separation_vector] = 0
  end
  
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
function rules_demo_state.update(dt)
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
function rules_demo_state.draw()
  state.level:draw()
  
  local x, y = 10, 10
  lg.setFont(FONTS.bebas_text)
  lg.print("Toggle Rules:", x, y)
  
  -- draw boids
  lg.setFont(FONTS.bebas_small)
  state.level.camera:set()
  state.flock:draw()
  state.level.camera:unset()
  
  -- draw buttons
  lg.setFont(FONTS.bebas_text)
  for i=1,#state.buttons do
    local b = state.buttons[i]
    if b.toggle then
      lg.setColor(0, 255, 0, 255)
    else
      lg.setColor(100, 100, 100, 255)
    end
    lg.print(b.text, b.x, b.y)
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

return rules_demo_state












