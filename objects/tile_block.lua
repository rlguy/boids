
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- tile_block object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local tb = {}
tb.table = TILE_BLOCK
tb.debug = false
tb.level = nil
tb.collider = nil
tb.x = nil
tb.y = nil
tb.width = nil
tb.height = nil
tb.bbox = nil
tb.columns = nil
tb.rows = nil

-- tiles
tb.tile_spritesheet = nil
tb.tile_gradient = nil
tb.tile_grid = nil

-- noise genration
tb.noise_scale = 0.07
tb.noise_min = 0.4
tb.noise_max = 0.5

-- bloom effect
tb.bloom = nil
tb.bloom_bbox = nil
tb.bloom_canvas = nil
tb.effect_pad = 8

-- tile light
tb.rect_light = nil
tb.light_radius = 300
tb.light_power = 0.8

local TILE_WIDTH, TILE_HEIGHT = TILE_WIDTH, TILE_HEIGHT

local tb_mt = { __index = tb }
-- x, y in world coordinates
-- columns, rows in number of tiles
function tb:new(level, x, y, columns, rows, tile_gradient, light_fade_curve)
  local tb = setmetatable({}, tb_mt)
  tb.level = level
  tb.tile_spritesheet = level:get_tile_spritesheet()
  tb.x, tb.y = x, y
  tb.width, tb.height = columns * TILE_WIDTH, rows * TILE_HEIGHT
  tb.bbox = bbox:new(tb.x, tb.y, tb.width, tb.height)
  tb.columns, tb.rows = columns, rows
  tb.tile_gradient = tile_gradient
  tb.bloom_bbox = bbox:new(0, 0, 0, 0)
  tb.fade_curve = light_fade_curve
  tb._init(tb)
  
  return tb
end

function tb:get_bbox()
  return self.bbox
end

function tb:hit(object, cx, cy, power)
  --print(object, cx, cy)
end

function tb:_init()
  self:_init_tile_grid()
  local noise = self:_generate_noise_grid()
  self:_init_tiles(noise)
  --self:_init_bloom_effect()
  self:_init_lighting()
  self:_init_collision()
end

function tb:_init_collision()
  self.collider = self.level:get_collider()
  self.collider:add_object(self.bbox, self)
end

function tb:_init_lighting()
  local x, y = self.x, self.y
  local w, h = self.width, self.height
  local radius = self.light_radius
  local power = self.light_power
  local fade_curve = self.fade_curve
  local light = rectangle_tile_light:new(self.level, x, y, w, h, 
                                          radius, power, fade_curve)
  self.rect_light = light
end

function tb:_refresh_bloom_canvas()
  local canvas = self.bloom_canvas
  canvas:clear()
  local tiles = self.tile_grid
  
  local x, y = self.effect_pad, self.effect_pad
  local w, h = TILE_WIDTH, TILE_HEIGHT
  local spritesheet = self.tile_spritesheet
  lg.setColor(255, 255, 255, 255)
  lg.setCanvas(canvas)
  for j=1,self.rows do
    for i=1,self.columns do
      local tile = tiles[j][i]
      lg.draw(spritesheet, tile.quad, x + (i-1)*w, y + (j-1)*h)
    end
  end
  lg.setCanvas()
end

function tb:_init_bloom_effect()
  local x, y = self.x, self.y
  local bbox = self.bloom_bbox
  local pad = self.effect_pad
  bbox.x, bbox.y = x - pad, y - pad
  bbox.width, bbox.height = self.width + 2 * pad, self.height + 2 * pad
  self.bloom_canvas = lg.newCanvas(bbox.width, bbox.height)
  self:_refresh_bloom_canvas()
  
  self.bloom = bloom_effect:new(self.level, bbox.x, bbox.y, self.bloom_canvas)
end

function tb:_init_tiles(noise)
  local gradient = self.tile_gradient
  local tiles = self.tile_grid
  for j=1,self.rows do
    for i=1,self.columns do
      local tile = tiles[j][i]
      local intensity = noise[j][i]
      local quad = gradient:get_quad(intensity)
      tile:_set_quad(quad)
      tile:set_gradient(gradient)
      tile:init_intensity(intensity)
    end
  end
end

function tb:_init_tile_grid()
  local cols, rows = self.columns, self.rows
  local grid = {}
  for i=1,rows do
    grid[i] = {}
  end
  
  local w, h = TILE_WIDTH, TILE_HEIGHT
  local x, y = self.x, self.y
  for j=1,rows do
    for i=1,cols do
      local tile = tile:new()
      tile.x, tile.y = x + (i-1)*w, y + (j-1)*h
      grid[j][i] = tile
    end
  end
  self.tile_grid = grid
end

function tb:_generate_noise_grid()
  local grid = self.tile_grid
  local offx, offy = 10000 * math.random(), 10000 * math.random()
  local scale = self.noise_scale
  local min, max = self.noise_min, self.noise_max
  
  local noise = {}
  for j=1,self.rows do
    noise[j] = {}
    for i=1,self.columns do
      local val = love.math.noise(offx + i*scale, offy + j*scale)
      val = min + val * (max - min)
      noise[j][i] = val
    end
  end
  
  return noise
end

------------------------------------------------------------------------------
function tb:update_shader()
  --self.bloom:update_draw()
end

function tb:update(dt)
  local tiles = self.tile_grid
  for j=1,#tiles do
    for i=1,#tiles[j] do
      tiles[j][i]:update(dt)
    end
  end
  
  --self:_refresh_bloom_canvas()
end

------------------------------------------------------------------------------
function tb:draw()
  
  --self.bloom:draw()
  
  lg.setColor(255, 255, 255, 255)
  local tiles = self.tile_grid
  local sp = self.tile_spritesheet
  local x, y = self.x, self.y
  local w, h = TILE_WIDTH, TILE_HEIGHT
  for j=1,#tiles do
    for i=1,#tiles[j] do
      local t = tiles[j][i]
      lg.draw(sp, t.quad, x + (i-1)*w, y + (j-1)*h)
    end
  end
  
  if self.debug then
    lg.setColor(0, 255, 0, 255)
    lg.setLineWidth(1)
    self.bbox:draw()
    self.bloom_bbox:draw()
    
    lg.setColor(255, 255, 255, 255)
    --lg.draw(self.bloom_canvas, self.bloom_bbox.x, self.bloom_bbox.y) 
    
  end
end

return tb


























