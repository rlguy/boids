
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- tile_gradient object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local STATIC_BORDER = 0
local DYNAMIC_BORDER = 1

local tile_gradient = {}
tile_gradient.gradient = nil
tile_gradient.t_width = nil
tile_gradient.t_height = nil
tile_gradient.num_colors = nil
tile_gradient.rows = nil                -- tiles in rows, cols, of tile image
tile_gradient.cols = nil


tile_gradient.max_image_size = MAX_IMAGE_WIDTH
tile_gradient.tileset_imgdata = nil
tile_gradient.tileset_image = nil       -- image of all tiles colored with
                                        -- all shades
tile_gradient.spritebatch_image = nil
tile_gradient.quads = nil
tile_gradient.diag_quads = nil

tile_gradient.diag_enabled = false

tile_gradient.bdr_type = nil
tile_gradient.bdr_color = nil
tile_gradient.bdr_alpha = nil

tile_gradient.bdr_alpha_curve = nil
tile_gradient.bdr_min_alpha = nil
tile_gradient.bdr_max_alpha = nil

tile_gradient.bdr_gradient = nil
tile_gradient.bdr_min_gradient = nil
tile_gradient.bdr_max_gradient = nil

local tile_gradient_mt = { __index = tile_gradient }

-- gradient is table of shades in form {{r,g,b,a},{r,g,b,a},...,{r,g,b,a}}
-- num_colors - default is number of colors in gradient
function tile_gradient:new(gradient, num_colors, t_width, t_height)
  num_colors = num_colors or #gradient
  local t_width, t_height = t_width or TILE_WIDTH, t_height or TILE_HEIGHT
  
  -- map gradient colors
  if num_colors ~= #gradient then
    local inv_num = 1 / num_colors
    local len = #gradient
    local g = {}
    for i=1,num_colors do
      local idx = math.floor(i * inv_num * len) + 1
      if idx > len then idx = len end
      g[i] = gradient[idx]
    end
    
    gradient = g
  end
        
  return setmetatable({ gradient = gradient,
                        t_width = t_width,
                        t_height = t_height,
                        tileset_image = img,
                        tileset_imgdata = imgdata,
                        rows = rows,
                        cols = cols,
                        num_colors = #gradient,
                        diag_enabled = diag_enabled}, tile_gradient_mt)
end

function tile_gradient:add_diagonals()
  self.diag_enabled = true
end

function tile_gradient:add_border(border_color, border_alpha)
  self.bdr_type = STATIC_BORDER
  self.bdr_color = border_color
  self.bdr_alpha = border_alpha
end

function tile_gradient:add_border_blend_curve(border_color, border_alpha_curve, 
                                          min_alpha, max_alpha)
  self.bdr_type = DYNAMIC_BORDER
  self.bdr_color = border_color
  self.bdr_alpha_curve = border_alpha_curve
  self.bdr_min_alpha = min_alpha
  self.bdr_max_alpha = max_alpha
end

function tile_gradient:add_border_gradient(bdr_gradient, min_gradient, max_gradient)
  self.bdr_type = DYNAMIC_BORDER
  self.bdr_gradient = bdr_gradient
  self.bdr_color = bdr_gradient[1]
  self.bdr_min_gradient = min_gradient or 0
  self.bdr_max_gradient = max_gradient or 1
  
  if not self.bdr_min_alpha then
    self.bdr_min_alpha = 1
    self.bdr_max_alpha = 1
  end
end

function tile_gradient:set_spritebatch_image_width(width)
  self.max_image_size = width
end

function tile_gradient:load()
  local gradient = self.gradient
  local t_width, t_height = self.t_width, self.t_height
  local bdr_color, bdr_alpha = self.bdr_color, self.bdr_alpha
  local diag_enabled = self.diag_enabled
  
  local img, imgdata,rows, 
     cols = self:_generate_tileset_image(gradient, t_width, t_height, diag_enabled)
  self.rows, self.cols = rows, cols
  self.tileset_image = img
  self.tileset_imgdata = imgdata         
end

function tile_gradient:get_tileset_image()
  return self.tileset_image
end

function tile_gradient:get_spritebatch_image()
  return self.spritebatch_image
end

function tile_gradient:has_diagonal_tiles()
	return self.diag_enabled
end

function tile_gradient:get_image_height()
	return self.tileset_image:getHeight()
end

function tile_gradient:get_image_width()
	return self.tileset_image:getWidth()
end

function tile_gradient:set_spritebatch_image(spritebatch_image)
  self.spritebatch_image = spritebatch_image
end

-- t in range [0,1]
function tile_gradient:get_quad(t)
  local idx = math.floor(self.num_colors * t)
  if idx == 0 then
    idx = 1
  end
  
  return self.quads[idx]
end

-- t in range [0,1]
function tile_gradient:get_diagonal_quad(t)
  local idx = math.floor(self.num_colors * t)
  if idx == 0 then
    idx = 1
  end
  
  return self.diag_quads[idx]
end

function tile_gradient:get_quads()
  return self.quads
end

-- list of quads in a table correspinding to tile_gradient's spritebatch
-- ordered from left to right, row by row.
function tile_gradient:set_quads(quad_list, diag_quads)
  self.quads = quad_list
  if #diag_quads > 0 then
  	self.diag_quads = diag_quads
  end
end

-- fills tile with white pixels
function tile_gradient:_get_blank_tile_image(width, height)
  local square = love.image.newImageData(width, height)
  for j=0,square:getWidth()-1 do
    for i=0,square:getHeight()-1 do
      square:setPixel(j, i, 255,255,255,255)
    end
  end
  return lg.newImage(square)
end

function tile_gradient:_get_blank_diagonal_tile_image(width, height)
  local square = love.image.newImageData(width, height)
  for j=0,square:getWidth()-1 do
    for i=0,square:getHeight()-1 do
    	if i > j then
      	square:setPixel(j, i, 255,255,255,255)
      end
    end
  end
  return lg.newImage(square)
end

-- fills a tile size image with 1 pixel thick white border
function tile_gradient:_get_blank_border_image(width, height)
  local bdr = love.image.newImageData(width, height)
  local w, h = width, height
  for j=0,h-1 do
    bdr:setPixel(0, j, 255, 255, 255,255)
    bdr:setPixel(w-1, j, 255, 255, 255,255)
  end
  for i=0,w-1 do
    bdr:setPixel(i, 0, 255, 255, 255,255)
    bdr:setPixel(i, h-1, 255, 255, 255,255)
  end
  
  return lg.newImage(bdr)
end

function tile_gradient:_get_blank_diagonal_border_image(width, height)
  local bdr = love.image.newImageData(width, height)
  local w, h = width, height
  for j=0,h-1 do
    bdr:setPixel(0, j, 255, 255, 255,255)
  end
  for i=0,w-1 do
    bdr:setPixel(i, h-1, 255, 255, 255,255)
  end
  
  if width == height then
  	for i=0,w-1 do
  		bdr:setPixel(i, i, 255, 255, 255,255)
  	end
  end
  
  return lg.newImage(bdr)
end

-- gradient is table of shades in form {{r,g,b,a},{r,g,b,a},...,{r,g,b,a}}
-- bdr_color in form {r,g,b,255}
-- alpha is blending value of border with tile [0-1], smaller value, lighter border
function tile_gradient:_generate_tileset_image(gradient, width, height, gen_diag)
  local tile_img = self:_get_blank_tile_image(width, height)
  local bdr_img = self:_get_blank_border_image(width, height)
  local diag_tile_img = self:_get_blank_diagonal_tile_image(width, height)
  local diag_bdr_img = self:_get_blank_diagonal_border_image(width, height)
  
  -- image dimensions
  local len = #gradient
  local max_size = self.max_image_size
  local cols = math.floor(max_size / width)
  if cols > len then
    cols = len
  end
  local full_rows = math.floor(len / cols)
  local rem_row = len % cols                 -- remainder of tiles on last row
  local rows = full_rows
  if rem_row > 0 then
    rows = rows + 1
  end
  
  -- draw tiles to canvas
  local px_width = cols * width
  local px_height = rows * height
  if gen_diag then
  	px_height = 2 * px_height
  end
  
  
  local canvas = lg.newCanvas(px_width, px_height)
  lg.setCanvas(canvas)
  
  local x, y = 0, 0
  local y_offset = rows * height
  local xstep, ystep = width, height
  local idx = 1
  local break_loop = false
  local bdr_color = self.bdr_color
  local alpha = self.bdr_alpha
  local has_border = self.bdr_type
  local bdr_type = self.bdr_type
  for j=1,rows do
    for i=1,cols do
      local color = gradient[idx]
      idx = idx + 1
    
      -- draw tile color
      lg.setColor(color)
      lg.draw(tile_img, x, y)
      if gen_diag then
      	lg.draw(diag_tile_img, x, y + y_offset)
      end
      
      if has_border then
        -- calculate border blend color
        local a = alpha
        if bdr_type == DYNAMIC_BORDER then
          local progress = 1
          if self.bdr_alpha_curve then
            progress = self.bdr_alpha_curve:get(idx / self.num_colors)
          end
          local min, max = self.bdr_min_alpha, self.bdr_max_alpha
          a = lerp(min, max, progress)
          
          if self.bdr_gradient then
            local progress = idx / self.num_colors
            local min, max = self.bdr_min_gradient, self.bdr_max_gradient
            local gidx = math.floor(lerp(min, max, progress) * #self.bdr_gradient)
            if gidx == 0 then
              gidx = 1
            end
            bdr_color = self.bdr_gradient[gidx]
          end
        end
        
        local ia = 1 - a
        local r, g, b = color[1], color[2], color[3]
        local br, bg, bb = bdr_color[1], bdr_color[2], bdr_color[3]
        local nr, ng, nb = ia*r + a*br, ia*g + a*bg, ia*b + a*bb
        
        -- draw tile border
        lg.setColor(nr, ng, nb, 255)
        lg.draw(bdr_img, x, y)
        if gen_diag then
          lg.draw(diag_bdr_img, x, y + y_offset)
        end
      end
      
      x = x + xstep
      
      if idx > len then
        break_loop = true
        break
      end
    end
    x = 0
    y = y + ystep
    
    if break_loop then
      break
    end
  end
  lg.setCanvas()
  
  -- convert canvas to image
  local imgdata = canvas:getImageData()
  local img = lg.newImage(imgdata)
  
  return img, imgdata, rows, cols
end

------------------------------------------------------------------------------
function tile_gradient:update(dt)
end

------------------------------------------------------------------------------
function tile_gradient:draw()
end

return tile_gradient



