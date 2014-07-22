-- enums
DSCALE = 32   -- in pixels per metre
EPSILON = 0.0000001
VECT_ZERO = vector2:new(0, 0)


--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- point object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local point = {}
point.table = PHYS_POINT
point.dscale = DSCALE
point.pos = nil
point.vel = nil
point.mass = 1
point.force = nil
point.forces = nil       -- format: {vect1, timer1, vect2, timer2, ...}
point.has_force = false

local point_mt = { __index = point }
function point:new(pos)
  local point = setmetatable({}, point_mt)

  local pos = pos or VECT_ZERO
  local force = vector2:new(0, 0)
  local forces = {}
  
  
  point.pos = vector2:new(pos.x, pos.y)
  point.vel = vector2:new(0, 0)
  point.force = force
  point.forces = forces
  point.spare_forces = {}
  point.spare_timers = {}
                        
  return point
end

function point:set_position(pos) 
  self.pos:clone(pos) 
end
function point:set_velocity(vel) self.vel:clone(vel) end
function point:set_mass(mass) self.mass = mass end
function point:set_dscale(s) self.dscale = s end

function point:get_position()
  return self.pos 
end
function point:get_velocity() return self.vel end

-----------------------------------------------------------------------------
-- applies force vect for time t (miliseconds)
-- force is only applied once if t not specifided
function point:add_force(vect, t)
  if t then
    local len = #self.forces
    local force, p
    
    if #self.spare_forces > 0 then
      force = table.remove(self.spare_forces, 1)
      force:clone(vect)
    else
      force = vector2:new(vect.x, vect.y)
    end
    
    if #self.spare_timers > 0 then
      p = table.remove(self.spare_timers, 1)
      p:reset()
      p:set_length(t)
    else
      p = timer:new(t)
    end
    
    self.forces[len+1] = force
    self.forces[len+2] = p
    p:start()
  else
    self.force.x = self.force.x + vect.x
    self.force.y = self.force.y + vect.y
  end
  
  self.has_force = true
end


-----------------------------------------------------------------------------
-- adds timed forces to self.force
function point:_apply_forces()
  local forces = self.forces
  for i=#forces, 1, -2 do
    local force = forces[i-1]
    local timer = forces[i]
    self.force.x = self.force.x + force.x
    self.force.y = self.force.y + force.y
    
    -- remove entry if finished
    if timer:isfinished() then
      local timer = table.remove(forces, i)
      local force = table.remove(forces, i-1)
      self.spare_timers[#self.spare_timers + 1] = timer
      self.spare_forces[#self.spare_forces + 1] = force
    end
  end
end

------------------------------------------------------------------------------
function point:update(dt)
  if #self.forces > 0 then
    self:_apply_forces()
  end
  
  -- newton
  local acc = VECT_ZERO
  if self.has_force then
    acc = self.force / self.mass
  end
  
  local vel = self.vel
  vel:set(vel.x + acc.x * dt, vel.y + acc.y * dt)
  if vel:mag() < EPSILON then
    vel:set(0, 0)
  end
  
  local pos = self.pos
  pos.x = pos.x + self.dscale * vel.x * dt
  pos.y = pos.y + self.dscale * vel.y * dt  -- (m/s)*(px/m) = (px/s)

  -- clear force
  self.force:set(0, 0)
  self.has_force = false
end

------------------------------------------------------------------------------
function point:draw()
  lg.setColor(255,0,0,255)
  lg.setPoint(4, "smooth")
  lg.point(self.pos:get_vals())
end



--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- steer object - a point that steers toward it's target
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local steer = {}
steer.table = PHYS_STEER
steer.dscale = DSCALE
steer.point = nil
steer.target = nil
steer.max_force = 10
steer.max_vel = 30         -- meters/s
steer.slow_radius = 400     -- in pixels
steer.approach_factor = 1
steer.temp_vector = nil
steer.force_vector = nil
steer.temp_direction = nil

local steer_mt = { __index = steer }
function steer:new(pos)
  local steer = setmetatable({}, steer_mt)
  local pos = pos or VECT_ZERO
  
  steer.pos = vector2:new(pos.x, pos.y)
  steer.point = point:new(pos)
  steer.target = vector2:new(pos.x, pos.y)
  steer.temp_vector = vector2:new(0, 0)
  steer.force_vector = vector2:new(0, 0)
  steer.temp_direction = vector2:new(0, 0)
                        
  return steer
end

function steer:set_target(target)
  self.target:clone(target)
end

function steer:set_position(pos)
  self.point:set_position(pos)
end

function steer:set_force(f)  -- scalar
  self.max_force = f
end

function steer:set_max_speed(s)
  self.max_vel = s
end

function steer:set_radius(r)
  self.slow_radius = r
end

function steer:set_mass(m)
  self.point:set_mass(m)
end

function steer:set_dscale(s)
	self.dscale = s
	self.point:set_dscale(s)
end

function steer:set_approach_factor(f)
	self.approach_factor = f
end

function steer:get_position()
  return self.point:get_position()
end

------------------------------------------------------------------------------
function steer:_get_steer_force()
  local target = self.target
  local pos = self.point:get_position()
  local desired = self.temp_vector
  desired:set(target.x - pos.x, target.y - pos.y)
  desired = desired:unit_vector(desired)
  local dir = self.temp_direction
  dir:clone(desired)
  
  -- set length of desired vector
  local r = self.slow_radius
  local dist_sq = vector2:dist_sq(pos, target)
  if dist_sq < r * r then
    local factor = self.approach_factor * (math.sqrt(dist_sq) / r) * self.max_vel
    desired:set(desired.x * factor, desired.y * factor) 
  else
    desired:set(desired.x * self.max_vel, desired.y * self.max_vel)
  end
  
  local force = self.force_vector
  force:set(desired.x - self.point.vel.x, desired.y - self.point.vel.y)
  if force:mag_sq() > self.max_force * self.max_force then
    force:set(self.max_force * dir.x, self.max_force * dir.y)
  end
  
  return force
end

------------------------------------------------------------------------------
function steer:update(dt)
  if self.target then
    local force = self:_get_steer_force()
    self.point:add_force(force)
  end
  
  self.point:update(dt)
end

------------------------------------------------------------------------------
function steer:draw()
  lg.setColor(255,0,0,255)
  lg.setPoint(4, "smooth")
  lg.point(self.point.pos:get_vals())
  
  if self.target then
    lg.setColor(0,255,0,150)
    lg.point(self.target:get_vals())
    lg.circle("line", self.target.x, self.target.y, self.slow_radius)
  end
end


return { point = point,
         steer = steer}












