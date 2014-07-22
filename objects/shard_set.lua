
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- shard_set object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local random = math.random

local ss = {}
ss.table = 'ss'
ss.level = nil
ss.animation_set = nil
ss.shadow_animation_set = nil
ss.animation_spritesheet = nil
ss.shadow_animation_spritesheet = nil
ss.spritebatch = nil
ss.motion_curves = nil
ss.height_curves = nil
ss.light_x = nil
ss.light_y = nil
ss.light_z = nil

ss.shard_pool = nil
ss.active_shards = nil
ss.new_dormant_shards = nil
ss.current_id = 0

local ss_mt = { __index = ss }
function ss:new(level, animation_set, shadow_animation_set, motion_curves, height_curves,
                 light_dir_x, light_dir_y, light_dir_z)
  local ss = setmetatable({}, ss_mt)
  local self = ss
  self.level = level
  
  self.animation_set = animation_set
  self.shadow_animation_set = shadow_animation_set
  self.motion_curves = motion_curves
  self.height_curves = height_curves
  self.light_x = light_dir_x
  self.light_y = light_dir_y
  self.light_z = light_dir_z
  self.shard_pool = {}
  self.active_shards = {}
  self.new_dormant_shards = {}
  
  local s1 = shadow_animation_set:get_spritesheet()
  local s2 = animation_set:get_spritesheet()
  self.spritebatch = spritebatch:new({s1, s2})
  self.animation_spritesheet = s2
  self.shadow_animation_spritesheet = s1
  
  return ss
end

function ss:get_shard()
  local pool = self.shard_pool
  local active = self.active_shards
  
  local sh
  if #pool > 0 then
    local rand = random(1,#pool)
    sh = table.remove(pool, rand)
    active[#active + 1] = sh
    sh.is_active = true
  else
    local motion_curves = self.motion_curves
    local height_curves = self.height_curves
    local mc = motion_curves[random(1, #motion_curves)]
    local hc = height_curves[random(1, #height_curves)]
    local anim_set = self.animation_set
    local shadow_set = self.shadow_animation_set
    local lx, ly, lz = self.light_x, self.light_y, self.light_z
    
    sh = shard:new(self.level, 0, 0, 0, 0, 0, anim_set, shadow_set, 
                   mc, hc, lx, ly, lz)
    sh:set_id(self:_get_unique_id())
    sh:set_parent_shard_set(self)
    active[#active + 1] = sh
    
    -- create some extras
    for i=1,50 do
      local sh = shard:new(self.level, 0, 0, 0, 0, 0, anim_set, shadow_set, 
                            mc, hc, lx, ly, lz)
      sh:set_id(self:_get_unique_id())
      sh:set_parent_shard_set(self)
      pool[#pool + 1] = sh
    end
  end
  
  return sh
end

function ss:wakeup_shard(shard)
  local spritebatch = self.spritebatch
  local sprite_id, batch_id, layer_id = shard:get_sprite_identifiers()
  
  if sprite_id then
    spritebatch:remove(sprite_id, batch_id, layer_id)
  end
  
  sprite_id, batch_id, layer_id = shard:get_shadow_sprite_identifiers()
  if sprite_id then
    spritebatch:remove(sprite_id, batch_id, layer_id)
  end
  
  shard:remove_sprite_identifiers()
  
  self.active_shards[#self.active_shards + 1] = shard
end

function ss:_get_unique_id()
  local id = self.current_id
  self.current_id = self.current_id + 1
end

------------------------------------------------------------------------------
function ss:update(dt)
  local active = self.active_shards
  local pool = self.shard_pool
  local new_dormant_shards = self.new_dormant_shards
  
  -- Updating collisions before position causes collisions to lag behind by one
  -- frame. This also causes collisions to be handled better.
  for i=1,#active do
    active[i]:update_collision(dt)
  end
  
  -- update shards, add destroyed back into pool, check if dormant
  for i=#active,1,-1 do
    local shard = active[i]
    shard:update_position(dt)
    
    if not shard.is_active then
      pool[#pool + 1] = table.remove(active, i)
    elseif shard.is_sleeping then
      new_dormant_shards[#new_dormant_shards + 1] = table.remove(active, i)
    end
  end
  
  -- give dormant shards to the spritebatch
  local spritebatch = self.spritebatch
  for i=#new_dormant_shards,1,-1 do
    local shard = new_dormant_shards[i]
    local rotation = shard.rotation
    local scale = shard.scale
    local offx, offy = 0.5 * shard.width, 0.5 * shard.height
    
    local sid, bid, lid = spritebatch:add(shard.spritesheet, shard.last_quad, shard.x, shard.y,
                                       rotation, scale, scale, offx, offy)
    shard:set_sprite_identifiers(sid, bid, lid)
    
    sid, bid, lid = spritebatch:add(shard.shadow_spritesheet, shard.last_shadow_quad, 
                                    shard.shadow_x, shard.shadow_y,
                                    rotation, scale, scale, offx, offy)
    shard:set_shadow_sprite_identifiers(sid, bid, lid)
    
    new_dormant_shards[i] = nil
  end
  
end

function ss:draw_ground_layer()
  lg.setColor(255, 255, 255, 255)
  local spritebatch = self.spritebatch

  spritebatch:draw_layer(self.shadow_animation_spritesheet)
  spritebatch:draw_layer(self.animation_spritesheet)
end

------------------------------------------------------------------------------
function ss:draw_sky_layer()  
  local shards = self.active_shards
  lg.setColor(255, 255, 255, 255)
  
  for i=1,#shards do
    shards[i]:draw_shadow()
  end
  
  for i=1,#shards do
    shards[i]:draw()
  end
  
end

function ss:draw()
end

return ss






























