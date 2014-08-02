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
end


--#########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function rules_demo_state.update(dt)
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
end

return rules_demo_state












