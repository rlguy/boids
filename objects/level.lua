
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- level object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local level = {}
level.table = 'level'
level.tile_palette = nil
level.master_timer = nil
level.hero = nil
level.camera = nil
level.screen_canvas = nil
level.level_map = nil
level.audio_set = nil
level.collider = nil
level.mouse = nil
level.active_area_bbox = nil

level.animation_sets = nil
level.shard_sets = nil
level.shard_explosions = nil

-- cube explosions
level.cube_motion_curves = nil
level.cube_height_curves = nil
level.cube_shard_set = nil
level.min_num_cubes = 5
level.max_num_cubes = 15
level.cube_min_radius = 500
level.cube_max_radius = 1000

-- tile explosions
level.tile_explosion_is_initialized = false
level.tile_explosions = nil
level.tile_explosion_fade_curves = nil
level.tile_explosion_flash_curves = nil
level.tile_explosion_min_radius = 150
level.tile_explosion_max_radius = 400

-- sounds
level.audio_sample_sets = nil
level.explosion_sample_set = nil

-- camera shake
level.camera_shake_enabled = false

-- explosion sound effects
level.explosion_sound_effect_volume = 0.3
level.explosion_sound_effect_launch_time = 0.08
level.explosion_sound_effect_min_num_samples = 1
level.explosion_sound_effect_max_num_samples = 3
level.explosion_sound_effect_radius = 1000
level.explosion_sound_effect_spread = 50

local level_mt = { __index = level }
function level:new()
  local level = setmetatable({}, level_mt)
  level.master_timer = master_timer:new()
  level.audio_set = asset_set:new()
  level.animation_sets = {}
  level.shard_sets = {}
  level.shard_explosions = {}
  level.cube_motion_curves = {}
  level.cube_height_curves = {}
  
  level.tile_explosions = {}
  level.tile_explosion_fade_curves = {}
  level.tile_explosion_flash_curves = {}
  level.audio_sample_sets = {}
  
  level.screen_canvas = lg.newCanvas(SCR_WIDTH, SCR_HEIGHT)
  
  return level
end

function level:load()
  self.level_map:load()
  self.audio_set:load()
end

function level:is_loaded()
  local map_loaded = false
  if self.level_map then
    map_loaded = self.level_map:is_loaded()
  end
  
  local audio_loaded = false
  if self.audio_set then
    audio_loaded = self.audio_set:is_loaded()
  end
  return map_loaded and audio_loaded
end

----- set
function level:set_camera(camera)
  self.camera = camera
  
  -- compute active area
  local center = camera:get_center()
  local x, y = center.x - 0.5 * ACTIVE_AREA_WIDTH, center.y - ACTIVE_AREA_HEIGHT
  self.active_area_bbox = bbox:new(x, y, ACTIVE_AREA_WIDTH, ACTIVE_AREA_HEIGHT)
end

function level:set_camera_shake_curves(xcurves, ycurves)
  if self.camera then
    self.camera:set_shake_curves(xcurves, ycurves)
    self.camera_shake_enabled = true
  end
end

function level:set_level_map(level_map)
  self.level_map = level_map
end

function level:set_collider(level_collider)
  self.collider = level_collider
end

function level:set_player(hero)
  self.hero = hero
end

function level:set_mouse(mouse_input)
  self.mouse = mouse_input
end

function level:set_tile_explosion_curves(flash_curves, fade_curves)
  if #flash_curves == 0 or #fade_curves == 0 then
    return
  end
  
  for i=1,#flash_curves do
    self.tile_explosion_flash_curves[i] = flash_curves[i]
  end
  for i=1,#fade_curves do
    self.tile_explosion_fade_curves[i] = fade_curves[i]
  end
  self.tile_explosion_is_initialized = true
end

function level:set_tile_palette(tile_palette)
  self.tile_palette = tile_palette
end

----- get

function level:get_collider()
  return self.collider
end

function level:get_mouse()
  return self.mouse
end

function level:get_camera()
  return self.camera
end

function level:get_master_timer()
  return self.master_timer
end

function level:get_level_map()
  return self.level_map
end

function level:get_audio_set()
  return self.audio_set
end

function level:get_active_area()
  return self.active_area_bbox
end

function level:get_camera_viewport()
  if self.camera then
    return self.camera:get_viewport_bbox()
  end
end

function level:get_screen_canvas()
  return self.screen_canvas
end

function level:get_tile_palette()
  return self.tile_palette
end

function level:get_tile_spritesheet()
  return self.tile_palette:get_spritebatch_image()
end

-- add

-- files is a table of key-value pairs where the value is a table of paths
-- to audio files and the key is the identification string to retrieve the audio
-- asset/assets once sources are loaded
-- if value.data exists, data will be added to the asset
function level:add_audio_files(files)
  local audio_set = self.audio_set
  for id,paths in pairs(files) do
    if #paths == 1 then
      audio_set:add_audio(paths[1], id)
    else
      audio_set:add_audio_set(paths, id)
    end
    
    if paths.data then
      audio_set:add_asset_data(paths.data, id)
    end
  end
end

function level:add_animation_set(anim_set)
  self.animation_sets[anim_set] = anim_set
end

function level:add_cube_shard_set(cube_shard_set, motion_curves, height_curves)
  self.cube_shard_set = cube_shard_set
  self.shard_sets[cube_shard_set] = cube_shard_set
  self.cube_motion_curves = motion_curves
  self.cube_height_curves = height_curves
end

function level:add_explosion_sound_effects(audio_sample_set)
  self.explosion_sample_set = audio_sample_set
  self.audio_sample_sets[#self.audio_sample_sets + 1] = audio_sample_set
end

-- spawn
function level:spawn_cube_explosion(x, y, power, dirx, diry)
  if not self.cube_shard_set then
    return
  end
  local angle
  if dirx and diry then
    angle = 160
  end
  
  local minr, maxr = self.cube_min_radius, self.cube_max_radius
  local minn, maxn = self.min_num_cubes, self.max_num_cubes
  local radius = minr + power * (maxr - minr)
  local num_cubes = math.floor(minn + power * (maxn - minn))
  cubes = shard_explosion:new(x, y, self.cube_shard_set, num_cubes, radius, 
                              self.cube_motion_curves, self.cube_height_curves,
                              dirx, diry, angle)
  cubes:play()
  self.shard_explosions[#self.shard_explosions + 1] = cubes
end

function level:spawn_tile_explosion(x, y, power, radius, walkable_state)
  if not self.tile_explosion_is_initialized then
    return
  end
  
  if walkable_state == nil then
    walkable_state = true
  end
  
  local min, max = self.tile_explosion_min_radius, self.tile_explosion_max_radius
  local radius = radius or min + math.random() * (max - min)
  
  local flash_curves = self.tile_explosion_flash_curves
  local fade_curves = self.tile_explosion_fade_curves
  local flash = flash_curves[math.random(1, #flash_curves)]
  local fade = fade_curves[math.random(1, #fade_curves)]
  
  local te = tile_explosion:new(self, x, y, radius, walkable_state, flash, fade, power)
  te:play()
  self.tile_explosions[#self.tile_explosions + 1] = te
end

function level:spawn_explosion_sound_effect(x, y, power)
  if not self.explosion_sample_set then
    return
  end
  
  
  local n, v, t, radius, spread
  if x and y then
    local min = self.explosion_sound_effect_min_num_samples
    local max = self.explosion_sound_effect_max_num_samples
    n = math.floor(lerp(min, max, power))
    t = self.explosion_sound_effect_launch_time
    v = self.explosion_sound_effect_volume * power
    radius = self.explosion_sound_effect_radius
    spread = self.explosion_sound_effect_spread
  else
    n = 1
    v = self.explosion_sound_effect_volume * (power or 1)
  end
  
  love.audio.setDistanceModel("exponent")
  self.explosion_sample_set:play(n, v, t, x, y, radius, spread)
end

function level:shake(power, duration)
  if self.camera and self.camera_shake_enabled then
    local n = 4
    for i=1,n do
      local r = i/n
      local min, max = math.min(0.03, power), power
      local power = min + r * (max - min)
      local min, max = math.min(0.5, duration), duration
      local time = min + r * (max - min)
      self.camera:shake(power, time)
    end
  end
end



function level:keypressed(key)
  if key == 'c' and self.hero then
    self.hero:shoot_laser()
  end
end

function level:keyreleased(key)
end

function level:mousepressed(x, y, button)
  if self.mouse then
    self.mouse:mousepressed(x, y, button)
  end
end

function level:mousereleased(x, y, button)
  if self.mouse then
    self.mouse:mousereleased(x, y, button)
  end
end

function level:_update_active_area()
  local bbox = self.active_area_bbox
  local center = self.camera:get_center()
  local x, y = center.x - 0.5 * ACTIVE_AREA_WIDTH, center.y - 0.5 * ACTIVE_AREA_HEIGHT
  bbox.x, bbox.y = x, y
  bbox.width, bbox.height = ACTIVE_AREA_WIDTH, ACTIVE_AREA_HEIGHT
end


------------------------------------------------------------------------------
function level:update(dt)
  self.master_timer:update(dt)
  
  if self.hero then
    self.hero:update(dt)
    if self.camera then
      self.camera:set_target(self.hero:get_camera_target())
    end
  end
  
  if self.audio_set then self.audio_set:update(dt) end
  if self.level_map then self.level_map:update(dt) end
  if self.camera then self.camera:update(dt) end
  if self.active_area_bbox then self:_update_active_area() end
  
  for _,anim_set in pairs(self.animation_sets) do
    anim_set:update(dt)
  end
  for _,shard_set in pairs(self.shard_sets) do
    shard_set:update(dt)
  end
  
  local explosions = self.shard_explosions
  for i=#explosions,1,-1 do
    explosions[i]:update(dt)
    if explosions[i]:is_finished() then
      table.remove(explosions, i)
    end
  end
  
  local tile_explosions = self.tile_explosions
  for i=#tile_explosions,1,-1 do
    tile_explosions[i]:update(dt)
    if tile_explosions[i]:is_finished() then
      table.remove(tile_explosions, i)
    end
  end
  
  local sample_sets = self.audio_sample_sets
  for i=1,#sample_sets do
    sample_sets[i]:update(dt)
  end
  
end

------------------------------------------------------------------------------
function level:draw()

  if self.level_map then self.level_map:draw() end
  
  self.camera:set()
  
  for _,shard_set in pairs(self.shard_sets) do
    shard_set:draw_ground_layer()
  end
  
  if self.hero then self.hero:draw() end
  
  for _,shard_set in pairs(self.shard_sets) do
    shard_set:draw_sky_layer()
  end
  
  for i=1,#self.shard_explosions do
    self.shard_explosions[i]:draw()
  end
  
  self.camera:unset()
  
  local sample_sets = self.audio_sample_sets
  for i=1,#sample_sets do
    sample_sets[i]:draw()
  end
  
end

return level










