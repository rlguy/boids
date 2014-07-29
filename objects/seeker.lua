local lg = love.graphics
local vector3 = require("vector3")

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- seeker object - follows a point in 3d space
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local sk = {}
sk.table = 'sk'
sk.position = nil
sk.direction = nil
sk.velocity = nil
sk.acceleration = nil
sk.target = nil

sk.scale = 20     -- pixels / meter
sk.mass = 1
sk.inv_mass = 1 / sk.mass

sk.max_speed = 0.8
sk.max_force = 15

sk.current_angle = nil   -- angle on x,y plane
sk.current_zangle = nil  -- up/down angle respective to x,y plane
sk.angle_speed = 0

sk.is_boundec = false
sk.boundary_bbox = nil

local sk_mt = { __index = sk }
function sk:new(x, y, z)
  local sk = setmetatable({}, sk_mt)
  x, y, z = x or 0, y or 0, z or 0
  
  sk.position = {x = x, y = y, z = z}
  sk.direction = {x = 0, y = 1, z = 0}
  sk.velocity = {x = 0, y = 0, z = 0}
  sk.acceleration = {x = 0, y = 0, z = 0}
  sk.force = {x = 0, y = 0, z = 0}
  sk.target = {x = 0, y = 0, z = 0}
  sk.boundary_bbox = bbox:new(0, 0, 0, 0)
  
  sk.current_angle = math.atan2(sk.direction.y, sk.direction.x)
  
  return sk
end

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- Public
--[[----------------------------------------------------------------------]]--
--##########################################################################--

function sk:set_position(x, y, z)
  vector3.set(self.position, x, y, z)
end

function sk:set_direction(dx, dy, dz)
  vector3.set(self.direction, dx, dy, dz)
  local speed = vector3.len(self.velocity)
  vector3.set(self.velocity, dx * speed, dy * speed, dz * speed)
end

function sk:set_target(x, y, z)
  vector3.set(self.target, x, y, z)
end

function sk:add_force(fx, fy, fz)
  vector3.add(self.force, fx, fy, fz)
end

function sk:set_mass(m)
  if m == 0 then return end
  
  self.mass = m
  self.inv_mass = 1 / m
end

function sk:set_scale(s)
  if s <= 0 then return end
  self.scale = s
end

function sk:get_rotation_angle()
  return self.rotation_angle
end

function sk:get_roll_speed()
  return self.angle_speed
end

function sk:get_pitch_angle()
  return self.current_zangle
end

function sk:get_position()
  return self.position.x, self.position.y, self.position.z
end

function sk:get_direction()
  return self.direction.x, self.direction.y, self.direction.z
end

function sk:set_bounds(x, y, width, height, depth)
  self.boundary_bbox.x = x
  self.boundary_bbox.y = y
  self.boundary_bbox.width = width
  self.boundary_bbox.height = height
  self.boundary_bbox.depth = depth
  self.is_bounded = true
end

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- Private
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function sk:_update_position(dt)
  -- calculate acceleration (F = ma)
  local acc = self.acceleration
  local force = self.force
  local imass = self.inv_mass
  vector3.set(acc, force.x * imass, force.y * imass, force.z * imass)
  
  -- calculate velocity
  local vel = self.velocity
  vector3.set(vel, vel.x + acc.x * dt, vel.y + acc.y * dt, vel.z + acc.z * dt)
  
  -- calculate position
  local pos = self.position
  local s = self.scale
  vector3.set(pos, pos.x + s*vel.x * dt, pos.y + s*vel.y * dt, pos.z + s*vel.z * dt)
  
  vector3.set_zero(force)
  
  self:_update_boundary()
end

function sk:_update_boundary()
  local p = self.position
  local b = self.boundary_bbox
  
  if b:contains_coordinate(p.x, p.y) and p.z > 0 and p.z < b.depth then
    return
  end
  
  local eps = 0.0001
  if p.x < b.x then
    p.x = b.x
  elseif p.x > b.x + b.width then
    p.x = b.x + b.width - eps
  end
  
  if p.y < b.y then
    p.y = b.y
  elseif p.y > b.y + b.height then
    p.y = b.y + b.height - eps
  end
  
  if p.z < 0 then
    p.z = 0
  elseif p.z > b.depth then
    p.z = b.depth
  end
end

function sk:_update_steering(dt)
  local pos = self.position
  local targ = self.target
  
  -- desired velocity
  local desx, desy, desz = targ.x - pos.x, targ.y - pos.y, targ.z - pos.z
  local len = math.sqrt(desx*desx + desy*desy + desz*desz)
  if len == 0 then
    return
  end
  local fact = (1/len) * self.max_speed * self.scale
  desx, desy, desz = desx * fact, desy * fact, desz * fact
  
  -- steering force
  local vel = self.velocity
  local steerx, steery, steerz = desx - vel.x, desy - vel.y, desz - vel.z
  local lensqr = steerx*steerx + steery*steery + steerz*steerz
  if lensqr > self.max_force * self.max_force then
    local fact = (1 / math.sqrt(lensqr)) * self.max_force
    steerx, steery, steerz = steerx * fact, steery * fact, steerz * fact
  end
  
  self:add_force(steerx, steery, steerz)
end

function sk:_update_direction(dt)
  -- calculate direction
  local vel = self.velocity
  local len = vector3.len(vel)
  if len > 0 then
    local ilen = 1 / len
    vector3.set(self.direction, vel.x * ilen, vel.y * ilen, vel.z * ilen)
  end
  
  -- (x,y) plane angle
  local dx, dy = self.direction.x, self.direction.y
  local len = math.sqrt(dx*dx + dy*dy)
  if len == 0 then
    return
  end
  local ilen = 1/len
  dx, dy = dx * ilen, dy*ilen
  local angle = math.atan2(dy, dx)
  self.rotation_angle = angle
  
  local angle_speed = (angle - self.current_angle)
  if self.current_angle < 0 and angle > 0 and self.angle_speed < 0 then
    angle_speed = angle_speed - 2*math.pi
  elseif self.current_angle > 0 and angle < 0 and self.angle_speed > 0 then
    angle_speed =  angle_speed + 2*math.pi
  end
  angle_speed = angle_speed / dt
  
  self.angle_speed = angle_speed
  self.current_angle = angle
  
  -- pitch angle
  local dx, dy, dz = dx, dy, 0
  local ux, uy, uz = self.direction.x, self.direction.y, self.direction.z
  local zangle = 0
  if uz ~= 0 then
    zangle = math.acos(dx*ux + dy*uy + dz*uz)
    if uz < 0 then
      zangle = -zangle
    end
  end
  self.current_zangle = zangle
  
end

function sk:update(dt)
  self:_update_steering(dt)
  self:_update_position(dt)
  self:_update_direction(dt)
end


function sk:draw()
  local p = self.position
  lg.setPointStyle("rough")
  lg.setPointSize(5)
  lg.setColor(0, 0, 0, 255)
  lg.point(p.x, p.y)
  lg.circle("line", p.x, p.y, 10)
  
  local t = self.target
  lg.setColor(255, 0, 0, 255)
  lg.point(t.x, t.y)
  lg.circle("line", t.x, t.y, 10)
  
  local len = 20
  local d = self.direction
  local px, py = p.x + len * d.x, p.y + len * d.y
  lg.line(p.x, p.y, px, py)
  lg.circle("line", p.x, p.y, len)
  
end

return sk






















