--[[
  CSC 486A - Assignment #2
  Ryan Guy V00484803
]]--


--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- polygonizer object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local lg = love.graphics

local CELL_QUAD = 1
local HORIZONTAL_QUAD = 2
local VERTICAL_QUAD = 3
local TRIANGLE_QUAD = 4
local TILE_QUAD = 5

local SOLID_TILE = 0
local UPRIGHT_TILE = 2
local DOWNRIGHT_TILE = 4
local DOWNLEFT_TILE = 6
local UPLEFT_TILE = 8

local pgr = {}
pgr.table = 'pgr'
pgr.debug = false
pgr.level = nil
pgr.primitives = nil
pgr.bbox = nil

pgr.tile_width = 20
pgr.tile_height = 20
pgr.cell_width = 2 * pgr.tile_width
pgr.cell_height = 2 * pgr.tile_height
pgr.cols = nil
pgr.rows = nil

pgr.default_radius = 200
pgr.min_radius = 120
pgr.surface_threshold = 0.5
pgr.min_surface_threshold = 0
pgr.max_surface_threshold = 0.9

pgr.cell_inside_case = 16
pgr.cell_outside_case = 1

pgr.unused_cell_tables = nil
pgr.surface_cells = nil
pgr.flood_fill_cells = nil

pgr.spritebatch_image = nil
pgr.spritebatch_quads = nil
pgr.spritebatch = nil
pgr.gradient = require("gradients/named/orangeyellow")

pgr.marked_cells = nil
pgr.cell_queue = nil
pgr.is_current = false


pgr.marching_square_draw_cases = {}
pgr._init_marching_square_draw_cases = nil
do
  local cases = pgr.marching_square_draw_cases
  local tw, th = pgr.tile_width, pgr.tile_height
  local upright = 0
  local downright = math.pi / 2
  local downleft = math.pi
  local upleft = 3 * math.pi / 2
  local ox, oy = 0.5 * tw, 0.5 * th
  
  pgr._init_marching_square_draw_cases = function(self)
                                           tw, th = self.tile_width, self.tile_height
                                           ox, oy = 0.5 * tw, 0.5 * th
                                         end
  
  cases[1] = function(x, y)
               -- blank case
             end
  cases[2] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + ox, y + th + oy, upright,
                               1, 1, ox, oy)
             end
  cases[3] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + th + oy, upleft,
                               1, 1, ox, oy)
             end
  cases[4] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[HORIZONTAL_QUAD], x, y + th)
             end
  cases[5] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + oy, downleft,
                               1, 1, ox, oy)
             end
  cases[6] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + ox, y + oy, upleft,
                               1, 1, ox, oy)
                               
               batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + th + oy, downright,
                               1, 1, ox, oy)
                               
               batch:add(q[TILE_QUAD], x + tw, y)
               
               batch:add(q[TILE_QUAD], x, y + th)
             end
  cases[7] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[VERTICAL_QUAD], x + tw, y)
             end
  cases[8] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + ox, y + oy, upleft,
                               1, 1, ox, oy)
                      
               batch:add(q[TILE_QUAD], x + tw, y)
                               
               batch:add(q[HORIZONTAL_QUAD], x, y + th)
             end
  cases[9] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + ox, y + oy, downright,
                               1, 1, ox, oy)
             end
  cases[10] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[VERTICAL_QUAD], x, y)
              end
  cases[11] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + oy, upright,
                                1, 1, ox, oy)
                               
                batch:add(q[TRIANGLE_QUAD], x + ox, y + th + oy, downleft,
                                1, 1, ox, oy)
               
                batch:add(q[TILE_QUAD], x, y)
                
                batch:add(q[TILE_QUAD], x + tw, y + th)
              end
  cases[12] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + oy, upright,
                                1, 1, ox, oy)
                      
                batch:add(q[TILE_QUAD], x, y)
                               
                batch:add(q[HORIZONTAL_QUAD], x, y + th)
              end
  cases[13] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[HORIZONTAL_QUAD], x, y)
              end
  cases[14] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + th + oy, downright,
                                1, 1, ox, oy)
                      
                batch:add(q[TILE_QUAD], x + tw, y)
                               
                batch:add(q[VERTICAL_QUAD], x, y)
              end
  cases[15] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[TRIANGLE_QUAD], x + ox, y + th + oy, downleft,
                                1, 1, ox, oy)
                      
                batch:add(q[TILE_QUAD], x, y)
                               
                batch:add(q[VERTICAL_QUAD], x + tw, y)
              end
  cases[16] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[CELL_QUAD], x, y)
              end
end

pgr._init_marching_square_tile_cases = nil
pgr.marching_square_tile_cases = {}
do
  local cases = pgr.marching_square_tile_cases
  local tw, th = pgr.tile_width, pgr.tile_height
  local upright = UPRIGHT_TILE
  local downright = DOWNRIGHT_TILE
  local downleft = DOWNLEFT_TILE
  local upleft = UPLEFT_TILE
  local solid = SOLID_TILE
  local ox, oy = 0.5 * tw, 0.5 * th
  
  pgr._init_marching_square_tile_cases = function(self)
                                           tw, th = self.tile_width, self.tile_height
                                           ox, oy = 0.5 * tw, 0.5 * th
                                         end
                                         
  local init_field_data = function(self, tile)
                            local nx, ny, val = self.primitives:get_field_normal(tile.x, tile.y)
                            tile.field_vector = {x = nx, y = ny, z = 0}
                            tile.field_value = val
                            local cx, cy = tile.x + 0.5 * self.tile_width, 
                                           tile.y + 0.5 * self.tile_height
                            _, _, tile.center_field_value = self.primitives:get_field_normal(cx, cy)
                          end
  
  cases[1] = function(x, y, data)
               -- blank case
             end
  cases[2] = function(self, x, y, data)
               local tile = {}
               tile.x = x
               tile.y = y + th
               tile.direction = upright
               init_field_data(self, tile)
               
               data[#data + 1] = tile
             end
  cases[3] = function(self, x, y, data)
               local tile = {}
               tile.x = x + tw
               tile.y = y + th
               tile.direction = upleft
               init_field_data(self, tile)
               
               data[#data + 1] = tile
             end
  cases[4] = function(self, x, y, data)
               local tile1 = {}
               tile1.x = x
               tile1.y = y + th
               tile1.direction = solid
               init_field_data(self, tile1)
               
               local tile2 = {}
               tile2.x = x + tw
               tile2.y = y + th
               tile2.direction = solid
               init_field_data(self, tile2)
               
               data[#data + 1] = tile1
               data[#data + 1] = tile2
             end
  cases[5] = function(self, x, y, data)
               local tile = {}
               tile.x = x + tw
               tile.y = y
               tile.direction = downleft
               init_field_data(self, tile)
               
               data[#data + 1] = tile
             end
  cases[6] = function(self, x, y, data)
               local tile1 = {}
               tile1.x = x
               tile1.y = y
               tile1.direction = upleft
               init_field_data(self, tile1)
               
               local tile2 = {}
               tile2.x = x + tw
               tile2.y = y
               tile2.direction = solid
               init_field_data(self, tile2)
               
               local tile3 = {}
               tile3.x = x
               tile3.y = y + th
               tile3.direction = solid
               init_field_data(self, tile3)
               
               local tile4 = {}
               tile4.x = x + tw
               tile4.y = y + th
               tile4.direction = downright
               init_field_data(self, tile4)
               
               data[#data + 1] = tile1
               data[#data + 1] = tile2
               data[#data + 1] = tile3
               data[#data + 1] = tile4
             end
  cases[7] = function(self, x, y, data)
               local tile1 = {}
               tile1.x = x + tw
               tile1.y = y
               tile1.direction = solid
               init_field_data(self, tile1)
               
               local tile2 = {}
               tile2.x = x + tw
               tile2.y = y + th
               tile2.direction = solid
               init_field_data(self, tile2)
               
               data[#data + 1] = tile1
               data[#data + 1] = tile2
             end
  cases[8] = function(self, x, y, data)
               local tile1 = {}
               tile1.x = x
               tile1.y = y
               tile1.direction = upleft
               init_field_data(self, tile1)
               
               local tile2 = {}
               tile2.x = x + tw
               tile2.y = y
               tile2.direction = solid
               init_field_data(self, tile2)
               
               local tile3 = {}
               tile3.x = x
               tile3.y = y + th
               tile3.direction = solid
               init_field_data(self, tile3)
               
               local tile4 = {}
               tile4.x = x + tw
               tile4.y = y + th
               tile4.direction = solid
               init_field_data(self, tile4)
               
               data[#data + 1] = tile1
               data[#data + 1] = tile2
               data[#data + 1] = tile3
               data[#data + 1] = tile4
             end
  cases[9] = function(self, x, y, data)
               local tile = {}
               tile.x = x
               tile.y = y
               tile.direction = downright
               init_field_data(self, tile)
               
               data[#data + 1] = tile
             end
  cases[10] = function(self, x, y, data)
                local tile1 = {}
                tile1.x = x
                tile1.y = y
                tile1.direction = solid
                init_field_data(self, tile1)
               
                local tile2 = {}
                tile2.x = x
                tile2.y = y + th
                tile2.direction = solid
                init_field_data(self, tile2)
               
                data[#data + 1] = tile1
                data[#data + 1] = tile2
              end
  cases[11] = function(self, x, y, data)
                local tile1 = {}
                tile1.x = x
                tile1.y = y
                tile1.direction = solid
                init_field_data(self, tile1)
               
                local tile2 = {}
                tile2.x = x + tw
                tile2.y = y
                tile2.direction = upright
                init_field_data(self, tile2)
               
                local tile3 = {}
                tile3.x = x
                tile3.y = y + th
                tile3.direction = solid
                init_field_data(self, tile3)
               
                local tile4 = {}
                tile4.x = x + tw
                tile4.y = y + th
                tile4.direction = downleft
                init_field_data(self, tile4)
               
                data[#data + 1] = tile1
                data[#data + 1] = tile2
                data[#data + 1] = tile3
                data[#data + 1] = tile4
              end
  cases[12] = function(self, x, y, data)
                local tile1 = {}
                tile1.x = x
                tile1.y = y
                tile1.direction = solid
                init_field_data(self, tile1)
               
                local tile2 = {}
                tile2.x = x + tw
                tile2.y = y
                tile2.direction = upright
                init_field_data(self, tile2)
               
                local tile3 = {}
                tile3.x = x
                tile3.y = y + th
                tile3.direction = solid
                init_field_data(self, tile3)
               
                local tile4 = {}
                tile4.x = x + tw
                tile4.y = y + th
                tile4.direction = solid
                init_field_data(self, tile4)
               
                data[#data + 1] = tile1
                data[#data + 1] = tile2
                data[#data + 1] = tile3
                data[#data + 1] = tile4
              end
  cases[13] = function(self, x, y, data)
                local tile1 = {}
                tile1.x = x
                tile1.y = y
                tile1.direction = solid
                init_field_data(self, tile1)
               
                local tile2 = {}
                tile2.x = x + tw
                tile2.y = y
                tile2.direction = solid
                init_field_data(self, tile2)
               
                data[#data + 1] = tile1
                data[#data + 1] = tile2
              end
  cases[14] = function(self, x, y, data)
                local tile1 = {}
                tile1.x = x
                tile1.y = y
                tile1.direction = solid
                init_field_data(self, tile1)
               
                local tile2 = {}
                tile2.x = x + tw
                tile2.y = y
                tile2.direction = solid
                init_field_data(self, tile2)
               
                local tile3 = {}
                tile3.x = x
                tile3.y = y + th
                tile3.direction = solid
                init_field_data(self, tile3)
               
                local tile4 = {}
                tile4.x = x + tw
                tile4.y = y + th
                tile4.direction = downright
                init_field_data(self, tile4)
               
                data[#data + 1] = tile1
                data[#data + 1] = tile2
                data[#data + 1] = tile3
                data[#data + 1] = tile4
              end
  cases[15] = function(self, x, y, data)
                local tile1 = {}
                tile1.x = x
                tile1.y = y
                tile1.direction = solid
                init_field_data(self, tile1)
               
                local tile2 = {}
                tile2.x = x + tw
                tile2.y = y
                tile2.direction = solid
                init_field_data(self, tile2)
               
                local tile3 = {}
                tile3.x = x
                tile3.y = y + th
                tile3.direction = downleft
                init_field_data(self, tile3)
               
                local tile4 = {}
                tile4.x = x + tw
                tile4.y = y + th
                tile4.direction = solid
                init_field_data(self, tile4)
               
                data[#data + 1] = tile1
                data[#data + 1] = tile2
                data[#data + 1] = tile3
                data[#data + 1] = tile4
              end
  cases[16] = function(self, x, y, data)
                local tile1 = {}
                tile1.x = x
                tile1.y = y
                tile1.direction = solid
                init_field_data(self, tile1)
               
                local tile2 = {}
                tile2.x = x + tw
                tile2.y = y
                tile2.direction = solid
                init_field_data(self, tile2)
               
                local tile3 = {}
                tile3.x = x
                tile3.y = y + th
                tile3.direction = solid
                init_field_data(self, tile3)
               
                local tile4 = {}
                tile4.x = x + tw
                tile4.y = y + th
                tile4.direction = solid
                init_field_data(self, tile4)
               
                data[#data + 1] = tile1
                data[#data + 1] = tile2
                data[#data + 1] = tile3
                data[#data + 1] = tile4
              end
end
          

local pgr_mt = { __index = pgr }
function pgr:new(level, x, y, width, height, tile_width, tile_height)
  local pgr = setmetatable({}, pgr_mt)
  pgr.tile_width = tile_width or TILE_WIDTH
  pgr.tile_height = tile_height or TILE_HEIGHT
  pgr.cell_width = 2 * pgr.tile_width
  pgr.cell_height = 2 * pgr.tile_height
  pgr._init_marching_square_draw_cases(pgr)
  pgr._init_marching_square_tile_cases(pgr)
  
  pgr.level = level
  pgr.primitives = implicit_primitive_set:new(level, x, y, width, height)
  pgr.marked_cells = {}
  pgr.cell_queue = {}
  pgr.neighbour_storage = {}
  pgr.surface_cells = {}
  pgr.flood_fill_cells = {}
  pgr.tile_data = {}
  for i=1,8 do
    pgr.neighbour_storage[i] = {i=nil, j=nil}
  end
  
  local cols = math.ceil(width / pgr.cell_width)
  local rows = math.ceil(height / pgr.cell_height)
  local width, height = cols * pgr.cell_width, rows * pgr.cell_height
  pgr.cols, pgr.rows = cols, rows
  
  pgr.bbox = bbox:new(x, y, width, height)
  
  pgr:_init_cell_tables()
  pgr:_init_textures()
  
  return pgr
end

function pgr:set_surface_threshold(thresh)
  local min, max = self.min_surface_threshold, self.max_surface_threshold
  if thresh > max then thresh = max end
  if thresh < min then thresh = min end
  self.surface_threshold = thresh
end

function pgr:get_tile_data()
  return self.tile_data
end

function pgr:_init_cell_tables()
  self.unused_cell_tables = {}
  -- populate pgr with some empty cell_tables
  local n = 6000
  for i=1,n do
    self.unused_cell_tables[i] = {}
  end
end

function pgr:_generate_triangle_image(width, height)
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

function pgr:_generate_rectangle_image(width, height)
  local square = love.image.newImageData(width, height)
  for j=0,square:getWidth()-1 do
    for i=0,square:getHeight()-1 do
      square:setPixel(j, i, 255,255,255,255)
    end
  end
  return lg.newImage(square)
end


function pgr:_init_textures()
  -- blank white shapes
  local cell_img = self:_generate_rectangle_image(self.cell_width, self.cell_height)
  local horz_img = self:_generate_rectangle_image(2*self.tile_width, self.tile_height)
  local vert_img = self:_generate_rectangle_image(self.tile_width, 2*self.tile_height)
  local triangle_img = self:_generate_triangle_image(self.tile_width, self.tile_height)
  local tile_img = self:_generate_rectangle_image(self.tile_width, self.tile_height)
  
  
  -- place images on a canvas to generate spritebatch
  local w = cell_img:getWidth() + horz_img:getWidth() + 
            vert_img:getWidth() + triangle_img:getWidth() + tile_img:getWidth()
  local h = cell_img:getHeight()
  local canvas = lg.newCanvas(w, h)
  lg.setColor(255, 255, 255, 255)
  lg.setCanvas(canvas)
  local x, y = 0, 0
  lg.draw(cell_img, x, y)
  x = x + cell_img:getWidth()
  lg.draw(horz_img, x, y)
  x = x + horz_img:getWidth()
  lg.draw(vert_img, x, y)
  x = x + vert_img:getWidth()
  lg.draw(triangle_img, x, y)
  x = x + triangle_img:getWidth()
  lg.draw(tile_img, x, y)
  lg.setCanvas()
  
  local imgdata = canvas:getImageData()
  self.spritebatch_image = lg.newImage(imgdata)
  
  -- generate quads for the spritebatch image
  local quads = {}
  local x, y = 0, 0
  quads[CELL_QUAD] = lg.newQuad(x, y, self.cell_width, self.cell_height, w, h)
  x = x + cell_img:getWidth()
  quads[HORIZONTAL_QUAD] = lg.newQuad(x, y, 2*self.tile_width, self.tile_height, w, h)
  x = x + horz_img:getWidth()
  quads[VERTICAL_QUAD] = lg.newQuad(x, y, self.tile_width, 2*self.tile_height, w, h)
  x = x + vert_img:getWidth()
  quads[TRIANGLE_QUAD] = lg.newQuad(x, y, self.tile_width, self.tile_height, w, h)
  x = x + triangle_img:getWidth()
  quads[TILE_QUAD] = lg.newQuad(x, y, self.tile_width, self.tile_height, w, h)
  
  self.spritebatch_quads = quads
  self.spritebatch = lg.newSpriteBatch(self.spritebatch_image, 20000)
end

function pgr:keypressed(key)  
end

function pgr:keyreleased(key)
end

function pgr:mousepressed(x, y, button) 
end

function pgr:mousereleased(x, y, button)
end

function pgr:add_point(x, y, radius)
  radius = radius or self.default_radius
  
  if radius < self.min_radius then radius = self.min_radius end
  
  local p = implicit_point:new(x, y, radius)
  local b = p:get_bbox()
  if not self.bbox:contains(b) then
    return
  end
  self.primitives:add_primitive(p)
  
  self.is_current = false
  return p
end

function pgr:add_line(x1, y1, x2, y2)
  local line = implicit_line:new(x1, y1, x2, y2, self.default_radius)
  self.primitives:add_primitive(line)
  
  self.is_current = false
  return line
end

function pgr:add_rectangle(x, y, width, height)
  local rect = implicit_rectangle:new(x, y, width, height, self.default_radius)
  self.primitives:add_primitive(rect)
  
  self.is_current = false
  return rect
end

-- returns index (i, j) and position (cx, cy) of the cell containing point (x, y)
function pgr:_get_cell_at_position(x, y)
  local i = math.floor((x - self.bbox.x) / self.cell_width) + 1
  local j = math.floor((y - self.bbox.y) / self.cell_height) + 1
  local cx = (i-1) * self.cell_width + self.bbox.x
  local cy = (j-1) * self.cell_height + self.bbox.y
  
  return i, j, cx, cy
end

-- returns top left corner of cell indexed at (i, j)
function pgr:_get_cell_position(i, j)
  return (i-1) * self.cell_width + self.bbox.x, 
         (j-1) * self.cell_height + self.bbox.y
end

-- calculates hash value of cell indexed at (i, j)
function pgr:_get_cell_hash_value(i, j)
  return self.cols * (j-1) + i
end

-- returns whether point (x, y) is inside the implicit surface
function pgr:_is_inside_surface(x, y)
  return self.primitives:get_field_value(x, y) > self.surface_threshold
end

-- calculates marching square case (1 to 16) of cell indexed at (i, j)
function pgr:_get_cell_marching_square_case(i, j)
  local case = 0

  -- top left corner of cell
  local x = (i-1) * self.cell_width + self.bbox.x
  local y = (j-1) * self.cell_height + self.bbox.y
  if self:_is_inside_surface(x, y) then
    case = case + 8
  end
  
  -- top right corner
  x = x + self.cell_width
  if self:_is_inside_surface(x, y) then
    case = case + 4
  end
  
  -- bottom right corner
  y = y + self.cell_height
  if self:_is_inside_surface(x, y) then
    case = case + 2
  end
  
  -- bottom left corner
  x = x - self.cell_width
  if self:_is_inside_surface(x, y) then
    case = case + 1
  end
  
  -- cases start at 1 for lua indexing
  return case + 1
end

-- returns index (i, j) of cell that lies on the boundary of surface near
-- an implicit primitive
-- returns false if seed cannot be found
function pgr:_get_primitive_seed_cell(primitive)
  -- start at center cell
  local cx, cy = primitive:get_center()
  local i, j, x, y = self:_get_cell_at_position(cx, cy)
  local case = self:_get_cell_marching_square_case(i, j)
  if case ~= self.cell_inside_case then
    if case == self.cell_outside_case then
      return false
    else
      return i, j
    end
  end
  
  -- move right until cell has a portion outside of the implicit surface
  while true do
    i = i + 1
    local case = self:_get_cell_marching_square_case(i, j)
    if case ~= self.cell_inside_case then
      return i, j
    end
    
    if i > self.cols then
      return false
    end
  end
end

function pgr:_mark_cell(i, j)
  self.marked_cells[self:_get_cell_hash_value(i, j)] = true
end

function pgr:_is_cell_marked(i, j)
  return self.marked_cells[self:_get_cell_hash_value(i, j)]
end

function pgr:_clear_marked_cells()
  table.clear_hash(self.marked_cells)
end

-- places all cell neighbours into storage table
-- storage table in form {{i=i1,j=j1}, {i=i2,j=j2}, {i=i3,j=j3}, ...}
function pgr:_get_cell_neighbours(i, j, storage)
  storage[1].i, storage[1].j = i-1, j-1   -- upleft
  storage[2].i, storage[2].j = i,   j-1   -- up
  storage[3].i, storage[3].j = i+1, j-1   -- upright
  storage[4].i, storage[4].j = i+1, j     -- right
  storage[5].i, storage[5].j = i+1, j+1   -- downright
  storage[6].i, storage[6].j = i,   j+1   -- down
  storage[7].i, storage[7].j = i-1, j+1   -- downleft
  storage[8].i, storage[8].j = i-1, j     -- left
end

-- creates a new cell table
function pgr:_new_cell_table(i, j, case)
  local cell
  if #self.unused_cell_tables > 0 then
    cell = self.unused_cell_tables[#self.unused_cell_tables]
    self.unused_cell_tables[#self.unused_cell_tables] = nil
    cell.i, cell.j, cell.case = i, j, case
  else
    cell = {i=i, j=j, case=case}
  end
  cell.x, cell.y = self:_get_cell_position(cell.i, cell.j)
  return cell
end

function pgr:_clear_cell_table(tb)
  local unused = self.unused_cell_tables
  local idx = #unused + 1
  for i=#tb,1,-1 do
    unused[idx] = tb[i]
    tb[i] = nil
    idx = idx + 1
  end
end

function pgr:_polygonalize_surface()
  local surface_cells = self.surface_cells
  local neighbours = self.neighbour_storage
  local queue = self.cell_queue
  table.clear(queue)
  self:_clear_cell_table(surface_cells)
  self:_clear_marked_cells()
  
  local primitives = self.primitives:get_primitives()
  
  for i=1,#primitives do
    local primitive = primitives[i]
    
    -- seed may already have been marked
    local i, j = self:_get_primitive_seed_cell(primitive)
    if not self:_is_cell_marked(i, j) then
    
      self:_mark_cell(i, j)
      local case = self:_get_cell_marching_square_case(i, j)
      queue[#queue+1] = self:_new_cell_table(i, j, case)
      
      -- continuation algorithm
      local in_case, out_case = self.cell_inside_case, self.cell_outside_case
      while #queue > 0 do
        local cell = table.pop(queue)
        self:_get_cell_neighbours(cell.i, cell.j, neighbours)
        
        for i=1,#neighbours do
          local ncell = neighbours[i]
          if not self:_is_cell_marked(ncell.i, ncell.j) then
            self:_mark_cell(ncell.i, ncell.j)
            local case = self:_get_cell_marching_square_case(ncell.i, ncell.j)
            if case ~= in_case and case ~= out_case then
              queue[#queue+1] = self:_new_cell_table(ncell.i, ncell.j, case)
            end
          end
        end
        
        surface_cells[#surface_cells + 1] = cell
      end
    end
  end

end

function pgr:_flood_fill_surface()
  local flood_cells = self.flood_fill_cells
  local neighbours = self.neighbour_storage
  local queue = self.cell_queue
  table.clear(queue)
  self:_clear_cell_table(flood_cells)
  self:_clear_marked_cells()
  
  local primitives = self.primitives:get_primitives()
  
  for i=1,#primitives do
    local primitive = primitives[i]
    
    -- seed cell is at the centre of each primitive
    local i, j = self:_get_cell_at_position(primitive:get_center())
    if not self:_is_cell_marked(i, j) then
    
      self:_mark_cell(i, j)
      local case = self:_get_cell_marching_square_case(i, j)
      queue[#queue+1] = self:_new_cell_table(i, j, case)
      
      -- flood fill algorithm
      local in_case = self.cell_inside_case
      while #queue > 0 do
        local cell = table.pop(queue)
        self:_get_cell_neighbours(cell.i, cell.j, neighbours)
        
        for i=2,#neighbours,2 do
          local ncell = neighbours[i]
          if not self:_is_cell_marked(ncell.i, ncell.j) then
            self:_mark_cell(ncell.i, ncell.j)
            local case = self:_get_cell_marching_square_case(ncell.i, ncell.j)
            if case == in_case then
              queue[#queue+1] = self:_new_cell_table(ncell.i, ncell.j, case)
            end
          end
        end
        
        flood_cells[#flood_cells + 1] = cell
      end
    end
  end

end

function pgr:_draw_to_spritebatch()
  local cells = self.surface_cells
  local batch = self.spritebatch
  local case_funcs = self.marching_square_draw_cases
  batch:clear()
  batch:bind()
  
  local hw, hh = 0.5 * self.cell_width, 0.5 * self.cell_height
  local min, max = self.surface_threshold, 1
  local idiff = 1 / (max - min)
  local grad = self.gradient
  local glen = #grad
  
  local c = grad[1]
  batch:setColor(c[1], c[2], c[3], c[4])
  for i=1,#cells do
    local cell = cells[i]
    case_funcs[cell.case](self, cell.x, cell.y)
  end
  
  local fcells = self.flood_fill_cells
  for i=1,#fcells do
    local cell = fcells[i]
    local cx, cy = cell.x + hw, cell.y + hh
    local val = self.primitives:get_field_value(cx, cy)
    local ratio = (val - min) * idiff
    ratio = math.min(1, ratio)
    ratio = math.max(0, ratio)
    
    local cidx = math.floor(1 + ratio * (glen - 1))
    local c = grad[cidx]
    batch:setColor(c[1], c[2], c[3], c[4])
    
    case_funcs[cell.case](self, cell.x, cell.y)
  end
  
  batch:unbind()
end

function pgr:_generate_tile_data()
  local data = self.tile_data
  table.clear(data)
  local case_funcs = self.marching_square_tile_cases
  
  local surface = self.surface_cells
  local flood = self.flood_fill_cells
  for i=1,#surface do
    local cell = surface[i]
    case_funcs[cell.case](self, cell.x, cell.y, data)
  end
  
  for i=1,#flood do
    local cell = flood[i]
    case_funcs[cell.case](self, cell.x, cell.y, data)
  end
end

function pgr:force_update()
  self.is_current = false
  self:update()
end

function pgr:update()
  self.primitives:update()

  if self.is_current then return end
  
  self:_polygonalize_surface()
  self:_flood_fill_surface()
  self:_generate_tile_data()
  self:_draw_to_spritebatch()
  
  self.is_current = true
end

function pgr:_draw_debug()
  lg.setColor(0, 0, 255, 255)
  self.bbox:draw()
  
  -- polygonzied surface
  lg.setColor(255, 255, 255, 255)
  lg.draw(self.spritebatch, 0, 0)
  
  -- cell grid
  local cw, ch = self.cell_width, self.cell_height
  lg.setColor(0, 0, 0, 50)
  local x = self.bbox.x
  local yi = self.bbox.y
  local yf = self.bbox.y + self.bbox.height
  for i=1,self.cols-1 do
    x = x + cw
    lg.line(x, yi, x, yf)
  end
  
  local y = self.bbox.y
  local xi = self.bbox.x
  local xf = self.bbox.x + self.bbox.width
  for i=1,self.rows-1 do
    y = y + ch
    lg.line(xi, y, xf, y)
  end
  
  -- tile grid
  local tw, th = self.tile_width, self.tile_height
  lg.setColor(0, 0, 0, 30)
  local x = self.bbox.x
  local yi = self.bbox.y
  local yf = self.bbox.y + self.bbox.height
  for i=1,2*self.cols-1 do
    x = x + tw
    lg.line(x, yi, x, yf)
  end
  
  local y = self.bbox.y
  local xi = self.bbox.x
  local xf = self.bbox.x + self.bbox.width
  for i=1,2*self.rows-1 do
    y = y + tw
    lg.line(xi, y, xf, y)
  end
  
  self.primitives:draw()
  local primitives = self.primitives:get_primitives()
  for idx=1,#primitives do
    local cx, cy = primitives[idx]:get_center()
    local w, h = self.cell_width, self.cell_height
    local i, j, x, y = self:_get_cell_at_position(cx, cy)
    
    lg.setColor(0, 0, 255, 30)
    lg.rectangle("fill", x, y, w, h)
    
    -- seed cell
    local i, j = self:_get_primitive_seed_cell(primitives[idx])
    local x, y = self:_get_cell_position(i, j)
    lg.setColor(255, 0, 0, 50)
    lg.rectangle("fill", x, y, w, h)
  end
  
  -- surface cells
  local w, h = self.cell_width, self.cell_height
  local cells = self.surface_cells
  lg.setColor(0, 255, 0, 100)
  for idx=1,#cells do
    local i, j = cells[idx].i, cells[idx].j
    local x, y = self:_get_cell_position(i, j)
    lg.rectangle("fill", x, y, w, h)
  end
  
  --[[
  -- cell at mouse position
  local mx, my = love.mouse.getPosition()
  local w, h = self.cell_width, self.cell_height
  local i, j, x, y = self:_get_cell_at_position(mx, my)
  local case = self:_get_cell_marching_square_case(i, j)
  
  lg.setColor(0, 0, 255, 30)
  lg.rectangle("fill", x, y, w, h)
  lg.setColor(255, 0, 0, 255)
  lg.print(case, x, y)
  ]]--
end


------------------------------------------------------------------------------
function pgr:draw()
  if not self.debug then return end
  
  self:_draw_debug()
end

return pgr













