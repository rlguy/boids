
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- color_palette object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local color_palette = {}
color_palette.table_name = COLOR_PALETTE
color_palette.t_width = nil
color_palette.t_height = nil
color_palette.palette = nil
color_palette.ref_color = nil
color_palette.num_shades = nil
color_palette.img = nil

local color_palette_mt = { __index = color_palette }
function color_palette:new(tile_width, tile_height, num_shades, color)
  local h, s, l = color_palette:rgb_to_hsl(color[1], color[2], color[3])
  local ref_color = {h, s, l}
  local palette = {}
  
  local shades = {}
  local lstep = l / (num_shades + 1)
  for i=1,num_shades do
    local new_l = l - lstep * (i - 1)
    local r, g, b = color_palette:hsl_to_rgb(h, s, new_l)
    shades[i] = {math.floor(r), math.floor(g), math.floor(b), 255}
  end
  palette[1] = shades
  
  return setmetatable({ img = img,
                        t_width = tile_width, 
                        t_height = tile_height,
                        palette = palette,
                        num_shades = num_shades,
                        ref_color = ref_color}, color_palette_mt)
end


------------------------------------------------------------------------------
function color_palette:get_image()
  local image_data = self:generate_palette_imagedata(self.palette, self.t_width, self.t_height)
  local img = lg.newImage(image_data)
  self.img = img
  return img
end
------------------------------------------------------------------------------
-- h in range [0-360] in integer
function color_palette:add_color(h)
  h = h % 360
  local s = self.ref_color[2]
  local l = self.ref_color[3]
  
  local shades = {}
  local lstep = l / (self.num_shades + 1)
  for i=1,self.num_shades do
    local new_l = l - lstep * (i - 1)
    local r, g, b = color_palette:hsl_to_rgb(h, s, new_l)
    shades[i] = {math.floor(r), math.floor(g), math.floor(b), 255}
  end
  
  self.palette[#self.palette+1]= shades
end

------------------------------------------------------------------------------
function color_palette:generate_tile_imagedata(width, height, r, g, b, a)
  if type(r) == 'table' then
    local t = r
    r, g, b, a = t[1], t[2], t[3], t[4]
  end

  local image_data = love.image.newImageData(width, height)
  for y=0,height-1 do
    for x=0,width-1 do
      image_data:setPixel(x, y, r, g, b, a)
    end
  end
  
  return image_data
end

------------------------------------------------------------------------------
function color_palette:generate_palette_imagedata(palette, t_width, t_height)
  local width = t_width * #palette[1]
  local height = t_height * #palette
  local image_data = love.image.newImageData(width, height)
  
  for j = 1,#palette do
    for i = 1,#palette[1] do
      local color = palette[j][i]
      local tile = color_palette:generate_tile_imagedata(t_width, t_height, color)
      image_data:paste(tile, t_width * (i - 1), 
                             t_height * (j - 1), 0, 0, t_width, t_height)
    end
  end
  
  return image_data
end

------------------------------------------------------------------------------
-- h in range [0-360] in integer
-- s and l in range [0,1] in float
function color_palette:hsl_to_rgb(h, s, l)
  h = h % 360

  local C = (1 - math.abs(2 * l - 1)) * s
  local X = C * (1 - math.abs((h / 60) % 2 - 1))
  local m = l - 0.5 * C
  local index = math.floor(h / 60)
  
  local r, g, b
  if     index == 0 then r, g, b = C, X, 0
  elseif index == 1 then r, g, b = X, C, 0
  elseif index == 2 then r, g, b = 0, C, X
  elseif index == 3 then r, g, b = 0, X, C
  elseif index == 4 then r, g, b = X, 0, C
  elseif index == 5 then r, g, b = C, 0, X end
  r, g, b = r + m, g + m, b + m
  r, g, b = 255 * r, 255 * g, 255 * b
  
  return r, g, b
end

------------------------------------------------------------------------------
-- r, g, b in range [0-255] in integer
function color_palette:rgb_to_hsl(r, g, b)
  r, g, b = r/255, g/255, b/255
  
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local avg = 0.5 * (max + min)
  local h, s, l = avg, avg, avg
  
  if max == min then
    h, s = 0, 0
  else
    local d = max - min
    if l > 0.5 then
      s = d / (2 - max - min)
    else
      s = d / (max + min)
    end
    
    if     max == r then
      local val = 0
      if g < b then val = 6 end
      h = (g - b) / d + val
    elseif max == g then
      h = (b - r) / d + 2
    elseif max == b then
      h = (r - g) / d + 4
    end
    
    h = h * 60
  end
  
  return h, s, l
end

------------------------------------------------------------------------------
function color_palette:update(dt)
end

------------------------------------------------------------------------------
function color_palette:draw()
  if self.img == nil then return end
  lg.setColor(255,255,255,255)
  lg.draw(self.img, 0, 0)
end

return color_palette



