
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- tile_explosion object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local te = {}
te.table = 'te'
te.debug = false
te.level = level
te.x = nil
te.y = nil
te.top_left_tile = nil
te.tiles_wide = nil
te.tiles = nil
te.active_tiles = nil
te.tile_flash_data = nil
te.radius = nil
te.walkable_state = nil
te.current_time = 0
te.is_done = false
te.flash_curve = nil
te.min_delay = 0
te.max_delay = 0.3
te.min_power = 0
te.max_power = 1
te.max_intensity = 1
te.max_intensity_difference = 1
te.flash_time = 3
te.flash_time_deviation = 0
te.tile_coverage_percent = 1

te.num_raycasts = 0

local te_mt = { __index = te }
function te:new(level, x, y, radius, walkable_state, flash_curve, fade_curve, power)
  local te = setmetatable({}, te_mt)
  te.level = level
  te.flash_curve = flash_curve
  te.fade_curve = fade_curve
  te.x, te.y = x, y
  te.radius = radius
  te.max_power = power or te.max_power
  
  local tiles_wide = math.ceil(2 * radius / TILE_WIDTH) + 1
  local top_left = vector2:new(te.x - radius, te.y - radius)
  te.top_left_tile = level:get_level_map():get_tile_at_position(top_left)
  te.tiles_wide = tiles_wide
  te.walkable_state = walkable_state
  
  local tiles, check_raycasts = te._get_tiles_in_radius(te)
  if check_raycasts and walkable_state == true then
    tiles = te._filter_out_of_view_tiles(te, tiles)
  end
  te.active_tiles = {}
  
  -- filter out some tiles randomly
  if te.tile_coverage_percent < 1 then
    local percent = te.tile_coverage_percent
    local filtered_tiles = {}
    for i=1,#tiles do
      if math.random() < percent then
        filtered_tiles[#filtered_tiles + 1] = tiles[i]
      end
    end
    local tiles = filtered_tiles
  end
  
  te.tiles = tiles
  
  local tdata = te._init_tile_flash_data(te, tiles)
  te.tile_flash_data = tdata
  
  return te
end

function te:play()
  self.is_playing = true
end

function te:is_finished()
  return self.is_done
end

function te:_filter_out_of_view_tiles(tiles)
  local center = vector2:new(self.x, self.y)
  local ray = ray:new(self.level, center)
  local good_tiles = {}
  local good_tiles_idx = {}
  local num_casts = 0
  local dir = vector2:new(0, 0)
  local htw = 0.5 * TILE_WIDTH
  
  local tile_indexes = {}
  for i=1,#tiles do
    tile_indexes[tiles[i]] = i
  end
  
  for i=1,#tiles do
    local tile = tiles[i]
    if good_tiles[tile] == nil then
      local ctx, cty = tile.x + htw, tile.y + htw
      dir.x, dir.y = ctx - center.x, cty - center.y
      local dist = math.sqrt(dir.x * dir.x + dir.y * dir.y)
      dir = dir:unit_vector(dir)
      ray:set_direction(dir)
      ray:set_length(dist)
      local collision, tile_cover = ray:cast(1, true)
      local tile_cover = tile_cover[1]
      local n = #tile_cover
      if collision and not tile_cover[#tile_cover].diagonal then
        -- supercover includes the collision tile in tile cover
        n = n - 1
      end
      
      for j=1,n do
        local tile = tile_cover[j]
        
        if tile_indexes[tile] then
            good_tiles[tile] = true
            good_tiles_idx[tile_indexes[tile]] = tile
        end
      end
      
      num_casts = num_casts + 1
    end
  end
  self.num_raycasts = num_casts
  
  local fov_tiles = {}
  local i = 1
  local new_idx = 1
  for old_idx,t in pairs(good_tiles_idx) do
    fov_tiles[new_idx] = t
    new_idx = new_idx + 1
  end
  
  return fov_tiles
end

function te:_init_tile_flash_data(tiles)
  local tdata = {}
  local tiles = self.tiles
  local htw = 0.5 * TILE_WIDTH
  local cx, cy = self.x, self.y
  local sqrt = math.sqrt
  local random = math.random
  local radius = self.radius
  local delay_diff = self.max_delay - self.min_delay
  local power_diff = self.max_power - self.min_power
  local fade_curve = self.fade_curve
  
  for i=1,#tiles do
    local t = tiles[i]
    local data = {}
    tdata[i] = data
    data.tile = t
    
    local dx, dy = t.x + htw - cx, t.y + htw - cy
    local dist = sqrt(dx*dx + dy*dy)
    local ratio = (dist / radius)
    local power_ratio = fade_curve:get(ratio)
    
    local dev = self.flash_time_deviation
    data.start_time = self.min_delay + ratio * delay_diff
    local end_time = data.start_time + self.flash_time - dev + 2 * dev * random()
    data.current_time = 0
    data.lifetime = end_time - data.start_time
    data.power = self.min_power + power_ratio * power_diff
    data.curve = self.flash_curve
  end
  
  return tdata
end

function te:_get_tiles_in_radius()
  -- starting at the top left corner find all tiles in the bounding rectangle 
  -- by following a spiral pattern so that the array of tiles is ordered roughly
  -- in decreasing distance to center

  local top_left_tile = self.top_left_tile
  
  -- assume that the top left tile is not within the radius of the explostion
  -- so don't add it to the array of tiles within radius
  local tiles = {}
  local num_tiles = 0                        -- index for tile arrays
  local dirs = {RIGHT, DOWN, LEFT, UP}
  local didx = 1                             -- index of current direction
  local cx, cy = self.x, self.y
  local walk_state = self.walkable_state
  local has_opp_state = false               -- whether radius contains a tile
                                             -- of the opposite walkable state.
                                             -- if not, then we can skip raycasts
  
  -- top row
  local rsq = self.radius * self.radius
  local width = self.tiles_wide - 1
  local tile = top_left_tile
  for i=1,width do
    local next_tile = tile.neighbours[dirs[didx]]
    local tcx = next_tile.x + 0.5 * TILE_WIDTH
    local tcy = next_tile.y + 0.5 * TILE_HEIGHT
    local dx, dy = tcx - cx, tcy - cy
    local distsq = dx * dx + dy * dy
    
    if distsq < rsq and next_tile.walkable == walk_state then
      tiles[num_tiles + 1] = next_tile
      num_tiles = num_tiles + 1
    elseif distsq < rsq and next_tile.diagonal and 
            next_tile.diagonal.walkable == false then
      tiles[num_tiles + 1] = next_tile.diagonal
      num_tiles = num_tiles + 1
    elseif distsq < rsq and next_tile.walkable ~= walk_state then
      has_opp_state = true
    end
    tile = next_tile
  end
  didx = didx + 1
  
  -- rest of tiles
  while width > 0 do
    for j=1,2 do
      for i=1,width do
        local next_tile = tile.neighbours[dirs[didx]]
        local tcx = next_tile.x + 0.5 * TILE_WIDTH
        local tcy = next_tile.y + 0.5 * TILE_HEIGHT
        local dx, dy = tcx - cx, tcy - cy
        local distsq = dx * dx + dy * dy
        
        if distsq < rsq and next_tile.walkable == walk_state then
          tiles[num_tiles + 1] = next_tile
          num_tiles = num_tiles + 1
        elseif distsq < rsq and next_tile.diagonal and 
                next_tile.diagonal.walkable == false then
          tiles[num_tiles + 1] = next_tile.diagonal
          num_tiles = num_tiles + 1
        elseif distsq < rsq and next_tile.walkable ~= walk_state then
          has_opp_state = true
        end
        tile = next_tile
      end
      
      didx = didx + 1
      if didx == 5 then didx = 1 end
    end
    
    width = width - 1
  end
  
  return tiles, has_opp_state
end

function te:_update_tile_flash_data(dt)
  if self.is_done then
    return
  end

  local flash_data = self.tile_flash_data
  local time = self.current_time
  for i=#flash_data,1,-1 do
    local data = flash_data[i]
    if time > data.start_time then
      data.tile:flash(data.power, data.lifetime, data.curve)
      table.remove(flash_data,i)
    end
  end
  if #flash_data == 0 then
    self.is_done = true
    self.is_playing = false
  end
end

------------------------------------------------------------------------------
function te:update(dt)
  if not self.is_playing then
    return
  end

  self.current_time = self.current_time + dt
  self:_update_tile_flash_data(dt)
end

------------------------------------------------------------------------------
function te:draw()
  if self.debug then
    local tile = self.top_left_tile
    local w = self.tiles_wide * TILE_WIDTH
    lg.setColor(255, 0, 0, 255)
    lg.rectangle('line', tile.x, tile.y, w, w)
    
    lg.setColor(0, 255, 0, 255)
    lg.circle('line', self.x, self.y, self.radius)
    lg.point(self.x, self.y)
    
    local tiles = self.tiles
    local min, max = 20, 255
    for i=1,#tiles do
      local t = tiles[i]
      local a = min + (i / #tiles) * (max - min)
      lg.setColor(0, 0, 255, a)
      lg.rectangle('line', t.x, t.y, TILE_WIDTH, TILE_HEIGHT)
    end
    
    lg.setColor(255, 0, 0, 255)
    lg.print("#tiles: "..tostring(#tiles)..
             "\n#raycasts: "..tostring(self.num_raycasts), 
              tile.x, tile.y)
  end
  
end

return te






























