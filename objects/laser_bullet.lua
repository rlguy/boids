
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- laser_bullet object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local laser_bullet = {}
local lb = laser_bullet
lb.table = 'laser_bullet'
lb.debug = false
lb.level = nil
lb.collider = nil
lb.raycaster = nil
lb.parent = nil
lb.owner = nil
lb.level = nil
lb.speed = 800
lb.min_tail_speed = 0.3 * lb.speed
lb.length = 100
lb.current_length = 0
lb.collision_normals = nil
lb.temp_vect = nil
lb.temp_vect2 = nil
lb.temp_bbox = nil
lb.temp_table = nil

lb.path_length = 2000
lb.remaining_path_length = lb.path_length
lb.path = nil                                               
lb.num_segments = nil
lb.laser_segments = nil
lb.segment_directions = nil
lb.segment_lengths = nil
lb.wall_collision_radii = nil
lb.head_segment = 1
lb.tail_segment = 1

lb.head_length = 0
lb.tail_length = 0
lb.total_distance_travelled = 0
lb.tail_distance_travelled = 0
lb.head_finished = false
lb.tail_finished = false
lb.head_x = nil
lb.head_y = nil
lb.tail_x = nil
lb.tail_y = nil
lb.is_dead = false

-- draw
lb.num_overlays = 10
lb.overlay_time = 0.01
lb.overlays = nil
lb.overlay_timer = nil

-- explosion
lb.min_shard_power = 0.05
lb.max_shard_power = 0.2
lb.min_tile_power = 0.2
lb.max_tile_power = 0.6
lb.max_power_distance = 1500

-- shake
lb.min_shake_time = 5
lb.max_shake_time = 12
lb.min_shake_power = 0
lb.max_shake_power = 0.1

-- collision check
lb.collision_radius = 75
lb.collision_bbox = nil
lb.collision_length = 100
lb.collision_head = nil
lb.collision_tail = nil
lb.collision_center = nil
lb.handled_collisions = nil   -- objects that have already been collided with
lb.collision_objects = nil  -- table for containing a set of potential collisions
lb.collision_zone_active = false
lb.kill_radius = 7
lb.throw_radius = 20
lb.max_collision_distance = 55
lb.min_throw_dist = 50
lb.max_throw_dist = 200
lb.min_push_dist = 20
lb.max_push_dist = 100
lb.tblock_collision_power = 1

lb.min_wall_collision_radius = 100
lb.max_wall_collision_radius = 250
lb.min_explosion_throw_dist = 200
lb.max_explosion_throw_dist = 400

local laser_bullet_mt = { __index = laser_bullet }
function laser_bullet:new(level)
  local lb = setmetatable({}, laser_bullet_mt)
  lb.level = level
  lb.collider = level:get_collider()
  lb.temp_vect = vector2:new(0, 0)
  lb.temp_vect2 = vector2:new(0, 0)
  lb.temp_bbox = bbox:new(0, 0, 0, 0)
  lb.laser_segments = {}
  lb.segment_lengths = {}
  lb.segment_directions = {}
  lb.wall_collision_radii = {}
  lb.temp_table = {}
  
  lb.path = {}
  lb.collision_normals = {}
  
  local r = lb.collision_radius
  lb.collision_bbox = bbox:new(0, 0, 2 * r, 2 * r)
  lb.collision_head = vector2:new(0, 0)
  lb.collision_tail = vector2:new(0, 0)
  lb.collision_center = vector2:new(0, 0)
  lb.collision_objects = {}
  lb.handled_collisions = {}
  
  lb.overlays = {}
  for i=1,lb.num_overlays do
    lb.overlays[i] = {}
  end
  lb.overlay_timer = timer:new(level:get_master_timer(), lb.overlay_time)
  
  return lb
end

function laser_bullet:set_parent(obj)
  self.parent = obj
end
function laser_bullet:set_owner(obj)
  self.owner = obj
end

function laser_bullet:_init_path_data(path)
  local segment_dirs = self.segment_directions
  local segment_lens = self.segment_lengths
  table.clear(segment_dirs)
  table.clear(segment_lens)
  
  local segment_idx = 1
  for i=1,#path-2,2 do
    local x1, y1, x2, y2 = path[i], path[i+1], path[i+2], path[i+3]
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then
      len = 0.000001
    end
    local invlen = 1 / len
    segment_dirs[i], segment_dirs[i + 1] = dx * invlen, dy * invlen
    segment_lens[segment_idx] = len
    segment_idx = segment_idx + 1
  end
  self.num_segments = segment_idx - 1
  
  -- wall explosions radii
  local radii = self.wall_collision_radii
  table.clear(radii)
  local total_dist = 0
  local max_r, min_r = self.max_wall_collision_radius, self.min_wall_collision_radius
  local max_d = self.max_power_distance
  for i=1,#segment_lens do
    total_dist = total_dist + segment_lens[i]
    local ratio = math.max(1 - (total_dist / max_d), 0)
    local radius = min_r + ratio * (max_r - min_r)
    radii[i] = radius
  end
  
end

function laser_bullet:init(position, direction, raycaster, depth)
  -- raycast
  self.remaining_path_length = self.path_length
  self.depth = depth or 1
  self.raycaster = raycaster
  raycaster:set(position, direction, self.path_length)
  raycaster:cast(depth)
  local path = raycaster:get_line()
  local collision_normals = raycaster:get_normals()
  
  table.clear(self.path)
  table.copy(path, self.path)
  self:_init_path_data(self.path)
  
  
  table.clear(self.collision_normals)
  for i=1,#collision_normals do
    local idx = 2*i - 1
    self.collision_normals[idx], self.collision_normals[idx + 1] = collision_normals[i]:get_vals()
  end
  table.clear_hash(self.handled_collisions)
  
  
  -- laser position data
  local lsegs = self.laser_segments
  table.clear(lsegs)
  lsegs[1], lsegs[2], lsegs[3], lsegs[4] = path[1], path[2], path[1], path[2]
  self.head_x, self.head_y = path[1], path[2]
  self.tail_x, self.tail_y = path[1], path[2]
  self.head_length = 0
  self.tail_length = 0
  self.current_length = 0
  self.total_distance_travelled = 0
  self.tail_distance_travelled = 0
  self.head_segment = 1
  self.tail_segment = 1
  self.head_finished = false
  self.tail_finished = false
  self.is_dead = false
  
  -- draw segments
  for i=1,#self.overlays do
    table.clear(self.overlays[i])
  end
  self.overlay_timer:start()
end

function laser_bullet:die()
  self.is_dead = true
end

function laser_bullet:_handle_wall_explosion_shard_collisions(x, y, radius, shards)
  local min_throw = self.min_explosion_throw_dist
  local max_throw = self.max_explosion_throw_dist
  
  for i=1,#shards do
    local shard = shards[i]
    local sx, sy = shard:get_position()
    local dirx, diry = sx - x, sy - y
    local dist = math.sqrt(dirx*dirx + diry*diry)
    if dist == 0 then
      dist = 0.00001
    end
    dirx, diry = dirx / dist, diry / dist
    local ratio = 1 - (dist / radius)
    local throw_dist = min_throw + ratio * (max_throw - min_throw)
    shard:throw(dirx, diry, throw_dist)
  end
  
end

function laser_bullet:_wall_collision_explosion(x, y, power)
  local min = self.min_wall_collision_radius
  local max = self.max_wall_collision_radius
  local radius = min + power * (max - min)
  local rsq = radius * radius
  local objects = self.collision_objects
  table.clear(objects)
  local bbox = self.temp_bbox
  bbox.x, bbox.y = x - radius, y - radius
  bbox.width, bbox.height = 2 * radius, 2 * radius
  
  self.collider:get_collisions(bbox, objects)
  local shards = self.temp_table
  table.clear(shards)
  for i=#objects,1,-1 do
    if objects[i].table == SHARD then
      local sx, sy = objects[i]:get_position()
      local dx, dy = sx - x, sy - y
      local dsq = dx*dx + dy*dy
      if dsq < rsq then
        shards[#shards + 1] = objects[i]  
      end
    end
    objects[i] = nil
  end
  
  self:_handle_wall_explosion_shard_collisions(x, y, radius, shards)
end

function laser_bullet:_collide_with_wall()
  local normals = self.collision_normals
  local segments = self.path
  local idx = self.head_segment
  
  -- case where laser ends without hitting wall
  if not normals[2*idx] then
    return
  end
  
  local nx, ny = normals[2*idx - 1], normals[2*idx]
  local x, y = segments[2*idx + 1], segments[2*idx + 2]
  local jog = 10
  local view_pad = 200
  x, y = x + jog * nx, y + jog * ny
  
  -- case where explosion too far out of view
  local viewport = self.level:get_camera_viewport()
  local pos = self.temp_vect
  local bbox = self.temp_bbox
  bbox.x, bbox.y = viewport.x - view_pad, viewport.y - view_pad
  bbox.width, bbox.height = viewport.width + 2 * view_pad, viewport.height + 2 * view_pad
  pos:set(x, y)
  if not bbox:contains_point(pos) then
    return
  end
  
  -- calculate strength
  local dist = self.total_distance_travelled
  local ratio = 1 - (dist/self.max_power_distance)
  if ratio < 0 then
    ratio = 0
  end
  local min, max = self.min_shard_power, self.max_shard_power
  local shard_power = min + ratio * (max - min)
  local min, max = self.min_tile_power, self.max_tile_power
  local tile_power = min + ratio * (max - min)
  
  if math.random() < 0.3 then
    self.level:spawn_cube_explosion(x, y, shard_power, nx, ny)
  end
  
  self.level:spawn_tile_explosion(x, y, tile_power)
  self.level:spawn_tile_explosion(x, y, tile_power, nil, false)
  self:_wall_collision_explosion(x, y, ratio)
  
  local min, max = self.min_shake_power, self.max_shake_power
  local power = min + ratio * (max - min)
  local min, max = self.min_shake_time, self.max_shake_time
  local time = min + ratio * (max - min)
  self.level:shake(power, time)
  
  -- sound effect
  local listener = self.owner
  if listener and listener.get_position then
    local lx, ly = listener:get_position():get_vals()
    local sx, sy = x - lx, y - ly
    self.level:spawn_explosion_sound_effect(sx, sy, 0.7*tile_power)
  end
end

function laser_bullet:_find_new_head_position(dt)
  local increase = self.speed * dt
  local idx = self.head_segment
  local seg_len = self.segment_lengths[idx]
  local head_x, head_y = self.head_x, self.head_y
  local remainder = self.head_length + increase - seg_len
  local num_segments = self.num_segments
  
  local new_idx = idx + 1
  local new_length = 0
  local head_finished = false
  while true do
    if new_idx > num_segments then
      head_finished = true
      new_idx = #self.segment_lengths
      new_length = self.segment_lengths[#self.segment_lengths]
      break
    end
  
    local seg_len = self.segment_lengths[new_idx]
    if remainder - seg_len < 0 then
      new_length = remainder
      break
    end
    
    remainder = remainder - seg_len
    new_idx = new_idx + 1
  end
  
  local new_hx, new_hy
  if not head_finished then
    local idx = new_idx
    local dirx = self.segment_directions[2*idx - 1]
    local diry = self.segment_directions[2*idx]
    local x, y = self.path[2*idx - 1], self.path[2*idx]
    self.total_distance_travelled = self.total_distance_travelled + increase
    new_hx, new_hy = x + dirx * new_length, y + diry * new_length
  else
    new_hx, new_hy = self.path[#self.path - 1], self.path[#self.path]
  end
  
  return new_hx, new_hy, new_idx, new_length, head_finished
end

function laser_bullet:_find_new_tail_position(dt)
  local increase = self.speed * dt
  local idx = self.tail_segment
  local seg_len = self.segment_lengths[idx]
  local tail_x, tail_y = self.tail_x, self.tail_y
  local remainder = self.tail_length + increase - seg_len
  local num_segments = self.num_segments
  
  local new_idx = idx + 1
  local new_length = 0
  local tail_finished = false
  while true do
    if new_idx > num_segments then
      tail_finished = true
      new_idx = #self.segment_lengths
      new_length = self.segment_lengths[#self.segment_lengths]
      break
    end
  
    local seg_len = self.segment_lengths[new_idx]
    if remainder - seg_len < 0 then
      new_length = remainder
      break
    end
    
    remainder = remainder - seg_len
    new_idx = new_idx + 1
  end
  
  local new_tx, new_ty
  if not tail_finished then
    local idx = new_idx
    local dirx = self.segment_directions[2*idx - 1]
    local diry = self.segment_directions[2*idx]
    local x, y = self.path[2*idx - 1], self.path[2*idx]
    self.tail_distance_travelled = self.tail_distance_travelled + increase
    new_tx, new_ty = x + dirx * new_length, y + diry * new_length
  else
    new_tx, new_ty = self.path[#self.path - 1], self.path[#self.path]
  end
  
  return new_tx, new_ty, new_idx, new_length, tail_finished
end

function laser_bullet:_update_head_position(dt)
  if not self.head_finished then
    local increase = self.speed * dt
    local idx = self.head_segment
    local seg_len = self.segment_lengths[idx]
    local hx, hy = self.head_x, self.head_y
    if self.head_length + increase < seg_len then
      local dirx = self.segment_directions[2*idx - 1]
      local diry = self.segment_directions[2*idx]
      hx = hx + increase * dirx
      hy = hy + increase * diry
      
      self.head_length = self.head_length + increase
      self.total_distance_travelled = self.total_distance_travelled + increase
      self.head_x, self.head_y = hx, hy
      self.remaining_path_length = self.remaining_path_length - increase
    else
      self:_collide_with_wall()
      hx, hy, new_segment, new_length, is_finished = self:_find_new_head_position(dt)
      self.head_segment = new_segment
      self.head_length = new_length
      self.head_x, self.head_y = hx, hy
      self.head_finished = is_finished
    end
  end
  
end

function laser_bullet:_update_tail_position(dt)
  if not self.tail_finished then
    local increase
    if self.current_length >= self.length or self.head_finished then
      increase = self.speed * dt
    else
      local ratio = self.current_length / self.length
      local min, max = self.min_tail_speed, self.speed
      increase = (min + ratio * (max - min)) * dt
    end
    
    local idx = self.tail_segment
    local seg_len = self.segment_lengths[idx]
    local tx, ty = self.tail_x, self.tail_y
    if self.tail_length + increase < seg_len then
      local dirx = self.segment_directions[2*idx - 1]
      local diry = self.segment_directions[2*idx]
      tx = tx + increase * dirx
      ty = ty + increase * diry
      self.tail_distance_travelled = self.tail_distance_travelled + increase
      self.tail_length = self.tail_length + increase
      self.tail_x, self.tail_y = tx, ty
    else
      tx, ty, new_segment, new_length, is_finished = self:_find_new_tail_position(dt)
      self.tail_segment = new_segment
      self.tail_length = new_length
      self.tail_x, self.tail_y = tx, ty
      
      self.tail_finished = is_finished
    end
    
    if not self.head_finished then
      self.current_length = self.total_distance_travelled - self.tail_distance_travelled
    end
  end
  
end

function laser_bullet:_update_laser_segments()
  local segs = self.laser_segments
  table.clear(segs)
  
  local hidx, tidx = self.head_segment, self.tail_segment + 1
  segs[1] = self.tail_x
  segs[2] = self.tail_y
  local seg_idx = 3
  for i=tidx, hidx do
    segs[seg_idx] = self.path[2*i - 1]
    segs[seg_idx + 1] = self.path[2*i]
    seg_idx = seg_idx + 2
  end
  segs[#segs + 1] = self.head_x
  segs[#segs + 1] = self.head_y
  
  -- overlays
  if self.overlay_timer:isfinished() then
    local overlays = self.overlays
    local next_seg = table.remove(overlays, 1)
    table.clear(next_seg)
    table.copy(segs, next_seg)
    overlays[#overlays + 1] = next_seg
    self.overlay_timer:start()
  end
  
end

function laser_bullet:_update_collision_zone()
  local hx, hy = self.head_x, self.head_y
  local idx = self.head_segment
  local dirx = self.segment_directions[2*idx - 1]
  local diry = self.segment_directions[2*idx]
  
  local r = self.collision_radius
  self.collision_center:set(hx - r * dirx, hy - r * diry)
  self.collision_head:set(hx, hy)
  
  local bbox = self.collision_bbox
  bbox.x, bbox.y = self.collision_center.x - r, self.collision_center.y - r
  
  local len = self.collision_length
  self.collision_tail:set(hx - len * dirx, hy - len * diry)
end

function laser_bullet:_handle_collision_with_shard(shard, dist, dirx, diry)
  if      dist < self.kill_radius then
    shard:kill()
  elseif dist < self.throw_radius and self.collision_zone_active then
    -- throw
    local kr = self.kill_radius
    local ratio = 1 - (dist - kr) / (self.throw_radius - kr)
    local min, max = self.min_throw_dist, self.max_throw_dist
    local d = min + ratio * (max - min)
    shard:throw(dirx, diry, d)
  elseif self.collision_zone_active then
    -- push
    local tr = self.throw_radius
    local ratio = 1 - (dist - tr) / (self.max_collision_distance - tr)
    local min, max = self.min_push_dist, self.max_push_dist
    local d = min + ratio * (max - min)
    shard:push(dirx, diry, d)
  end
  
  self.handled_collisions[shard] = true
end

function laser_bullet:_update_collisions_with_shards(shards)
  local A = self.collision_head
  local B = self.collision_tail
  local BA_x, BA_y = A.x - B.x, A.y - B.y
  
  -- don't collide if head is within wall explosion radius
  local idx = self.head_segment
  local rsq = self.wall_collision_radii[idx] or self.min_wall_collision_radius
  rsq = rsq * rsq
  local wall_x, wall_y = self.path[2*idx + 1], self.path[2*idx + 2]
  local dx, dy = A.x - wall_x, A.y - wall_y
  local dsq = dx*dx + dy*dy
  if dsq < rsq then
    self.collision_zone_active = false
  else
    self.collision_zone_active = true
  end
  
  -- find shards within zone
  local dx, dy = A.x - B.x, A.y - B.y
  if dx == 0 and dy == 0 then
    return
  end
  local len = math.sqrt(dx*dx + dy*dy)
  if len == 0 then
    len = 0.000001
  end
  local inv_dist = 1 / len
  local idx = self.head_segment
  local nx, ny = self.segment_directions[2*idx-1], self.segment_directions[2*idx]
  nx, ny = ny, -nx
  local maxd = self.max_collision_distance
  
  local handled = self.handled_collisions
  for i=1,#shards do
    if not handled[shards[i]] then
      local shard = shards[i]
      local x, y = shard:get_position()
      
      -- check if (x,y) between A and B
      local AX_x, AX_y = x - A.x, y - A.y
      local BX_x, BX_y = x - B.x, y - B.y
      local dot1 = BA_x * BX_x + BA_y * BX_y
      local dot2 = -BA_x * AX_x + -BA_y * AX_y
      if dot1 >= 0 and dot2 >= 0 then
        -- distance from point to laser head segment line
        local dist = math.abs(dy*x-dx*y + A.x*B.y - B.x*A.y) * inv_dist
        if dist < maxd then
          -- find normal of line to shard
          local dirx, diry = nx, ny
          if nx * AX_x + ny * AX_y < 0 then
            dirx, diry = -nx, -ny
          end
          self:_handle_collision_with_shard(shard, dist, dirx, diry)
        end
      end
      
    end
  end
  
end

function laser_bullet:_reflect_laser_against_rectangle(x, y, nx, ny)
  local segment_idx = self.head_segment
  local path = self.path
  
  -- erase rest of path after collision
  for i=2 + 2*segment_idx-1,#path do
    path[i] = nil
  end
  
  -- find reflected direction
  local sdirs = self.segment_directions
  local dirx, diry = sdirs[2*segment_idx - 1], sdirs[2*segment_idx]
  local new_dirx, new_diry
  if nx == 0 then
    new_dirx, new_diry = dirx, -diry
  elseif ny == 0 then
    new_dirx, new_diry = -dirx, diry
  end
  
  -- cast ray from collsion point in reflected direction
  local remaining_depth = self.depth - segment_idx
  local pos, dir = self.temp_vect, self.temp_vect2
  pos:set(x, y)
  dir:set(new_dirx, new_diry)
  local raycaster = self.raycaster
  raycaster:set(pos, dir, self.remaining_path_length)
  raycaster:cast(remaining_depth)
  
  -- Append new path points to path
  local new_path = raycaster:get_line()
  local idx = #path + 1
  for i=1,#new_path do
    path[idx] = new_path[i]
    idx = idx + 1
  end
  
  -- reconstruct path data
  self:_init_path_data(path)
  local hx, hy, new_segment, 
        new_length, is_finished = self:_find_new_head_position(1/60)
  self.head_segment = new_segment
  self.head_length = new_length
  self.head_x, self.head_y = hx, hy
  self.head_finished = is_finished
  
  -- Erase wall collision normals after collision point
  local normals = self.collision_normals
  for i=2*segment_idx - 1,#normals do
    normals[i] = nil
  end
  normals[#normals+1] = nx
  normals[#normals+1] = ny
  
  -- Append new wall collision normals
  local new_normals = raycaster:get_normals()
  local idx = #normals + 1
  for i=1,#new_normals do
    normals[idx], normals[idx+1] = new_normals[i]:get_vals()
    idx = idx + 2
  end
end

function laser_bullet:_update_collision_with_tile_block(tblock)
  if self.handled_collisions[tblock] then
    return
  end

  local A = self.collision_head
  local B = self.collision_tail
  local bbox = tblock:get_bbox()
  
  local x, y, nx, ny = line_rectangle_intersection(B.x, B.y, A.x, A.y, 
                                                    bbox.x, bbox.y, 
                                                    bbox.width, bbox.height)
  if x then
    self:_reflect_laser_against_rectangle(x, y, nx, ny)
    self.level:shake(self.max_shake_power, self.min_shake_time)
    self.collider:report_collision(tblock, self, x, y, self.tblock_collision_power)
    self.handled_collisions[tblock] = true
  end
end

function laser_bullet:_update_collisions(dt)
  local bbox = self.collision_bbox
  local objects = self.collision_objects
  self.collider:get_collisions(bbox, objects)
  
  local shards = self.temp_table
  local tblock = nil
  table.clear(shards)
  for i=#objects,1,-1 do
    if objects[i].table == SHARD then
      shards[#shards + 1] = objects[i]
    elseif objects[i].table == TILE_BLOCK then
      tblock = objects[i]
    end
    objects[i] = nil
  end
  
  self:_update_collisions_with_shards(shards)
  if tblock then
    self:_update_collision_with_tile_block(tblock)
  end
end

------------------------------------------------------------------------------
function laser_bullet:update(dt)
  if not self.head_finished then
    self:_update_head_position(dt)
  end
  
  if not self.tail_finished then
    self:_update_tail_position(dt)
  end
  
  if not self.head_finished or not self.tail_finished then
    self:_update_collision_zone(dt)
    self:_update_collisions(dt)
    self:_update_laser_segments(dt)
  end
  
  if self.head_finished and self.tail_finished then
    self:die()
  end
  
end

------------------------------------------------------------------------------
function laser_bullet:draw()  
  lg.setColor(255, 255, 255, 150)
  lg.setLineWidth(2)
  local segs = self.laser_segments
  for i=1,#segs-2,2 do
    lg.line(segs[i], segs[i+1], segs[i+2], segs[i+3])
  end
  
  lg.setLineWidth(1)
  lg.setColor(255, 180, 55, 30)
  local overlays = self.overlays
  for i=#overlays,1,-1 do
    local segs = overlays[i]
    for j=1,#segs-2,2 do
      lg.line(segs[j], segs[j+1], segs[j+2], segs[j+3])
    end
  end

  if self.debug then
    local path = self.path
    lg.setColor(255, 255, 0, 100)
    lg.setLineWidth(2)
    
    for i=1,#path-2,2 do
      lg.line(path[i], path[i+1], path[i+2], path[i+3])
    end
    
    
    local alpha = 255
    if not self.collision_zone_active then
      alpha = 50
    end
     -- collision_zone
    local head = self.collision_head
    local mid = self.collision_center
    local tail = self.collision_tail
    local bbox = self.collision_bbox
    local r = self.collision_radius
    lg.setColor(0, 0, 255, alpha)
    lg.circle('fill', mid.x, mid.y, 3)
    lg.circle('fill', head.x, head.y, 3)
    lg.circle('fill', tail.x, tail.y, 3)
    
    lg.setColor(255, 0, 0, alpha)
    lg.setLineWidth(2)
    lg.line(head.x, head.y, tail.x, tail.y)
    local idx = self.head_segment
    local nx, ny = self.segment_directions[2*idx-1], self.segment_directions[2*idx]
    nx, ny = ny, -nx
    local r = self.max_collision_distance
    lg.line(head.x, head.y, head.x + r * nx, head.y + r * ny)
    lg.line(head.x, head.y, head.x - r * nx, head.y - r * ny)
    lg.line(tail.x, tail.y, tail.x + r * nx, tail.y + r * ny)
    lg.line(tail.x, tail.y, tail.x - r * nx, tail.y - r * ny)

    local min, max = self.min_wall_collision_radius, self.max_wall_collision_radius
    local radii = self.wall_collision_radii
    for i=1,#path-2,2 do
      lg.setColor(0, 0, 255, 100)
      lg.circle("line", path[i+2], path[i+3], min)
      lg.setColor(0, 0, 255, 150)
      lg.circle("line", path[i+2], path[i+3], max)
      
      lg.setColor(0, 255, 255, 255)
      lg.circle("line", path[i+2], path[i+3], radii[(i+1)/ 2])
    end
    
  end
end

return laser_bullet
























