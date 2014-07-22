
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- shard object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local random = math.random

local shard = {}
shard.table = SHARD
shard.debug = false
shard.level = nil
shard.parent_shard_set = nil
shard.id = nil
shard.sprite_id = nil             -- table {sprite_id, batch_id, layer_id}
shard.shadow_sprite_id = nil      -- table {sprite_id, batch_id, layer_id}
shard.x = nil
shard.y = nil
shard.z = nil
shard.pos = nil
shard.min_z = nil
shard.max_z = nil
shard.orig_x = nil
shard.orig_y = nil
shard.disp_x = nil
shard.disp_y = nil
shard.old_x = nil
shard.old_y = nil
shard.width = nil
shard.height = nil
shard.dest_x = nil
shard.dest_y = nil
shard.vel_x = nil
shard.vel_y = nil
shard.rotation = nil
shard.shadow_x = nil
shard.shadow_y = nil

shard.animation = nil
shard.shadow_animation = nil
shard.anim_id = nil
shard.spritesheet = nil
shard.shadow_spritesheet = nil
shard.progress = 0
shard.last_quad = nil
shard.last_shadow_quad = nil
shard.is_active = false
shard.is_finished = false
shard.is_playing = true
shard.is_sleeping = false
shard.alpha = 255
shard.light_x = nil
shard.light_y = nil
shard.light_z = nil

shard.animation_set = nil
shard.shadow_set = nil
shard.motion_curve = nil
shard.height_curve = nil
shard.height_ratio = nil
shard.progress = nil
shard.motion_progress = nil
shard.height_progress = 0
shard.height_progress_cutoff = nil

shard.collider = nil
shard.collision_objects = nil
shard.collision_timeout_timer = nil
shard.shard_collision_objects = nil
shard.bbox = nil
shard.collision_active = false
shard.lifetime = 0
shard.body_points = nil
shard.map_body = nil

shard.is_initialized = false
shard.initialize_with_push = false
shard.height_to_length_ratio = 0.4
shard.max_height = 250
shard.min_height_progress_cutoff = 0.50
shard.max_height_progress_cutoff = 0.70
shard.min_scale = 1
shard.max_scale = 1
shard.min_rectangle_throw = 50
shard.max_rectangle_throw = 200

shard.min_alpha = 200
shard.max_alpha = 255
shard.min_animation_speed = 1
shard.max_animation_speed = 1
shard.bbox_pad = 5
shard.collision_height_threshold = 80
shard.time_before_collision_active = 0.3
shard.collision_timeout = 0.1

shard.temp_vector = nil

local shard_mt = { __index = shard }
function shard:new(level, x, y, dest_x, dest_y, rotation, anim_set, shadow_set, 
                    motion_curve, height_curve,
                    light_x, light_y, light_z)
  local shard = setmetatable({}, shard_mt)
  local self = shard
  self.level = level
  self.collider = level:get_collider()
  self.collision_objects = {}
  self.shard_collision_objects = {}
  
  self.x = x or 0
  self.y = y or 0
  self.z = 0
  self.pos = vector2:new(self.x, self.y)
  self.temp_vector = vector2:new(0, 0)
  self.dest_x = dest_x or 0
  self.dest_y = dest_y or 0
  self.rotation = rotation or 0
  
  self.animation_set = anim_set
  self.shadow_set = shadow_set
  self.motion_curve = motion_curve
  self.height_curve = height_curve
  
  self.sprite_id = {}
  self.shadow_sprite_id = {}
  
  self.body_points = {vector2:new(0, 0), vector2:new(0, 0), 
                      vector2:new(0, 0), vector2:new(0, 0)}
                      
  -- true for deferring map_body:init() stage. body points may be unknown at this point
  -- and should be set in self:init()
  self.map_body = map_body:new(level, nil, true)
  self.bbox = bbox:new(0, 0, 0, 0)
  
  self.light_x, self.light_y, self.light_z = light_x, light_y, light_z
  
  self.collision_timeout_timer = timer:new(level:get_master_timer(), 
                                           self.collision_timeout)
  
  return shard
end

function shard:set_parent_shard_set(shard_set)
  self.parent_shard_set = shard_set
end

function shard:set_id(id)
  self.id = id
end

function shard:set_sprite_identifiers(sprite_id, spritebatch_id, layer_id)
  local id = self.sprite_id
  id[1] = sprite_id
  id[2] = spritebatch_id
  id[3] = layer_id
end
function shard:set_shadow_sprite_identifiers(sprite_id, spritebatch_id, layer_id)
  local id = self.shadow_sprite_id
  id[1] = sprite_id
  id[2] = spritebatch_id
  id[3] = layer_id
end
function shard:get_sprite_identifiers()
  local sprite_id = self.sprite_id
  return sprite_id[1], sprite_id[2], sprite_id[3]
end
function shard:get_shadow_sprite_identifiers()
  local sprite_id = self.shadow_sprite_id
  return sprite_id[1], sprite_id[2], sprite_id[3]
end
function shard:remove_sprite_identifiers()
  local sprite_id = self.sprite_id
  sprite_id[1], sprite_id[2], sprite_id[3] = nil, nil, nil
  sprite_id = self.shadow_sprite_id
  sprite_id[1], sprite_id[2], sprite_id[3] = nil, nil, nil
end

function shard:get_position()
  return self.x, self.y
end
function shard:get_velocity()
  return self.vel_x, self.vel_y
end

function shard:_recycle(x, y, dest_x, dest_y, rotation, motion_curve, height_curve)
  self.x = x
  self.y = y
  self.dest_x = dest_x
  self.dest_y = dest_y
  self.rotation = rotation or 0
  if motion_curve then
    self.motion_curve = motion_curve
  end
  if height_curve then
    self.height_curve = height_curve
  end
end

-- parameters are optional. Only for re initialization
function shard:init(x, y, dest_x, dest_y, rotation, motion_curve, height_curve)
  if x then
    self:_recycle(x, y, dest_x, dest_y, rotation, motion_curve, height_curve)
  end
  
  if self.is_sleeping then
    self:wakeup()
  end
  if self.collision_active then
    self.collider:remove_object(self.bbox)
  end
  
  local push_init = self.initialize_with_push

  self.is_playing = false
  self.is_finished = false
  self.is_active = true
  self.is_sleeping = false
  self.collision_active = false
  self.lifetime = 0
  
  -- position
  local x, y = self.x, self.y
  self.pos:set(x, y)
  self.orig_x, self.orig_y = x, y
  self.old_x, self.old_y = x, y
  self.shadow_x, self.shadow_y = x, y
  self.disp_x, self.disp_y = self.dest_x - x, self.dest_y - y
  self.vel_x, self.vel_y = 0, 0
  self.tx, self.ty = 0.01 * self.disp_x, 0.01 * self.disp_y
  
  -- motion
  local dx, dy = self.disp_x, self.disp_y
  local dist = math.sqrt(dx*dx + dy*dy)
  self.min_z = 0
  self.max_z = random() * self.max_height
  if push_init then
    self.max_z = 0
  end
  
  self.height_ratio = 0
  local min_prog = self.min_height_progress_cutoff
  local max_prog = self.max_height_progress_cutoff
  self.height_progress_cutoff = min_prog + random() * (max_prog - min_prog)
  
  -- animation
  self.is_finished = false
  self.is_pushed = push_init
  self.animation = self.animation_set:get_animation()
  self.anim_id = self.animation:get_id()
  self.shadow_animation = self.shadow_set:get_animation(self.anim_id)
  self.spritesheet = self.animation.spritesheet
  self.shadow_spritesheet = self.shadow_animation.spritesheet
  self.width, self.height = self.animation.width, self.animation.height
  self.progress = 0
  self.last_quad = self.animation:get_last_frame()
  self.last_shadow_quad = self.shadow_animation:get_last_frame()
  self.animation:set_rotation(self.rotation)
  self.shadow_animation:set_rotation(self.rotation)
  local min, max = self.min_animation_speed, self.max_animation_speed
  local speed = min + random() * (max - min)
  self.animation:set_speed(speed)
  self.shadow_animation:set_speed(speed)
  self.animation:set_center(self.x, self.y)
  self.shadow_animation:set_center(self.x, self.y)
  
  -- collision
  self.collision_objects = self.collision_objects or {}
  local pad = self.bbox_pad
  local bbox = self.bbox
  bbox.width, bbox.height = self.width - 2 * pad, self.height - 2*pad
  bbox.x, bbox.y = x - 0.5 * bbox.width, y - 0.5 * bbox.height
  
  local map_body = self.map_body
  local bbox = self.bbox
  local points = self.body_points
  local p1, p2, p3, p4 = points[1], points[2], points[3], points[4]
  p1.x, p1.y = bbox.x, bbox.y
  p2.x, p2.y = bbox.x + bbox.width, bbox.y
  p3.x, p3.y = bbox.x + bbox.width, bbox.y + bbox.height
  p4.x, p4.y = bbox.x, bbox.y + bbox.height
  map_body:set_body_points(points)
  map_body:set_origin(self.pos)
  map_body:set_parent(self)
  map_body:init()
   
  self.is_initialized = true
end

function shard:throw(dirx, diry, distance)
  local x, y = self:get_position()
  local dest_x, dest_y = x + dirx * distance, y + diry * distance
  self:init(x, y, dest_x, dest_y)
  self:play()
end

function shard:push(dirx, diry, distance)
  if not self.is_sleeping and not self.is_pushed then
    self:throw(dirx, diry, distance)
    return
  end
  
  local x, y = self:get_position()
  local dest_x, dest_y = x + dirx * distance, y + diry * distance
  self.initialize_with_push = true
  self:init(x, y, dest_x, dest_y)
  self.initialize_with_push = false
  self:play()
end

function shard:play()
  if not self.is_initialized then
    print(self, "Error in shard:play() - shard not initialized")
  end
  
  self.is_playing = true
  self.animation:play()
  self.shadow_animation:play()
end

function shard:stop()
  self.is_playing = false
  self.animation:stop()
  self.shadow_animation:stop()
end

function shard:is_running()
  return self.is_playing
end

function shard:sleep()
  self.is_sleeping = true
end

function shard:wakeup()
  if not self.is_sleeping then
    return
  end
  self.parent_shard_set:wakeup_shard(self)
  self.is_sleeping = false
end

function shard:kill()
  self:destroy()
end

function shard:destroy()
  self.is_active = false
  self.is_playing = false
  self.is_initialized = false
  
  if self.animation then
    self.animation:destroy()
    self.animation = nil
  end
  if self.shadow_animation then
    self.shadow_animation:destroy()
    self.shadow_animation = nil
  end
  
  if self.is_sleeping then
    self:wakeup()
  end
  
  if self.collision_active then
    self.collider:remove_object(self.bbox)
  end
end

function shard:update_position(dt)
  if self.is_finished or not self.is_playing then
    return
  end
  
  -- animation progress
  local motion_curve = self.motion_curve
  local anim = self.animation
  self.progress = anim:progress()
  local motion_progress = motion_curve:get(self.progress)
  self.motion_progress = motion_progress
  
  -- update x, y position
  self.old_x, self.old_y = self.x, self.y
  self.x = math.floor(self.orig_x + motion_progress * self.disp_x)
  self.y = math.floor(self.orig_y + motion_progress * self.disp_y)
  self.pos:set(self.x, self.y)
  local vx, vy = (self.x - self.old_x) / dt, (self.y - self.old_y) / dt
  self.vel_x, self.vel_y = 0.5 * (vx + self.vel_x), 0.5 * (vy + self.vel_y)
  anim:set_center(self.x, self.y)
  
  -- distance travelled since last frame
  self.tx = self.x - self.old_x
  self.ty = self.y - self.old_y
  if self.tx == 0 then self.tx = 0.01 * self.disp_x end
  if self.ty == 0 then self.ty = 0.01 * self.disp_y end
  
  -- update z position
  local hprog = math.min(self.progress / self.height_progress_cutoff, 1)
  local height_progress = self.height_curve:get(hprog)
  local min, max = self.min_z, self.max_z
  self.z = min + height_progress * (max - min)
  self.height_ratio = self.z / self.max_height
  self.height_progress = height_progress
  
  -- display
  local min, max = self.min_alpha, self.max_alpha
  self.alpha = min + (1 - self.height_progress) * (max - min)
  min, max = self.min_scale, self.max_scale
  self.scale = min + (self.height_ratio * self.height_ratio) * (max - min)
  self.animation:set_scale(self.scale)
  self.shadow_animation:set_scale(self.scale)
  
  -- shadow position
  if self.z == 0 then
    self.shadow_x, self.shadow_y = self.x, self.y
  else
    local lx, ly, lz = self.light_x, self.light_y, self.light_z
    local d= -self.z / lz
    self.shadow_x, self.shadow_y = d * lx + self.x, d * ly + self.y
  end
  self.shadow_animation:set_center(self.shadow_x, self.shadow_y)
  
  -- animation finished
  if not anim:is_running() then
    self.is_finished = true
    self.is_playing = false
    self.animation:destroy()
    self.shadow_animation:destroy()
    self.animation = nil
    self.shadow_animation = nil
    self.vel_x = 0
    self.vel_y = 0
    self.z = 0
    self.alpha = 255
    self.scale = 1
    self:sleep()
  end
  
end

function shard:_update_collision_status(dt)
  -- are collisions_active?
  local bbox = self.bbox
  local time_thresh = self.time_before_collision_active
  local height_thresh = self.collision_height_threshold
  self.lifetime = self.lifetime + dt
  local is_active = self.z < height_thresh and self.lifetime > time_thresh
  if is_active ~= self.collision_active then
    local collider = self.collider
    if is_active then
      collider:add_object(bbox, self)
    else
      collider:remove_object(bbox)
    end
  end
  self.collision_active = is_active
end

function shard:_update_tile_map_collisions(dt)
  -- collisions with wall
  local map_body = self.map_body
  map_body:set_position(self.pos)
  map_body:update(dt)
  local c, n, p, offset, tiles = map_body:get_collision_data()
  if c then
    -- update position in event of collision
    local body_pos = map_body:get_position()
    local new_x, new_y = body_pos.x + offset.x, body_pos.y + offset.y
    local new_pos = self.temp_vector
    new_pos:set(new_x, new_y)
    local success, safe_pos = map_body:update_position(new_pos)
    if not success then
      new_pos:clone(safe_pos)
    end
    self:_set_new_position(new_pos.x, new_pos.y)
    
    if self.vel_x == 0 and self.vel_y == 0 then
      return
    end
    
    -- find new direction
    local friction, restitution = 0.95, 0.55
    local vx, vy = get_bounce_velocity_components(self.vel_x, self.vel_y, 
                                                   n.x, n.y, friction, restitution)
    local inv_len = 1 / math.sqrt(vx * vx + vy * vy)
    local new_dir_x, new_dir_y = vx * inv_len, vy * inv_len
    self:_set_new_direction(new_dir_x, new_dir_y, restitution)
  end
end

function shard:_collide_with_sleeping_shard(other_shard)
  
  local nx, ny = self.dest_x - self.x, self.dest_y - self.y
  local nlen = math.max(math.sqrt(nx*nx + ny*ny), 0.00001)
  nx, ny = nx / nlen, ny / nlen
  
  local max_vel = 300 
  local vel = math.sqrt(self.vel_x*self.vel_x + self.vel_y*self.vel_y)
  local ratio = vel / max_vel
  if ratio > 1 then ratio = 1 end
  local dist = 100 * ratio
  if dist < 1 then -- prevents shards from repeatedly colliding and going nowhere
    return
  end
  other_shard:push(nx, ny, dist)
  other_shard.collision_timeout_timer:start()
end

function shard:_collide_with_shards(shards)
  -- find average point of all shards
  local px, py = 0, 0
  for i=1,#shards do
    px, py = px + shards[i].x, py + shards[i].y
    
    if shards[i].is_sleeping then
      self:_collide_with_sleeping_shard(shards[i])
    end
  end
  px, py = px / #shards, py / #shards
    
  -- find normal of collision
  -- treat shape of shard like a circle
  local epsilon = 0.00001
  local nx, ny = self.x - px, self.y - py
  local nlen = math.max(math.sqrt(nx*nx + ny*ny), epsilon)
  
  nx, ny = nx / nlen, ny / nlen
  
  -- find bounce direction
  local friction, restitution = 0.95, 0.5
  local dirx, diry = self.dest_x - self.orig_x, self.dest_y - self.orig_y
  if dirx == 0 and diry == 0 then
    return
  end
  dirx, diry = get_bounce_velocity_components(dirx, diry, nx, ny, friction, restitution)
  local dirlen = math.max(math.sqrt(dirx*dirx + diry*diry), epsilon)
  dirx, diry = dirx / dirlen, diry / dirlen
  self:_set_new_direction(dirx, diry, restitution)
  self.collision_timeout_timer:start()
end

function shard:_collide_with_rectangle(bbox)

  local tx, ty = self.disp_x, self.disp_y
  if tx == 0 and ty == 0 then
    return
  end
  local b = self.bbox
  local tx, ty, nx, ny = rectangle_rectangle_collision(
                                   b.x, b.y, b.width, b.height,
                                   bbox.x, bbox.y, bbox.width, bbox.height, tx, ty)
  
  if tx then
    self:_translate(tx, ty)
    
    local vx, vy = self.disp_x, self.disp_y
    if vx == 0 and vy == 0 then
      return
    end
    local friction, restitution = 0.95, 0.9
    local dirx, diry = get_bounce_velocity_components(vx, vy, nx, ny, friction, restitution)
    local len = math.sqrt(dirx*dirx + diry*diry)
    dirx, diry = dirx / len, diry / len
    self:_set_new_direction(dirx, diry, restitution)
    self.collision_timeout_timer:start()
  end
  
end

function shard:_update_world_collisions(dt)
  if not self.collision_active then
    --return
  end
  
  local objects = self.collision_objects
  table.clear(objects)
  
  self.collider:get_collisions(self.bbox, objects)
  if #objects == 0 then
    return
  end
  
  -- collide with shards
  local shards = self.shard_collision_objects
  local tblock
  table.clear(shards)
  for i=1,#objects do
    if not objects or not objects[i] or not objects[i].table then
      print(i, #objects, objects, objects[i].table)
    end
    if objects[i] then
      if objects[i].table == SHARD then
        shards[#shards+1] = objects[i]
      elseif objects[i].table == TILE_BLOCK then
        tblock = objects[i]
      end
    end
  end
  
  if tblock then
    self:_collide_with_rectangle(tblock:get_bbox(), dt)
    self.collider:report_collision(tblock, self)
  end
  if #shards > 0 and  self.collision_active and not self.collision_timeout_timer:isrunning() then
    self:_collide_with_shards(shards)
  end
  
  
end

function shard:update_collision(dt)
  
  local bbox = self.bbox
  local tx, ty = self.x - self.old_x, self.y - self.old_y
  bbox.x, bbox.y = bbox.x + tx, bbox.y + ty
  if self.collision_active then
    self.collider:update_object(bbox)
  end
  
  self:_update_collision_status(dt)
  self:_update_tile_map_collisions(dt)
  self:_update_world_collisions(dt)
end

function shard:_set_new_position(x, y)
  local tx, ty = x - self.x, y - self.y
  self.x, self.y = x, y
  self.old_x, self.old_y = x, y
  self.pos:set(x, y)
  self.bbox.x, self.bbox.y = self.bbox.x + tx, self.bbox.y + ty
  self.shadow_x, self.shadow_y = self.shadow_x + tx, self.shadow_y + ty
  
  if self.animation then
    self.animation:set_center(x, y)
  end
  if self.shadow_aniamtion then
    self.shadow_animation:set_center(self.shadow_x, self.shadow_y)
  end
end

function shard:_set_new_direction(dir_x, dir_y, elasticity)
  elasticity = elasticity or 1

  -- change the displacement and origin vector as if it had this direction
  -- all along
  local x, y = self.x, self.y
  local progress = self.motion_progress or 0
  local disp_x, disp_y = self.disp_x, self.disp_y
  local total_dist = math.sqrt(disp_x * disp_x + disp_y * disp_y)
  local progress_dist = progress * total_dist
  local remainder_dist = total_dist - progress_dist
  progress_dist = progress_dist * elasticity
  remainder_dist = remainder_dist * elasticity
  local new_orig_x = x - progress_dist * dir_x
  local new_orig_y = y - progress_dist * dir_y
  local new_dest_x = x + remainder_dist * dir_x
  local new_dest_y = y + remainder_dist * dir_y
  
  self.disp_x, self.disp_y = new_dest_x - new_orig_x, new_dest_y - new_orig_y
  self.orig_x, self.orig_y = new_orig_x, new_orig_y
  self.dest_x, self.dest_y = new_dest_x, new_dest_y
end

function shard:_translate(tx, ty)
  self.orig_x = self.orig_x + tx
  self.orig_y = self.orig_y + ty
  self.dest_x = self.dest_x + tx
  self.dest_y = self.dest_y + ty
  --[[
  self.bbox.x, self.bbox.y = self.bbox.x + tx, self.bbox.y + ty
  self.pos:set(self.pos.x + tx, self.pos.y + ty)
  ]]--
  self:_set_new_position(self.x + tx, self.y + ty)
  self.map_body:set_position(self.pos)
end

------------------------------------------------------------------------------
function shard:update(dt)
end

------------------------------------------------------------------------------
function shard:draw_shadow()
  if self.is_sleeping or self.is_pushed then
    return
  end

  if not self.is_finished then
    lg.setColor(255, 255, 255, self.alpha)
    self.shadow_animation:draw()
  else
    local scale = self.scale
    local rot = self.rotation
    lg.setColor(255, 255, 255, 255)
    lg.draw(self.shadow_spritesheet, self.last_shadow_quad,
            self.shadow_x, self.shadow_y,
            rot, scale, scale, 0.5 * self.width, 0.5 * self.height)
  end
end

function shard:draw()
  if not self.is_finished then
    if self.is_pushed then
      local q1 = self.last_shadow_quad
      local q2 = self.last_quad
      local hw, hh = 0.5 * self.width, 0.5 * self.height
      lg.draw(self.shadow_spritesheet, q1, self.x, self.y, self.rotation,
              1, 1, hw, hh)
      lg.draw(self.spritesheet, q2, self.x, self.y, self.rotation,
              1, 1, hw, hh)
    else
      self.animation:draw()
    end
  else
    local scale = self.scale
    local rot = self.rotation
    lg.draw(self.spritesheet, self.last_quad, self.x, self.y,
            rot, scale, scale, 0.5 * self.width, 0.5 * self.height)
  end
  
  if self.debug then
    if self.collision_active then
      lg.setColor(255, 0, 0, 255)
      local b = self.bbox
      lg.rectangle('line', b.x, b.y, b.width, b.height)
      lg.setColor(255, 255, 255, 255)
    end
    
    self.map_body:draw()
    
    lg.setColor(0, 0, 255, 30)
    lg.line(self.orig_x, self.orig_y, self.dest_x, self.dest_y)
  end
end

return shard



























