
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- tile_layer object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local tile_layer = {}
tile_layer.table = 'tile_layer'
tile_layer.imgdata = nil
tile_layer.data = nil                -- 2d array of pixel values from image
tile_layer.width = nil               -- in tiles
tile_layer.height = nil
tile_layer.t_width = nil
tile_layer.t_height = nil
tile_layer.gradient = nil
tile_layer.tile_type = nil

-- preview
tile_layer.preview_enabled = false
tile_layer.preview_data = nil
tile_layer.spritebatch_image = nil
tile_layer.preview_grid = nil
tile_layer.preview_min_color = 0
tile_layer.preview_max_color = 255
tile_layer.preview_x = 64
tile_layer.preview_y = 64
tile_layer.preview_xoff = 0
tile_layer.preview_yoff = 0
tile_layer.preview_t_width = 32
tile_layer.preview_t_height = 32
tile_layer.preview_width = 870
tile_layer.preview_height = 800
tile_layer.transparent_image = nil
tile_layer.transparent_quad = nil

local tile_layer_mt = { __index = tile_layer }

-- image_name is a tilemap image filename
-- gradient is a tile_gradient object with spritebatch initialized
-- nil_value is [0,255] pixel value and represents a nil tile in the tilemap image
function tile_layer:new(imgdata, x, y, width, height, gradient, nil_value, 
                        tile_type, tile_width, tile_height)
  nil_value = nil_value or 255
  local tile_width = tile_width or TILE_WIDTH
  local tile_height = tile_height or TILE_HEIGHT
  
  local tile_layer = setmetatable({ imgdata = imgdata,
                        imgdata_x = x,
                        imgdata_y = y,
                        width = width,
                        height = height,
                        t_width = tile_width,
                        t_height = tile_height,
                        gradient = gradient,
                        nil_value = nil_value,
                        tile_type = tile_type }, tile_layer_mt)
  
  return tile_layer
end

function tile_layer:get_gradient()
  return self.gradient
end

function tile_layer:get_imgdata()
  return self.imgdata
end

function tile_layer:get_tile_type()
  return self.tile_type
end

function tile_layer:get_tile_type()
  return self.tile_type
end

------------------------------------------------------------------------------
function tile_layer:update(dt)
end

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- PREVIEW
--[[----------------------------------------------------------------------]]--
--##########################################################################--

-- initializes preview of tilelayer for testing
function tile_layer:initialize_preview()
  if not self.preview_enabled then
    -- read imgdata into table of pixel values
    local imgdata = self.imgdata
    local data = {}
    local height, width = imgdata:getWidth(), imgdata:getHeight()
    for j=1,height do
      local row = {}
      for i=1,width do
        local px_val = imgdata:getPixel(i-1, j-1)
        row[i] = px_val
      end
      data[j] = row
    end
    
    self.preview_data = data
    
    local t_img = love.image.newImageData(self.t_width, self.t_height)
    local t_img = lg.newImage(t_img)
    local t_quad = lg.newQuad(0, 0, self.t_width, self.t_height, 
                                    self.t_width, self.t_height)
    self.transparent_image = t_img
    self.transparent_quad = t_quad
  end

  self.preview_enabled = true
  self.spritebatch_image = self.gradient:get_spritebatch_image()
  self.quads = self.gradient:get_quads()
  
  -- empty grid for quads
  local grid = {}
  local w, h = self.width, self.height
  for j=1,h do
    grid[j] = {}
  end
  
  grid = self:_generate_preview_colors(grid)
  self.preview_grid = grid
end

function tile_layer:set_preview_offset(xoff, yoff)
  xoff = math.max(xoff, 0)
  xoff = math.min(xoff, self.width * self.preview_t_width - self.preview_width)
  yoff = math.max(yoff, 0)
  yoff = math.min(yoff, self.height * self.preview_t_height - self.preview_height)

  self.preview_xoff = xoff
  self.preview_yoff = yoff
end

function tile_layer:get_preview_offset()
  return self.preview_xoff, self.preview_yoff
end

-- min < max in [0,255]
function tile_layer:set_preview_color_range(min, max)
  if min > max then
    return
  end
  
  if self.preview_min_color == min and self.preview_max_color == max then
    return
  end
  
  self.preview_min_color = min
  self.preview_max_color = max
  self:initialize_preview()
end

function tile_layer:get_preview_color_range()
  return self.preview_min_color, self.preview_max_color
end

function tile_layer:set_preview_gradient(tile_gradient)
  self.gradient = tile_gradient
  self.spritebatch_image = tile_gradient:get_spritebatch_image()
  self:initialize_preview()
end

function tile_layer:set_preview_tile_dimensions(t_width, t_height)
  self.preview_t_width = t_width
  self.preview_t_height = t_height
end

function tile_layer:get_preview_tile_dimensions()
  return self.preview_t_width, self.preview_t_height
end

function tile_layer:_generate_preview_colors(grid)
  local data = self.preview_data
  local width, height = self.width, self.height
  
  local quad_hash = {}
  quad_hash[self.nil_value] = self.transparent_quad
  for j=1,height do
    for i=1,width do
      local px_val = data[j][i]
      local quad
      if quad_hash[px_val] then
        quad = quad_hash[px_val]
      else
        quad = self:_get_preview_quad(px_val)
        quad_hash[px_val] = quad
      end
      
      grid[j][i] = quad
    end
  end
  
  return grid
end

-- returns quad corresponding to [0-255] pixel value
function tile_layer:_get_preview_quad(px_val, quad_hash)
  local min, max = self.preview_min_color, self.preview_max_color
  local t = (px_val - min) / (max - min)  
  if t < 0 then
    t = 0
  elseif t > 1 then
    t = 1
  end

  return self.gradient:get_quad(t)
end

------------------------------------------------------------------------------
function tile_layer:draw_preview(highlight)

  -- draw preview pane
  local img = self.spritebatch_image
  local t_img = self.transparent_image
  local x, y = self.preview_x, self.preview_y
  local width, height = self.preview_width, self.preview_height
  local tw, th = self.preview_t_width, self.preview_t_height
  local xoff, yoff = self.preview_xoff, self.preview_yoff
  local draw_xoff, draw_yoff = -(xoff % tw), -(yoff % th)
  local rows, cols = math.floor(height / th) + 1, math.floor(width / tw) + 1
  local grid = self.preview_grid
  local start_i, start_j = math.floor(xoff / tw), math.floor(yoff / th) + 1
  local end_i, end_j = start_i + cols, start_j + rows
  
  start_i = math.max(start_i, 1)
  start_i = math.min(start_i, self.width)
  start_j = math.max(start_j, 1)
  start_j = math.min(start_j, self.height)
  end_i = math.max(end_i, 1)
  end_i = math.min(end_i, self.width)
  end_j = math.max(end_j, 1)
  end_j = math.min(end_j, self.height)
  
  lg.setColor(255, 255, 255, 255)
  lg.setStencil(function() lg.rectangle('fill', x, y, width, height)  end)
  local tx, ty = x, y
  local scale = self.preview_t_width / self.t_width 
  for j=start_j,end_j do
    for i=start_i, end_i do
      lg.setColor(255, 255, 255, 255)
      local quad = grid[j][i]
      if quad == self.transparent_quad then
        lg.drawq(t_img, quad, tx + draw_xoff, ty + draw_yoff, 0, scale, scale)
      else
        lg.drawq(img, quad, tx + draw_xoff, ty + draw_yoff, 0, scale, scale)
      end
      
      if highlight and quad ~= self.transparent_quad then
        lg.setColor(0, 0, 0, 255)
        local x, y, w, h = quad:getViewport()
        x = tx + draw_xoff
        y = ty + draw_yoff
        lg.rectangle('fill', x, y, w, h)
      end
      
      tx = tx + tw
    end
    
    tx = self.preview_x
    ty = ty + th
  end
  lg.setStencil()
  
  -- draw border around pane
  local bdr = 5
  lg.setColor(0, 0, 0, 255)
  lg.rectangle('fill', x-bdr, y-bdr, width + 2 * bdr, bdr)
  lg.rectangle('fill', x-bdr, y+height, width + 2 * bdr, bdr)
  lg.rectangle('fill', x-bdr, y-bdr, bdr, height + 2 * bdr)
  lg.rectangle('fill', x+width, y-bdr, bdr, height + 2 * bdr)
  
  lg.setColor(0,0,0,255)
  lg.print(self.preview_min_color.." "..self.preview_max_color, x, y-20)
  
end



return tile_layer





















