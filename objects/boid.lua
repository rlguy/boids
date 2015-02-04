local vector3 = require("vector3")

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- boid object - a boid in 3d space
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local bd = {}
bd.table = 'bd'
bd.debug = false
bd.flock = nil
bd.position = nil
bd.direction = nil
bd.target = nil
bd.default_direction = {x = 1, y = 0, z = 0}
bd.collider = nil

bd.graphic_width = 17
bd.graphic_height = 24
bd.min_roll_angle = 0
bd.max_roll_angle = math.pi / 2.4
bd.min_roll_speed = 0
bd.max_roll_speed = 4
bd.min_scale = 0.5
bd.max_scale = 1.3
bd.field_of_view = 1.3 * math.pi
bd.sight_radius = 200
bd.separation_radius = 0.2 * bd.sight_radius
bd.boundary_zpad = 200
bd.boundary_ypad = 200
bd.boundary_xpad = 200
bd.boundary_vector_mix_ratio = 0.25           -- mixes normal to reflected projection
bd.obstacle_vector_mix_ratio = 0.5
bd.max_obstacle_reflect_angle = math.pi / 4
bd.max_boundary_reflect_angle = math.pi / 3  -- boundary rule vector is reflected
                                             -- if angle between boundary normal
                                             -- and boid direction is less than this
                                             -- angle.
                                             -- helps boids steer away from boundary

                                             
bd.neighbours = nil
bd.neighbours_in_view = nil
bd.frames_per_neighbour_update = 20
bd.neighbour_frame_offset = nil
bd.neighbour_frame_count = 0

bd.rule_weights = nil
bd.vector_length = 200
bd.waypoint = nil
bd.alignment_vector = nil
bd.cohesion_vector = nil
bd.separation_vector = nil
bd.boundary_vector = nil
bd.waypoint_vector = nil
bd.obstacle_vector = nil

bd.seeker = nil
bd.graphic = nil

bd.is_initialized = false
bd.temp_vector = nil

local bd_mt = { __index = bd }
function bd:new(level, parent_flock, x, y, z, dirx, diry, dirz)
  local bd = setmetatable({}, bd_mt)
  bd.level = level
  
  bd.position = {}
  bd.direction = {}
  bd.target = {x = 0, y = 0, z = 0}
  bd.temp_vector = {}
  bd.neighbours = {}
  bd.neighbours_in_view = {}
  bd:_init_map_point(x, y, parent_flock)
  bd:_init_boid_seeker()
  bd:_init_boid_graphic()
  bd:_init_rule_vectors()
  bd:_init_waypoint()
  
  if level and parent_flock and x and y and z then
    bd:init(level, parent_flock, x, y, z, dirx, diry, dirz)
  end
  
  return bd
end

function bd:_init_waypoint()
  local waypoint = {}
  waypoint.is_active = false
  waypoint.x = 0
  waypoint.y = 0
  waypoint.z = 0
  waypoint.inner_radius = 0
  waypoint.outer_radius = 0
  waypoint._default_inner_radius = 100
  waypoint._default_outer_radius = 200
  waypoint._min_power = 0.5
  waypoint._max_power = 1
  self.waypoint = waypoint
end

function bd:_init_rule_vectors()
  self.alignment_vector = {}
  self.cohesion_vector = {}
  self.separation_vector = {}
  self.boundary_vector = {}
  self.waypoint_vector = {}
  self.obstacle_vector = {}
  self:_clear_rule_vectors()
  
  local weights = {}
  weights[self.alignment_vector]  = 0.5
  weights[self.cohesion_vector]   = 0.2
  weights[self.separation_vector] = 3
  weights[self.boundary_vector]   = 3
  weights[self.waypoint_vector]   = 1
  weights[self.obstacle_vector]   = 8
  self.rule_weights = weights
end

function bd:_clear_rule_vectors()
  vector3.set(self.alignment_vector, 0, 0, 0)
  vector3.set(self.cohesion_vector, 0, 0, 0)
  vector3.set(self.separation_vector, 0, 0, 0)
  vector3.set(self.boundary_vector, 0, 0, 0)
  vector3.set(self.waypoint_vector, 0, 0, 0)
  vector3.set(self.obstacle_vector, 0, 0, 0)
end

function bd:_init_boid_seeker()
  self.seeker = seeker:new(0, 0)
end

function bd:_init_boid_graphic()
  self.body_graphic = boid_graphic:new(self.graphic_width, self.graphic_height)
end

function bd:_init_map_point(x, y)
  -- to get a position on the map
  local tmap = self.level:get_level_map().tile_maps[1]
  x, y = x or tmap.bbox.x + TILE_WIDTH, y or tmap.bbox.y + TILE_HEIGHT
  
  self.map_point = map_point:new(self.level, vector2:new(x, y))
end

function bd:init(parent_flock, x, y, z, dirx, diry, dirz)
  if not parent_flock or not x or not y or not z then
    print("Error in boid:init() - missing parameter")
    return
  end

  if not parent_flock:contains_point(x, y, z) then
    print("Error in boid:init() - point outside of flock region")
    return
  end

  -- orientation
  vector3.set(self.position, x, y, z)
  if dirx and diry and dirz then
    vector3.set(self.direction, dirx, diry, dirz)
  else
    local dx, dy, dz = random_direction3()
    vector3.set(self.direction, dx, dy, dz)
  end
  
  -- seeker
  self.flock = parent_flock
  local b = self.flock:get_bbox()
  self.seeker:set_position(self.position.x, self.position.y, self.position.z)
  self.seeker:set_bounds(b.x, b.y, b.width, b.height, b.depth)
  
  -- collider
  self.collider = parent_flock:get_collider()
  self.map_point:update_position(vector2:new(self.position.x, self.position.y))
  self.collider:add_object(self.map_point, self)
  
  -- neighbour update
  self.neighbour_frame_offset = math.random(1, self.frames_per_neighbour_update)
  self.neighbour_frame_count = self.neighbour_frame_offset
  
  self:_clear_rule_vectors()
  
  self.is_initialized = true
end

function bd:set_position(x, y, z)
  vector3.set(self.position, x, y, z)
  self.seeker:set_position(x, y, z)
  
  local pos = self.temp_vector
  vector3.set(pos, x, y, nil)
  self.map_point:update_position(pos)
end

function bd:set_gradient(grad_table)
  self.body_graphic:set_gradient(grad_table)
end

function bd:get_position()
  return self.position.x, self.position.y, self.position.z
end

function bd:get_velocity()
  return self.seeker.velocity
end

function bd:set_direction(dx, dy, dz)
  vector3.set(self.direction, dx, dy, dz)
  self.seeker:set_direction(dx, dy, dz)
end

function bd:set_waypoint(x, y, z, inner_radius, outer_radius)
  if inner_radius and outer_radius and inner_radius <= outer_radius then
  else
    inner_radius = self.waypoint._default_inner_radius
    outer_radius = self.waypoint._default_outer_radius
  end

  z = z or 0.5 * self.flock.bbox.depth
  local w = self.waypoint
  w.x, w.y, w.z = x, y, z
  w.inner_radius, w.outer_radius = inner_radius, outer_radius
  w.is_active = true
end

function bd:clear_waypoint()
  self.waypoint.is_active = false
end

function bd:destroy()
  self.collider:remove_object(self.map_point)
  self:clear_waypoint()
end


------------------------------------------------------------------------------
function bd:_update_seeker(dt)
  local t = self.target  
  self.seeker:set_target(t.x, t.y, t.z)
  self.seeker:update(dt)
end

function bd:_handle_tile_collision(normal, point, offset, tile)
  local dir = self.direction
  
  local dot = dir.x * normal.x + dir.y * normal.y + dir.z * 0
  local rx = -2 * dot * normal.x + dir.x
  local ry = -2 * dot * normal.y + dir.y
  local rz = -2 * dot * 0 + dir.z
  
  local len = math.sqrt(rx*rx + ry*ry + rz*rz)
  if len == 0 then return end
  local inv = 1 / len
  rx, ry, rz = rx * inv, ry * inv, rz * inv
  
  local jog = 3
  local x, y, z = point.x + jog * normal.x, point.y + jog * normal.y, self.position.z
  self:set_position(x, y, z)
  
  self:set_direction(rx, ry, rz)
end

function bd:_update_map_point(dt)
  local x, y, z = self.seeker:get_position()
  self.map_point:set_position_coordinates(x, y)
  self.map_point:update(dt)
  self.collider:update_object(self.map_point)
  
  local collided, normal, collision_point, 
        collision_offset, collsion_tile = self.map_point:get_collision_data()
  if collided then
    self:_handle_tile_collision(normal, collision_point, collision_offset, collision_tile)
  end
end

function bd:_update_graphic_orientation(dt)
  local graphic = self.body_graphic
  local seeker = self.seeker
  local x, y, z = seeker:get_position()
  graphic:set_rotation_angle(seeker:get_rotation_angle())
  graphic:set_pitch_angle(seeker:get_pitch_angle())
  graphic:set_altitude(z)
  
  local mina, maxa = self.min_roll_angle, self.max_roll_angle
  local mins, maxs = self.min_roll_speed, self.max_roll_speed
  local roll_speed = seeker:get_roll_speed()
  local absv = math.abs(roll_speed)
  local prog =  (absv - mins) / (maxs - mins)
  local roll_angle = lerp(mina, maxa, prog)
  if roll_speed < 0 then
    roll_angle = -roll_angle
  end
  graphic:set_roll_angle(roll_angle)
  
  local minz, maxz = 0, self.flock.bbox.depth
  local mins, maxs = self.min_scale, self.max_scale
  z = math.min(maxz, z)
  z = math.max(minz, z)
  local prog = (z - minz) / (maxz - minz)
  local scale = lerp(mins, maxs, prog)
  graphic:set_scale(scale)
  
  graphic:update(dt)
end

function bd:_update_boid_orientation(dt)
  local x, y, z = self.seeker:get_position()
  local dx, dy, dz = self.seeker:get_direction()
  vector3.set(self.position, x, y, z)
  vector3.set(self.direction, dx, dy, dz)
end

function bd:_update_neighbours_in_view()
  local view = self.neighbours_in_view
  local nbs = self.neighbours
  table.clear(view)
  local idx = 1
  
  local p1 = self.position
  local dir = self.direction
  local max_angle = 0.5 * self.field_of_view
  for i=1,#nbs do
    local b = nbs[i]
    if b ~= self then
      local p2 = b.position
      local dx, dy, dz = p2.x - p1.x, p2.y - p1.y, p2.z - p1.z
      if not (dx == 0 and dy == 0 and dz == 0) then
        local invlen = 1 / math.sqrt(dx*dx + dy*dy + dz*dz)
        dx, dy, dz = invlen * dx, invlen * dy, invlen * dz
        local angle = math.acos(dx*dir.x + dy*dir.y + dz*dir.z)
        if angle < max_angle then
          view[idx] = b
          idx = idx + 1
        end
      end
    end
  end
end

function bd:_update_neighbours()
  self.neighbour_frame_count = self.neighbour_frame_count + 1
  if self.neighbour_frame_count % self.frames_per_neighbour_update ~= 0 then
    return
  end

  local p = self.position
  local nbs = self.neighbours
  table.clear(nbs)
  self.flock:get_boids_in_sphere(p.x, p.y, p.z, self.sight_radius, nbs)
  
  self:_update_neighbours_in_view()
end

function bd:_update_alignment_rule(dt)
  if #self.neighbours_in_view == 0 then return end
  
  local nbs = self.neighbours_in_view
  local align = self.alignment_vector
  for i=1,#nbs do
    local v = nbs[i].seeker.velocity
    align.x, align.y, align.z = align.x + v.x, align.y + v.y, align.z + v.z
  end
  local inv = 1 / #nbs 
  align.x, align.y, align.z = inv * align.x, inv * align.y,  inv * align.z
  local len = vector3.len(align)
  
  if len == 0 then return end
  
  local invlen = 1 / len
  align.x, align.y, align.z = invlen * align.x, invlen * align.y, invlen * align.z
  
end

function bd:_update_cohesion_rule(dt)
  if #self.neighbours_in_view == 0 then return end
  
  local nbs = self.neighbours_in_view
  local coh = self.cohesion_vector
  local p1 = self.position
  for i=1,#nbs do
    local p2 = nbs[i].position
    local dx, dy, dz = p2.x - p1.x, p2.y - p1.y, p2.z - p1.z
    coh.x, coh.y, coh.z = coh.x + dx, coh.y + dy, coh.z + dz 
  end
  local inv = 1 / #nbs
  coh.x, coh.y, coh.z = coh.x * inv, coh.y * inv, coh.z * inv
  local len = vector3.len(coh)
  
  if len == 0 then
    return
  end
  
  local invlen = 1 / len
  coh.x, coh.y, coh.z = invlen * coh.x, invlen * coh.y, invlen * coh.z
end

function bd:_update_separation_rule(dt)
  if #self.neighbours_in_view == 0 then return end
  
  local nbs = self.neighbours_in_view
  local sep = self.separation_vector
  local p1 = self.position
  local rsq = self.separation_radius * self.separation_radius
  local count = 0
  for i=1,#nbs do
    local p2 = nbs[i].position
    local dx, dy, dz = p2.x - p1.x, p2.y - p1.y, p2.z - p1.z
    local lensqr = dx*dx + dy*dy + dz*dz
    if lensqr < rsq and lensqr > 0 then
      sep.x, sep.y, sep.z = sep.x - dx, sep.y - dy, sep.z - dz
      count = count + 1
    end
  end
  
  if count == 0 then return end
  
  local inv = 1 / count
  sep.x, sep.y, sep.z = sep.x * inv, sep.y * inv, sep.z * inv
  local len = vector3.len(sep)
  
  if len == 0 then return end
  
  local invlen = 1 / len
  sep.x, sep.y, sep.z = sep.x * invlen, sep.y * invlen, sep.z * invlen
  
end

function bd:_update_boundary_rule()
  local p = self.position
  local bbox = self.flock:get_bbox()
  local xpad, ypad, zpad = self.boundary_xpad, self.boundary_ypad, self.boundary_zpad
  local bvect = self.boundary_vector
  
  local min_x = bbox.x + xpad
  local max_x = bbox.x + bbox.width - xpad
  local min_y = bbox.y + ypad
  local max_y = bbox.y + bbox.height - ypad
  local min_z = 0 + zpad
  local max_z = bbox.depth - zpad
  local xpower, ypower, zpower = 0, 0, 0
  
  if p.x < min_x then
    xpower = 1 - ((p.x - bbox.x) / xpad)
    bvect.x = (bvect.x + 1) * xpower
  elseif p.x > max_x then
    xpower = (p.x - max_x) / xpad
    bvect.x = (bvect.x - 1) * xpower
  end
  
  if p.y < min_y then
    ypower = 1 - ((p.y - bbox.y) / ypad)
    bvect.y = (bvect.y + 1) * ypower
  elseif p.y > max_y then
    ypower = (p.y - max_y) / ypad
    bvect.y = (bvect.y - 1) * ypower
  end
  
  if p.z < min_z then
    zpower = 1 - ((p.z - 0) / zpad)
    bvect.z = (bvect.z + 1) * zpower
  elseif p.z > max_z then
    zpower = (p.z - max_z) / zpad
    bvect.z = (bvect.z - 1) * zpower
  end
  
  if xpower == 0 and ypower == 0 and zpower == 0 then
    return
  end
  
  local invlen = 1 / vector3.len(bvect)
  bvect.x, bvect.y, bvect.z = bvect.x * invlen, bvect.y * invlen, bvect.z * invlen
  
  -- reflect direction of void using normal bvect
  local dir = self.direction
  local dot = dir.x * bvect.x + dir.y * bvect.y + dir.z * bvect.z
  local angle = math.acos(-dot)
  local eps = 0.0001
  if angle > eps and angle < self.max_boundary_reflect_angle then
    local dot = dir.x * bvect.x + dir.y * bvect.y + dir.z * bvect.z
    local rx = -2 * dot * bvect.x + dir.x
    local ry = -2 * dot * bvect.y + dir.y
    local rz = -2 * dot * bvect.z + dir.z
    
    -- project reflected vector onto plane normal to bvect
    local dot = rx * bvect.x + ry * bvect.y + rz * bvect.z
    local dx = rx - dot * bvect.x
    local dy = ry - dot * bvect.y 
    local dz = rz - dot * bvect.z
    
    local len = math.sqrt(dx*dx + dy*dy + dz*dz)
    if len > 0 then
      local invlen = 1 / len
      dx, dy, dz = dx*invlen, dy*invlen, dz*invlen
      
      -- mix projected reflection vector with normal vector (bvect)
      local r = self.boundary_vector_mix_ratio
      dx = r * bvect.x + (1-r) * dx
      dy = r * bvect.y + (1-r) * dy
      dz = r * bvect.z + (1-r) * dz
      len = math.sqrt(dx*dx + dy*dy + dz*dz)
      if len > 0 then
        local invlen = 1 / len
        bvect.x, bvect.y, bvect.z = invlen * dx, invlen * dy, invlen * dz
      end
    end
  end
  
end

function bd:_update_waypoint_rule()
  if not self.waypoint.is_active then return end

  local p = self.position
  local w = self.waypoint
  local wv = self.waypoint_vector
  local dx, dy, dz = w.x - p.x, w.y - p.y, w.z - p.z
  local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
  
  if dist == 0 then 
    self:_clear_waypoint()
    return 
  end
  local min, max = w._min_power, w._max_power
  local power = 1
  if dist < w.outer_radius then
    local prog = (dist - w.inner_radius) / (w.outer_radius - w.inner_radius)
    power = min + prog * (max - min)
  end
  
  local factor = (1 / dist) * power
  wv.x, wv.y, wv.z = dx * factor * power, dy * factor * power, dz * factor * power
  
  if dist < w.inner_radius then
    self:clear_waypoint()
  end
end

function bd:_update_obstacle_rule()
  local vect = self.obstacle_vector
  local level_map = self.level:get_level_map()
  local nx, ny, val = level_map:get_field_vector_at_position(self.position)
  vect.x, vect.y, vect.z = nx, ny, 0
  
  if vect.x == 0 and vect.y == 0 then 
    return
  end
  
  -- reflect direction of using normal vect
  local dir = self.direction
  local dot = dir.x * vect.x + dir.y * vect.y + dir.z * vect.z
  local angle = math.acos(-dot)
  local eps = 0.0001
  if angle > eps and angle < self.max_obstacle_reflect_angle then
    local dot = dir.x * vect.x + dir.y * vect.y + dir.z * vect.z
    local rx = -2 * dot * vect.x + dir.x
    local ry = -2 * dot * vect.y + dir.y
    local rz = -2 * dot * vect.z + dir.z
    
    -- project reflected vector onto plane normal to bvect
    local dot = rx * vect.x + ry * vect.y + rz * vect.z
    local dx = rx - dot * vect.x
    local dy = ry - dot * vect.y 
    local dz = rz - dot * vect.z
    
    local len = math.sqrt(dx*dx + dy*dy + dz*dz)
    if len > 0 then
      local invlen = 1 / len
      dx, dy, dz = dx*invlen, dy*invlen, dz*invlen
      
      -- mix projected reflection vector with normal vector (bvect)
      local r = self.obstacle_vector_mix_ratio
      dx = r * vect.x + (1-r) * dx
      dy = r * vect.y + (1-r) * dy
      dz = r * vect.z + (1-r) * dz
      len = math.sqrt(dx*dx + dy*dy + dz*dz)
      if len > 0 then
        local factor = (1 / len) * val
        vect.x, vect.y, vect.z = factor * dx, factor * dy, factor * dz
      end
    end
  end
end

function bd:_update_rules(dt)
  self:_clear_rule_vectors()
  self:_update_alignment_rule(dt)
  self:_update_cohesion_rule(dt)
  self:_update_separation_rule(dt)
  self:_update_boundary_rule(dt)
  self:_update_waypoint_rule(dt)
  self:_update_obstacle_rule(dt)
end

function bd:_update_target(dt)
  local weights = self.rule_weights
  local targx, targy, targz = 0, 0, 0
  local mag = self.vector_length
  local n = 0
  for vect,weight in pairs(weights) do
    if not (vect.x == 0 and vect.y == 0 and vect.z == 0) then
      targx = targx + vect.x * mag * weight
      targy = targy + vect.y * mag * weight
      targz = targz + vect.z * mag * weight
      n = n + 1
    end
  end
  if n > 0 then 
    local inv = 1 / n
    local p = self.position
    targx, targy, targz = targx * inv, targy * inv, targz * inv
    vector3.set(self.target, targx + p.x, targy + p.y, targz + p.z)
  else
    local p = self.position
    local dir = self.direction
    targx, targy, targz = p.x + mag * dir.x, p.y + mag * dir.y, p.z + mag * dir.z
    vector3.set(self.target, targx, targy, targz)
  end
end

function bd:update(dt)
    if not self.is_initialized then return end
    self:_update_neighbours(dt)
    self:_update_rules(dt)
    self:_update_target(dt)
    self:_update_seeker(dt)
    self:_update_map_point(dt)
    self:_update_graphic_orientation(dt)
    self:_update_boid_orientation(dt)
end

function bd:draw_shadow()
  local x, y, z = self:get_position()
  self.body_graphic:draw_shadow(x, y)
end

------------------------------------------------------------------------------
function bd:_draw_debug_rule_vector(vector, label)
  local v = vector
  local x1, y1 = self.position.x, self.position.y
  if not (v.x == 0 and v.y == 0 and v.z == 0) then
    local len = self.sight_radius
    local x2, y2 = x1 + v.x * len, y1 + v.y * len
    lg.setColor(255, 255, 0, 255)
    lg.setLineWidth(3)
    lg.line(x1, y1, x2, y2)
    lg.setColor(255, 255, 0, 255)
    lg.print(label, x2, y2)
  end
  
end

function bd:draw_debug()
  lg.setColor(0, 100, 255, 255)

  
  -- selection circle
  local r = 3
  lg.circle("fill", self.position.x, self.position.y, r)
  lg.point(self.position.x, self.position.y)
  
  local len = 30
  local d = self.direction
  local x1, y1 = self.position.x, self.position.y
  local x2, y2 = x1 + len * d.x, y1 + len * d.y
  lg.setColor(0, 100, 255, 255)
  lg.setLineWidth(1)
  lg.line(x1, y1, x2, y2)
  
  -- sight
  lg.setColor(0, 0, 0, 255)
  lg.circle("line", x1, y1, self.sight_radius)
  
  
  -- neigbours in view
  local nbs = self.neighbours_in_view
  local len = 10
  lg.setColor(0, 0, 0, 255)
  for i=1,#nbs do
    local b = nbs[i]
    if b ~= self then
      local x, y = b.position.x, b.position.y
      lg.line(x-len, y, x+len, y)
      lg.line(x, y-len, x, y+len)
      lg.circle("fill", x, y, len)
    end
  end
  
  -- field of view
  local angle = self.seeker:get_rotation_angle() + math.pi / 2
  local fov_angle = 0.5 * self.field_of_view
  local min_angle = angle - fov_angle
  local max_angle = angle + fov_angle
  local dirx1, diry1 = math.sin(min_angle), -math.cos(min_angle)
  local dirx2, diry2 = math.sin(max_angle), -math.cos(max_angle)
  local len = self.sight_radius
  local p1x, p1y = x1 + len * dirx1, y1 + len * diry1
  local p2x, p2y = x1 + len * dirx2, y1 + len * diry2
  lg.setColor(0, 0, 0, 255)
  lg.line(x1, y1, p1x, p1y)
  lg.line(x1, y1, p2x, p2y)
  
  
  self:_draw_debug_rule_vector(self.alignment_vector, "Align")
  self:_draw_debug_rule_vector(self.cohesion_vector, "Cohesion")
  self:_draw_debug_rule_vector(self.separation_vector, "Separation")
  self:_draw_debug_rule_vector(self.boundary_vector, "Boundary")
  self:_draw_debug_rule_vector(self.waypoint_vector, "Waypoint")
  self:_draw_debug_rule_vector(self.obstacle_vector, "Obstacle")
  
  -- target
  local t = self.target
  local p = self.position
  local dx, dy, dz = t.x - p.x, t.y - p.y, t.z - p.z
  local len = math.sqrt(dx*dx + dy*dy + dz*dz)
  if len > 0 then
    dx, dy, dz = dx/len, dy/len, dz/len
    local r = self.sight_radius
    local x2, y2 = x1 + dx * r, y1 + dy * r
    lg.setColor(255, 255, 0, 255)
    lg.setLineWidth(3)
    lg.line(x1, y1, x2, y2)
    lg.print("Target", x2, y2)
  end
  
  -- waypoint sphere
  if self.waypoint.is_active then
    local w = self.waypoint
    local x, y, z = w.x, w.y, w.z
    local r1, r2 = w.inner_radius, w.outer_radius
    
    local p = self.position
    local dx, dy, dz = x - p.x, y - p.y, z - p.z
    local lensqr = dx*dx + dy*dy + dz*dz
    if lensqr < r1 then
      lg.setColor(0, 0, 255, 50)
    else
      lg.setColor(255, 0, 0, 50)
    end
    lg.circle("fill", x, y, r1)
    
    lg.setColor(255, 0, 0, 255)
    lg.circle("line", x, y, r1)
    lg.circle("line", x, y, r2)
  end
  
  
  
  self.seeker:draw()
end

function bd:draw()
  if not self.is_initialized then return end
  
  local x, y, z = self:get_position()
  self.body_graphic:draw(x, y)
  
  --[[
  lg.setLineWidth(1)
  lg.setColor(0, 0, 0, 10)
  for i=1,#self.neighbours do
    local b = self.neighbours[i]
    lg.line(x, y, b.position.x, b.position.y)
  end
  ]]--
end

return bd



