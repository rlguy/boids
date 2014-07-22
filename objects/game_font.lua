
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- game_font object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local gf = {}
gf.table = 'gf'
gf.debug = true
gf.is_loaded = false
gf.chars = nil
gf.font_pattern = nil
gf.size = nil
gf.height = nil
gf.tile_gradients_by_key = nil
gf.num_colors = 255
gf.palette = nil

gf.default_gradient_name = nil
gf.default_gradient = nil

local gf_mt = { __index = gf }
function gf:new(font_pattern, pixel_size)
  local gf = setmetatable({}, gf_mt)
  gf.size = pixel_size
  gf.font_pattern = font_pattern
  gf.tile_gradients_by_key = {}
  
  return gf
end


function gf:_init_tile_palette()
  local palette = tile_palette:new()
  for key,gradient in pairs(self.tile_gradients_by_key) do
    palette:add_gradient(gradient, key)
  end
  palette:load()
  
  for key,_ in pairs(self.tile_gradients_by_key) do
    self.tile_gradients_by_key[key] = palette:get_gradient(key)
  end
  
  self.palette = palette
  self.default_gradient = palette:get_gradient(self.default_gradient_name)
end

function gf:_init_chars()
  local font_pattern = self.font_pattern
  local max_height = 0
  local chars = {}
  for i=1,#font_pattern do
    local char_pattern = font_pattern[i]
    local const = char_pattern.char
    chars[const] = game_font_char:new(char_pattern, self.size)
    
    if chars[const]:get_height() > max_height then
      max_height = chars[const]:get_height()
    end
  end
  
  self.chars = chars
  self.height = max_height
end

function gf:get_size()
  return self.size
end

function gf:get_char(char_const)
  if self.chars[char_const] then
    return self.chars[char_const]
  else
    return false
  end
end

function gf:get_height()
  return self.height
end

function gf:get_size()
  return self.size
end

function gf:get_spritesheet()
  return self.palette:get_spritebatch_image()
end

function gf:get_default_gradient_name()
  return self.default_gradient_name
end

function gf:get_tile_palette()
  return self.palette
end

function gf:add_gradient(gradient_table, key)
  if self.is_loaded then return end
  local t_gradient = tile_gradient:new(gradient_table, self.num_colors, 
                                       self.size, self.size)
  self.tile_gradients_by_key[key] = t_gradient
  
  if not self.default_gradient_name then
    self.default_gradient_name = key
  end
  return t_gradient
end

function gf:get_gradient(key)
  local grad = self.tile_gradients_by_key[key]
  if not grad then
    grad = self.tile_gradients_by_key[self.default_gradient_name]
    print("ERROR in game_font:get_gradient() - gradient "..key.."not found")
  end
  
  return grad
end

function gf:set_num_colors(n) 
  if self.is_loaded then return end
  self.num_colors = n
end

function gf:load()
  self:_init_tile_palette()
  self:_init_chars()
  self.is_loaded = true
end

------------------------------------------------------------------------------
function gf:update(dt)
end

------------------------------------------------------------------------------
function gf:draw()
  if not self.debug then return end
  
  local img = self.palette:get_spritebatch_image()
  lg.setColor(255, 255, 255, 255)
  lg.draw(img, 0, 0)
  
end

return gf



