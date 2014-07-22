
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- rectangle_tile_light object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local rtl = {}
rtl.table = 'rtl'
rtl.debug = false
rtl.level = nil
rtl.x = nil
rtl.y = nil
rtl.dimmer_ratio = nil
rtl.radius = nil
rtl.power = nil
rtl.fade_curve = nil

rtl.rectangle_bbox = nil
rtl.outer_bbox = nil
rtl.max_outer_bbox = nil
rtl.inner_bbox = nil

rtl.min_x = nil
rtl.max_x = nil
rtl.min_y = nil
rtl.max_y = nil

rtl.zones = nil
rtl.tile_id_by_table = nil
rtl.tile_zone_by_table = nil
rtl.tile_distance_tracker_by_table = nil

local UNUSED_TILE = 9
local TILE_WIDTH, TILE_HEIGHT = TILE_WIDTH, TILE_HEIGHT

local rtl_mt = { __index = rtl }
function rtl:new(level, x, y, width, height, radius, power, fade_curve)
  local rtl = setmetatable({}, rtl_mt)
  local self = rtl
  
  self.level = level
  self.x, self.y = x, y
  local rect = bbox:new(x, y, width, height)
  self.rectangle_bbox = rect
  self.power = power
  self.radius = radius
  self.fade_curve = fade_curve
  self.dimmer_ratio = vector2:new(1, 0)
  self.tile_id_by_table = {}
  self.tile_zone_by_table = {}
  self.tile_distance_tracker_by_table = {}
  self.distance_trackers = {}
  
  self._init(rtl)
  
  return rtl
end

function rtl:_init()
  self:_init_dimensions()
  self:_init_tiles()
end

function rtl:_init_tiles()
  local ob = self.outer_bbox
  self.tile_cover = rectangle_tile_cover:new(self.level, ob.x, ob.y, ob.width, ob.height)
  self.tile_cover:set_add_remove_tile_callback(self._add_remove_tiles, self)
  
  local tile_ids = self.tile_id_by_table
  local tile_zones = self.tile_zone_by_table
  local tile_trackers = self.tile_distance_tracker_by_table
  local tiles = self.tile_cover:get_tile_cover()
  for j=1,#tiles do
    for i=1,#tiles[j] do
      local tile = tiles[j][i]
      if tile.walkable then
        tile_zones[tile] = self:_get_tile_zone(tile)
        
        local tracker = self:_get_distance_tracker()
        tracker.x = self:_get_tile_distance(tile)
        tile_trackers[tile] = tracker
        
        tile_ids[tile] = tile:add_distance_light(tracker, self.dimmer_ratio,
                                                 self.radius, self.power, self.fade_curve)
      else
        tile_ids[tile] = UNUSED_TILE
      end
    end
  end
  
end

function rtl:_get_distance_tracker()
  if #self.distance_trackers == 0 then
    return {x = 0}
  else
    local tracker = self.distance_trackers[#self.distance_trackers]
    self.distance_trackers[#self.distance_trackers] = nil
    return tracker
  end
end

function rtl:_discard_distance_tracker(tracker)
  self.distance_trackers[#self.distance_trackers + 1] = tracker
end

function rtl:_get_tile_zone(tile)
  local x, y = tile.x + 0.5 * TILE_WIDTH, tile.y + 0.5 * TILE_HEIGHT
  local inner = self.inner_bbox
  local left, right = self.min_x, self.max_x
  local top, bottom = self.min_y, self.max_y
  
  if      x < left then
    if y < top then
      zone_no = 8
    elseif y > bottom then
      zone_no = 6
    else
      zone_no = 7
    end
  elseif x > right then 
    if y < top then
      zone_no = 2
    elseif y > bottom then
      zone_no = 4
    else
      zone_no = 3
    end
  else
    if y < top then
      zone_no = 1
    elseif y > bottom then
      zone_no = 5
    else
      zone_no = 0
    end
  end
  
  return zone_no
end

function rtl:_get_tile_distance(tile)
  local zone = self.tile_zone_by_table[tile]
  local x, y = tile.x + 0.5 * TILE_WIDTH, tile.y + 0.5 * TILE_HEIGHT
  
  if zone == 0 then 
    return 0
  end
  
  local dist
  local rect = self.rectangle_bbox
  if zone % 2 == 0 then
    local dx, dy
    if     zone == 2 then
      dx = x - (rect.x + rect.width)
      dy = y - rect.y
    elseif zone == 4 then
      dx = x - (rect.x + rect.width)
      dy = y - (rect.y + rect.height)
    elseif zone == 6 then
      dx = x - rect.x
      dy = y - (rect.y + rect.height)
    elseif zone == 8 then
      dx = x - rect.x
      dy = y - rect.y
    end
    dist = math.sqrt(dx*dx + dy*dy)
  else
    if     zone == 1 then
      dist = rect.y - y
    elseif zone == 3 then
      dist = x - (rect.x + rect.width)
    elseif zone == 5 then
      dist = y - (rect.y + rect.height)
    elseif zone == 7 then
      dist = rect.x - x
    end
    
    if dist < 0 then
      dist = 0
    end
  end
  
  return dist
end

function rtl:_init_dimensions()
  local x, y, width, height = self.rectangle_bbox:get_dimensions()
  local r = self.radius
  local htw, hth = 0.5 * TILE_WIDTH, 0.5 * TILE_HEIGHT
  self.outer_bbox = bbox:new(x - r, y - r, width + 2*r, height + 2*r)
  self.max_outer_bbox = bbox:new(x - r - htw, y - r - hth,
                                  width + 2*r + 2*htw, height + 2*r + 2*hth)
  self.inner_bbox = bbox:new(x + htw, y + hth, width - 2*htw, height - 2*hth)
  
  local b = self.inner_bbox
  self.min_x, self.max_x = b.x, b.x + b.width
  self.min_y, self.max_y = b.y, b.y + b.height
  
  local max_bbox = self.max_outer_bbox
  local zones = {}
  self.zones = zones
  local min_x, min_y = self.min_x, self.min_y
  local max_x, max_y = self.max_x, self.max_y
  local left_x = max_bbox.x
  local right_x = max_bbox.x + max_bbox.width
  local up_y = max_bbox.y
  local down_y = max_bbox.y + max_bbox.height
  zones[0] = self.inner_bbox
  zones[UP] = bbox:new(min_x, up_y, max_x - min_x, min_y - up_y)
  zones[UPRIGHT] = bbox:new(max_x, up_y, right_x - max_x, min_y - up_y)
  zones[RIGHT] = bbox:new(max_x, min_y, right_x - max_x, max_y - min_y)
  zones[DOWNRIGHT] = bbox:new(max_x, max_y, right_x - max_x, down_y - max_y)
  zones[DOWN] = bbox:new(min_x, max_y, max_x - min_x, down_y - max_y)
  zones[DOWNLEFT] = bbox:new(left_x, max_y, min_x - left_x, down_y - max_y)
  zones[LEFT] = bbox:new(left_x, min_y, min_x - left_x, max_y - min_y)
  zones[UPLEFT] = bbox:new(left_x, up_y, min_x - left_x, min_y - up_y)
  
end

function rtl:_add_remove_tiles(added, removed)
  local tile_ids = self.tile_id_by_table
  local tile_zones = self.tile_zone_by_table
  local tile_trackers = self.tile_distance_tracker_by_table
  
  for i=1,#added do
    local tile = added[i]
    if tile.walkable then
      tile_zones[tile] = self:_get_tile_zone(tile)
      
      local tracker = self:_get_distance_tracker()
      tracker.x = self:_get_tile_distance(tile)
      tile_trackers[tile] = tracker
      
      tile_ids[tile] = tile:add_distance_light(tracker, self.dimmer_ratio,
                                               self.radius, self.power, self.fade_curve)
    else
      tile_ids[tile] = UNUSED_TILE
    end
  end
  
  for i=1,#removed do
    local tile = removed[i]
    if tile_ids[tile] ~= UNUSED_TILE then
       -- remove_light todo
       self:_discard_distance_tracker(tile_trackers[tile])
       tile:remove_light(tile_ids[tile])
    end
    tile_ids[tile] = nil
    tile_zones[tile] = nil
    tile_trackers[tile] = nil
  end
end

function rtl:move(x, y)
  local tx, ty = x - self.x, y - self.y
  self.x, self.y = x, y
  
  self.rectangle_bbox:set_position(x, y)
  self.outer_bbox:translate(tx, ty)
  self.max_outer_bbox:translate(tx, ty)
  self.inner_bbox:translate(tx, ty)
  self.min_x, self.max_x = self.min_x + tx, self.max_x + tx
  self.min_y, self.max_y = self.min_y + ty, self.max_y + ty
  
  for i=1,#self.zones do
    self.zones[i]:translate(tx, ty)
  end
  
  self.tile_cover:move(self.outer_bbox.x, self.outer_bbox.y)
  self:_update_tile_zones()
  self:_update_distance_trackers()
end

function rtl:_update_tile_zones()
  local tile_zones = self.tile_zone_by_table
  local tiles = self.tile_id_by_table
  for tile,v in pairs(tiles) do
    if v ~= UNUSED_TILE then
      tile_zones[tile] = self:_get_tile_zone(tile)
    end
  end
end

function rtl:_update_distance_trackers()
  local tile_trackers = self.tile_distance_tracker_by_table
  local tiles = self.tile_id_by_table
  for tile,v in pairs(tiles) do
    if v ~= UNUSED_TILE then
      tile_trackers[tile].x = self:_get_tile_distance(tile)
    end
  end
end

------------------------------------------------------------------------------
function rtl:update(dt)
end

------------------------------------------------------------------------------
function rtl:draw()

  if self.debug then
    lg.setColor(0, 255, 0, 255)
    lg.setLineWidth(1)
    self.rectangle_bbox:draw()
    
    lg.setColor(0, 0, 255, 255)
    self.outer_bbox:draw()
    lg.setColor(0, 0, 255, 100)
    self.max_outer_bbox:draw()
    
    lg.setColor(255, 0, 0, 255)
    self.inner_bbox:draw()
    
    local out = self.outer_bbox
    lg.setColor(255, 0, 0, 100)
    lg.line(out.x, self.min_y, out.x + out.width, self.min_y)
    lg.line(out.x, self.max_y, out.x + out.width, self.max_y)
    lg.line(self.min_x, out.y, self.min_x, out.y + out.height)
    lg.line(self.max_x, out.y, self.max_x, out.y + out.height)
    
    lg.setColor(255, 255, 0, 255)
    lg.setLineWidth(2)
    for i=1,#self.zones do
      if i % 2 == 0 then
        lg.setColor(255, 255, 0, 255)
      else
        lg.setColor(0, 255, 255, 255)
      end
      self.zones[i]:draw()
    end
    
    lg.setColor(0, 0, 255, 100)
    local w, h = TILE_WIDTH, TILE_HEIGHT
    local tiles = self.tile_id_by_table
    local tile_zones = self.tile_zone_by_table
    local tile_trackers = self.tile_distance_tracker_by_table
    
    for tile,v in pairs(tiles) do
      if v ~= UNUSED_TILE then
        local d = tile_trackers[tile].x
        local ratio = math.max(1 - (d / self.radius), 0)
        local minc, maxc = 0, 255
        local c = minc + ratio * (maxc - minc)
        lg.setColor(c, 0, 0, 255)
        lg.rectangle('fill', tile.x, tile.y, w, h)
      end
    end
    
    lg.setColor(255, 255, 255, 0)
    for tile,v in pairs(tiles) do
      if v ~= UNUSED_TILE then
        lg.rectangle('line', tile.x, tile.y, w, h)
        local zone = tile_zones[tile]
        lg.print(zone, tile.x, tile.y)
      end
    end
    
  end
end

return rtl














