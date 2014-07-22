
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- level_collider object 
--    reports collisions for map_point objects and bbox objects
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local level_collider = {}
local lc = level_collider
lc.table = 'level_collider'
lc.debug = false
lc.level = nil

lc.level_map = nil
lc.tile_maps = nil

-- objects
lc.objects_by_table = nil         -- all objects in collider hashed by table

-- data for updating bbox
lc.new_maps = nil
lc.old_maps = nil
lc.changed = nil

local level_collider_mt = { __index = level_collider }
function level_collider:new(level, level_map)
  local lc = setmetatable({}, level_collider_mt)
  lc.level = level
  lc.level_map = level_map
  lc.tile_maps = {}
  lc.objects = {}
  lc.objects_by_table = {}
  lc.new_maps = {}
  lc.old_maps = {}
  lc.changed = {}
  
  return lc
end

function level_collider:add_tile_map(tmap)
  self.tile_maps[#self.tile_maps + 1] = tmap
  tmap.collider.debug = self.debug
end

function level_collider:add_object(object, parent)
  if self.objects_by_table[object] then
    return -- already added
  end  

  if     object.table == MAP_POINT then
		self:_insert_point(object, parent)
	elseif object.table == BBOX then
		self:_insert_bbox(object, parent)
	end
	
	self.objects_by_table[object] = object
end

function level_collider:update_object(object)
  if not self.objects_by_table[object] then
    return -- object not in collider
  end

  if     object.table == MAP_POINT then
    self:_update_point(object)
  elseif object.table == BBOX then
    self:_update_bbox(object)
  end
end

function level_collider:remove_object(object)
  if not self.objects_by_table[object] then
    return -- object not in collider
  end

  if     object.table == MAP_POINT then
    self:_remove_point(object)
  elseif object.table == BBOX then
    self:_remove_bbox(object)
  end
end

function level_collider:get_collisions(object, storage)
  if self.objects_by_table[object] then 
    if     object.table == MAP_POINT and object.cldata then
      return self:_get_point_collisions(object)
    elseif object.table == BBOX and object.cldata then
      return self:_get_bbox_collisions(object, storage)
    end
  else  -- object not in collider
    if     object.get_x and object.get_width then
      return self:_get_collisions_at_bbox(object, storage)
    elseif object.get_x then
      return self:_get_collisions_at_position(object)
    end
  end
end

-- hit_object, object being collided with (must implement function hit_object.hit())
-- hitter_object, object that collided with hit_object
-- cx, cy, optional points of collision
-- power, reported power of collision [0-1]
function level_collider:report_collision(hit_object, hitter_object, cx, cy, power)
  if hit_object.hit then
    hit_object:hit(hitter_object, cx, cy, power)
  end
end

-- ###############################################################################


function level_collider:_insert_point(point, parent)
  local level_map = self.level_map
  local pos = point:get_position()
  local tmap = level_map:get_tile_map_at_position(pos)
  
  tmap.collider:add_object(point, parent)
  
  point.cldata = {}
  point.cldata.parent = parent
  point.cldata.collider = tmap.collider
  point.cldata.tmap = tmap
  
end

function level_collider:_insert_bbox(bbox, parent)
  
  local level_map = self.level_map
  local tmaps = level_map:get_tile_maps_at_bbox(bbox)
  for i=1,#tmaps do
    tmaps[i].collider:add_object(bbox, parent)
  end
  
  local cldata = bbox.cldata or {}
  if not cldata.tmaps_temp_table then
    cldata.tmaps_temp_table = {}
    cldata.added_temp_table = {}
    cldata.storage_temp_table = {}
  end
  cldata.parent = parent
  
  if cldata.pos then
    cldata.pos.x, cldata.pos.y = bbox.x, bbox.y
  else
    cldata.pos = vector2:new(bbox.x, bbox.y)
  end
  
  -- corners
  if cldata.upleft then
    cldata.upleft:set(bbox.x, bbox.y)
    cldata.upright:set(bbox.x + bbox.width, bbox.y)
    cldata.downleft:set(bbox.x, bbox.y + bbox.height)
    cldata.downright:set(bbox.x + bbox.width, bbox.y + bbox.height)
  else
    cldata.upleft    = vector2:new(bbox.x, bbox.y)
    cldata.upright   = vector2:new(bbox.x + bbox.width, bbox.y)
    cldata.downleft  = vector2:new(bbox.x, bbox.y + bbox.height)
    cldata.downright = vector2:new(bbox.x + bbox.width, bbox.y + bbox.height)
  end
  
  -- tile_maps at corners
  if     #tmaps == 1 then
    cldata.multiple_span = false
    cldata.upleft_tmap    = tmaps[1]
    cldata.upright_tmap   = tmaps[1]
    cldata.downleft_tmap  = tmaps[1]
    cldata.downright_tmap = tmaps[1]
  elseif #tmaps > 1 then
    cldata.multiple_span = true
    cldata.upleft_tmap    = level_map:get_tile_map_at_position(cldata.upleft)
    cldata.upright_tmap   = level_map:get_tile_map_at_position(cldata.upright)
    cldata.downleft_tmap  = level_map:get_tile_map_at_position(cldata.downleft)
    cldata.downright_tmap = level_map:get_tile_map_at_position(cldata.downright)
  end
  
  bbox.cldata = cldata
end

function level_collider:_update_point(point)
  -- check if still in map
  local tmap = point.cldata.tmap
  local pos = point:get_position()
  if not tmap.bbox:contains_point(pos) then
    local level_map = self.level_map
    local new_tmap = level_map:get_tile_map_at_position(pos)
    local new_collider = new_tmap.collider
    
    point.cldata.collider = new_collider
    point.cldata.tmap = new_tmap
    
    tmap.collider:remove_object(point)
    -- This make cause a bug (jun 4, 2014)
    -- original: new_collider:add_object(point)
    new_collider:add_object(point, point.cldata.parent)
  end

  local collider = point.cldata.collider
  collider:update_object(point)
end

function level_collider:_update_bbox(bbox)

  local cldata = bbox.cldata
  
  -- update corners and position
  local pos = cldata.pos
  local trans_x = bbox.x - pos.x
  local trans_y = bbox.y - pos.y
  
  cldata.upright.x   = cldata.upright.x + trans_x
  cldata.upright.y   = cldata.upright.y + trans_y
  cldata.upleft.x    = cldata.upleft.x + trans_x
  cldata.upleft.y    = cldata.upleft.y + trans_y
  cldata.downright.x = cldata.downright.x + trans_x
  cldata.downright.y = cldata.downright.y + trans_y
  cldata.downleft.x  = cldata.downleft.x + trans_x
  cldata.downleft.y  = cldata.downleft.y + trans_y
  cldata.pos.x = pos.x + trans_x
  cldata.pos.y = pos.y + trans_y
  
  -- check if within a single map
  local tmap = cldata.upright_tmap
  local multiple_span = not tmap.bbox:contains(bbox)
  local changed_span = multiple_span ~= cldata.multiple_span and not multiple_span
  cldata.multiple_span = multiple_span
  
  -- case where bbox went from multiple_span to single map since last frame
  if changed_span then
    if cldata.upleft_tmap ~= tmap then
      cldata.upleft_tmap.collider:remove_object(bbox)
    end
    if cldata.downright_tmap ~= tmap then
      cldata.downright_tmap.collider:remove_object(bbox)
    end
    if cldata.downleft_tmap ~= tmap then
      cldata.downleft_tmap.collider:remove_object(bbox)
    end
      
    cldata.upleft_tmap = tmap
    cldata.downright_tmap = tmap
    cldata.downleft_tmap = tmap
  end
  
  if not cldata.multiple_span then
    tmap.collider:update_object(bbox)
    return
  end
  
  -- not within single map
  local level_map      = self.level_map
  local upright_tmap   = cldata.upright_tmap
  local upleft_tmap    = cldata.upleft_tmap
  local downright_tmap = cldata.downright_tmap
  local downleft_tmap  = cldata.downleft_tmap
  
  local old_maps = self.old_maps
  old_maps[1] = upright_tmap
  old_maps[2] = upleft_tmap
  old_maps[3] = downright_tmap
  old_maps[4] = downleft_tmap
  
  -- check for new maps
  local new_upright = false
  local new_upleft = false
  local new_downright = false
  local new_downleft = false
  
  if not cldata.upright_tmap.bbox:contains_point(cldata.upright) then
    new_upright = true
    upright_tmap = level_map:get_tile_map_at_position(cldata.upright)
  end
  if not cldata.upleft_tmap.bbox:contains_point(cldata.upleft) then
    new_upleft = true
    upleft_tmap = level_map:get_tile_map_at_position(cldata.upleft)
  end
  if not cldata.downright_tmap.bbox:contains_point(cldata.downright) then
    new_downright = true
    downright_tmap = level_map:get_tile_map_at_position(cldata.downright)
  end
  if not cldata.downleft_tmap.bbox:contains_point(cldata.downleft) then
    new_downleft = true
    downleft_tmap = level_map:get_tile_map_at_position(cldata.downleft)
  end
  
  -- check if any maps have changed, if not, then update all
  if not (new_upright or new_upleft or new_downright or new_downleft) then
    upright_tmap.collider:update_object(bbox)
    upleft_tmap.collider:update_object(bbox)
    downright_tmap.collider:update_object(bbox)
    downleft_tmap.collider:update_object(bbox)
    return
  end
  
  cldata.upright_tmap   = upright_tmap
  cldata.upleft_tmap    = upleft_tmap
  cldata.downright_tmap = downright_tmap
  cldata.downleft_tmap  = downleft_tmap
  
  -- check which maps need to be added or updated or removed
  local changed = self.changed
  changed[1] = new_upright
  changed[2] = new_upleft
  changed[3] = new_downright
  changed[4] = new_downleft
  
  local new_maps = self.new_maps
  new_maps[1] = upright_tmap
  new_maps[2] = upleft_tmap
  new_maps[3] = downright_tmap
  new_maps[4] = downleft_tmap
  
  -- new map needs to be added if new map does not exist in old maps
  -- new map needs to be updated otherwise
  for i=1,#changed do
    if changed[i] then
      local new = new_maps[i]
      if not (new == old_maps[1] or new == old_maps[2] or new == old_maps[3] or
              new == old_maps[4]) then
        new.collider:add_object(bbox, bbox.cldata.parent)
      end
    else
      new_maps[i].collider:update_object(bbox)
    end
  end
  
  -- old map needs to be removed if it does not exist in new maps
  for i=1,#old_maps do
    local old = old_maps[i]
    if not (old == new_maps[1] or old == new_maps[2] or old == new_maps[3] or 
            old == new_maps[4]) then
      old.collider:remove_object(bbox)
    end
  end
  
end

function level_collider:_remove_point(point)
  local collider = point.cldata.collider
  collider:remove_object(point)
  
  self.objects_by_table[point] = nil
end

function level_collider:_remove_bbox(bbox)
  self.objects_by_table[bbox] = nil

  -- remove from colliders
  local cldata = bbox.cldata
  cldata.upright_tmap.collider:remove_object(bbox)
  cldata.upleft_tmap.collider:remove_object(bbox)
  cldata.downright_tmap.collider:remove_object(bbox)
  cldata.downleft_tmap.collider:remove_object(bbox)
  
end

function level_collider:_get_point_collisions(point)
  return point.cldata.tmap.collider:get_collisions(point)
end

function level_collider:_get_bbox_collisions(bbox, storage)
  local cldata = bbox.cldata
  if cldata.multiple_span then
    local tmaps = cldata.tmaps_temp_table
    for k,_ in pairs(tmaps) do
      tmaps[k] = nil
    end
    
    tmaps[cldata.upright_tmap] = cldata.upright_tmap
    if not tmaps[cldata.upleft_tmap] then
      tmaps[cldata.upleft_tmap] = cldata.upleft_tmap
    end
    if not tmaps[cldata.downright_tmap] then
      tmaps[cldata.downright_tmap] = cldata.downright_tmap
    end
    if not tmaps[cldata.downleft_tmap] then
      tmaps[cldata.downleft_tmap] = cldata.downleft_tmap
    end
    
    local added = cldata.added_temp_table
    for k,_ in pairs(added) do
      added[k] = nil
    end
    
    local items = cldata.storage_temp_table
    local idx = 1
    for _,tmap in pairs(tmaps) do
      for i=#items,1,-1 do
        items[i] = nil
      end
    
      tmap.collider:get_collisions(bbox, items)
      if #items > 0 then
        for i=1,#items do
          if not added[items[i]] then
            storage[idx + 1] = items[i]
            added[items[i]] = items[i]
            idx = idx + 1
          end
        end
      end
    end
    
    return
  else
    cldata.upright_tmap.collider:get_collisions(bbox, storage)
  end
end

function level_collider:_get_collisions_at_position(point)
  local tmap = self.level_map:get_tile_map_at_position(point)
  return tmap.collider:get_objects_at_position(point)
end

function level_collider:_get_collisions_at_bbox(bbox, storage)
  local tmaps = self.level_map:get_tile_maps_at_bbox(bbox)
  if #tmaps > 1 then
    local objects = storage
    local idx = #storage + 1
    local added = {}
    for _,tmap in pairs(tmaps) do
      local items = tmap.collider:get_objects_at_bbox(bbox, {})
      for i=1,#items do
        if not added[items[i]] then
          objects[idx] = items[i]
          added[items[i]] = items[i]
          idx = idx + 1
        end
      end
    end

    return objects
  else
    local objects = tmaps[1].collider:get_objects_at_bbox(bbox, storage)
    return objects
  end
end

------------------------------------------------------------------------------
function level_collider:update(dt)
  local tmaps = self.tile_maps
  for i=1,#tmaps do
    tmaps[i].collider:update()
  end
end

------------------------------------------------------------------------------
function level_collider:draw()
  if not debug then return end
  
  -- draw tile_map colliders
  local tmaps = self.tile_maps
  for i=1,#tmaps do
    tmaps[i].collider:draw()
  end
  
end

return level_collider



















