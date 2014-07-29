
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- tile_palette object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local tile_palette = {}
tile_palette.table = 'tile_palette'
tile_palette.gradients = nil
tile_palette.spritebatch_image = nil

local tile_palette_mt = { __index = tile_palette }
function tile_palette:new()
  return setmetatable({ gradients = {} }, tile_palette_mt)
end

-- gradient is a tile_gradient object
-- name is a string used to access/index gradient
function tile_palette:add_gradient(gradient, name)
  local gradients = self.gradients
  if gradients[name] ~= nil then
    print("ERROR in tile_pallette:add_gradient(): gradient names must be unique")
    return
  end
  
  gradients[name] = gradient
end

function tile_palette:load()
  for _,grad in pairs(self.gradients) do
    grad:load()
  end
  self:_generate_spritebatch_image()
end

function tile_palette:replace_gradient(gradient, name)
  if not self.gradients[name] then
    print("ERROR in tile_pallette:replace_gradient(): cannot find gradient")
    return
  end
  
  local old_gradient = self.gradients[name]
  self.gradients[name] = gradient
  
  if type(name) == 'string' then
    for i=1,#self.gradients do
      if self.gradients[i] == old_gradient then
        self.gradients[i] = gradient
      end
    end
  end
  
  self:_generate_spritebatch_image()
end

function tile_palette:get_gradient(name)
  return self.gradients[name]
end

function tile_palette:_generate_spritebatch_image()
  local grads = self.gradients
  
  -- find width and height of final image
  local width, height = 0, 0
  for i,v in pairs(grads) do
    local g = grads[i]
    local g_width = g:get_image_width()
    if g_width > width then
      width = g_width
    end
    
    height = height + g:get_image_height()
  end
  
  if width > MAX_IMAGE_WIDTH or height > MAX_IMAGE_HEIGHT then
    local msg = "ERROR in tile_palette:generate_spritebatch_image(): final image"..
          "size (w="..width..",h="..height..") exceeds MAX_IMAGE_WIDTH or "..
          "MAX_IMAGE_HEIGHT (w="..MAX_IMAGE_WIDTH..",h="..MAX_IMAGE_HEIGHT..")"
          
    print(msg)
    return
  end
  
  -- draw tilesets to canvas
  local canvas = lg.newCanvas(width, height)
  local x, y = 0, 0
  lg.setCanvas(canvas)
  lg.setColor(255, 255, 255, 255)
  for _,g in pairs(grads) do
    local img = g:get_tileset_image()
    lg.draw(img, x, y)
    
    -- calculate quads
    local quads = {}
    local diag_quads = {}
    local gen_diag = g:has_diagonal_tiles()
    local idx = 1
    local num = g.num_colors
    local rows, cols = g.rows, g.cols
    local tw, th = g.t_width, g.t_height
    local tx, ty = 0, 0
    local diag_y_off = ty + rows * th
    local breakloop = false
    for j=1,rows do
      for i=1,cols do
        quads[idx] = lg.newQuad(tx, ty + y, tw, th, width, height)
        if gen_diag then
        	diag_quads[idx] = lg.newQuad(tx, ty + y + diag_y_off, tw, th, width, height)
        end
        
        tx = tx + tw
        idx = idx + 1
        if idx > num then
          breakloop = true
          break
        end
      end
      
      if breakloop then
        break
      end
      
      tx = 0
      ty = ty + th
    end
    g:set_quads(quads, diag_quads)
    
    y = y + img:getHeight()
  end
  lg.setCanvas()
  
  local imgdata = canvas:getImageData()
  local img = lg.newImage(imgdata)
  -- set spritebatch image
  for _,g in pairs(grads) do
    g:set_spritebatch_image(img)
  end
  self.spritebatch_image = img
end

function tile_palette:get_spritebatch_image()
  return self.spritebatch_image
end

------------------------------------------------------------------------------
function tile_palette:update(dt)
end

------------------------------------------------------------------------------
function tile_palette:draw()
end

return tile_palette



