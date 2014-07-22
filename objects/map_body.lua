
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- map_body object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local map_body = {}
map_body.table = MAP_BODY
map_body.debug = true
map_body.initialized = false
map_body.parent = nil
map_body.iscurrent = true
map_body.mpoints = nil
map_body.next_points = nil
map_body.reset_next_points = true

map_body.points = nil
map_body.level = level

-- init
map_body.initial_maps = nil
map_body.check_initial_maps_loaded = false

-- collision
map_body.collided = false
map_body.cnormal = nil
map_body.cpoint = nil
map_body.c_mpoint = nil

-- vectors
map_body.avg_point = nil
map_body.origin = nil
map_body.old_origin = nil
map_body.temp_vect = nil
map_body.temp_vect2 = nil

map_body.current_rotation = 0

local map_body_mt = { __index = map_body }
function map_body:new(level, points, manual_initialization)
  local mbody = setmetatable({}, map_body_mt)
  local self = mbody
  mbody.points = points
  mbody.level = level
  
  mbody.avg_point = vector2:new(0, 0)
  mbody.origin = vector2:new(0, 0)
  mbody.old_origin = vector2:new(0, 0)
  mbody.temp_vect = vector2:new(0, 0)
  mbody.temp_vect2 = vector2:new(0, 0)
  mbody.next_points = {}
  
  if manual_initialization then
    return mbody
  end
  
  -- check if all maps loaded
  local loaded = true
  local level_map = level:get_level_map()
  local initial_tmaps = {}
  local tmap = level_map:get_tile_map_at_position(points[1])
  initial_tmaps[1] = tmap
  for i=2,#points do
    local p = points[i]
    local tmap = level_map:get_tile_map_at_position(p, tmap)
    initial_tmaps[i] = tmap
    
    if not tmap:is_loaded() then
      loaded = false
    end
  end
  if not tmap:is_loaded() then
    loaded = false
  end
  
  if not loaded then
    for i=1,#initial_tmaps do
      initial_tmaps[i]:add_to_init_queue(mbody)
    end
    
    self.initial_maps = initial_tmaps
    self.check_initial_maps_loaded = true
    return mbody
  end
  
  mbody.init(mbody)
  
  return mbody
end

function map_body:set_body_points(points)
  if not self.points then
    self.points = points
    return
  end
  
  -- expand or shrink existing points
  local old_points = self.points
  if #points > #old_points then
    local n = #points - #old_points
    for i = 1,n do
      old_points[#old_points + 1] = vector2:new(0, 0)
    end
  elseif #points < #old_points then
    local n = #old_points - #points
    for i=#old_points, #old_points - n + 1,-1 do
      old_points[i] = nil
    end
  end
  
  -- set values
  for i=1,#points do
    old_points[i]:clone(points[i])
  end
end

function map_body:init()
  if self.initialized then
    self:_re_initialize()
    return
  end

  if self.check_initial_maps_loaded then
    local init_maps = self.initial_maps
    for i=1,#init_maps do
      if not init_maps[i]:is_loaded() then
        return
      end
    end
  end

  -- create map points from table of points (vector2's)
	local avg_point = self.avg_point
	avg_point:set(0, 0)
	local points = self.points
	local level = self.level
	local mpoints = {}
	local next_points = self.next_points
	for i=1,#points do
		local p = points[i]
		local np = vector2:new(p.x, p.y)
		local mpoint = map_point:new(level, p)
		mpoints[i] = mpoint
		next_points[i] = np
		
		avg_point.x = avg_point.x + p.x
		avg_point.y = avg_point.y + p.y
	end
	
	local origin = self.origin
	origin:set(avg_point.x / #points, avg_point.y / #points)
  self.old_origin:clone(origin)
	self.mpoints = mpoints
	
	self.initialized = true
end

function map_body:_re_initialize_next_points(points)
  -- expand or shrink existing points
  local old_points = self.next_points
  if #points > #old_points then
    local n = #points - #old_points
    for i = 1,n do
      old_points[#old_points + 1] = vector2:new(0, 0)
    end
  elseif #points < #old_points then
    local n = #old_points - #points
    for i=#old_points, #old_points - n + 1,-1 do
      old_points[i] = nil
    end
  end
  
  -- set values
  for i=1,#points do
    old_points[i]:clone(points[i])
  end
end

function map_body:_re_initialize_map_points(points)
  local map_points = self.mpoints
  
  -- shrink array if needed
  if #map_points > #points then
    local n = #map_points - #points
    for i=#map_points,#map_points - n + 1 do
      map_points[i] = nil
    end
  end
  
  for i=1,#points do
    local p = points[i]
    local mpoint = map_points[i]
    if mpoint then
      mpoint:update_position(p)
    else
      local mpoint = map_point:new(self.level, p)
      map_points[i] = mpoint
    end
  end
  
end

function map_body:_re_initialize()
	local points = self.points
	local level = self.level
	
	self:_re_initialize_next_points(points)
	self:_re_initialize_map_points(points)
  
	-- find avg point
	local avg_point = self.avg_point
	avg_point:set(0, 0)
	for i=1,#points do
	  local p = points[i]
	  avg_point.x = avg_point.x + p.x
		avg_point.y = avg_point.y + p.y
	end
	local origin = self.origin
	origin:set(avg_point.x / #points, avg_point.y / #points)
	self.old_origin:clone(origin)
	
	-- reset variables
	self.iscurrent = true
	self.reset_next_points = false
	self.check_initial_maps_loaded = false
	self.collided = false
end

function map_body:set_parent(parent)
	self.parent = parent
end

function map_body:set_origin(pos)
	self.origin:clone(pos)
end

function map_body:set_rotation(rot)
  self:rotate(rot - self.current_rotation)
end

function map_body:rotate(rot)
  local sin, cos = math.sin, math.cos
  self.current_rotation = self.current_rotation + rot
  
  local points = self.next_points
  local cx, cy = self.origin.x, self.origin.y
  
  for i=1,#points do
    local p = points[i]
    local x, y = p.x - cx, p.y - cy
    p.x = (x * cos(rot) - y * sin(rot)) + cx
    p.y = (x * sin(rot) + y * cos(rot)) + cy
  end
  
  self.iscurrent = false
end

function map_body:translate(offset)
	if self.iscurrent then
		self.old_origin:clone(self.origin)
	end

	local next_points = self.next_points
	local mpoints = self.mpoints
	
	if self.reset_next_points then
	  for i=1,#mpoints do
	    local mpos = mpoints[i]:get_position()
	    next_points[i].x = mpos.x + offset.x
	    next_points[i].y = mpos.y + offset.y
		end
	  self.reset_next_points = false
	else
    for i=1,#next_points do
      next_points[i].x = next_points[i].x + offset.x
      next_points[i].y = next_points[i].y + offset.y
    end
  end

	self.origin:set(self.origin.x + offset.x, self.origin.y + offset.y)
	self.iscurrent = false
end

function map_body:set_position(new_pos)
  local offset = self.temp_vect
	offset.x = new_pos.x - self.origin.x
	offset.y = new_pos.y - self.origin.y
	self:translate(offset)
end
function map_body:get_position()
	return self.origin
end

function map_body:update_position(new_pos)
	local old_origin = self.old_origin
  
	local offset = self.temp_vect
	offset.x = new_pos.x - self.origin.x
	offset.y = new_pos.y - self.origin.y
	
	local mpoints = self.mpoints
	local is_colliding = false
	for i=1,#mpoints do
		local m = mpoints[i]
		local mpos = m:get_position()
		local new = self.temp_vect2
		new.x = mpos.x + offset.x
		new.y = mpos.y + offset.y
		m:update_position(new)
		
		local tile = m:get_tile()
		if not tile.walkable then
			is_colliding = true
		end
	end
	
	self.origin:clone(new_pos)
	
	-- move to old position if new position results in collision
	-- this can happen when more then one map point is colliding at the same time
	if is_colliding then
	  local offset = self.temp_vect
    offset.x = old_origin.x - self.origin.x
    offset.y = old_origin.y - self.origin.y
		for i=1,#mpoints do
			local m = mpoints[i]
			local mpos = m:get_position()
      local new = self.temp_vect2
      new.x = mpos.x + offset.x
      new.y = mpos.y + offset.y
			mpoints[i]:update_position(new)
		end
		
		self.origin:clone(old_origin)
	end
	
	return not is_colliding, self.origin
end

function map_body:get_collision_data()
	if self.collided then
		return true, self.cnormal, self.cpoint, self.coffset, self.ctiles
	else
		return false
	end
end

-- true if all tiles walkable, false otherwise
function map_body:check_tiles()
	local result = true
	local mpoints = self.mpoints
	for i=1,#mpoints do
		local tile = mpoints[i]:get_tile()
		if not tile.type.walkable then
			result = false
			break
		end
	end
	
	return result
end

------------------------------------------------------------------------------
function map_body:update(dt)
  if not self.initialized then
    return
  end

	if self.iscurrent then return end
	
	-- move mpoints to new positions
	self.collided = false
	local mpoints = self.mpoints
	local next_points = self.next_points
	self.ctiles = {}
	for i=1,#mpoints do
		mpoint = mpoints[i]
		mpoint:set_position(next_points[i])
		mpoint:update(dt)
		local c, n, p, poffset, tile = mpoint:get_collision_data()
		if c then
			self.collided = true
			self.cnormal = n
			self.cpoint = p
			self.c_mpoint = mpoint
			self.coffset = poffset
			
			if not tile.walkable then
				self.ctiles[#self.ctiles+1] = tile
			end
		end
	end
	
	self.reset_next_points = true
	self.iscurrent = true
end

------------------------------------------------------------------------------
function map_body:draw()
  if not self.initialized then
    return
  end

	if self.debug then
		-- draw points
		lg.setColor(0,255,0,255)
		lg.setPointSize(4)
		for i=1,#self.mpoints do
			local p = self.mpoints[i]
			local pos = p:get_position()
			lg.point(pos.x, pos.y)
		end
		
		-- origin
		lg.setColor(255, 0, 0, 255)
		lg.point(self.origin.x, self.origin.y)
		
	end
	
end

return map_body























