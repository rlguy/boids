
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- ray object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local ray = {}
ray.table = 'ray'
ray.level_map = nil

ray.x = nil
ray.y = nil
ray.pos = nil
ray.start_pos = nil
ray.end_pos = nil
ray.dirx = nil
ray.diry = nil
ray.max_length = 2000

ray.line = nil
ray.normals = nil

local solve_intersection = {}
local w, h = TILE_WIDTH, TILE_HEIGHT
solve = solve_intersection
solve[UP]    = function(m, b, tx, ty)
                 local x = (1 / m) * (ty - b)
                 local y = ty
                 return x, y, NORMAL[UP]
               end
solve[RIGHT] = function(m, b, tx, ty)
                 local x = tx + w
                 local y = m * x + b
                 return x, y, NORMAL[RIGHT]
               end
solve[DOWN] =  function(m, b, tx, ty)
                 local x = (1 / m) * (ty + h - b)
                 local y = ty + h
                 return x, y, NORMAL[DOWN]
               end
solve[LEFT] =  function(m, b, tx, ty)
                 local x = tx
                 local y = m * x + b
                 return x, y, NORMAL[LEFT]
               end
                
solve[UPRIGHT] =   function(m, b, tx, ty)
                     local x = (ty - tx - b) / (m - 1)
                     local y = x + ty - tx
                     return x, y, NORMAL[UPRIGHT]
                   end
solve[DOWNRIGHT] = function(m, b, tx, ty)
                     local x = (ty + tx + w - b) / (m + 1)
                     local y = -x + ty + tx + w
                     return x, y, NORMAL[DOWNRIGHT]
                   end                 
                 
solve[DOWNLEFT] =  function(m, b, tx, ty)
                     local x = (ty - tx - b) / (m - 1)
                     local y = x + ty - tx
                     return x, y, NORMAL[DOWNLEFT]
                   end
solve[UPLEFT] =    function(m, b, tx, ty)
                     local x = (ty + tx + w - b) / (m + 1)
                     local y = -x + ty + tx + w
                     return x, y, NORMAL[UPLEFT]
                   end  

local solve_quadrant_case = {}
local qcase = solve_quadrant_case
qcase[1] = function(m, b, tile)
             local ix, iy, normal
             local tx, ty, w, h = tile.x, tile.y, TILE_WIDTH, TILE_HEIGHT
             if tile.diagonal then
               local dir = tile.diagonal.direction
               
               if     dir == UPRIGHT then
                 local ix, iy, normal = solve_intersection[LEFT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[UPRIGHT](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
                 
               elseif dir == DOWNRIGHT then
                 local ix, iy, normal = solve_intersection[LEFT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[UP](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
                 
               elseif dir == DOWNLEFT then
                 local ix, iy, normal = solve_intersection[DOWNLEFT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[UP](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
               elseif dir == UPLEFT then
                 local ix, iy, normal = solve_intersection[UPLEFT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
               end
             else
               local ix, iy, normal = solve_intersection[LEFT](m, b, tx, ty)
               if iy >= ty and iy <= ty + h then
                 return true, ix, iy, normal
               end
               local ix, iy, normal = solve_intersection[UP](m, b, tx, ty)
               if ix >= tx and ix <= tx + w then
                 return true, ix, iy, normal
               end
             end
             
             return false
           end
           
qcase[2] = function(m, b, tile)
             local ix, iy, normal
             local tx, ty, w, h = tile.x, tile.y, TILE_WIDTH, TILE_HEIGHT
             if tile.diagonal then
               local dir = tile.diagonal.direction
               
               if     dir == DOWNRIGHT then
                 local ix, iy, normal = solve_intersection[DOWNRIGHT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[UP](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
                 
               elseif dir == DOWNLEFT then
                 local ix, iy, normal = solve_intersection[RIGHT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[UP](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
                 
               elseif dir == UPLEFT then
                 local ix, iy, normal = solve_intersection[RIGHT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[UPLEFT](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
               elseif dir == UPRIGHT then
                 local ix, iy, normal = solve_intersection[UPRIGHT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
               end
             else
               local ix, iy, normal = solve_intersection[RIGHT](m, b, tx, ty)
               if iy >= ty and iy <= ty + h then
                 return true, ix, iy, normal
               end
               local ix, iy, normal = solve_intersection[UP](m, b, tx, ty)
               if ix >= tx and ix <= tx + w then
                 return true, ix, iy, normal
               end
             end
             
             return false
           end
           
qcase[3] = function(m, b, tile)
             local ix, iy, normal
             local tx, ty, w, h = tile.x, tile.y, TILE_WIDTH, TILE_HEIGHT
             if tile.diagonal then
               local dir = tile.diagonal.direction
               
               if     dir == UPRIGHT then
                 local ix, iy, normal = solve_intersection[UPRIGHT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[DOWN](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
                 
               elseif dir == DOWNLEFT then
                 local ix, iy, normal = solve_intersection[RIGHT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[DOWNLEFT](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
                 
               elseif dir == UPLEFT then
                 local ix, iy, normal = solve_intersection[RIGHT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[DOWN](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
               elseif dir == DOWNRIGHT then
                 local ix, iy, normal = solve_intersection[DOWNRIGHT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
               end
             else
               local ix, iy, normal = solve_intersection[RIGHT](m, b, tx, ty)
               if iy >= ty and iy <= ty + h then
                 return true, ix, iy, normal
               end
               local ix, iy, normal = solve_intersection[DOWN](m, b, tx, ty)
               if ix >= tx and ix <= tx + w then
                 return true, ix, iy, normal
               end
             end
             
             return false
           end

qcase[4] = function(m, b, tile)
             local ix, iy, normal
             local tx, ty, w, h = tile.x, tile.y, TILE_WIDTH, TILE_HEIGHT
             if tile.diagonal then
               local dir = tile.diagonal.direction
               
               if     dir == UPRIGHT then
                 local ix, iy, normal = solve_intersection[LEFT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[DOWN](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
                 
               elseif dir == DOWNRIGHT then
                 local ix, iy, normal = solve_intersection[LEFT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[DOWNRIGHT](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
                 
               elseif dir == UPLEFT then
                 local ix, iy, normal = solve_intersection[UPLEFT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
                 local ix, iy, normal = solve_intersection[DOWN](m, b, tx, ty)
                 if ix >= tx and ix <= tx + w then
                   return true, ix, iy, normal
                 end
               elseif dir == DOWNLEFT then
                 local ix, iy, normal = solve_intersection[DOWNLEFT](m, b, tx, ty)
                 if iy >= ty and iy <= ty + h then
                   return true, ix, iy, normal
                 end
               end
             else
               local ix, iy, normal = solve_intersection[LEFT](m, b, tx, ty)
               if iy >= ty and iy <= ty + h then
                 return true, ix, iy, normal
               end
               local ix, iy, normal = solve_intersection[DOWN](m, b, tx, ty)
               if ix >= tx and ix <= tx + w then
                 return true, ix, iy, normal
               end
             end
             
             return false
           end
                   
local ray_mt = { __index = ray }
function ray:new(level, position, direction)
  local ray = setmetatable({}, ray_mt)
  
  ray.x, ray.y = 0, 0
  ray.dirx, ray.diry = 0, 1
  if position then
    ray.x, ray.y = position.x, position.y
  end
  if direction and (direction.x ~= 0 or direction.y ~= 0) then
    ray.dirx, ray.diry = direction.x, direction.y
  end
  ray.pos = vector2:new(0, 0)
  ray.pos.x, ray.pos.y = position.x, position.y
  ray.start_pos = vector2:new(0, 0)
  ray.end_pos = vector2:new(0, 0)
  
  ray.level_map = level:get_level_map()
  ray.line = {}
  ray.normals = {}
  ray.tiles = {{}}
  
  return ray
end

-- point source of ray
function ray:set_position(p)
  self.x, self.y = point.x, point.y
  self.pos = p
end

-- normalized vector
function ray:set_direction(dir)
  self.dirx, self.diry = dir.x, dir.y
end

function ray:set_length(length)
  self.max_length = length
end

function ray:set(point, direction, length)
  self.x, self.y = point.x, point.y
  self.pos.x, self.pos.y = point.x, point.y
  
  if direction then
    self.dirx, self.diry = direction.x, direction.y
    
    -- makes calculation easier if line is not completely vertical or horizontal
    if self.dirx == 0 then
      self.dirx = self.dirx + 0.0000001
      local ilen = 1 / math.sqrt(self.dirx * self.dirx + self.diry * self.diry)
      self.dirx = self.dirx * ilen, self.diry * ilen
    elseif self.diry == 0 then
      self.diry = self.diry + 0.0000001
      local ilen = 1 / math.sqrt(self.dirx * self.dirx + self.diry * self.diry)
      self.dirx = self.dirx * ilen, self.diry * ilen
    end
  end
  
  if length then
    self.max_length = length
  end
end

function ray:get_line()
  return self.line
end
function ray:get_normals()
  return self.normals
end
function ray:get_supercover()
  return self.tiles
end

function ray:_get_line_equation(x1, y1, x2, y2)
  if x1 == x2 then
	  x2 = x2 + EPSILON
	end
	
	local m, b
	if x2 > x1 then
	  m = (y2 - y1) / (x2 - x1)
	  b = y1 - m * x1
	else
	  m = (y1 - y2) / (x1 - x2)
	  b = y2 - m * x2
	end
	
	local quadrant
	local dx, dy = x2 - x1, y2 - y1
	if dx > 0 then
	  if dy > 0 then
	    quadrant = 1
	  else
	    quadrant = 4
	  end
	else
	  if dy < 0 then
	    quadrant = 3
	  else
	    quadrant = 2
	  end
	end
	
	return m, b, quadrant
end

-- checks for intersection between ray and a tile
function ray:_get_intersection(m, b, x1, y1, x2, y2, quadrant, tile)
  local start_x, end_x = math.min(x1, x2), math.max(x1, x2)
  local collision, ix, iy, normal = solve_quadrant_case[quadrant](m, b, tile)
  if collision and ix >= start_x and ix <= end_x then
    return true, ix, iy, normal
  end
  
  return false
end

-- depth for number of recursive raycasts to calculate
-- get_tiles is a boolean for whether to store the supercover tiles
function ray:cast(depth, get_tiles)
  local depth = depth or 1
  local current_depth = 0
  local x, y = self.x, self.y
  local dirx, diry = self.dirx, self.diry
  
  -- clear line storage
  local line = self.line
  local normals = self.normals
  table.clear(normals)
  table.clear(line)
  line[1] = x
  line[2] = y
  
  -- initialize more tile set tables if needed
  -- clear values in tile sets
  local tiles = self.tiles
  if #tiles < depth then
    for i=1,depth-#tiles do
      tiles[#tiles + 1] = {}
    end
  end
  if get_tiles then
    for i=1,depth do
      local tile_set = tiles[i]
      for j=#tile_set,1,-1 do
        tile_set[j] = nil
      end
    end
  end
  
  local tile_set_count = 0
  local ray_collision = false
  while current_depth < depth do
    
    local tile_set = tiles[current_depth + 1]
    local collision, cx, cy, normal = self:_cast_ray(x, y, dirx, diry, 
                                                     current_depth, 
                                                     get_tiles, tile_set)
    tile_set_count = tile_set_count + 1
          
    if collision then
      ray_collision = true
      local vx, vy = cx - x, cy - y
      local vdotn = vx * normal.x + vy * normal.y
      dirx = -2 * vdotn * normal.x + vx
      diry = -2 * vdotn * normal.y + vy
      local len = math.sqrt(dirx*dirx + diry*diry)
      dirx = dirx / len
      diry = diry / len
      x, y = cx, cy
      
      line[#line + 1] = cx
      line[#line + 1] = cy
      normals[#normals + 1] = normal
    else
      local length = self.max_length
      local x2, y2 = x + length * dirx, y + length * diry
      line[#line + 1] = x2
      line[#line + 1] = y2
      break
    end
    current_depth = current_depth + 1
  end
  self.line = line
  self.tiles = tiles
  self.tiles.tile_set_count = tile_set_count
  
  return ray_collision, self.tiles
end

function ray:_cast_ray(x, y, dir_x, dir_y, depth, get_tiles, tile_storage)
  -- find start and end tiles
  local max_len = self.max_length
  local dirx, diry = dir_x, dir_y
  local x1, y1 = x, y
  local x2, y2 = x1 + max_len * dirx, y1 + max_len * diry
  local end_pos = self.end_pos
  local start_pos = self.start_pos
  start_pos.x, start_pos.y = x1, y1
  end_pos.x, end_pos.y = x2, y2
  
  -- The start of the ray should be within the level map
  if not self.level_map.bbox:contains_point(start_pos) then
    return false
  end
  
  -- if the end of the ray is out of the map, then shorten the ray
  if not self.level_map.bbox:contains_point(end_pos) then
    local r = self.level_map.bbox
    local x, y, nx, ny = line_rectangle_intersection(x1, y1, x2, y2, 
                                             r.x, r.y, r.width, r.height)
    if x then
      -- jog collision point back a bit from map boundary
      -- nx. ny is the normal of box side, not of the collision
      local jog = 1
      x2, y2 = x - jog * nx, y - jog * ny
      end_pos:set(x2, y2)
    else
      return false -- this shouldn't happen
    end
  end
  
  
  
  local t1 = self.level_map:get_tile_at_position(start_pos)
  local t2 = self.level_map:get_tile_at_position(end_pos)
  local m, b_original, quadrant = self:_get_line_equation(x1, y1, x2, y2)
  
  -- offset points so that top left corner of t1 is at origin
  local offx, offy = -t1.x, -t1.y
  local x1, x2 = x1 + offx, x2 + offx
  local y1, y2 = y1 + offy, y2 + offy
  local m, b, quadrant = self:_get_line_equation(x1, y1, x2, y2)
  
  -- find supercover of line
  -- A is the current tile
  -- depending on quadrant, B is up/down from A, C is left/right from A
  local A = t1
  local B, C
  local start_i, end_i, inc_i
  local start_j, inc_j
  
  -- find quadrant specific values
  if     quadrant == 1 then
    B_dir = DOWN
    C_dir = RIGHT
    start_i = 1
    inc_i, inc_j = 1, 1
  elseif quadrant == 2 then
    B_dir = DOWN
    C_dir = LEFT
    start_i = 0
    inc_i, inc_j = -1, 1
  elseif quadrant == 3 then
    B_dir = UP
    C_dir = LEFT
    start_i = 0
    inc_i, inc_j = -1, -1
  elseif quadrant == 4 then
    B_dir = UP
    C_dir = RIGHT
    start_i = 1
    inc_i, inc_j = 1, -1
  end
  start_j = 0
  
  local i, j = start_i, start_j
  local w, h = TILE_WIDTH, TILE_HEIGHT
  local c, cx, cy, n
  local collision = false
  local tiles = tile_storage
  tiles[1] = A
  
  -- Check that ray does not intersect first tile when player 
  --is located on that tile
  if depth == 0 and (not A.walkable or (A.diagonal and not A.diagonal.walkable)) then
    c, cx, cy, n = self:_get_intersection(m, b_original, 
                                                x1-offx, y1-offy, 
                                                x2-offx, y2-offy, quadrant, A)
  end
  
  -- compute supercover
  while A ~= t2 and not collision do
    B = A.neighbours[B_dir]
    C = A.neighbours[C_dir]
    
    -- which is the next tiles in the supercover?
    local y = m * i * w + b
    if y >= j * h and y <= (j + 1) * h then
      A = C
      i = i + inc_i
    else
      A = B
      j = j + inc_j
    end
    
    if not A then
      print("false")
      return false, cx, cy, n, tiles
    end
    if get_tiles then
      tiles[#tiles + 1] = A
    end
    
    if not A.walkable or (A.diagonal and not A.diagonal.walkable) then
      c, cx, cy, n = self:_get_intersection(m, b_original, 
                                                  x1-offx, y1-offy, 
                                                  x2-offx, y2-offy, quadrant, A)
      if c then break end
    end
  end
  
  return c, cx, cy, n, tiles
end

------------------------------------------------------------------------------
function ray:update(dt)
end

------------------------------------------------------------------------------
function ray:draw()
  if not lk.isDown("l") then
    return
  end

  
  local alpha = 40
  local dec = 30
  lg.setColor(190, 255, 210, 200)
  lg.setPointSize(2)
  lg.setLineWidth(1)
  
  local line = self.line
  if not line then return end
  
  for i=1,#line-2,2 do
    lg.setColor(170, 255, 200, alpha)
    alpha = alpha - dec
    
    local x1, y1 = line[i], line[i+1]
    local x2, y2 = line[i+2], line[i+3]
    
    lg.line(x1, y1, x2, y2)
    
    lg.setColor(200, 255, 230, alpha + 30)
    lg.point(x2, y2)
  end
  
end

return ray













