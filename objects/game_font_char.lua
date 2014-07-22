
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- game_font_char object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local gfc = {}
gfc.table = 'gfc'
gfc.const = nil
gfc.bitmap_width = nil
gfc.bitmap_height = nil
gfc.width = nil
gfc.height = nil
gfc.pixels = nil          -- table of pixel coordinates

local gfc_mt = { __index = gfc }
function gfc:new(char_pattern, size)
  local gfc = setmetatable({}, gfc_mt)
  
  gfc:_init_char(char_pattern, size)
  
  return gfc
end

function gfc:get_width()
  return self.width
end

function gfc:get_height()
  return self.height
end

function gfc:get_pixels()
  return self.pixels
end

function gfc:_init_char(char_pattern, size)
  local pat = char_pattern.pattern
  local const = char_pattern.char
  local width = #pat[1]
  local height = #pat
  local pixels = {}
  
  for j=1,height do
    for i=1,width do
      if pat[j][i] == 1 then
        pixels[#pixels + 1] = {x = (i-1) * size, y = (j-1) * size}
      end
    end
  end
  
  self.pixels = pixels
  self.const = const
  self.bitmap_width = width
  self.bitmap_height = height
  self.width = size * self.bitmap_width
  self.height = size * self.bitmap_height
end

------------------------------------------------------------------------------
function gfc:update(dt)
end

------------------------------------------------------------------------------
function gfc:draw()
end

return gfc































