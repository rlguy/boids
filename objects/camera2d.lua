
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- camera2d object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local camera2d = {}
camera2d.table = CAMERA2D
camera2d.debug = false
camera2d.pos = nil
camera2d.target = nil
camera2d.center = nil
camera2d.x_scale = 1
camera2d.y_scale = 1
camera2d.view_w = SCR_WIDTH
camera2d.view_h = SCR_HEIGHT
camera2d.viewport_box = nil

camera2d.min_scale = 1
camera2d.max_scale = 1
camera2d.act_scale = 1
camera2d.scale = 1
camera2d.scale_up_vel = 6
camera2d.scale_down_vel = 3

camera2d.mass = 0.4

camera2d.shake_curves = nil
camera2d.free_shake_data = nil
camera2d.shakes = nil
camera2d.max_shake_offset = 3

-- temporary vectors
camera2d.center_coordinate = nil
camera2d.scale_vector = nil

camera2d.camera_shake_enabled = false

local camera2d_mt = { __index = camera2d }
function camera2d:new(target_position)
  local camera = setmetatable({}, camera2d_mt)
  
  local pos = vector2:new(0, 0)
  local center = vector2:new(SCR_WIDTH/2, SCR_HEIGHT/2)
  
  -- for smooth movement
  local target = physics.steer:new(pos)
  target:set_dscale(1)
  target:set_target(pos)
  target:set_mass(camera2d.mass)  
  target:set_max_speed(500)
  target:set_force(500)
  target:set_radius(300)
  
  -- for smooth scaling
  local scale_target = physics.steer:new()
  scale_target:set_target(vector2:new(camera2d.min_scale, 0))
  scale_target:set_position(vector2:new(camera2d.min_scale, 0))
  scale_target:set_mass(1)
  scale_target:set_max_speed(camera2d.scale_up_vel)
  
  local view_width, view_height = SCR_WIDTH, SCR_HEIGHT
  
  camera.pos = pos
  camera.center = center
  camera.target = target
  camera.scale_target = scale_target
  camera.view_w = view_width
  camera.view_h = view_height
  camera.center_coordinate = vector2:new(0, 0)
  camera.scale_vector = vector2:new(1, 0)
  camera.viewport_bbox = bbox:new(camera.pos.x, camera.pos.y, 
                                  camera.view_w, camera.view_h)
  camera.shake_curves = {}
  camera.free_shake_data = {}
  camera.shakes = {}
  
  if target_position then
    camera:set_target(target_position, true)
  end
                        
  return camera
end

------------------------------------------------------------------------------
function camera2d:set()
  lg.push()
  lg.scale(self.x_scale, self.y_scale)
  lg.translate(math.floor(-self.pos.x), math.floor(-self.pos.y))
end

-----------------------------------------------------------------------------
function camera2d:unset()
  love.graphics.pop()
end

function camera2d:set_shake_curves(x_curves, y_curves)
  local num = math.min(#x_curves, #y_curves)
  for i=1,num do
    self.shake_curves[#self.shake_curves + 1] = x_curves[i]
    self.shake_curves[#self.shake_curves + 1] = y_curves[i]
  end
  if #self.shake_curves > 0 then
    self.camera_shake_enabled = true
  end
end

-----------------------------------------------------------------------------
-- sets center of the screen at position pos
-- NOTE: if scaling, set_scale must be set before set_position
function camera2d:set_position(pos)
  self.pos:set(pos.x - self.center.x, pos.y - self.center.y)
end

function camera2d:set_target(pos, immediate)
  if immediate then
    self.target:set_position(pos)
    self:set_position(pos)
  end
  self.target:set_target(pos)
end

------------------------------------------------------------------------------
function camera2d:set_scale(sx, sy)
  self.x_scale = sx or 1
  self.y_scale = sy or self.x_scale
  self.view_w = SCR_WIDTH / self.x_scale
  self.view_h = SCR_HEIGHT / self.y_scale
  self.center:set(0.5*self.view_w, 0.5*self.view_h)
end

function camera2d:get_pos()
  return self.pos
end

function camera2d:get_center()
  local c = self.center_coordinate
  c:set(self.pos.x + self.center.x, self.pos.y + self.center.y)
  return c
end

function camera2d:get_size()
  return self.view_w, self.view_h
end

function camera2d:get_viewport()
  return self.pos.x, self.pos.y, self.view_w, self.view_h
end

function camera2d:get_viewport_bbox()
  return self.viewport_bbox
end

function camera2d:_get_new_free_shake_data()
  if #self.free_shake_data == 0 then
    self.free_shake_data[1] = {}
  end
  return self.free_shake_data[#self.free_shake_data]
end

function camera2d:_update_shakes(dt)
  if not self.camera_shake_enabled then return end

  local shakes = self.shakes
  for i=#shakes,1,-1 do
    local shake = shakes[i]
    shake.current_time = shake.current_time + dt
    if shake.current_time > shake.lifetime then
      shake.current_time = shake.lifetime
      shake.is_finished = true
    end
    
    local progress = shake.current_time / shake.lifetime
    shake.xoff = shake.xdir * shake.x_curve:get(progress) * shake.radius
    shake.yoff = shake.ydir * shake.y_curve:get(progress) * shake.radius
    
    if shake.is_finished then
      self.free_shake_data[#self.free_shake_data + 1] = table.remove(shakes, i)
    end
  end
end

function camera2d:_get_shake_offset()
  local xoff, yoff = 0, 0
  local shakes = self.shakes
  
  for i=1,#shakes do
    xoff = xoff + shakes[i].xoff
    yoff = yoff + shakes[i].yoff
  end
  
  return xoff, yoff
end

function camera2d:shake(power, duration)
  local curves = self.shake_curves

  local shake = self:_get_new_free_shake_data()
  shake.radius = power * self.max_shake_offset
  shake.lifetime = duration
  shake.current_time = 0
  shake.is_finished = false
  shake.xdir = 1
  shake.ydir = 1
  if math.random() < 0.5 then
    shake.xdir = -1
  end
  if math.random() < 0.5 then
    shake.ydir = -1
  end
  
  local idx = math.random(1, 0.5 * #curves)
  local x_curve, y_curve = curves[idx], curves[idx + 1]
  if math.random() < 0.5 then
    x_curve, y_curve = y_curve, x_curve
  end
  
  shake.x_curve = x_curve
  shake.y_curve = y_curve
  shake.offx = 0
  shake.offy = 0
  
  self.shakes[#self.shakes + 1] = shake
end

------------------------------------------------------------------------------
function camera2d:update(dt)
  -- calculate what the camera should be scaled to
  local vel = self.target.point:get_velocity():mag()
  local max_vel = self.target.max_vel
  local r = vel / max_vel
  local act_scale = self.min_scale + r * (self.max_scale - self.min_scale)
  
  -- find the smooth scale value
  self.scale_vector:set(act_scale, 0)
  self.scale_target:set_target(self.scale_vector)
  self.scale_target:update(dt)
  if self.scale_target.point:get_velocity().x > 0 then
    self.scale_target:set_max_speed(self.scale_down_vel)
  else
    self.scale_target:set_max_speed(self.scale_up_vel)
  end
  self.scale = self.scale_target:get_position().x
  
  -- commit the scale
  self:set_scale(self.scale)
  
  -- set position
  self.target:update(dt)
  self:_update_shakes(dt)
  self:set_position(self.target:get_position())
  local xoff, yoff = self:_get_shake_offset()
  self.pos.x, self.pos.y = self.pos.x + xoff, self.pos.y + yoff
  
  local bbox = self.viewport_bbox
  bbox.x, bbox.y = self.pos.x, self.pos.y
  bbox.width, bbox.height = self.view_w, self.view_h
end

------------------------------------------------------------------------------
function camera2d:draw()
  if self.debug then
    self.target:draw()
  end
end

return camera2d







