
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- game_font_string object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local gfs = {}
gfs.table = 'gfs'
gfs.debug = false
gfs.font = nil
gfs.string = nil
gfs.chars = nil
gfs.pixels = nil
gfs.size = nil
gfs.char_x_pad = 0
gfs.spritesheet = nil
gfs.cols = nil
gfs.rows = nil

gfs.min_intensity = 0
gfs.max_intensity = 1

gfs.noise_offx = nil
gfs.noise_offy = nil
gfs.noise_offz = nil
gfs.noise_scale = 0.07
gfs.lower_noise_range = 0
gfs.upper_noise_range = 0.4
gfs.noise_depth = 10

gfs.lower_power_limit = nil
gfs.upper_power_limit = nil
gfs.current_intensity = 0

gfs.default_crossfade_curve = curve:new(require("curves/linear_decrease_curve"))
gfs.default_crossfade_length = 50
gfs.crossfade_curve = gfs.default_crossfade_curve
gfs.crossfade_length = gfs.default_crossfade_length
gfs.current_crossfade_power = 1
gfs.min_crossfade_position = nil
gfs.max_crossfade_position = nil
gfs.left_crossfade_height = nil
gfs.right_crossfade_height = nil

gfs.current_alpha = 255
gfs.current_tile_gradient = nil

gfs.noise_animation_active = false
gfs.noise_z = gfs.noise_depth
gfs.noise_vx = 1
gfs.noise_vy = 0
gfs.noise_vz = 0

gfs.tile_flash_countdown = 0
gfs.is_pixels_static = false
gfs.spritebatch = nil
gfs.current_alpha_changed = false

gfs.is_loaded = false

local gfs_mt = { __index = gfs }
function gfs:new(font, str)
  local gfs = setmetatable({}, gfs_mt)
  gfs.string = str
  gfs.font = font
  gfs.size = font:get_size()
  gfs.spritesheet = font:get_spritesheet()
  gfs.spritebatch = lg.newSpriteBatch(gfs.spritesheet)
  gfs.palette = font:get_tile_palette()
  gfs.pixels = {}
  
  return gfs
end

function gfs:load()
  self:_init_pixels()
  self:_init_pixel_tiles()
  self:_init_crossfade()
  self.is_loaded = true
end

function gfs:set_noise_speed(vx, vy, vz)
  self.noise_vx = vx
  self.noise_vy = vy
  self.noise_vz = vz
end

function gfs:set_noise_scale(scale)
  self.noise_scale = scale
  self:_update_noise_animation(1/60)
end

function gfs:set_intensity_range(min, max)
  self.min_intensity = min
  self.max_intensity = max
end

function gfs:set_noise_ranges(lower_range, upper_range)
  self.lower_noise_range = lower_range
  self.upper_noise_range = upper_range
  self:_update_noise_animation(1/60)
end

function gfs:turn_noise_on()
  self.noise_animation_active = true
end

function gfs:turn_noise_off()
  self.noise_animation_active = false
end

function gfs:flash(power, time, flash_curve)
  if self.current_alpha == 0 then
    return  -- we wont see it
  end
  
  local pixels = self.pixels
  for i=1,#pixels do
    pixels[i].tile:flash(power, time, flash_curve)
  end
  
  if time > self.tile_flash_countdown then
    self.tile_flash_countdown = time
  end
end

function gfs:set_intensity(val)
  if val == self.current_intensity then
    return
  end
  
  self.current_intensity = val
  self.pixel_intensities_current = false
end

function gfs:set_gradient(gradient_name)
  local grad = self.font:get_gradient(gradient_name)
  if grad ~= self.current_tile_gradient then
    local pixels = self.pixels
    for i=1,#pixels do
      local px = pixels[i]
      px.tile:set_gradient(grad)
    end
  end
  
  self:_update_pixel_intensities()
end

function gfs:set_crossfade(power, length, curve)
  self.current_crossfade_power = power
  local changed = false
  if length  and self.crossfade_length ~= length then
    self.crossfade_length = length
    changed = true
  end
  
  if curve and self.crossfade_curve ~= curve then
    self.crossfade_curve = curve
    changed = true
  end
  
  if changed then
    self:_init_crossfade()
  end
  
  self.pixel_intensities_current = false
end

-- val is [0-255]
function gfs:set_alpha(val)
  if val == self.current_alpha then return end

  self.current_alpha = val
  self.current_alpha_changed = true
end

function gfs:get_width()
  return self.width
end
function gfs:get_height()
  return self.height
end

function gfs:_init_crossfade()
  local curve = self.crossfade_curve
  local len = self.crossfade_length
  self.min_crossfade_position = -len
  self.max_crossfade_position = self.width
  self.left_crossfade_height = curve:get(0)
  self.right_crossfade_height = curve:get(1)
end

function gfs:_init_pixel_tiles()
  local offx = 10000 * math.random()
  local offy = 10000 * math.random()
  local offz = 10000 * math.random()
  self.noise_offx, self.noise_offy, self.noise_offz = offx, offy, offz
  local scale = self.noise_scale
  local depth = self.noise_z
  local low_range = self.lower_noise_range
  local high_range = self.upper_noise_range
  local low_min, low_max = self.min_intensity, low_range
  local high_min, high_max = self.max_intensity - high_range, self.max_intensity
  self.lower_power_limit = low_max
  self.upper_power_limit = high_min

  local pixels = self.pixels
  local gradient = self.palette:get_gradient(self.font:get_default_gradient_name())
  self.current_tile_gradient = gradient
  local noise = self.noise_grid
  for i=1,#pixels do
    local px = pixels[i]
    px.tile = tile:new()
    px.tile.x, px.tile.y = px.x, px.y
    
    local i, j = px.i, px.j
    local val_low = love.math.noise(offx + i*scale, offy + j*scale, offz)
    local val_high = love.math.noise(offx + i*scale, offy + j*scale, offz + depth)
    local low_intensity = low_min + val_low * (low_max - low_min)
    local high_intensity = high_min + val_high * (high_max - high_min)
    
    px.min_power = low_intensity
    px.max_power = high_intensity
    px.current_power = 0
    
    local quad = gradient:get_quad(low_intensity)
    px.tile:_set_quad(quad)
    px.tile:set_gradient(gradient)
    px.tile:init_intensity(low_intensity)
  end
end

function gfs:_update_pixel_intensities()
  local minx, maxx = self.min_crossfade_position, self.max_crossfade_position
  local cross_power = self.current_crossfade_power
  local cross_x = minx + cross_power * (maxx - minx)
  local len = self.crossfade_length
  local mincx, maxcx = cross_x, cross_x + len
  local lp, hp = self.left_crossfade_height, self.right_crossfade_height
  local cross_curve = self.crossfade_curve
  
  local power = self.current_intensity
  
  local pixels = self.pixels
  for i=1,#pixels do
    local px = pixels[i]
    
    -- find crossfade power
    cross_power = nil
    local x, y = px.x, px.y
    if x < mincx then
      cross_power = lp
    elseif x > maxcx then
      cross_power = hp
    else
      local prog
      if maxcx - mincx ~= 0 then 
        prog = (x - mincx) / (maxcx - mincx)
      else
        prog = 1
      end
      cross_power = cross_curve:get(prog)
    end
    
    local min, max = px.min_power, px.max_power
    max = min + cross_power * (max - min)
    
    px.current_power = lerp(min, max, power)
    px.tile:init_intensity(px.current_power)
    px.tile:set_intensity(px.current_power)
  end
  
  self.pixel_intensities_current = true
end

function gfs:_init_pixels()
  local font = self.font
  local pixels = self.pixels
  local offx, offy = 0, 0
  local offi, offj = 0, 0
  local size = self.size
  local cols, rows = 0, math.ceil(font:get_height() / size)
  
  local pixel_idx = 1
  local max_char_height = 0
  for char_const in self.string:gmatch(".") do
    local char = font:get_char(char_const)
    if not char then
      print("ERROR in game_font_string - char_const "..char_const.." not found")
    end
    
    if char:get_height() > max_char_height then
      max_char_height = char:get_height()
    end
    
    local char_pixels = char:get_pixels()
    for i=1,#char_pixels do
      local char_px = char_pixels[i]
      local ii, jj = char_px.x / size + offi, char_px.y / size + offj
      pixels[pixel_idx] = self:_new_pixel(ii, jj, offx + char_px.x, offy + char_px.y)
      pixel_idx = pixel_idx + 1
    end
    
    offx = offx + char:get_width() + self.char_x_pad
    offi = offi + char.bitmap_width
    cols = cols + char.bitmap_width
  end

  self.cols, self.rows = cols, rows
  self.width = offx
  self.height = max_char_height
  
  -- sort left to right
  table.sort(pixels, function(a,b) if a.i ~= b.i then 
                                     return a.i < b.i
                                   else 
                                     return a.j < b.j 
                                   end
                     end)  
end

function gfs:_new_pixel(i, j, x, y)
  local px = {}
  px.x, px.y = x, y
  px.i, px.j = i, j
  px.width, px.height = self.size, self.size
  
  return px
end

function gfs:_update_noise_animation(dt)
  if not self.is_loaded then return end

  self.noise_z = self.noise_z + self.noise_vz * dt
  self.noise_offx = self.noise_offx + self.noise_vx * dt
  self.noise_offy = self.noise_offy + self.noise_vy * dt
  
  local offx = self.noise_offx
  local offy= self.noise_offy
  local offz = self.noise_offz
  
  local scale = self.noise_scale
  local depth = self.noise_z
  local low_min, low_max = self.min_intensity, self.lower_noise_range
  local high_min = self.max_intensity - self.upper_noise_range
  local high_max = self.max_intensity
  self.lower_power_limit = low_max
  self.upper_power_limit = high_min

  local pixels = self.pixels
  for i=1,#pixels do
    local px = pixels[i]
    
    local i, j = px.i, px.j
    local val_low = love.math.noise(offx + i*scale, offy + j*scale, offz)
    local val_high = love.math.noise(offx + i*scale, offy + j*scale, offz + depth)
    local low_intensity = low_min + val_low * (low_max - low_min)
    local high_intensity = high_min + val_high * (high_max - high_min)
    
    px.min_power = low_intensity
    px.max_power = high_intensity
  end
  
  self.pixel_intensities_current = false
end

------------------------------------------------------------------------------
function gfs:update(dt)
  local is_pixels_static = true

  if self.noise_animation_active then
    self:_update_noise_animation(dt)
    is_pixels_static = false
  end

  if not self.pixel_intensities_current then
    self:_update_pixel_intensities()
    is_pixels_static = false
  end
  
  if self.tile_flash_countdown > 0 then
    for i=1,#self.pixels do
      self.pixels[i].tile:update(dt)
    end
    self.tile_flash_countdown = self.tile_flash_countdown - dt
    if self.tile_flash_countdown < 0 then
      self.tile_flash_countdown = 0
    end
    is_pixels_static = false
  end
  
  if self.current_alpha_changed then
    is_pixels_static = false
    self.current_alpha_changed = false
  end
  
  if is_pixels_static and not self.is_pixels_static then
    -- pixels just became static
    self:_draw_pixels_to_spritebatch()
  end
  self.is_pixels_static = is_pixels_static
end

function gfs:_draw_pixels_to_spritebatch()
  local batch = self.spritebatch
  batch:clear()
  batch:bind()
  batch:setColor(255, 255, 255, self.current_alpha)
  local pixels = self.pixels
  for i=1,#pixels do
    local t = pixels[i].tile
    batch:add(t.quad, t.x, t.y)
  end
  batch:unbind()
end

------------------------------------------------------------------------------
function gfs:draw(x, y)
  x, y = math.floor(x or 0), math.floor(y or 0)
  
  if self.is_pixels_static then
    lg.setColor(255, 255, 255, 255)
    lg.draw(self.spritebatch, x, y)
  else
    if self.current_alpha > 0 then
      local spritesheet = self.spritesheet
      lg.setColor(255, 255, 255, self.current_alpha)
      local pixels = self.pixels
      for i=1,#pixels do
        local t = pixels[i].tile
        lg.draw(spritesheet, t.quad, x + t.x, y + t.y)
      end
    end
  end
  
  if not self.debug then return end
  lg.setLineWidth(2)
  lg.setColor(0, 255, 0, 255)
  local len = self.crossfade_length
  local w, h = self.width, self.height
  local lh, rh = (1-self.left_crossfade_height) * self.height, 
                 (1 - self.right_crossfade_height) * self.height
  local minx, maxx = self.min_crossfade_position, self.max_crossfade_position
  local power = self.current_crossfade_power
  local posx = minx + power * (maxx - minx)
  lg.line(x + posx, y + lh, x + posx + len, y + rh)
  
end

return gfs














