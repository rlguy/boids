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
-- tile_map object (A collection of tile_layers)
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local tile_map = {}
tile_map.table = 'tile_map'
tile_map.debug = false
tile_map.level = nil
tile_map.master_timer = nil

-- map
tile_map.offset_x = 100               -- pixel offset of tile map from origin
tile_map.offset_y = 100
tile_map.x = nil                    -- pixel coordinate of top-left corner
tile_map.y = nil
tile_map.width = nil                -- width of map in pixels
tile_map.height = nil
tile_map.bbox = nil
tile_map.map_isvisible = false

-- tiles
tile_map.tiles = nil                     -- 2d array of tile objects
tile_map.tile_cols = nil                 -- # of tiles in a row
tile_map.tile_rows = nil
tile_map.tile_width = nil
tile_map.tile_height = nil
tile_map.num_tiles = nil

-- chunks
tile_map.chunks = nil                    -- 2d array of tile_chunk objects
tile_map.tiles_per_chunk_col = 16
tile_map.tiles_per_chunk_row = 16
tile_map.chunk_width = nil               -- width of a chunk in pixels
tile_map.chunk_height = nil
tile_map.chunk_cols = nil                -- # of chunks in a row
tile_map.chunk_rows = nil
tile_map.num_chunks  = nil
tile_map.chunks_in_view = nil
tile_map.chunks_in_view_by_id = nil

-- tile layers
tile_map.tile_layers = nil               -- table of all tile_layer objects
tile_map.num_layers = 0
tile_map.spritesheet = nil
tile_map.spritesheet_quads = nil    -- form of {layer1_quads, layer2_quads, ...}

-- loading
tile_map.load_timer = nil
tile_map.final_load_time = nil
tile_map.loaded = false                    -- boolean, whether map has loaded
tile_map.loading = false                   -- whether map is loading
tile_map.load_finished_callback = nil
tile_map.load_time_slice = (1 / 60) * 0.5  -- alloted loading time per frame
tile_map.continue_idx_i = 1                -- next index to operate on
tile_map.continue_idx_j = 1
tile_map.loader_functions = nil            -- table of loading functions in order
tile_map.current_loader_idx = 1
tile_map.num_loaders = 0
tile_map.loader_percent = 0           -- percentage completion of current loader
tile_map.quad_hash = nil              -- hashes pixel value to quad for each layer

-- form: {{ self's adjacent side, self's start tile idx, self's end tile idx, 
--          other's start tile idx, other's end tile idx }, ...}
-- indexed by neighbour tile_map
tile_map.neighbour_data = nil

-- tile_map neighbours
tile_map.neighbours = nil

-- object initialization
tile_map.init_queue = nil

-- collider
tile_map.collider = nil

-- temporary vectors
tile_map.top_left = nil
tile_map.bottom_right = nil

local tile_map_mt = { __index = tile_map }
function tile_map:new(level, columns, rows, tile_width, tile_height)
  tile_width = tile_width or TILE_WIDTH
  tile_height = tile_height or TILE_HEIGHT

  local tmap = setmetatable({}, tile_map_mt)
  
  tmap.level = level
  tmap.master_timer = level:get_master_timer()
  tmap.camera = level:get_camera()
  
  -- map
  tmap.x = tile_map.offset_x
  tmap.y = tile_map.offset_x
  tmap.width = columns * tile_width
  tmap.height = rows * tile_height
  tmap.bbox = bbox:new(tmap.x, tmap.y, tmap.width, tmap.height)
  
  -- tiles
  local tiles = {}
  for j=1,rows do
    tiles[j] = {}
  end
  
  tmap.tiles = tiles
  tmap.tile_cols = columns
  tmap.tile_rows = rows
  tmap.tile_width = tile_width
  tmap.tile_height = tile_height
  tmap.num_tiles = columns * rows
  
  -- chunks
  local t_per_row = tile_map.tiles_per_chunk_row
  local t_per_col = tile_map.tiles_per_chunk_col
  local ch_width = t_per_row * tile_width
  local ch_height = t_per_col * tile_height
  local ch_cols = math.floor(columns * tile_width / ch_width) + 1
  local ch_rows = math.floor(rows * tile_height / ch_height) + 1
  if (columns * tile_width) % ch_width == 0 then
    ch_cols = ch_cols - 1
  end
  if (rows * tile_height) % ch_height == 0 then
    ch_rows = ch_rows - 1
  end
  
  local chunks = {}
  for j=1,ch_rows do
    chunks[j] = {}
  end
  
  tmap.chunks_in_view = {}
  tmap.chunks_in_view_by_id = {}
  self.chunks_in_area = {}
  self.chunks_in_area_by_id = {}
  tmap.chunks = chunks
  tmap.chunk_width = ch_width
  tmap.chunk_height = ch_height
  tmap.chunk_cols = ch_cols
  tmap.chunk_rows = ch_rows
  tmap.num_chunks = ch_cols * ch_rows
  tmap.top_left = vector2:new(0, 0)
  tmap.bottom_right = vector2:new(0, 0)
  
  -- tile_layers
  tmap.tile_layers = {}
  
  -- loading
  local loaders = { function() return tmap._load_blank_tiles(tmap, 1000) end, 
                    function() return tmap._load_initialized_tiles(tmap, 100) end,
                    function() return tmap._load_chunks(tmap, 1) end }
  tmap.loader_functions = loaders
  tmap.load_timer = timer:new(tmap.master_timer)
  
  tmap.neighbours = {}
  tmap.neighbour_data = {}
  
  tmap.init_queue = {}
  
  return tmap
end

function tile_map:add_tile_layer(layer)
  local imgdata = layer:get_imgdata()
  local w, h = layer.width, layer.height
  if w ~= self.tile_cols or h ~= self.tile_rows then
    print("ERROR in tile_map:add_tile_layer() - tile_layer does not match"..
          " tile_map dimensions")
    return
  end
  
  if self:is_loaded() or self:is_loading() then
    print("ERROR in tile_map:add_tile_layer() - Cannot add layer during or"..
          " after loading process")
    return
  end
  
  -- set spritesheet image
  local gradient = layer:get_gradient()
  if #self.tile_layers == 0 then
    self.spritesheet = gradient:get_spritebatch_image()
    self.spritesheet_quads = {}
    self.quad_hash = {}
  end
  
  if self.spritesheet ~= gradient:get_spritebatch_image() then
    print("ERROR in tile_map:add_tile_layer() - spritesheets must match"..
          " for each layer")
    return
  end

  self.spritesheet_quads[#self.spritesheet_quads+1] = gradient:get_quads()
  self.quad_hash[#self.quad_hash + 1] = {}
  self.tile_layers[#self.tile_layers + 1] = layer
  self.num_layers = #self.tile_layers
end

function tile_map:add_tile_map_neighbour(neighbour, side, self_i, self_j, 
                                                          nb_i, nb_j)
  if self:is_loading() or self:is_loaded() then
    print("ERROR in tile_map:add_tile_map_neighbours() - neighbours must"..
          " be added befor load()")
    return
  end
                                                          
  self.neighbours[#self.neighbours + 1] = neighbour
  self.neighbour_data[neighbour] = { side, self_i, self_j, nb_i, nb_j}
end

function tile_map:get_neighbours()
  return self.neighbours, self.neighbour_data
end

function tile_map:get_tile_at_position(pos)
  local i = math.floor((pos.x - self.offset_x) / self.tile_width) + 1
  local j = math.floor((pos.y - self.offset_y)/ self.tile_height) + 1
  if not self.tiles[j] or not self.tiles[j][i] then
    --[[
    if not self.tiles[j] then
      print("DEBUG - Not self.tiles[j]")
    end
    if self.tiles[j] and not self.tiles[j][i] then
      print("DEBUG - Not self.tiles[j][i]")
    end
  
    print("DEBUG", i, j, pos.x, pos.y, self.offset_x, self.offset_y, self.tile_width, self.tile_height)
    print("DEBUG", #self.tiles, j)
    if self.tiles[j] then
      print("DEBUG", #self.tiles[j], i)
    end
    ]]--
    
    -- pos might be out of range of the tile map
    return nil
  end
  return self.tiles[j][i]
end

function tile_map:get_tiles_at_bbox(bbox, storage)
  local x1, y1, x2, y2 = bbox.x, bbox.y, bbox.x + bbox.width, bbox.y + bbox.height
  local min_i = math.floor((x1 - self.offset_x) / self.tile_width) + 1
  local min_j = math.floor((y1 - self.offset_y)/ self.tile_height) + 1
  local max_i = math.floor((x2 - self.offset_x) / self.tile_width) + 1
  local max_j = math.floor((y2 - self.offset_y)/ self.tile_height) + 1
  
  min_i = math.max(1, min_i)
  min_j = math.max(1, min_j)
  max_i = math.min(max_i, self.tile_cols)
  max_j = math.min(max_j, self.tile_rows)
  
  local tiles = self.tiles
  local idx = #storage + 1
  for j=min_j, max_j do
    for i=min_i, max_i do
      storage[idx] = tiles[j][i]
      idx = idx + 1
    end
  end
end

function tile_map:get_tile_at_location(x, y)
  local i = math.floor((x - self.offset_x) / self.tile_width) + 1
  local j = math.floor((y - self.offset_y)/ self.tile_height) + 1
  return self.tiles[j][i]
end

-- when tile map is loaded, object:init() will be called
function tile_map:add_to_init_queue(object)
  self.init_queue[#self.init_queue + 1] = object
end

function tile_map:stitch_tile_map_neighbour(nb_map)
  
  local nb_data = self.neighbour_data
  local data = nb_data[nb_map]
  if data == nil then
    print("ERROR in tile-map:stitch_tile_neighbour() -- cannot find neighbour"..
          " tile_map")
    return
  end
  
  local myside = data[1]
  local my_i = data[2]
  local my_j = data[3]
  local nb_i = data[4]
  local nb_j = data[5]
  local my_rows = self.tile_rows
  local my_cols = self.tile_cols
  local nb_rows = nb_map.tile_rows
  local nb_cols = nb_map.tile_cols
  
  -- diagonal case
  if myside % 2 == 0 then
    if myside == UPRIGHT then
      self.tiles[1][my_cols].neighbours[UPRIGHT] = nb_map.tiles[nb_rows][1]
    elseif myside == DOWNRIGHT then
      self.tiles[my_rows][my_cols].neighbours[DOWNRIGHT] = nb_map.tiles[1][1]
    elseif myside == DOWNLEFT then
      self.tiles[my_rows][1].neighbours[DOWNLEFT] = nb_map.tiles[1][nb_cols]
    elseif myside == UPLEFT then
      self.tiles[1][1].neighbours[UPLEFT] = nb_map.tiles[nb_rows][nb_cols]
    end
  
    -- up down left right case
  else
    
    if     myside == UP then
      -- query neighbour tiles
      local nb_tiles = {}
      local idx = 1
      for i=nb_i,nb_j do
        nb_tiles[idx] = nb_map.tiles[nb_rows][i]
        idx = idx + 1
      end
      
      -- set neighbours
      -- previous tile
      if my_i > 1 then
        local neighbours = self.tiles[1][my_i-1].neighbours
        if nb_i <= nb_cols then
          neighbours[UPRIGHT] = nb_tiles[1]
        end
      end
      
      -- first tile
      local neighbours = self.tiles[1][my_i].neighbours
      neighbours[UP] = nb_tiles[1]
      if nb_i > 1 then
        neighbours[UPLEFT] = nb_map.tiles[nb_rows][nb_i - 1]
      end 
      if nb_i + 1 <= nb_cols then
        neighbours[UPRIGHT] = nb_map.tiles[nb_rows][nb_i + 1]
      end
      
      -- middle tiles
      for i=my_i + 1,my_j - 1 do
        local neighbours = self.tiles[1][i].neighbours
        neighbours[UPLEFT] =  nb_tiles[i - (my_i-1) - 1]
        neighbours[UP] =      nb_tiles[i - (my_i-1)]
        neighbours[UPRIGHT] = nb_tiles[i - (my_i-1) + 1]
      end
      
      -- last tile
      local neighbours = self.tiles[1][my_j].neighbours
      neighbours[UP] = nb_tiles[#nb_tiles]
      if nb_j > 1 then
        neighbours[UPLEFT] = nb_map.tiles[nb_rows][nb_j - 1]
      end
      if nb_j < nb_cols then
        neighbours[UPRIGHT] = nb_map.tiles[nb_rows][nb_j + 1]
      end
      
      -- next tile
      if my_j < self.tile_cols then
        local neighbours = self.tiles[1][my_j+1].neighbours
        if nb_i <= nb_cols then
          neighbours[UPLEFT] = nb_tiles[#nb_tiles]
        end
      end
    
    elseif myside == DOWN then
      -- query neighbour tiles
      local nb_tiles = {}
      local idx = 1
      for i=nb_i,nb_j do
        nb_tiles[idx] = nb_map.tiles[1][i]
        idx = idx + 1
      end
      
      -- set neighbours
      -- previous tile
      if my_i > 1 then
        local neighbours = self.tiles[my_rows][my_i-1].neighbours
        if nb_i <= nb_cols then
          neighbours[DOWNRIGHT] = nb_tiles[1]
        end
      end
      
      -- first tile
      local neighbours = self.tiles[my_rows][my_i].neighbours
      neighbours[DOWN] = nb_tiles[1]
      if nb_i > 1 then
        neighbours[DOWNLEFT] = nb_map.tiles[1][nb_i - 1]
      end 
      if nb_i + 1 <= nb_cols then
        neighbours[DOWNRIGHT] = nb_map.tiles[1][nb_i + 1]
      end
      
      -- middle tiles
      for i=my_i + 1,my_j - 1 do
        local neighbours = self.tiles[my_rows][i].neighbours
        neighbours[DOWNLEFT] =  nb_tiles[i - (my_i-1) - 1]
        neighbours[DOWN] =      nb_tiles[i - (my_i-1)]
        neighbours[DOWNRIGHT] = nb_tiles[i - (my_i-1) + 1]
      end
      
      -- last tile
      local neighbours = self.tiles[my_rows][my_j].neighbours
      neighbours[DOWN] = nb_tiles[#nb_tiles]
      if nb_j > 1 then
        neighbours[DOWNLEFT] = nb_map.tiles[1][nb_j - 1]
      end
      if nb_j < nb_cols then
        neighbours[DOWNRIGHT] = nb_map.tiles[1][nb_j + 1]
      end
      
      -- next tile
      if my_j < my_cols then
        local neighbours = self.tiles[my_rows][my_j+1].neighbours
        if nb_i <= nb_cols then
          neighbours[DOWNLEFT] = nb_tiles[#nb_tiles]
        end
      end
    elseif myside == LEFT then
      
      -- query neighbour tiles
      local nb_tiles = {}
      local idx = 1
      for i=nb_i,nb_j do
        nb_tiles[idx] = nb_map.tiles[i][nb_cols]
        idx = idx + 1
      end
      
      -- set neighbours
      -- previous tile
      if my_i > 1 then
        local neighbours = self.tiles[my_i-1][1].neighbours
        if nb_i <= nb_rows then
          neighbours[DOWNLEFT] = nb_tiles[1] --?
        end
      end
      
      -- first tile
      local neighbours = self.tiles[my_i][1].neighbours
      neighbours[LEFT] = nb_tiles[1]
      if nb_i > 1 then
        neighbours[UPLEFT] = nb_map.tiles[nb_i - 1][nb_cols] --?
      end 
      if nb_i + 1 <= nb_rows then
        neighbours[DOWNLEFT] = nb_map.tiles[nb_i + 1][nb_cols] --?
      end
      
      -- middle tiles
      for i=my_i + 1,my_j - 1 do
        local neighbours = self.tiles[i][1].neighbours
        neighbours[UPLEFT] =    nb_tiles[i - (my_i-1) - 1]
        neighbours[LEFT] =      nb_tiles[i - (my_i-1)]
        neighbours[DOWNLEFT] =  nb_tiles[i - (my_i-1) + 1]
      end
      
      -- last tile
      local neighbours = self.tiles[my_j][1].neighbours
      neighbours[LEFT] = nb_tiles[#nb_tiles]
      if nb_j > 1 then
        neighbours[UPLEFT] = nb_map.tiles[nb_j - 1][nb_cols] --?
      end
      if nb_j < nb_rows then
        neighbours[DOWNLEFT] = nb_map.tiles[nb_j + 1][nb_cols] --?
      end
      
      -- next tile
      if my_j < my_rows then
        local neighbours = self.tiles[my_j+1][1].neighbours
        if nb_i <= nb_rows then
          neighbours[UPLEFT] = nb_tiles[#nb_tiles] --?
        end
      end
      
    elseif myside == RIGHT then
      -- query neighbour tiles
      local nb_tiles = {}
      local idx = 1
      for i=nb_i,nb_j do
        nb_tiles[idx] = nb_map.tiles[i][1]
        idx = idx + 1
      end
      
      -- set neighbours
      -- previous tile
      if my_i > 1 then
        local neighbours = self.tiles[my_i-1][my_cols].neighbours
        if nb_i <= nb_rows then
          neighbours[DOWNRIGHT] = nb_tiles[1] --?
        end
      end
      
      -- first tile
      local neighbours = self.tiles[my_i][my_cols].neighbours
      neighbours[RIGHT] = nb_tiles[1]
      if nb_i > 1 then
        neighbours[UPRIGHT] = nb_map.tiles[nb_i - 1][1] --?
      end 
      if nb_i + 1 <= nb_rows then
        neighbours[DOWNRIGHT] = nb_map.tiles[nb_i + 1][1] --?
      end
      
      -- middle tiles
      for i=my_i + 1,my_j - 1 do
        local neighbours = self.tiles[i][my_cols].neighbours
        neighbours[UPRIGHT] =    nb_tiles[i - (my_i-1) - 1]
        neighbours[RIGHT] =      nb_tiles[i - (my_i-1)]
        neighbours[DOWNRIGHT] =  nb_tiles[i - (my_i-1) + 1]
      end
      
      -- last tile
      local neighbours = self.tiles[my_j][my_cols].neighbours
      neighbours[RIGHT] = nb_tiles[#nb_tiles]
      if nb_j > 1 then
        neighbours[UPRIGHT] = nb_map.tiles[nb_j - 1][1] --?
      end
      if nb_j < nb_rows then
        neighbours[DOWNRIGHT] = nb_map.tiles[nb_j + 1][1] --?
      end
      
      -- next tile
      if my_j < my_rows then
        local neighbours = self.tiles[my_j+1][my_cols].neighbours
        if nb_i <= nb_rows then
          neighbours[UPRIGHT] = nb_tiles[#nb_tiles] --?
        end
      end
    end
    
  end
  
end

function tile_map:set_map_offset(ox, oy)
  if self:is_loaded() or self:is_loading() then
    print("ERROR in tile_map:set_pixel_offset() - offset must be set before "..
          "tile map has loaded")
    return
  end

  self.offset_x = ox
  self.offset_y = oy
  self.x = ox
  self.y = oy
  self.bbox.x = ox
  self.bbox.y = oy
  
  -- we now have location of map, so collider can be created
  self.collider = collider:new(self.level, ox, oy, self.width, self.height)
  self.collider.debug = true
end

function tile_map:get_map_offset()
  return self.offset_x, self.offset_y
end
function tile_map:get_tile_offset()
  return self.offset_x / self.tile_width, self.offset_y / self.tile_height
end


function tile_map:load(load_finished_callback)
  if tile_map:is_loaded() or tile_map:is_loading() then
    print("ERROR in tile_map:load() - map already loaded / is loading")
    return
  end
  
  if #self.tile_layers == 0 then
    print("ERROR in tile_map:load() - There is nothing to load")
    return
  end

  self.load_finished_callback = load_finished_callback
  self.loading = true
  
  self.current_loader_idx = 1
  self.num_loaders = #self.loader_functions
  self:_save_index(1, 1)
  
  self.load_timer:start()
end

-- time per frame
function tile_map:set_load_time_slice(time)
  self.load_time_slice = time
end

function tile_map:is_loaded()
  return self.loaded
end

function tile_map:is_loading()
  return self.loading
end

function tile_map:get_load_status()
  local loaded = self:is_loaded()
  local percent = math.floor(self.loader_percent * 1000) / 1000
  local current_idx = self.current_loader_idx
  local num_loaders = self.num_loaders
  local time = self.load_timer:time_elapsed()
  
  if current_idx > num_loaders then 
    current_idx = num_loaders 
    percent = 1
    time = self.final_load_time
  end
  
  return loaded, percent, current_idx, num_loaders, time
end

function tile_map:update_chunks_in_view()
  -- calculate which chunks can be seen by the camera
  local cpos = self.camera:get_pos()
  local cw, ch = self.camera:get_size()
  local topleft = self.top_left
  local botright = self.bottom_right
  topleft:clone(cpos)
  botright:set(topleft.x + cw, topleft.y + ch)
  local mini, minj = self:get_chunk_index(topleft)
  local maxi, maxj = self:get_chunk_index(botright)
  
  mini = math.max(mini, 1)
  minj = math.max(minj, 1)
  maxi = math.min(maxi, self.chunk_cols)
  maxj = math.min(maxj, self.chunk_rows)
  
  local visible = true
  if mini > self.chunk_cols or maxi < 1 then 
    visible = false
  end
  if minj > self.chunk_rows or maxj < 1 then 
    visible = false
  end
  self.map_isvisible = visible
  
  local chunks_in_view = self.chunks_in_view
  local chunks_in_view_by_id = self.chunks_in_view_by_id
  table.clear(chunks_in_view)
  table.clear_hash(chunks_in_view_by_id)
  if self.map_isvisible then
    for j=minj,maxj do
      for i=mini,maxi do
      	local chunk = self.chunks[j][i]
        chunks_in_view[#chunks_in_view+1] = chunk
        chunks_in_view_by_id[chunk.id] = true
      end
    end
  end
  
  return chunks_in_view, chunks_in_view_by_id
end

function tile_map:update_chunks_in_active_area()
  -- calculate which chunks can be seen by the camera
  local area = self.level:get_active_area()
  local topleft = self.top_left
  local botright = self.bottom_right
  topleft:set(area.x, area.y)
  botright:set(topleft.x + area.width, topleft.y + area.height)
  local mini, minj = self:get_chunk_index(topleft)
  local maxi, maxj = self:get_chunk_index(botright)
  
  mini = math.max(mini, 1)
  minj = math.max(minj, 1)
  maxi = math.min(maxi, self.chunk_cols)
  maxj = math.min(maxj, self.chunk_rows)
  
  local visible = true
  if mini > self.chunk_cols or maxi < 1 then 
    visible = false
  end
  if minj > self.chunk_rows or maxj < 1 then 
    visible = false
  end
  self.map_isvisible = visible
  
  
  -- clean up memory waste
  local chunks_in_area = self.chunks_in_area
  local chunks_in_area_by_id = self.chunks_in_area_by_id
  table.clear(chunks_in_area)
  table.clear_hash(chunks_in_area_by_id)
  for j=minj,maxj do
    for i=mini,maxi do
      local chunk = self.chunks[j][i]
      chunks_in_area[#chunks_in_area+1] = chunk
      chunks_in_area_by_id[chunk.id] = true
    end
  end
  
  return chunks_in_area, chunks_in_area_by_id
end

-- returns the index of the chunk that contains point
-- returns the chunk if it exists
function tile_map:get_chunk_index(point)
  local width = self.tile_width * self.tiles_per_chunk_col
  local height = self.tile_height * self.tiles_per_chunk_row
  local offx, offy = self.offset_x, self.offset_y
  
  local i = math.floor((point.x - offx) / width) + 1
  local j = math.floor((point.y - offy) / height) + 1
  
  if i >= 1 and i <= self.chunk_cols and j >= 1 and j <= self.chunk_rows then
    return i, j, self.chunks[j][i]
  else
    return i, j, false
  end
end

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- LOADING
--[[----------------------------------------------------------------------]]--
--##########################################################################--

function tile_map:_load_finished()
  self.loading = false
  self.loaded = true
  
  self.final_load_time = self.load_timer:time_elapsed()
  
  if type(self.load_finished_callback) == 'function' then
    self.load_finished_callback()
  end
  
  local init_queue = self.init_queue
  for i=1,#init_queue do
    init_queue[i]:init()
  end
  
end

function tile_map:_save_index(i, j)
  self.continue_idx_i = i
  self.continue_idx_j = j
end

function tile_map:_load_saved_index()
  return self.continue_idx_i, self.continue_idx_j
end

-- runs a loader function until time t runs out
-- loader function must return true if there is more to load, false otherwise
-- returns true if there is still more to load on the func, false otherwise
count = 0
function tile_map:_timed_load(func, t)
  local time_left = t
  local start_time = love.timer.getTime()
  
  while time_left > 0 do
    count = count + 1
  
    local result = func()
    if not result then
      return false
    end
    time_left = t - (love.timer.getTime() - start_time)
  end
  count = 0
  
  return true
end

-- loader function for initializing blank tiles
function tile_map:_load_blank_tiles(num)
  -- load context
  local next_x, next_y = self:_load_saved_index()
  local rows = self.tile_rows
  local cols = self.tile_cols
  local count = 0
  local tiles = self.tiles
  local off_x, off_y = self.offset_x, self.offset_y
  while (count <= num and next_y <= rows) do
  	local tile = tile:new()
    tile.x = TILE_WIDTH * (next_x-1) + off_x
    tile.y = TILE_HEIGHT * (next_y-1) + off_y
    tiles[next_y][next_x] = tile
    
    next_x = next_x + 1
    if next_x > cols then
    	next_x = 1
    	next_y = next_y + 1
    end
  end
  
  if next_y <= rows then
  	-- save context
    self:_save_index(next_x, next_y)
    self.loader_percent = next_y * cols / self.num_tiles
    return true
  else
  	return false
  end
end

function tile_map:_load_chunks(num)
	-- load context
  local next_x, next_y = self:_load_saved_index()
  local rows = self.chunk_rows
  local cols = self.chunk_cols
  local count = 0
  while (count <= num and next_y <= rows) do
  	local chunk = self:_generate_chunk(next_x, next_y)
  	chunk:set_parent(self)
  	chunk:set_id(chunk)
    self.chunks[next_y][next_x] = chunk
    
    next_x = next_x + 1
    if next_x > cols then
    	next_x = 1
    	next_y = next_y + 1
    end
    count = count + 1
  end
  
  if next_y <= rows then
  	-- save context
  	self:_save_index(next_x, next_y)
  	self.loader_percent = (next_y * cols) / self.num_chunks
    return true
  else
  	return false
  end
end

-- generates chunk for row j, column i
function tile_map:_generate_chunk(i, j)
  local off_x, off_y = self.offset_x, self.offset_y
  local chunk = tile_chunk:new()
  chunk:set_parent(self)
  chunk:set_spritesheet(self.spritesheet, self.spritesheet_quads)
  
  chunk:set_position((i-1) * self.tiles_per_chunk_col * self.tile_width + off_x, 
                     (j-1) * self.tiles_per_chunk_row * self.tile_height + off_y)
  
  -- calculate boundaries for which tiles fit into this chunk
  local t_per_c, t_per_r = self.tiles_per_chunk_col, self.tiles_per_chunk_row
  local minx, miny = (i-1) * t_per_c + 1, (j-1) * t_per_r + 1
  local maxx, maxy = minx + t_per_c - 1, miny + t_per_r - 1
  if maxx > self.tile_cols then maxx = self.tile_cols end
  if maxy > self.tile_rows then maxy = self.tile_rows end
  
  -- put those tiles in the chunk
  local tiles = {}
  local diag_tiles = {}
  local idx, idy = 1, 1
  local map_tiles = self.tiles
  local tw, th = self.tile_width, self.tile_height
  for y=miny,maxy do
    local row = {}
    idx = 1
    for x=minx,maxx do
      local tile = map_tiles[y][x]
      tile:set_chunk(chunk)
      tile:set_parent(self)
      tile:set_spritebatch_position((x - minx) * tw, 
                                    (y - miny) * th)
                                    
      if tile:has_diagonal_tile() then
      	local diag_tile = tile.diagonal
      	diag_tile:set_chunk(chunk)
				diag_tile:set_parent(self)
				diag_tile:set_spritebatch_position((x - minx) * tw, 
																			     (y - miny) * th)
																			     
	      diag_tiles[#diag_tiles + 1] = diag_tile
      end
      
      row[idx] = tile
      idx = idx + 1
    end
    
    tiles[idy] = row
    idy = idy + 1
  end
  
  chunk:set_tiles(tiles)
  chunk:set_diagonal_tiles(diag_tiles)
  chunk:init_sprite_batch()
  return chunk
end

function tile_map:_update_load()
  local loader_idx = self.current_loader_idx
  local loaders = self.loader_functions
  
  local loader_func = loaders[loader_idx]
  if self:_timed_load(loader_func, self.load_time_slice) == false then
    self.current_loader_idx = loader_idx + 1
    self:_save_index(1, 1)
    self.loader_percent = 0
  end
  
  if self.current_loader_idx > #loaders then
    self:_load_finished()
  end
end

function tile_map:_load_initialized_tiles(num)
	-- load context
  local next_x, next_y = self:_load_saved_index()
  local rows = self.tile_rows
  local cols = self.tile_cols
  local count = 0
  while (count <= num and next_y <= rows) do
  	self:_set_neighbours(next_x, next_y)
  	self:_set_tile_type(next_x, next_y)
    
    next_x = next_x + 1
    if next_x > cols then
    	next_x = 1
    	next_y = next_y + 1
    end
    count = count + 1
  end
  
  if next_y <= rows then
  	-- save context
  	self:_save_index(next_x, next_y)
  	self.loader_percent = (next_y * cols) / self.num_tiles
    return true
  else
  	return false
  end
end

function tile_map:_set_neighbours(i, j)
  local tiles = self.tiles
  local tile = tiles[j][i]
  local has_right = i+1 <= self.tile_cols
  local has_left = i-1 >= 1
  local has_up = j-1 >= 1
  local has_down = j+1 <= self.tile_rows
  
  local neighbours = {}
  if has_right and has_left and has_up and has_down then
    neighbours[UP]        = tiles[j-1][i]
    neighbours[UPRIGHT]   = tiles[j-1][i+1]
    neighbours[RIGHT]     = tiles[j][i+1]
    neighbours[DOWNRIGHT] = tiles[j+1][i+1]
    neighbours[DOWN]      = tiles[j+1][i]
    neighbours[DOWNLEFT]  = tiles[j+1][i-1]
    neighbours[LEFT]      = tiles[j][i-1]
    neighbours[UPLEFT]    = tiles[j-1][i-1]
  else
    if has_up                 then neighbours[UP]        = tiles[j-1][i] end
    if has_right and has_up   then neighbours[UPRIGHT]   = tiles[j-1][i+1] end
    if has_right              then neighbours[RIGHT]     = tiles[j][i+1] end
    if has_right and has_down then neighbours[DOWNRIGHT] = tiles[j+1][i+1] end
    if has_down               then neighbours[DOWN]      = tiles[j+1][i] end
    if has_left and has_down  then neighbours[DOWNLEFT]  = tiles[j+1][i-1] end
    if has_left               then neighbours[LEFT]      = tiles[j][i-1] end
    if has_left and has_up    then neighbours[UPLEFT]    = tiles[j-1][i-1] end
  end
  
  tile:set_neighbours(neighbours)
end

function tile_map:_set_tile_type(i, j)
  
  local layers = self.tile_layers
  local layer_idx = nil
  local px_val = nil
  
  local has_diagonal = false
  local diag_layer_idx = nil
  local diag_px_val = nil
  local diag_direction = nil
  
  -- get highest priority layer
  for k=#layers,1,-1 do
    local t_layer = layers[k]
    local offx, offy = t_layer.imgdata_x, t_layer.imgdata_y
    local imgdata = t_layer:get_imgdata()
    local r, g, b, a = imgdata:getPixel(offx + i-1, offy + j-1)
    
    -- check for a diagonal tile
    local continue = false
    if r == 1 and g >=2 and g <= 8 and g % 2 == 0 then
    	has_diagonal = true
    	diag_layer_idx = k
    	diag_direction = g
    	diag_px_val = b
    	continue = true
    end
    
    -- diagonal tiles do not count as a base tile
    if not continue then
			px_val = r
			if a ~= t_layer.nil_value then
				layer_idx = k
				break
			end
    end
  end
  if not layer_idx then layer_idx = 1 end
  
  -- calculate quad
  local layer = layers[layer_idx]
  local gradient = layer:get_gradient()
  local quad
  local quad_hash = self.quad_hash[layer_idx]
  
  if quad_hash[px_val] then
    quad = quad_hash[px_val]
  else
    quad = self:_color_to_quad(px_val, gradient)
    quad_hash[px_val] = quad
  end
  
  -- set tile
  local tile_type_num = layer:get_tile_type()
  local tile = self.tiles[j][i]
  tile:_set_quad(quad)
  tile:set_gradient(gradient)
  tile:init_intensity(px_val / 255)
  tile:set_type(tile_type_num)
  
  -- set diagonal tile
  if has_diagonal then
		local diag_layer = layers[diag_layer_idx]
		local diag_gradient = diag_layer:get_gradient()
		local diag_quad = self:_color_to_diagonal_quad(diag_px_val, diag_gradient)
		local diag_tile_type_num = diag_layer:get_tile_type()
	  tile:set_diagonal_tile(diag_direction, diag_tile_type_num, diag_quad, diag_gradient)
	  tile.diagonal:init_intensity(diag_px_val / 255)
  end
  
end

-- converts a color (0-255) to a shade index (1-num) 
function tile_map:_color_to_quad(px_val, gradient)
  return gradient:get_quad(px_val / 255)
end

function tile_map:_color_to_diagonal_quad(px_val, gradient)
  return gradient:get_diagonal_quad(px_val / 255)
end



--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--

function tile_map:update(dt)
  if self:is_loading() then
    self:_update_load()
    return
  end
  if not self:is_loaded() then
    return
  end
  
  local update_chunks = self:update_chunks_in_active_area()
  for i=1,#update_chunks do
    update_chunks[i]:update(dt)
  end
  
  local chunks_in_view, chunks_in_view_by_id = self:update_chunks_in_view()
  self.chunks_in_view = chunks_in_view
  self.chunks_in_view_by_id = chunks_in_view_by_id
  
  if self.collider then
    self.collider:update(dt)
  end
end

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--

function tile_map:draw()
  lg.setColor(255, 255, 255, 255)

  local camera = self.level:get_camera()
  camera:set()
  
  local chunks_in_view = self.chunks_in_view
  if chunks_in_view then
    for i=1,#chunks_in_view do
      local chunk = chunks_in_view[i]
      chunk:draw()
      
      if self.debug then
        chunk:draw_debug()
      end
    end
  end
  
  if self.debug then
    self.collider.debug = true
    self.collider:draw()
  end
  
  camera:unset()
  
end

return tile_map











