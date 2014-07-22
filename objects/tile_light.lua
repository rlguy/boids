
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- tile_light object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local tile_light = {}
local tl = tile_light
tl.table = 'tile_light'
tl.debug = false
tl.level = nil
tl.level_map = nil
tl.x = nil
tl.y = nil
tl.position = nil
tl.dimmer_ratio = nil
tl.radius = nil
tl.width = nil
tl.height = nil
tl.bbox = nil

tl.tiles = nil
tl.tiles_by_table = nil
tl.tiles_to_add = nil
tl.tiles_to_remove = nil

tl.fade_curve = nil
tl.max_power = nil

tl.tile_cover = nil

local tile_light_mt = { __index = tile_light }
function tile_light:new(level, x, y, radius, power, fade_curve)
  local tl = setmetatable({}, tile_light_mt)
  
  tl.level = level
  tl.level_map = level:get_level_map()
  tl.x, tl.y = x, y
  tl.position = vector2:new(x, y)
  tl.dimmer_ratio = vector2:new(1, 0)
  tl.radius = radius
  tl.power = power
  tl.max_power = power
  tl.fade_curve = fade_curve
  tl.width, tl.height = radius, radius
  tl.bbox = bbox:new(x - radius, y - radius, 2*radius, 2*radius)
  
  local bbox = tl.bbox
  tl.tile_cover = rectangle_tile_cover:new(level, bbox.x, bbox.y, bbox.width, bbox.height)
  tl.tile_cover:set_add_remove_tile_callback(tl._add_remove_tiles, tl)
  local tiles = tl.tile_cover:get_tile_cover()
  tl.tiles = tiles
  
  local tiles_by_table = {}
  for j=1,#tiles do
    for i=1,#tiles[j] do
      local tile = tiles[j][i]
      if tile.walkable then
        tiles_by_table[tile] = tile:add_point_light(tl.position, tl.dimmer_ratio,
                                                     radius, power, fade_curve)
      else
        tiles_by_table[tile] = true
      end
    end
  end
  tl.tiles_by_table = tiles_by_table
  
  return tl
end

function tile_light:set_position(x, y)
  local tx, ty = x - self.x, y - self.y
  self.x, self.y = x, y
  self.position:set(x, y)
  
  local bbox = self.bbox
  bbox.x, bbox.y = bbox.x + tx, bbox.y + ty
  
  self.tile_cover:move(bbox.x, bbox.y)
end

function tile_light:_add_remove_tiles(added, removed)
  local tiles_by_table = self.tiles_by_table
  
  for i=1,#added do
    local tile = added[i]
    if tile.walkable then
      tiles_by_table[tile] = tile:add_point_light(self.position, self.dimmer_ratio,
                                                  self.radius, self.power, self.fade_curve)
    else
      tiles_by_table[tile] = true
    end
  end
  
  for i=1,#removed do
    local tile = removed[i]
    if tiles_by_table[tile] ~= true then
       tile:remove_light(tiles_by_table[tile])
    end
    tiles_by_table[tile] = nil
  end
end

------------------------------------------------------------------------------
function tile_light:update(dt)
end

------------------------------------------------------------------------------
function tile_light:draw()
  if self.debug then
    lg.setColor(0, 255, 255, 255)
    lg.circle('line', self.x, self.y, self.radius)
    lg.setColor(255, 0, 0, 255)
    lg.setPointSize(4)
    lg.point(self.x, self.y)
    
    self.bbox:draw()
    
    local w, h = TILE_WIDTH, TILE_HEIGHT
    local tiles = self.tiles
    lg.setColor(0, 255, 0, 100)
    for j=1,#tiles do
      for i=1,#tiles[j] do
        local t = tiles[j][i]
        lg.rectangle('line', t.x, t.y, w, h)
      end
    end
    
    local add_list = self.tile_cover.added_tiles
    local remove_list = self.tile_cover.removed_tiles
    lg.setColor(0, 255, 0, 255)
    for i=1,#add_list do
      local t = add_list[i]
      lg.rectangle('line', t.x, t.y, w, h)
    end
    lg.setColor(255, 0, 0, 255)
    for i=1,#remove_list do
      local t = remove_list[i]
      lg.rectangle('line', t.x, t.y, w, h)
    end
    
  end
end

return tile_light









