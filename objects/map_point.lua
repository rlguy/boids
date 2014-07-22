
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- map_point object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local map_point = {}
map_point.table = MAP_POINT
map_point.debug = false
map_point.initialized = false

map_point.pos = nil
map_point.next_pos = nil
map_point.map = nil
map_point.is_current = false
map_point.tile = nil              -- tile that point is on
map_point.tile_offset = nil       -- pixel offset from top left corner of tile
map_point.neighbours = nil        -- tiles surrounding tile that point is on
map_point.open_tiles = nil
map_point.open_tiles_table = nil

-- temporary vectors
map_point.temp_vector = nil
map_point.collision_point = nil
map_point.collision_offset = nil
map_point.temp_tile_offset = nil

-- collision data
map_point.collided = false
map_point.cpoint = nil            -- point of collision
map_point.cnormal = nil           -- normal of surface of colission
map_point.coffset = nil           -- offset to the point of colission
map_point.ctile = nil             -- tile collided with
map_point.on_diagonal = nil
map_point.diagonal_case = nil

-- used by collider`
map_point.cdata = nil

-- tile map
map_point.level = nil
map_point.level_map = nil
map_point.current_tile_map = nil

-- line intersection cases
-- Each function returns (x interection, y intersection, normal vector) of
-- surface intersected with line y = m*x + b
local map_lines = {}
local lines = map_lines
local w, h = TILE_WIDTH, TILE_HEIGHT
local NORMAL = NORMAL
lines[1]  = function(m, b) return -b / m, 0, NORMAL[DOWN] end
lines[2]  = function(m, b) return w, m * w + b, NORMAL[LEFT] end
lines[3]  = function(m, b) return (h - b) / m, h, NORMAL[UP] end
lines[4]  = function(m, b) return 0, b, NORMAL[RIGHT] end
lines[5]  = function(m, b) return w, m * w + b, NORMAL[LEFT] end
lines[6]  = function(m, b) return -b / m, 0, NORMAL[DOWN] end
lines[7]  = function(m, b) return (h - b) / m, h, NORMAL[UP] end
lines[8]  = function(m, b) return w, m * w + b, NORMAL[LEFT] end
lines[9]  = function(m, b) return 0, b, NORMAL[RIGHT] end
lines[10] = function(m, b) return (h - b) / m, h, NORMAL[UP] end
lines[11] = function(m, b) return -b / m, 0, NORMAL[DOWN] end
lines[12] = function(m, b) return 0, b, NORMAL[RIGHT] end
lines[13] = function(m, b)
              local x = (1 / (m - 1)) * (-2 * h - b)
              return x, x - 2 * h, NORMAL[DOWNLEFT] 
            end
lines[14] = function(m, b)
              local x = (1 / (m + 1)) * (3 * h - b)
              return x, -x + 3 * h, NORMAL[UPLEFT] 
            end
lines[15] = function(m, b)
              local x = (1 / (m - 1)) * (2 * h - b)
              return x, x + 2 * h, NORMAL[UPRIGHT] 
            end
lines[16] = function(m, b)
              local x = (1 / (m + 1)) * (-h - b)
              return x, -x - h, NORMAL[DOWNRIGHT] 
            end
lines[17] = function(m, b)
              local x = (1 / (m + 1)) * (2 * h - b)
              return x, -x + 2 * h, NORMAL[UPLEFT] 
            end
lines[18] = function(m, b)
              local x = (1 / (m - 1)) * (-h - b)
              return x, x - h, NORMAL[DOWNLEFT] 
            end
lines[19] = function(m, b)
              local x = (1 / (m - 1)) * (h - b)
              return x, x + h, NORMAL[UPRIGHT] 
            end
lines[20] = function(m, b)
              local x = (1 / (m + 1)) * (2 * h - b)
              return x, -x + 2 * h, NORMAL[UPLEFT] 
            end
lines[21] = function(m, b)
              local x = (1 / (m + 1)) * (-b)
              return x, -x, NORMAL[DOWNRIGHT] 
            end
lines[22] = function(m, b)
              local x = (1 / (m - 1)) * (h - b)
              return x, x + h, NORMAL[UPRIGHT] 
            end
lines[23] = function(m, b)
              local x = (1 / (m - 1)) * (-h - b)
              return x, x - h, NORMAL[DOWNLEFT] 
            end
lines[24] = function(m, b)
              local x = (1 / (m + 1)) * (-b)
              return x, -x, NORMAL[DOWNRIGHT] 
            end
            
-- To check if point is "inside" a diagonal based on line segment case
local inside_map_lines = {}
local lines = inside_map_lines
lines[13] = function(x, y) return y < x - 2 * h end
lines[14] = function(x, y) return y > -x + 3 * h end
lines[15] = function(x, y) return y > x + 2 * h end
lines[16] = function(x, y) return y < -x - h end
lines[17] = function(x, y) return y > -x + 2 * h end
lines[18] = function(x, y) return y < x - h end
lines[19] = function(x, y) return y > x + h end
lines[20] = function(x, y) return y > -x + 2 * h end
lines[21] = function(x, y) return y < -x end
lines[22] = function(x, y) return y > x + h end
lines[23] = function(x, y) return y < x - h end
lines[24] = function(x, y) return y < -x end

-- functions to solve tile collision cases
local collision_cases = {}
local cc = collision_cases
cc[1] = function(m, b, x2, y2, t_old, t_new)
          local tile = t_new
          local cx, cy, normal
          
          -- diagonal tile cases
          if tile.diagonal then
            local dir = tile.diagonal.direction
            if dir == UPRIGHT or dir == UPLEFT then
              cx, cy, normal = map_lines[1](m, b)
            elseif dir == DOWNRIGHT and inside_map_lines[24](x2, y2) then
              cx, cy, normal = map_lines[24](m, b)
            elseif dir == DOWNLEFT and inside_map_lines[23](x2, y2) then
              cx, cy, normal = map_lines[23](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- solid tile case
          if not tile.walkable then
            cx, cy, normal = map_lines[1](m, b)
            return true, cx, cy, normal
          end
          
          return false
        end
        
cc[4] = function(m, b, x2, y2, t_old, t_new)
          local tile = t_new
          local cx, cy, normal
          
          -- diagonal tile cases
          if tile.diagonal then
            local dir = tile.diagonal.direction
            if dir == UPRIGHT or dir == DOWNRIGHT then
              cx, cy, normal = map_lines[2](m, b)
            elseif dir == DOWNLEFT and inside_map_lines[18](x2, y2) then
              cx, cy, normal = map_lines[18](m, b)
            elseif dir == UPLEFT and inside_map_lines[17](x2, y2) then
              cx, cy, normal = map_lines[17](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- solid tile case
          if not tile.walkable then
            cx, cy, normal = map_lines[2](m, b)
            return true, cx, cy, normal
          end
          
          return false
        end
        
cc[7] = function(m, b, x2, y2, t_old, t_new)
          local tile = t_new
          local cx, cy, normal
          
          -- diagonal tile cases
          if tile.diagonal then
            local dir = tile.diagonal.direction
            if dir == DOWNRIGHT or dir == DOWNLEFT then
              cx, cy, normal = map_lines[3](m, b)
            elseif dir == UPRIGHT and inside_map_lines[19](x2, y2) then
              cx, cy, normal = map_lines[19](m, b)
            elseif dir == UPLEFT and inside_map_lines[20](x2, y2) then
              cx, cy, normal = map_lines[20](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- solid tile case
          if not tile.walkable then
            cx, cy, normal = map_lines[3](m, b)
            return true, cx, cy, normal
          end
          
          return false
        end
        
cc[10] = function(m, b, x2, y2, t_old, t_new)
          local tile = t_new
          local cx, cy, normal
          
          -- diagonal tile cases
          if tile.diagonal then
            local dir = tile.diagonal.direction
            if dir == UPLEFT or dir == DOWNLEFT then
              cx, cy, normal = map_lines[4](m, b)
            elseif dir == UPRIGHT and inside_map_lines[22](x2, y2) then
              cx, cy, normal = map_lines[22](m, b)
            elseif dir == DOWNRIGHT and inside_map_lines[21](x2, y2) then
              cx, cy, normal = map_lines[21](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- solid tile case
          if not tile.walkable then
            cx, cy, normal = map_lines[4](m, b)
            return true, cx, cy, normal
          end
          
          return false
        end

cc[2] = function(m, b, x2, y2, t_old, t_new)
          local t1 = t_old.neighbours[UP]
          local t2 = t_new
          local empty1 = not t1.diagonal and t1.walkable
          local empty2 = not t2.diagonal and t2.walkable
          local diag1 = t1.diagonal or false
          local diag2 = t2.diagonal or false
          local dir1, dir2
          if diag1 then dir1 = t1.diagonal.direction end
          if diag2 then dir2 = t2.diagonal.direction end
          local solid1 = (not diag1 and not t1.walkable)
          local solid2 = (not diag2 and not t2.walkable)
          local cx, cy, normal
          
          -- cases where first tile is bypassed
          if empty1 or (diag1 and dir1 == DOWNRIGHT) then
            if solid2 or dir2 == UPRIGHT or dir2 == DOWNRIGHT then
              cx, cy, normal = map_lines[5](m, b)
            elseif dir2 == DOWNLEFT and inside_map_lines[13](x2, y2) then
              cx, cy, normal = map_lines[13](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- cases where first tile is hit
          if solid1 or dir1 == UPRIGHT or dir1 == UPLEFT then
            cx, cy, normal = map_lines[1](m, b)
          elseif dir1 == DOWNLEFT and inside_map_lines[23](x2, y2) then
            cx, cy, normal = map_lines[23](m, b)
          end
          
          if cx then
            return true, cx, cy, normal
          end
            
          return false
        end
        
cc[3] = function(m, b, x2, y2, t_old, t_new)
          local t1 = t_old.neighbours[RIGHT]
          local t2 = t_new
          local empty1 = not t1.diagonal and t1.walkable
          local empty2 = not t2.diagonal and t2.walkable
          local diag1 = t1.diagonal or false
          local diag2 = t2.diagonal or false
          local dir1, dir2
          if diag1 then dir1 = t1.diagonal.direction end
          if diag2 then dir2 = t2.diagonal.direction end
          local solid1 = (not diag1 and not t1.walkable)
          local solid2 = (not diag2 and not t2.walkable)
          local cx, cy, normal
          
          -- cases where first tile is bypassed
          if empty1 or (diag1 and dir1 == UPLEFT) then
            if solid2 or dir2 == UPRIGHT or dir2 == UPLEFT then
              cx, cy, normal = map_lines[6](m, b)
            elseif dir2 == DOWNLEFT and inside_map_lines[13](x2, y2) then
              cx, cy, normal = map_lines[13](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- cases where first tile is hit
          if solid1 or dir1 == UPRIGHT or dir1 == DOWNRIGHT then
            cx, cy, normal = map_lines[2](m, b)
          elseif dir1 == DOWNLEFT and inside_map_lines[18](x2, y2) then
            cx, cy, normal = map_lines[18](m, b)
          end
          
          if cx then
            return true, cx, cy, normal
          end
            
          return false
        end
        
cc[5] = function(m, b, x2, y2, t_old, t_new)
          local t1 = t_old.neighbours[RIGHT]
          local t2 = t_new
          local empty1 = not t1.diagonal and t1.walkable
          local empty2 = not t2.diagonal and t2.walkable
          local diag1 = t1.diagonal or false
          local diag2 = t2.diagonal or false
          local dir1, dir2
          if diag1 then dir1 = t1.diagonal.direction end
          if diag2 then dir2 = t2.diagonal.direction end
          local solid1 = (not diag1 and not t1.walkable)
          local solid2 = (not diag2 and not t2.walkable)
          local cx, cy, normal
          
          -- cases where first tile is bypassed
          if empty1 or (diag1 and dir1 == DOWNLEFT) then
            if solid2 or dir2 == DOWNRIGHT or dir2 == DOWNLEFT then
              cx, cy, normal = map_lines[7](m, b)
            elseif dir2 == UPLEFT and inside_map_lines[14](x2, y2) then
              cx, cy, normal = map_lines[14](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- cases where first tile is hit
          if solid1 or dir1 == UPRIGHT or dir1 == DOWNRIGHT then
            cx, cy, normal = map_lines[2](m, b)
          elseif dir1 == UPLEFT and inside_map_lines[17](x2, y2) then
            cx, cy, normal = map_lines[17](m, b)
          end
          
          if cx then
            return true, cx, cy, normal
          end
            
          return false
        end
        
cc[6] = function(m, b, x2, y2, t_old, t_new)
          local t1 = t_old.neighbours[DOWN]
          local t2 = t_new
          local empty1 = not t1.diagonal and t1.walkable
          local empty2 = not t2.diagonal and t2.walkable
          local diag1 = t1.diagonal or false
          local diag2 = t2.diagonal or false
          local dir1, dir2
          if diag1 then dir1 = t1.diagonal.direction end
          if diag2 then dir2 = t2.diagonal.direction end
          local solid1 = (not diag1 and not t1.walkable)
          local solid2 = (not diag2 and not t2.walkable)
          local cx, cy, normal
          
          -- cases where first tile is bypassed
          if empty1 or (diag1 and dir1 == UPRIGHT) then
            if solid2 or dir2 == UPRIGHT or dir2 == DOWNRIGHT then
              cx, cy, normal = map_lines[8](m, b)
            elseif dir2 == UPLEFT and inside_map_lines[14](x2, y2) then
              cx, cy, normal = map_lines[14](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- cases where first tile is hit
          if solid1 or dir1 == DOWNRIGHT or dir1 == DOWNLEFT then
            cx, cy, normal = map_lines[3](m, b)
          elseif dir1 == UPLEFT and inside_map_lines[20](x2, y2) then
            cx, cy, normal = map_lines[20](m, b)
          end
          
          if cx then
            return true, cx, cy, normal
          end
            
          return false
        end
        
cc[8] = function(m, b, x2, y2, t_old, t_new)
          local t1 = t_old.neighbours[DOWN]
          local t2 = t_new
          local empty1 = not t1.diagonal and t1.walkable
          local empty2 = not t2.diagonal and t2.walkable
          local diag1 = t1.diagonal or false
          local diag2 = t2.diagonal or false
          local dir1, dir2
          if diag1 then dir1 = t1.diagonal.direction end
          if diag2 then dir2 = t2.diagonal.direction end
          local solid1 = (not diag1 and not t1.walkable)
          local solid2 = (not diag2 and not t2.walkable)
          local cx, cy, normal
          
          -- cases where first tile is bypassed
          if empty1 or (diag1 and dir1 == UPLEFT) then
            if solid2 or dir2 == DOWNLEFT or dir2 == UPLEFT then
              cx, cy, normal = map_lines[9](m, b)
            elseif dir2 == UPRIGHT and inside_map_lines[15](x2, y2) then
              cx, cy, normal = map_lines[15](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- cases where first tile is hit
          if solid1 or dir1 == DOWNRIGHT or dir1 == DOWNLEFT then
            cx, cy, normal = map_lines[3](m, b)
          elseif dir1 == UPRIGHT and inside_map_lines[19](x2, y2) then
            cx, cy, normal = map_lines[19](m, b)
          end
          
          if cx then
            return true, cx, cy, normal
          end
            
          return false
        end

cc[9] = function(m, b, x2, y2, t_old, t_new)
          local t1 = t_old.neighbours[LEFT]
          local t2 = t_new
          local empty1 = not t1.diagonal and t1.walkable
          local empty2 = not t2.diagonal and t2.walkable
          local diag1 = t1.diagonal or false
          local diag2 = t2.diagonal or false
          local dir1, dir2
          if diag1 then dir1 = t1.diagonal.direction end
          if diag2 then dir2 = t2.diagonal.direction end
          local solid1 = (not diag1 and not t1.walkable)
          local solid2 = (not diag2 and not t2.walkable)
          local cx, cy, normal
          
          -- cases where first tile is bypassed
          if empty1 or (diag1 and dir1 == DOWNRIGHT) then
            if solid2 or dir2 == DOWNRIGHT or dir2 == DOWNLEFT then
              cx, cy, normal = map_lines[10](m, b)
            elseif dir2 == UPRIGHT and inside_map_lines[15](x2, y2) then
              cx, cy, normal = map_lines[15](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- cases where first tile is hit
          if solid1 or dir1 == DOWNLEFT or dir1 == UPLEFT then
            cx, cy, normal = map_lines[4](m, b)
          elseif dir1 == UPRIGHT and inside_map_lines[22](x2, y2) then
            cx, cy, normal = map_lines[22](m, b)
          end
          
          if cx then
            return true, cx, cy, normal
          end
            
          return false
        end
        
cc[11] = function(m, b, x2, y2, t_old, t_new)
          local t1 = t_old.neighbours[LEFT]
          local t2 = t_new
          local empty1 = not t1.diagonal and t1.walkable
          local empty2 = not t2.diagonal and t2.walkable
          local diag1 = t1.diagonal or false
          local diag2 = t2.diagonal or false
          local dir1, dir2
          if diag1 then dir1 = t1.diagonal.direction end
          if diag2 then dir2 = t2.diagonal.direction end
          local solid1 = (not diag1 and not t1.walkable)
          local solid2 = (not diag2 and not t2.walkable)
          local cx, cy, normal
          
          -- cases where first tile is bypassed
          if empty1 or (diag1 and dir1 == UPRIGHT) then
            if solid2 or dir2 == UPRIGHT or dir2 == UPLEFT then
              cx, cy, normal = map_lines[11](m, b)
            elseif dir2 == DOWNRIGHT and inside_map_lines[16](x2, y2) then
              cx, cy, normal = map_lines[16](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- cases where first tile is hit
          if solid1 or dir1 == DOWNLEFT or dir1 == UPLEFT then
            cx, cy, normal = map_lines[4](m, b)
          elseif dir1 == DOWNRIGHT and inside_map_lines[21](x2, y2) then
            cx, cy, normal = map_lines[21](m, b)
          end
          
          if cx then
            return true, cx, cy, normal
          end
            
          return false
        end
        
cc[12] = function(m, b, x2, y2, t_old, t_new)
          local t1 = t_old.neighbours[UP]
          local t2 = t_new
          local empty1 = not t1.diagonal and t1.walkable
          local empty2 = not t2.diagonal and t2.walkable
          local diag1 = t1.diagonal or false
          local diag2 = t2.diagonal or false
          local dir1, dir2
          if diag1 then dir1 = t1.diagonal.direction end
          if diag2 then dir2 = t2.diagonal.direction end
          local solid1 = (not diag1 and not t1.walkable)
          local solid2 = (not diag2 and not t2.walkable)
          local cx, cy, normal
          
          -- cases where first tile is bypassed
          if empty1 or (diag1 and dir1 == DOWNLEFT) then
            if solid2 or dir2 == DOWNLEFT or dir2 == UPLEFT then
              cx, cy, normal = map_lines[12](m, b)
            elseif dir2 == DOWNRIGHT and inside_map_lines[16](x2, y2) then
              cx, cy, normal = map_lines[16](m, b)
            end
            
            if cx then
              return true, cx, cy, normal
            end
            
            return false
          end
          
          -- cases where first tile is hit
          if solid1 or dir1 == UPRIGHT or dir1 == UPLEFT then
            cx, cy, normal = map_lines[1](m, b)
          elseif dir1 == DOWNRIGHT and inside_map_lines[24](x2, y2) then
            cx, cy, normal = map_lines[24](m, b)
          end
          
          if cx then
            return true, cx, cy, normal
          end
            
          return false
        end
        
local map_point_mt = { __index = map_point }
function map_point:new(level, pos)
  local mpoint = setmetatable({}, map_point_mt)
  
  local level_map = level:get_level_map()
  local tile_map = level_map:get_tile_map_at_position(pos)
  
  mpoint.current_tile_map = tile_map
  mpoint.level_map = level_map
  mpoint.pos = vector2:new(pos.x, pos.y)
  mpoint.next_pos = vector2:new(0, 0)
  mpoint.tile_width = tile_map.tile_width
  mpoint.tile_height = tile_map.tile_height
  mpoint.tile_offset = vector2:new(0, 0)
  mpoint.temp_vector = vector2:new(0, 0)
  mpoint.collision_point = vector2:new(0, 0)
  mpoint.collision_offset = vector2:new(0, 0)
  mpoint.temp_tile_offset = vector2:new(0, 0)
  mpoint.open_tiles_table = {}
  
  if not tile_map:is_loaded() then
    tile_map:add_to_init_queue(mpoint)
    return mpoint
  end
  
  mpoint.init(mpoint)
	
	return mpoint
end

function map_point:init()
  local tmap = self.current_tile_map
  local level_map = self.level_map
  local pos = self.pos
  self.next_pos:clone(pos)

  self.tile = tmap:get_tile_at_position(pos)
  self.tile_offset:set(pos.x % self.tile_width, pos.y % self.tile_height)
  self.neighbours = self.tile.neighbours
  self.open_tiles = self:_get_open_tiles(self.tile)
  
  self.initialized = true
end

------------------------------------------------------------------------------
function map_point:update(dt)
  if not self.initialized then
    return
  end

	if self.is_current then return end
	
	-- calculate new offset from next_pos
	local temp = self.temp_vector
	local next_pos = self.next_pos
	temp.x, temp.y = next_pos.x - self.pos.x, next_pos.y - self.pos.y
	local offset = self.tile_offset
	offset.x = offset.x + temp.x
	offset.y = offset.y + temp.y
	
	-- check if offset moves point to another tile
	-- if id does, then we need to check for collision
	self.collided = false
	local change_tile = offset.x >= TILE_WIDTH or offset.y >= TILE_HEIGHT or
	                    offset.x < 0 or offset.y < 0
	                   
	if change_tile then
		local old_tile = self.tile
		local new_tile = self:_get_tile(next_pos)

		local c, n, p, off = self:_check_collision(old_tile, new_tile, self.pos, next_pos)
		if c then
			self.collided = true
			self.cnormal = n
			self.cpoint = p
			self.coffset = off
			self.ctile = new_tile
		else
			self.collided = false
		end
		
		self.tile = new_tile
		offset = self:_get_tile_offset(next_pos)
		self.neighbours = self.tile.neighbours
		self.open_tiles = self:_get_open_tiles(self.tile)
	end
	
	if not change_tile and self.on_diagonal then
	  local c, n, p, off = self:_check_diagonal_collision(self.pos, next_pos)
	  if c then
	    self.collided = true
	    self.cnormal = n
			self.cpoint = p
			self.coffset = off
			self.ctile = self.tile
	  else
	    self.collided = false
	  end
	end
	
	self.tile_offset = offset
	self.pos:clone(next_pos)
	self.is_current = true
	
end

------------------------------------------------------------------------------
function map_point:draw()
  if not self.initialized then
    return
  end

	if self.debug then
		lg.setColor(C_RED)
		lg.setPointSize(4)
		lg.point(self.pos.x, self.pos.y)
		
		local tile = self.tile
		if tile then
			-- occupied tile
			lg.setColor(0, 255, 0, 40)
			--lg.rectangle('fill', tile.x, tile.y, self.tile_width, self.tile_height)
			
			-- neighbours
			local open = self.open_tiles
			for i=1,8 do
				local tile = self.neighbours[i]
				if tile then
				  if open[i] then
				  	lg.setColor(0, 255, 0, 0)
				  else
				  	lg.setColor(255, 0, 0, 40)
				  end
				  lg.rectangle('fill', tile.x, tile.y, TILE_WIDTH, TILE_HEIGHT)
				  
				end
			end
			
		end
		
		-- draw collision
		if self.cpoint then
			local p = self.cpoint
			local n = self.cnormal
			local len = 20
			local e = p + len * n
			
			lg.setColor(0, 255, 0, 255)
			lg.setPointSize(3)
			lg.setLineWidth(2)
			lg.point(p.x, p.y)
			lg.line(p.x, p.y, e.x, e.y)
		end
		
	end
	
end


function map_point:_check_collision(t_old, t_new, p_old, p_new)
  -- find which neighbour new tile is in relation to old tile
	local n = nil
	for i=1,8 do
		if t_new == t_old.neighbours[i] then
			n = i
			break
		end
	end
	
	-- can the player get to that tile?
	local open = self.open_tiles
	if open[n] then
	  if t_new.diagonal and not t_new.diagonal.walkable then
      self.on_diagonal = true
      self.diagonal_case = t_new.diagonal.direction
    else
      self.on_diagonal = false
    end
		return false
	end
	if not n then
		print('error in map_point ', self)
		return false
	end
	
	--offset points so that top left corner of t_old is origin
	local xoff, yoff = -t_old.x, -t_old.y
	local x1, y1 = p_old.x + xoff, p_old.y + yoff
	local x2, y2 = p_new.x + xoff, p_new.y + yoff
	if x1 == x2 then
	  x2 = x2 + EPSILON
	end
	
	-- find equation of line
	local m, b
	if x2 > x1 then
	  m = (y2 - y1) / (x2 - x1)
	  b = y1 - m * x1
	else
	  m = (y1 - y2) / (x1 - x2)
	  b = y2 - m * x2
	end
	
	-- find tile transition case
	local case
	local w, h = TILE_WIDTH, TILE_HEIGHT
	local collided, cx, cy, normal
	if n % 2 == 0 then                    -- diagonal cases
	  if     n == UPRIGHT then
	    local ix, iy = map_lines[1](m, b)
	    if ix > 0 and ix <= w then
	      case = 2
	    else
	      case = 3
	    end
	  elseif n == DOWNRIGHT then
	    local ix, iy = map_lines[3](m, b)
	    if ix > 0 and ix <= w then
	      case = 6
	    else
	      case = 5
	    end
	  elseif n == DOWNLEFT then
	    local ix, iy = map_lines[3](m, b)
	    if ix > 0 and ix <= w then
	      case = 8
	    else
	      case = 9
	    end
	  elseif n == UPLEFT then
	    local ix, iy = map_lines[1](m, b)
	    if ix > 0 and ix <= w then
	      case = 12
	    else
	      case = 11
	    end
	  end
	else               -- up/down/left/right cases
	  if     n == UP then
	    case = 1
	  elseif n == RIGHT then
	    case = 4
	  elseif n == DOWN then
	    case = 7
	  elseif n == LEFT then
	    case = 10
	  end
	end
	collided, cx, cy, normal = collision_cases[case](m, b, x2, y2, t_old, t_new)
	
	if collided then
	  self.collided = true
	  
	  -- calc point of collision. Move point off of collision line
	  local cx = cx - xoff + 0.1 * normal.x
	  local cy = cy - yoff + 0.1 * normal.y
	  local cpoint = self.collision_point
	  cpoint:set(cx, cy)
	  
	  -- get tile point collided with
	  local tile = self:_get_tile(cpoint)
    if not tile or not tile.walkable then
      cpoint = p_old
      tile = t_old
    end
    
    -- check if on a diagonal tile so that update knows to check if
    -- point has moved insed diagonal boundary
    if tile.diagonal and not tile.diagonal.walkable then
      self.on_diagonal = true
      self.diagonal_case = tile.diagonal.direction
    else
      self.on_diagonal = false
    end
    
    -- calc offset from point position to collision point
    local offset = self.collision_offset
    offset:subtract(cpoint, p_new, offset) 
    return true, normal, cpoint, offset
    
	elseif t_new.walkable and t_new.diagonal and not t_new.diagonal.walkable then
    self.on_diagonal = true
    self.diagonal_case = t_new.diagonal.direction
    return false
	end
	
end

function map_point:_check_diagonal_collision(p_old, p_new)
  local tile = self.tile
  
  --offset points so that top left corner of t_old is origin
	local xoff, yoff = -tile.x, -tile.y
	local x1, y1 = p_old.x + xoff, p_old.y + yoff
	local x2, y2 = p_new.x + xoff, p_new.y + yoff
	if x1 == x2 then
	  x2 = x2 + EPSILON
	end
	
	-- find equation of line
	local m, b
	if x2 > x1 then
	  m = (y2 - y1) / (x2 - x1)
	  b = y1 - m * x1
	else
	  m = (y1 - y2) / (x1 - x2)
	  b = y2 - m * x2
	end
  
	local w, h = TILE_WIDTH, TILE_HEIGHT
  local case = self.diagonal_case
  local cx, cy, normal
  if     case == UPRIGHT then
    if y2 > x2 then
      if m - 1 == 0 then
        m = 0.00001
      end
      cx = -b / (m - 1)
      cy = cx
      normal = NORMAL[UPRIGHT]
    end
  elseif case == DOWNRIGHT then
    if y2 < -x2 + h then
      if m + 1 == 0 then
        m = 0.00001
      end
      cx = (h - b) / (m + 1)
      cy = -cx + h
      normal = NORMAL[DOWNRIGHT]
    end
  elseif case == DOWNLEFT then
    if y2 < x2 then
      if m - 1 == 0 then
        m = 0.00001
      end
      cx = -b / (m - 1)
      cy = cx
      normal = NORMAL[DOWNLEFT]
    end
  elseif case == UPLEFT then
    if y2 > -x2 + h then
      if m + 1 == 0 then
        m = 0.00001
      end
      cx = (h - b) / (m + 1)
      cy = -cx + h
      normal = NORMAL[UPLEFT]
    end
  end
  
  local cpoint
  local collided = false
  if cx and cy then
    collided = true
    self.collided = collided
    
    
    -- calc point of collision. Move point off of collision line
	  local cx = cx - xoff + 0.1 * normal.x
	  local cy = cy - yoff + 0.1 * normal.y
	  local cpoint = self.collision_point
	  cpoint:set(cx, cy)
    
	  -- get tile point collided with
    local tile = self:_get_tile(cpoint)
    if not tile or not tile.walkable then
      cpoint:clone(p_old)
      tile = self:_get_tile(p_old)
    end
    
    -- check if on a diagonal tile so that update knows to check if
    -- point has moved insed diagonal boundary
    if tile.diagonal and not tile.diagonal.walkable then
      self.on_diagonal = true
      self.diagonal_case = tile.diagonal.direction
    else
      self.on_diagonal = false
    end
    
    -- calc offset from point position to collision point
    local offset = self.collision_offset
    offset:subtract(cpoint, p_new, offset) 
    
    return collided, normal, cpoint, offset
  else
    if tile.walkable and tile.diagonal and not tile.diagonal.walkable then
	    self.on_diagonal = true
	    self.diagonal_case = tile.diagonal.direction
	    return collided
	  end
  end

end


------------------------------------------------------------------------------
-- returns tile under the point p
function map_point:_get_tile(p)
  local tmap = self.current_tile_map
  
  -- moved to new tile map
	if not tmap.bbox:contains_point(p) then
	  tmap = self.level_map:get_tile_map_at_position(p, tmap)
		self.current_tile_map = tmap
	end
	
	return tmap:get_tile_at_position(p)
end

------------------------------------------------------------------------------
function map_point:_get_tile_offset(p)
  local offset = self.temp_tile_offset
  offset:set(p.x % TILE_WIDTH, p.y % TILE_HEIGHT)
	return offset
end

------------------------------------------------------------------------------
-- returns table of booleans cooresponding to neighbour tiles player can move to
function map_point:_get_open_tiles(tile)
	local up, down, left, right = true, true, true, true
	local upleft, upright, downleft, downright = true, true, true, true
	local n = tile.neighbours
	
	if not n[UP].walkable or (n[UP].diagonal and not n[UP].diagonal.walkable) then
		upleft, up, upright = false, false, false
	end
	if not n[DOWN].walkable or (n[DOWN].diagonal and not n[DOWN].diagonal.walkable) then
		downleft, down, downright = false, false, false
	end
	if not n[LEFT].walkable or (n[LEFT].diagonal and not n[LEFT].diagonal.walkable) then
		upleft, left, downleft = false, false, false
	end
	if not n[RIGHT].walkable or (n[RIGHT].diagonal and not n[RIGHT].diagonal.walkable)then
		upright, right, downright = false, false, false
	end
	
	if not n[UPLEFT].walkable or (n[UPLEFT].diagonal and not n[UPLEFT].diagonal.walkable) then 
	  upleft = false 
	end
	if not n[UPRIGHT].walkable or (n[UPRIGHT].diagonal and not n[UPRIGHT].diagonal.walkable) then 
	  upright = false 
	end
	if not n[DOWNLEFT].walkable or (n[DOWNLEFT].diagonal and not n[DOWNLEFT].diagonal.walkable) then 
	  downleft = false 
	end
	if not n[DOWNRIGHT].walkable or (n[DOWNRIGHT].diagonal and not n[DOWNRIGHT].diagonal.walkable) then 
	  downright = false 
	end
	
	local open = self.open_tiles_table
	open[1], open[2], open[3], open[4] = up, upright, right, downright
	open[5], open[6], open[7], open[8] = down, downleft, left, upleft
	return open
end

------------------------------------------------------------------------------
function map_point:get_collision_data()
	if self.collided then
		return true, self.cnormal, self.cpoint, self.coffset, self.ctile
	else
		return false
	end
end

------------------------------------------------------------------------------
function map_point:get_x() return self.pos.x end
function map_point:get_y() return self.pos.y end
function map_point:get_position() return self.pos end
function map_point:get_tile()
	return self.tile
end

------------------------------------------------------------------------------
function map_point:set_position_coordinates(x, y, z)
  self.next_pos.x = x
  self.next_pos.y = y
  self.next_pos.z = z
  self.is_current = false
end

function map_point:set_position(pos)
	self.next_pos:clone(pos)
	self.is_current = false
end

function map_point:update_position(pos)
	self.pos:clone(pos)
	self.next_pos:clone(pos)
	self.tile = self:_get_tile(pos)
 if self.tile.diagonal and not self.tile.diagonal.walkable then
    self.on_diagonal = true
    self.diagonal_case = self.tile.diagonal.direction
  else
    self.on_diagonal = false
  end
	
	self.tile_offset = self:_get_tile_offset(pos)
	self.open_tiles = self:_get_open_tiles(self.tile)
	self.neighbours = self.tile.neighbours
	self.is_current = true
end

return map_point



