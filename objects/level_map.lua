local UP        = UP
local UPRIGHT   = UPRIGHT
local RIGHT     = RIGHT
local DOWNRIGHT = DOWNRIGHT
local DOWN      = DOWN
local DOWNLEFT  = DOWNLEFT
local LEFT      = LEFT
local UPLEFT    = UPLEFT

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- level_map object (A collection of tile_map objects)
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local level_map = {}
level_map.table = 'level_map'
level_map.db = false
level_map.level = nil
level_map.master_timer = nil
level_map.camera = nil

-- dimensions
level_map.width = 0             -- bounding width height of level_map
level_map.height = 0
level_map.bbox = nil
level_map.tile_width = nil
level_map.tile_height = nil
level_map.inv_tile_width = nil
level_map.inv_tile_height = nil

-- tile_map query
level_map.tile_map_collider = nil   -- collider containing tilemap bbox's
level_map.query_cell_width = 2512
level_map.query_cell_height = 2512

-- object collider
level_map.collider = nil
level_map.collider_objects_storage = nil

-- tile_maps
level_map.tile_maps = nil
level_map.num_tile_maps = 0
level_map.loaded_maps = nil
level_map.tile_maps_in_view = nil
level_map.current_map = nil
level_map.adjacent_maps = nil

-- load
level_map.is_initial_maps_loading = false
level_map.is_initial_maps_loaded = false
level_map.initial_load_maps = nil
level_map.initial_map_load_slice = (1/60) * 3
level_map.background_map_load_slice = (1/60) * 0.2
level_map.background_loading = false
level_map.background_loaded = false
level_map.current_backround_load_map = nil

-- camera
level_map.camera_bbox = nil

-- polygonizer
level_map.polygonizer = nil
level_map.is_polygonizer_initialized = false
level_map.polygonizer_tile_type = nil
level_map.polygonizer_tile_gradient = nil
level_map.polygonizer_surface_threshold = 0.6
level_map.polygonizer_edited_tiles = nil


local level_map_mt = { __index = level_map }
function level_map:new(level)
  local map = setmetatable({}, level_map_mt)
  --level:set_level_map(map)
  map.level = level
  map.tile_maps = {}
  map.camera = level:get_camera()
  map.master_timer = level:get_master_timer()
  
  local camera = level:get_camera()
  local cpos = camera:get_pos()
  local cw, ch = camera:get_size()
  map.camera_bbox = bbox:new(cpos.x, cpos.y, cw, ch)
  
  map.loaded_maps = {}
  map.adjacent_maps = {}
  
  map.collider = level_collider:new(level, map)
  map.collider_objects_storage = {}
  level:set_collider(map.collider)
  
  return map
end

function level_map:add_tile_map(tile_map, tile_offset_x, tile_offset_y)
  if tile_map:is_loaded() or tile_map:is_loading() then
    print("ERROR in level_map:add_tile_map() - tile_map must be unloaded")
    return
  end
  
  if not tile_offset_x or not tile_offset_y then
    print("ERROR in level_map:add_tile_map() - nil offset for tile_map")
    return
  end
  
  if     #self.tile_maps == 0 then
    self.tile_width = tile_map.tile_width
    self.tile_height = tile_map.tile_height
    self.inv_tile_width = 1 / self.tile_width
    self.inv_tile_height = 1 / self.tile_height
  elseif self.tile_width ~= tile_map.tile_width or 
         self.tile_height ~= self.tile_height then
    print("ERROR in level_map:add_tile_map() - tile dimensions must be same"..
          " for each tile_layer")
    return
  end
  
  tile_map:set_map_offset(tile_offset_x * self.tile_width, 
                          tile_offset_y * self.tile_height)
                          
  -- check for overlap
  local maps = self.tile_maps
  local tbbox = tile_map.bbox
  for i=1,#maps do
    if tbbox:intersects(maps[i].bbox) then
      print("ERROR in level_map:add_tile_map() - tile maps may not overlap")
      return
    end
  end
  
  -- check for adjacent tile maps and stitch them together
  local neighbours = self:_find_adjacent_tile_maps(tile_map)
  for _,adj in ipairs(neighbours) do
    self:_stitch_tile_maps(tile_map, adj[2], adj[1], adj[3])
  end
                          
  self.tile_maps[#self.tile_maps+1] = tile_map
  self.num_tile_maps = #self.tile_maps
  
  -- update bbox for entile level map
  if self.bbox then
    self.bbox = self.bbox:union(tile_map.bbox)
  else
    local bbox = tile_map.bbox
    self.bbox = bbox:new(bbox.x, bbox.y, bbox.width, bbox.height)
  end
  self.width = self.bbox.width
  self.height = self.bbox.height
  
  -- update level collider
  self.collider:add_tile_map(tile_map)
end

function level_map:_init_polygonizer()
  local b = self.bbox
  self.polygonizer = polygonizer:new(self.level, b.x, b.y, b.width, b.height,
                                     self.tile_width, self.tile_height)
  self.polygonizer_edited_tiles = {}
  self.is_polygonizer_initialized = true
end

function level_map:set_polygonizer(tile_type, tile_gradient)
  if self.is_polygonizer_initialized then
    print("ERROR in level_map:set_polygonizer() - polygonizer already set")
    return
  end
  
  if not tile_type then
    print("ERROR in level_map:set_polygonizer() - missing tile type")
    return
  end
  
  if not tile_gradient then
    print("ERROR in level_map:set_polygonizer() - missing tile_gradient")
    return
  end
  
  self:_init_polygonizer()
  self.polygonizer_tile_type = tile_type
  self.polygonizer_tile_gradient = tile_gradient
end

function level_map:add_point_to_polygonizer(x, y, radius)
  if not self.is_polygonizer_initialized then
    print("ERROR in level_map:add_point_to_polygonizer() - polygonizer not set")
    return
  end
  
  if not x or not y then
    print("ERROR in level_map:add_point_to_polygonizer() - no coordinates found")
    return
  end
  
  local p = self.polygonizer:add_point(x, y, radius)
  return p
end

function level_map:remove_primitive_from_polygonizer(p)
  self.polygonizer:remove_primitive(p)
end

function level_map:set_polygonizer_surface_threshold(thresh)
  if not thresh then
    print("ERROR in level_map:et_polygonizer_surface_threshold() - missing threshold value")
    return
  end
  
  local min, max = self.polygonizer.min_surface_threshold, 
                   self.polygonizer.max_surface_threshold
  if thresh > max then thresh = max end
  if thresh < min then thresh = min end
  self.polygonizer_surface_threshold = thresh
end

function level_map:_save_tile_data(tile)
  local data = {}
  data.quad = tile.quad
  data.tile_gradient = tile.gradient
  data.intensity = tile.intensity
  data.tile_type = tile.type
  data.nx = tile.field_data.normal.x
  data.ny = tile.field_data.normal.y
  data.nz = tile.field_data.normal.z
  data.field_intensity = tile.field_data.intensity
  self.polygonizer_edited_tiles[tile] = data
end


function level_map:_update_polygonizer_field_values()
  local edited = self.polygonizer_edited_tiles

  -- set field values for entire polygonization cover
  -- field values are set as 1 at the surface threshold and 0 at the boundary
  -- of the implicit primitive
  self.polygonizer:set_surface_threshold(0)
  self.polygonizer:force_update()
  local inv_thresh = 1 / self.polygonizer_surface_threshold
  local data = self.polygonizer:get_tile_data()
  local pos = {}
  for i=1,#data do
    local td = data[i]
    pos.x, pos.y = td.x, td.y
    local n = td.field_vector
    local fvalue = td.field_value * inv_thresh
    if fvalue > 1 then fvalue = 1 end
    local tile = self:get_tile_at_position(pos)
    
    if not edited[tile] then
      self:_save_tile_data(tile)
    end
    
    tile:set_field_data(fvalue, n.x, n.y, n.z)
  end
end

function level_map:_update_polygonizer_surface_tiles()
  local thresh = self.polygonizer_surface_threshold
  self.polygonizer:set_surface_threshold(thresh)
  self.polygonizer:force_update()
  
  local tile_type = self.polygonizer_tile_type
  local tile_gradient = self.polygonizer_tile_gradient
  local hw, hh = 0.5 * self.tile_width, 0.5 * self.tile_height
  
  -- set tiles
  local data = self.polygonizer:get_tile_data()
  local pos = {}
  for i=1,#data do
    local td = data[i]
    local dir = td.direction
    local fvalue = td.center_field_value
    
    local min, max = 1, 0.5
    
    fvalue = 1 - ((fvalue - min) / (max - min))
    if fvalue < 0 then fvalue = 0 end
    if fvalue > 1 then fvalue = 1 end
    
    pos.x, pos.y = td.x, td.y
    local tile = self:get_tile_at_position(pos)
    
    
    local edited = self.polygonizer_edited_tiles
    -- solid tiles
    if dir == 0 then
      if not edited[tile] then
        self:_save_tile_data(tile)
      end
    
      local quad = tile_gradient:get_quad(fvalue)
      tile:_set_quad(quad)
      tile:set_gradient(tile_gradient)
      tile:init_intensity(fvalue)
      tile:set_type(tile_type)
      
    -- diagonal tiles
    else
      local quad = tile_gradient:get_diagonal_quad(fvalue)
      tile:set_diagonal_tile(dir, tile_type, quad, tile_gradient)
      tile.diagonal:init_intensity(fvalue)
      
      local diag = tile.diagonal
      diag:set_chunk(tile.chunk)
      diag:set_parent(tile.parent)
      diag:set_spritebatch_position(tile.batch_x, tile.batch_y)
      tile.chunk.diagonal_tiles[#tile.chunk.diagonal_tiles+1] = diag
    end
    
  end
end

function level_map:_reset_edited_tiles()
  for tile,data in pairs(self.polygonizer_edited_tiles) do
    local quad = data.quad
    local tile_gradient = data.tile_gradient
    local intensity = data.intensity
    local tile_type = data.tile_type
    
    tile:_set_quad(quad)
    tile:set_gradient(tile_gradient)
    tile:init_intensity(intensity)
    tile:set_type(tile_type)
    tile:set_field_data(data.field_intensity, data.nx, data.ny, data.nz)
    tile:remove_diagonal_tile()
  end
  
  table.clear_hash(self.polygonizer_edited_tiles)
end

function level_map:update_polygonizer()
  if not self.is_polygonizer_initialized then
    print("ERROR in level_map:update_polygonizer() - polygonizer not set")
    return
  end
  self:_reset_edited_tiles()
  self:_update_polygonizer_field_values()
  self:_update_polygonizer_surface_tiles()
end

function level_map:get_tile_map_at_position(pos)
  local objects = self.collider_objects_storage
  self.tile_map_collider:get_objects_at_position(pos, objects)
  if objects[1] then
    return objects[1]
  end
  
  print("ERROR in level_map:get_tile_map_at_position() - no tile_map at"..
        " this position")
  return
end

function level_map:get_tile_at_position(pos)
  local tmap = self:get_tile_map_at_position(pos)
  return tmap:get_tile_at_position(pos)
end

function level_map:get_tile_maps_at_bbox(bbox)
  return self.tile_map_collider:get_objects_at_bbox(bbox, {})
end

function level_map:get_tiles_at_bbox(bbox, storage)
  local tmaps = self:get_tile_maps_at_bbox(bbox)
  for i=1,#tmaps do
    tmaps[i]:get_tiles_at_bbox(bbox, storage)
  end
end

-- bilinearly interpolate field values
function level_map:get_field_vector_at_position(pos)
  local t1 = self:get_tile_at_position(pos) -- upleft
  if not t1 then
    return 0, 0, 0
  end
  
  local t2 = t1.neighbours[RIGHT]           -- upright
  local t3 = t1.neighbours[DOWN]            -- downleft
  local t4 = t1.neighbours[DOWNRIGHT]       -- downright
  
  if not t1 or not t2 or not t3 or not t4 then
    return 0, 0, 0
  end
  
  local x, y = pos.x, pos.y
  local d1, d2, d3, d4 = t1:get_field_data(), t2:get_field_data(), 
                         t3:get_field_data(), t4:get_field_data()
  local n1, n2, n3, n4 = d1.normal, d2.normal, 
                         d3.normal, d4.normal
  local i1, i2, i3, i4 = d1.intensity, d2.intensity, 
                         d3.intensity, d4.intensity
                         
  if i1 == 0 and i2 == 0 and i3 == 0 and i4 == 0 then
    return 0, 0, 0
  end
                         
  local invw, invh = self.inv_tile_width, self.inv_tile_height
  local progx, progy = (x - t1.x) * invw, (y - t1.y) * invh
  
  -- interpolate intensity
  local r1 = i1 + progx * (i2 - i1)
  local r2 = i3 + progx * (i4 - i3)
  local intensity = r1 + progy * (r2 - r1)
  
  -- interpolate direction
  local r1 = n1.x + progx * (n2.x - n1.x)
  local r2 = n3.x + progx * (n4.x - n3.x)
  local nx = r1 + progy * (r2 - r1)
  
  local r1 = n1.y + progx * (n2.y - n1.y)
  local r2 = n3.y + progx * (n4.y - n3.y)
  local ny = r1 + progy * (r2 - r1)
  
  local len = math.sqrt(nx*nx + ny*ny)
  if len > 0 then
    local inv = 1 / len
    nx, ny = nx * inv, ny * inv
  end
  return nx, ny, intensity
end

function level_map:_stitch_tile_maps(A_map, A_side, B_map, B_side)
  local A = A_map.bbox
  local B = B_map.bbox
  local tw, th = self.tile_width, self.tile_height
  
  -- diagonal case
  if (A_side % 2 == 0) then
   A_map:add_tile_map_neighbour(B_map, A_side)
   B_map:add_tile_map_neighbour(A_map, B_side)
  
  -- up down left right case
  else
    -- Swap A and B so that A is to the left or above B
    if     A_side == UP or A_side == LEFT then
      A_map, A_side, B_map, B_side = B_map, B_side, A_map, A_side
    end
    
    -- case 1: A side down, B side up
    if A_side == DOWN then
      -- find adjacent boundary
      local start_x = math.max(A.x, B.x)
      local end_x = math.min(A.x + A.width, B.x + B.width)
      
      local width = (end_x - start_x) / tw
      local A_offx, A_offy = A_map:get_tile_offset()
      local B_offx, B_offy = B_map:get_tile_offset()
      
      -- find tile index range for each map
      local A_i = (start_x / tw) - A_offx + 1
      local A_j = A_i + width - 1
      local B_i = (start_x / tw) - B_offx + 1
      local B_j = B_i + width - 1
      
      -- notify each tile map of their adjacent tile neighbours
      A_map:add_tile_map_neighbour(B_map, A_side, A_i, A_j, B_i, B_j)
      B_map:add_tile_map_neighbour(A_map, B_side, B_i, B_j, A_i, A_j)
      
    -- case 2: A side right, B side lefts
    elseif A_side == RIGHT then
      -- find adjacent boundary
      local start_y = math.max(A.y, B.y)
      local end_y = math.min(A.y + A.height, B.y + B.height)
      local height = (end_y - start_y) / th
      local A_offx, A_offy = A_map:get_tile_offset()
      local B_offx, B_offy = B_map:get_tile_offset()
      
      -- find tile index range for each map
      local A_i = (start_y / th) - A_offy + 1
      local A_j = A_i + height - 1
      local B_i = (start_y / th) - B_offy + 1
      local B_j = B_i + height - 1
      
      -- notify each tile map of their adjacent tile neighbours
      A_map:add_tile_map_neighbour(B_map, A_side, A_i, A_j, B_i, B_j)
      B_map:add_tile_map_neighbour(A_map, B_side, B_i, B_j, A_i, A_j)
    end
    
  end
end

-- returns list of adjacent tile_maps
-- each adjacency in form: {other_tile_map, tile_map_side, other_tile_map_side}
function level_map:_find_adjacent_tile_maps(tile_map)
  local maps = self.tile_maps
  local tmap_bbox = tile_map.bbox
  local adj_list = {}
  for i=1,#maps do
    local other = maps[i]
    local result, tmap_side, other_side = tmap_bbox:is_adjacent(other.bbox)
    if result then
      adj_list[#adj_list + 1] = {other, tmap_side, other_side}
    end
  end
  return adj_list
end

-- load maps in initial view
function level_map:load()
  if self:is_loaded() or self:is_loading() then
    print("ERROR in level_map:load() - map is alreadly loading or loaded")
    return
  end
  
  -- initialize collider for tile_map bbox query
  local bbox = self.bbox
  local cl = collider:new(self.level, bbox.x, bbox.y, bbox.width, bbox.height,
                          self.query_cell_width, self.query_cell_height)
  self.tile_map_collider = cl
  
  local tmaps = self.tile_maps
  for i=1,#tmaps do
    cl:add_object(tmaps[i].bbox, tmaps[i])
  end

  -- find initial maps to load
  local init_maps = self:_get_tile_maps_in_active_area()
  
  if #init_maps == 0 then
    print("ERROR in level_map:load() - no maps in view")
  end
  
  for i,v in ipairs(init_maps) do
    v:set_load_time_slice(self.initial_map_load_slice)
    v:load(function() print("loaded map "..tostring(v)) end)
  end
  self.initial_load_maps = init_maps
  self.is_initial_maps_loading = true

end


function level_map:is_loading()
  return self.is_initial_maps_loading
end
function level_map:is_loaded()
  return self.is_initial_maps_loaded
end
function level_map:is_background_loading()
  return self.background_loading
end
function level_map:is_background_loaded()
  return self.background_loaded
end

function level_map:_initial_map_loaded()
  self.loading = false
  self.loaded = true
  self.is_initial_maps_loaded = true
  
  -- stitch
  local init_maps = self.initial_load_maps
  for _,v in ipairs(init_maps) do
    self:_background_load_map_finished(v)
  end
  
  print("initial maps loaded")
end

------------------------------------------------------------------------------
function level_map:update(dt)
  if not self.is_initial_maps_loaded then
    self:_update_initial_load()
  end
  
  if not self:is_loaded() then
    return
  end

  self.collider:update(dt)
  for _,tmap in ipairs(self.tile_maps) do
    tmap:update(dt)
  end
  
  if not self:is_loaded() then return end
  
  local loaded_maps = self:_get_loaded_tile_maps()
  self.loaded_maps = loaded_maps
 
  self:_update_camera_viewport()
  local maps_in_view = self:_get_tile_maps_in_view()
  self.tile_maps_in_view = maps_in_view
  
  local current_map = self:_get_current_map()
  self.current_map = current_map
  
  local adjacent_maps = self.adjacent_maps
  if current_map then
    table.copy(current_map.neighbours, adjacent_maps)
  end
  
  self:_update_background_load()
  
  if self.tile_map_collider then
    self.tile_map_collider:update(dt)
  end
  
end

function level_map:_update_initial_load()
  local imaps = self.initial_load_maps
  for i=1,#imaps do
    imaps[i]:update(dt)
  end
  
  -- check if load finished
  local loaded = true
  for i=1,#imaps do
    if not imaps[i]:is_loaded() then
      loaded = false
    end
  end
  
  if loaded and not self:is_loaded() then
    self:_initial_map_loaded()
  end
end

function level_map:_update_background_load()
  if self:is_background_loading() then
    return
  end
  
  -- choose map to load - find closest unloaded map
  local adj_maps = self.adjacent_maps
  local camera = self.level:get_camera()
  local cpos = camera:get_center()
  local closest_map
  local min
  for i=1,#adj_maps do
    if not adj_maps[i]:is_loaded() then
      local cx, cy = adj_maps[i].bbox:get_center()
      local dist = (cpos.x - cx)^2 + (cpos.y - cy)^2
      if not min or dist < min then
        min = dist
        closest_map = adj_maps[i]
      end
    end
  end
  
  if not closest_map then
    local active_area_maps = self:_get_tile_maps_in_active_area()
    for i=1,#active_area_maps do
      if not active_area_maps[i]:is_loaded() then
        closest_map = active_area_maps[i]
      end
    end
  end
  
  if closest_map then
    self:_load_map_in_background(closest_map)
  end
end

function level_map:_load_map_in_background(tmap)
  tmap:set_load_time_slice(self.background_map_load_slice)
  tmap:load(function()
              print("Loaded map "..tostring(tmap))
              self:_background_load_map_finished(tmap)
            end)

  self.current_background_load_map = tmap
  self.background_loading = true
end

function level_map:_background_load_map_finished(tmap)
  -- find loaded adjacent maps and stitch together
  local adj_maps = tmap:get_neighbours()
  for i=1,#adj_maps do
    local other_map = adj_maps[i]
    if other_map:is_loaded() then
      tmap:stitch_tile_map_neighbour(other_map)
      other_map:stitch_tile_map_neighbour(tmap)
    end
  end
  
  self.background_loading = false
end

function level_map:_get_current_map()
  local camera = self.level:get_camera()
  local cpos = camera:get_center()
  local maps_in_view = self.tile_maps_in_view
  local current_map
  if #maps_in_view == 1 then
    current_map = maps_in_view[1]
  else
    for i=1,#maps_in_view do
      if maps_in_view[i].bbox:contains_point(cpos) then
        current_map = maps_in_view[i]
        break
      end
    end
  end
  
  -- find closest map
  if not current_map and #maps_in_view > 0 then
    local min
    for i=1,#maps_in_view do  
      local cx, cy = maps_in_view[i].bbox:get_center()
      local dist = (cpos.x - cx)^2 + (cpos.y - cy)^2
      if not min or dist < min then
        min = dist
        current_map = maps_in_view[i]
      end
    end
  end
  
  return current_map
end

function level_map:_get_tile_maps_in_view()
  local cbbox = self.camera_bbox
  local maps_in_view = self.tile_map_collider:get_objects_at_bbox(cbbox, {})
  
  return maps_in_view
end

function level_map:_get_tile_maps_in_active_area()
  local bbox = self.level:get_active_area()
  local maps_in_view = self.tile_map_collider:get_objects_at_bbox(bbox, {})
  
  return maps_in_view
end

function level_map:_get_loaded_tile_maps()
  local loaded_maps = {}
  local idx = 1
  for i,tmap in ipairs(self.tile_maps) do
    if tmap:is_loaded() then
      loaded_maps[idx] = tmap
      idx = idx + 1
    end
  end
  
  return loaded_maps
end

function level_map:_update_camera_viewport()
  local camera = self.level:get_camera()
  local maps = self.tile_maps
  local cpos = camera:get_pos()
  local cw, ch = camera:get_size()
  local cbbox = self.camera_bbox
  cbbox.x, cbbox.y, cbbox.width, cbbox.height = cpos.x, cpos.y, cw, ch
end

------------------------------------------------------------------------------
function level_map:draw()
  if not self:is_loaded() then return end

  for _,tmap in ipairs(self.loaded_maps) do
    tmap:draw()
  end
  
  self.camera:set()
  self.polygonizer:draw()
  self.camera:unset()

  if self.db then
    self.camera:set()
    lg.setColor(0, 0, 255, 255)
    self.bbox:draw()
    self.collider:draw()
    self.camera:unset()
  end
end

return level_map
















