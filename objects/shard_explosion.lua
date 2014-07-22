
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- shard_explosion object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local PI = math.pi
local random = math.random

local se = {}
se.table = 'se'
se.debug = false
se.light_x = nil
se.light_y = nil
se.light_z = nil
se.x = nil
se.y = nil
se.origin_width = nil
se.origin_height = nil
se.shards = nil
se.num_shards = nil
se.num_shards_emitted = 0
se.current_emit_time = 0
se.radius = nil
se.dirx = nil
se.diry = nil
se.min_angle = nil
se.max_angle = nil
se.is_directional = false
se.has_mulitiple_origins = false
se.motion_curves = nil
se.height_curves = nil
se.min_height_progress_cutoff = 0.50
se.max_height_progress_cutoff = 0.70
se.height_to_radius_ratio = 0.3
se.max_height = nil

se.has_started = false
se.is_playing = false
se.is_done = false
se.is_emitting = false

se.shard_min_scale = 1
se.shard_max_scale = 1.3
se.shard_min_alpha = 100
se.shard_max_alpha = 255
se.min_animation_speed = 1.0
se.max_animation_speed = 1.0
se.shard_bbox_pad = 8
se.shard_collision_height_threshold = 20
se.shard_time_before_collision_active = 0.4
se.shard_emit_time = 0.1

local se_mt = { __index = se }
function se:new(x, y, shard_set, num_shards, blast_radius, 
                 motion_curves, height_curves,
                 blast_dirx, blast_diry, blast_angle,
                 origin_width, origin_height, emit_time)
  local se = setmetatable({}, se_mt)
  
  if blast_dirx and blast_diry and blast_angle then
    se.is_directional = true
    se.dirx = blast_dirx
    se.diry = blast_diry
    local angle = math.atan2(blast_diry, blast_dirx)
    se.min_angle = angle - math.rad(0.5 * blast_angle)
    se.max_angle = angle + math.rad(0.5 * blast_angle)
    
    if origin_width and origin_height then
      se.has_multiple_origins = true
      se.origin_width = origin_width
      se.origin_height = origin_height
    end
  end
  
  se.shard_set = shard_set
  se.num_shards = num_shards
  se.radius = blast_radius
  se.max_height = self.height_to_radius_ratio * se.radius
  se.motion_curves = motion_curves
  se.height_curves = height_curves
  se.x = x
  se.y = y
  
  se.num_shards = num_shards
  se.shard_emit_time = emit_time or se.shard_emit_time
  se.shards = {}
  
  return se
end

function se:play()
  self.is_playing = true
  self.is_emitting = true
  self.has_started = true
end

function se:is_running()
  return self.is_playing
end

function se:is_finished()
  return self.is_done
end

function se:destroy()
  local shards = self.shards
  for i=1,#shards do
    shards[i]:destroy()
  end  

  self.is_done = true
  self.is_playing = false
end

function se:_update_shard_emitter(dt)
  local time = self.current_emit_time + dt
  local max_time = self.shard_emit_time
  local progress = math.min(time / max_time, 1)
  local max_emit = self.num_shards
  local num_emit = self.num_shards_emitted
  local n = math.floor(progress * max_emit - num_emit)
  
  local shards = self.shards
  for i = 1,n do
    local shard = self:_new_shard()
    shard:play()
    shards[#shards + 1] = shard
  end
  self.num_shards_emitted = num_emit + n
  self.current_emit_time = time
  
  if self.num_shards_emitted >= max_emit then
    self.is_emitting = false
    self.is_done = true
  end
end

function se:_new_shard()
  
  -- direction
  local radius = self.radius
  local min, max = 50, radius
  local length = min + random() * (max - min)
  local dirx, diry
  if self.is_directional then
    local min, max = self.min_angle, self.max_angle
    local angle = min + random() * (max - min)
    dirx, diry = math.cos(angle), math.sin(angle)
  else
    dirx, diry = random_direction2()
  end
  
  -- position
  local shard_x, shard_y
  if self.has_multiple_origins then
    local perpx, perpy = diry, -dirx
    local x, y = self.x, self.y
    local w, h = self.origin_width, self.origin_height
    local offx = -0.5 * w + math.random() * w
    local offy = -0.5 * h + math.random() * h
    local wx, wy = offx * perpx, offx * perpy
    local hx, hy = offy * dirx, offy * diry
    shard_x = x + wx + hx
    shard_y = y + wy + hy
  else
    shard_x = self.x
    shard_y = self.y
  end
  local dest_x = shard_x + length * dirx
  local dest_y = shard_y + length * diry
  local rotation = 0
  
  -- motion
  local motion_curves = self.motion_curves
  local height_curves = self.height_curves
  local motion_curve = motion_curves[random(1,#motion_curves)]
  local height_curve = height_curves[random(1,#height_curves)]
  
  -- animation
  local shard_set = self.shard_set
  local shard = shard_set:get_shard()
  shard:init(shard_x, shard_y, dest_x, dest_y, rotation, motion_curve, height_curve)
  
  return shard
end

------------------------------------------------------------------------------
function se:update(dt)
  if not self.is_playing then
    return
  end
  
  if self.is_emitting then
    self:_update_shard_emitter(dt)
  end

end

------------------------------------------------------------------------------
function se:draw()
  if not self.is_playing then
    return
  end
  
  if self.debug then
    -- blast radius
    lg.setColor(255, 0, 0, 40)
    lg.setLineWidth(1)
    lg.circle('line', self.x, self.y, self.radius)
    
    --origin
    if self.has_multiple_origins then
      local ox, oy = 0.5 * self.origin_width, 0.5 * self.origin_height
      local dirx, diry = self.dirx, self.diry
      local perpx, perpy = self.diry, -self.dirx
      local x, y = self.x, self.y
      local wx, wy = ox * perpx, ox * perpy
      local hx, hy = oy * dirx, oy * diry
      
      local x1, y1 = x - wx - hx, y - wy - hy
      local x2, y2 = x + wx - hx, y + wy - hy
      local x3, y3 = x + wx + hx, y + wy + hy
      local x4, y4 = x - wx + hx, y - wy + hy
      lg.setColor(255, 255, 0, 150)
      lg.polygon('line', x1, y1, x2, y2, x3, y3, x4, y4)
    end
    
    -- angle range
    if self.is_directional then
      local len = self.radius
      local dirx, diry = self.dirx, self.diry
      lg.setColor(0, 0, 255, 100)
      lg.line(self.x, self.y, self.x + len * dirx, self.y + len * diry)
      
      lg.setColor(255, 0, 0, 100)
      local min, max = self.min_angle, self.max_angle
      dirx, diry = math.cos(min), math.sin(min)
      lg.line(self.x, self.y, self.x + len * dirx, self.y + len * diry)
      
      dirx, diry = math.cos(max), math.sin(max)
      lg.line(self.x, self.y, self.x + len * dirx, self.y + len * diry)
    end
  end
end

return se










