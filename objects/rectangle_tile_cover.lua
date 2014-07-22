
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- rectangle_tile_cover object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local TILE_WIDTH, TILE_HEIGHT = TILE_WIDTH, TILE_HEIGHT

local rtc = {}
rtc.table = 'rtc'
rtc.debug = true
rtc.level = nil
rtc.x = nil
rtc.y = nil
rtc.width = nil
rtc.height = nil
rtc.bbox = nil
rtc.tiles = nil

-- corners
rtc.ul_tile = nil
rtc.ul_x = nil                -- upleft
rtc.ul_y = nil
rtc.ul_offx = nil
rtc.ul_offy = nil
rtc.dr_tile = nil
rtc.dr_x = nil                -- upleft
rtc.dr_y = nil
rtc.dr_offx = nil
rtc.dr_offy = nil

rtc.added_tiles = nil
rtc.removed_tiles = nil
rtc.added_tiles_hash = nil
rtc.removed_tiles_hash = nil
rtc.add_remove_tile_callback = nil
rtc.callback_parent = nil

rtc.empty_rows = nil


local rtc_mt = { __index = rtc }
function rtc:new(level, x, y, width, height)
  local rtc = setmetatable({}, rtc_mt)
  local self = rtc
  
  self.level = level
  self.x, self.y = x, y
  self.width, self.height = width, height
  self.bbox = bbox:new(x, y, width, height)
  self.added_tiles = {}
  self.removed_tiles = {}
  self.added_tiles_hash = {}
  self.removed_tiles_hash = {}
  self.empty_rows = {{}, {}}
  
  rtc:_init(rtc)
  
  return rtc
end

function rtc:set_add_remove_tile_callback(callback_func, callback_table)
  self.add_remove_tile_callback = callback_func
  self.callback_parent = callback_table
end

function rtc:get_tile_cover()
  return self.tiles
end

function rtc:_init()
  -- get tiles under area
  local x, y, width, height = self.x, self.y, self.width, self.height
  local cols = math.ceil(width / TILE_WIDTH)
  local rows = math.ceil(height / TILE_HEIGHT)
  
  if width % TILE_WIDTH == 0 and not (x % TILE_WIDTH == 0) then
    cols = cols + 1
  end
  if height % TILE_HEIGHT == 0 and not (y % TILE_WIDTH == 0) then
    rows = rows + 1
  end
  
  local tile = self.level:get_level_map():get_tile_at_position(vector2:new(x, y))
  local next_tile = tile
  local grid = {}
  for j=1,rows do
    grid[j] = {}
    for i=1,cols do
      grid[j][i] = next_tile
      next_tile = next_tile.neighbours[RIGHT]
    end
    tile = tile.neighbours[DOWN]
    next_tile = tile
  end
  self.tiles = grid
  
  -- set corner values
  local tile = grid[1][1]
  self.ul_tile = tile
  self.ul_x, self.ul_y = x, y
  self.ul_offx, self.ul_offy = x - tile.x, y - tile.y
  
  local tile = grid[#grid][#grid[#grid]]
  local x, y = x + width, y + height
  self.dr_tile = tile
  self.dr_x, self.dr_y = x, y
  self.dr_offx, self.dr_offy = x - tile.x, y - tile.y
  
end

function rtc:_update_added_and_removed_tiles()
  local added_hash = self.added_tiles_hash
  local removed_hash = self.removed_tiles_hash
  local added = self.added_tiles
  local removed = self.removed_tiles
  table.clear(added)
  table.clear(removed)
  
  local idx = 1
  for tile,_ in pairs(added_hash) do
    if not removed_hash[tile] then
      added[idx] = tile
      idx = idx + 1
    end
  end
  
  idx = 1
  for tile,_ in pairs(removed_hash) do
    if not added_hash[tile] then
      removed[idx] = tile
      idx = idx + 1
    end
  end
  
  table.clear_hash(removed_hash)
  table.clear_hash(added_hash)
  
  if self.add_remove_tile_callback then
    if self.callback_parent then
      self.add_remove_tile_callback(self.callback_parent, added, removed)
    else
      self.add_remove_tile_callback(added, removed)
    end
  end
end

function rtc:move(x, y)
  local next_x, next_y = x, y
  local x, y = self.x, self.y
  
  if next_x == x and next_y == y then
    return
  end
  
  -- check if corners have moved to new tile
  local w, h = TILE_WIDTH, TILE_HEIGHT
  local tx, ty = next_x - x, next_y - y
  local offx, offy = self.ul_offx, self.ul_offy
  offx, offy = offx + tx, offy + ty
  
  -- for upleft corner
  local up, right, down, left = offy < 0, offx >= w, offy >= h, offx < 0
  local upleft_has_moved =  up or right or down or left
  if upleft_has_moved then
    self:_move_upleft_corner(next_x, next_y, up, right, down, left)
  else
    self.ul_x, self.ul_y = self.ul_x + tx, self.ul_y + ty
    self.ul_offx, self.ul_offy = offx, offy
  end
  
  -- for down right corner
  local offx, offy = self.dr_offx, self.dr_offy
  offx, offy = offx + tx, offy + ty
  local up, right, down, left = offy < 0, offx >= w, offy >= h, offx < 0
  local downright_has_moved =  up or right or down or left
  if downright_has_moved then
    self:_move_downright_corner(next_x + self.width, next_y + self.height, 
                                up, right, down, left)
  else
    self.dr_x, self.dr_y = self.dr_x + tx, self.dr_y + ty
    self.dr_offx, self.dr_offy = offx, offy
  end
  
  self.x, self.y = next_x, next_y
  self.bbox.x, self.bbox.y = next_x, next_y
  
  -- update added and removed tiles
  if upleft_has_moved or downright_has_moved then
    self:_update_added_and_removed_tiles()
  end
end

function rtc:_move_upleft_corner(x, y, up, right, down, left)
  local new_tile
  local curr_tile = self.ul_tile
  if      up and right then
    self:_remove_left_tiles()
    self:_add_up_tiles()
    new_tile = curr_tile.neighbours[UPRIGHT]
  elseif down and right then
    self:_remove_left_tiles()
    self:_remove_up_tiles()
    new_tile = curr_tile.neighbours[DOWNRIGHT]
  elseif down and left then
    self:_add_left_tiles()
    self:_remove_up_tiles()
    new_tile = curr_tile.neighbours[DOWNLEFT]
  elseif up and left then
    self:_add_left_tiles()
    self:_add_up_tiles()
    new_tile = curr_tile.neighbours[UPLEFT]
  elseif up then
    self:_add_up_tiles()
    new_tile = curr_tile.neighbours[UP]
  elseif right then
    self:_remove_left_tiles()
    new_tile = curr_tile.neighbours[RIGHT]
  elseif down then
    self:_remove_up_tiles()
    new_tile = curr_tile.neighbours[DOWN]
  elseif left then
    self:_add_left_tiles()
    new_tile = curr_tile.neighbours[LEFT]
  end

  self.ul_tile = new_tile
  self.ul_x, self.ul_y = x, y
  self.ul_offx, self.ul_offy = x - new_tile.x, y - new_tile.y
end

function rtc:_move_downright_corner(x, y, up, right, down, left)
  local new_tile
  local curr_tile = self.dr_tile
  if      up and right then
    self:_add_right_tiles()
    self:_remove_down_tiles()
    new_tile = curr_tile.neighbours[UPRIGHT]
  elseif down and right then
    self:_add_right_tiles()
    self:_add_down_tiles()
    new_tile = curr_tile.neighbours[DOWNRIGHT]
  elseif down and left then
    self:_remove_right_tiles()
    self:_add_down_tiles()
    new_tile = curr_tile.neighbours[DOWNLEFT]
  elseif up and left then
    self:_remove_right_tiles()
    self:_remove_down_tiles()
    new_tile = curr_tile.neighbours[UPLEFT]
  elseif up then
    self:_remove_down_tiles()
    new_tile = curr_tile.neighbours[UP]
  elseif right then
    self:_add_right_tiles()
    new_tile = curr_tile.neighbours[RIGHT]
  elseif down then
    self:_add_down_tiles()
    new_tile = curr_tile.neighbours[DOWN]
  elseif left then
    self:_remove_right_tiles()
    new_tile = curr_tile.neighbours[LEFT]
  end
  
  self.dr_tile = new_tile
  self.dr_x, self.dr_y = x, y
  self.dr_offx, self.dr_offy = x - new_tile.x, y - new_tile.y
end

function rtc:_add_up_tiles()
  local tiles = self.tiles
  local added = self.added_tiles_hash
  local new_row = self.empty_rows[#self.empty_rows]
  self.empty_rows[#self.empty_rows] = nil
  
  for i=1,#tiles[1] do
    new_row[i] = tiles[1][i].neighbours[UP]
    added[new_row[i]] = true
  end
  
  table.insert(tiles, 1, new_row)
end

function rtc:_add_down_tiles()
  local tiles = self.tiles
  local added = self.added_tiles_hash
  local new_row = self.empty_rows[#self.empty_rows]
  self.empty_rows[#self.empty_rows] = nil
  
  for i=1,#tiles[1] do
    new_row[i] = tiles[#tiles][i].neighbours[DOWN]
    added[new_row[i]] = true
  end
  tiles[#tiles + 1] = new_row
end

function rtc:_add_left_tiles()
  local tiles = self.tiles
  local added = self.added_tiles_hash
  
  for j=1,#tiles do
    local t = tiles[j][1].neighbours[LEFT]
    table.insert(tiles[j], 1, t)
    added[t] = true
  end
end

function rtc:_add_right_tiles()
  local tiles = self.tiles
  local added = self.added_tiles_hash
  
  for j=1,#tiles do
    local t = tiles[j][#tiles[j]].neighbours[RIGHT]
    tiles[j][#tiles[j] + 1] = t
    added[t] = true
  end
end

function rtc:_remove_up_tiles()
  local tiles = self.tiles
  local removed = self.removed_tiles_hash
  
  local empty_row = table.remove(tiles, 1)
  for i=#empty_row,1,-1 do
    removed[empty_row[i]] = true
    empty_row[i] = nil
  end
  self.empty_rows[#self.empty_rows + 1] = empty_row
end

function rtc:_remove_down_tiles()
  local tiles = self.tiles
  local removed = self.removed_tiles_hash
  
  local empty_row = tiles[#tiles]
  tiles[#tiles] = nil
  for i=#empty_row,1,-1 do
    removed[empty_row[i]] = true
    empty_row[i] = nil
  end
  self.empty_rows[#self.empty_rows + 1] = empty_row
end

function rtc:_remove_left_tiles()
  local tiles = self.tiles
  local removed = self.removed_tiles_hash
  
  for j=1,#tiles do
    local t = table.remove(tiles[j], 1)
    removed[t] = true
  end
end

function rtc:_remove_right_tiles()
  local tiles = self.tiles
  local removed = self.removed_tiles_hash
  
  for j=1,#tiles do
    local t = tiles[j][#tiles[j]]
    tiles[j][#tiles[j]] = nil
    removed[t] = true
  end
end

------------------------------------------------------------------------------
function rtc:update(dt)
end

------------------------------------------------------------------------------
function rtc:draw()
  if self.debug then
    lg.setColor(0, 255, 0, 255)
    lg.setLineWidth(1)
    lg.rectangle('line', self.x, self.y, self.width, self.height)
    
    lg.setColor(0, 255, 0, 100)
    local w, h = TILE_WIDTH, TILE_HEIGHT
    local tiles = self.tiles
    for j=1,#tiles do
      for i=1,#tiles[j] do
        local t = tiles[j][i]
        lg.rectangle('line', t.x, t.y, w, h)
      end
    end
    
    lg.setColor(255, 0, 0, 255)
    lg.setPointSize(6)
    lg.point(self.ul_x, self.ul_y)
    lg.point(self.dr_x, self.dr_y)
    
    local added = self.added_tiles
    local removed = self.removed_tiles
    lg.setColor(0, 255, 0, 255)
    for i=1,#added do
      local t = added[i]
      lg.rectangle('line', t.x, t.y, w, h)
    end
    
    lg.setColor(255, 0, 0, 255)
    for i=1,#removed do
      local t = removed[i]
      lg.rectangle('line', t.x, t.y, w, h)
    end
    
  end
end

return rtc
















