
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- boid_food_source object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local bfs = {}
bfs.table = 'bfs'
bfs.debug = false
bfs.level = nil
bfs.level_map = nil
bfs.flock = nil
bfs.sources = nil
bfs.depletion_rate = 300
bfs.surface_threshold = 0.5
bfs.area = 0
bfs.unit_area = TILE_WIDTH * TILE_HEIGHT
bfs.area_changed = false
bfs.boid_hash = nil
bfs.collision_table = nil
bfs.polygonizer_update_rate = 1.5   -- updates per second
bfs.min_radius = 50

local bfs_mt = { __index = bfs }
function bfs:new(level, flock)
  local bfs = setmetatable({}, bfs_mt)
  bfs.level = level
  bfs.level_map = level:get_level_map()
  bfs.flock = flock
  bfs.sources = {}
  bfs.boid_hash = {}
  bfs.collision_table = {}
  bfs.update_timer = timer:new(level:get_master_timer(), 1/bfs.polygonizer_update_rate)
  bfs.update_timer:start()
  
  return bfs
end

function bfs:add_food(x, y, radius)
  local p = self.level_map:add_point_to_source_polygonizer(x, y, radius)
  self.sources[#self.sources + 1] = self:_new_food_source(x, y, radius, p)
  
  self:_calculate_total_area()
end

function bfs:force_polygonizer_update()
  self.level_map:update_source_polygonizer()
end

function bfs:set_depletion_rate(r)
  self.depletion_rate = r
end

function bfs:set_update_rate(r)
  self.polygonizer_update_rate = r
end

function bfs:set_surface_threshold(thresh)
  self.surface_threshold = thresh
end

function bfs:_new_food_source(x, y, radius, primitive)
  local source = {}
  source.x, source.y = x, y
  source.radius = radius
  source.starting_radius = radius
  source.primitive = primitive
  
  return source
end

-- for fairness when attaching boids to a food source
function bfs:_shuffle_food_sources()
  for i=1,#self.sources do
    local r = math.random(1,#self.sources)
    self.sources[r], self.sources[i] = self.sources[i], self.sources[r]
  end
end

function bfs:_calculate_total_area()
  local pi = math.pi
  local area = 0
  for i=1,#self.sources do
    local r = self.sources[i].radius
    area = area + pi * r * r
  end
  
  local eps = 0.01
  local new_area = area / self.unit_area
  if math.abs(self.area - new_area) > eps then
    self.area = new_area
    self.area_changed = true
  end
end

function bfs:_update_area(dt)
  local sources = self.sources
  local bhash = self.boid_hash
  local objects = self.collision_table
  table.clear_hash(bhash)
  for i=#sources,1,-1 do
    local s = sources[i]
    local r = s.radius
    table.clear(objects)
    self.flock:get_boids_in_radius(s.x, s.y, r, objects)
    local count = 0
    for i=1,#objects do
      if not bhash[objects[i]] then
        count = count + 1
        bhash[objects[i]] = true
      end
    end
    
    local units_eaten = self.depletion_rate * count * dt
    if units_eaten > 0 then
      local new_area = math.pi * r * r - units_eaten
      new_radius = math.sqrt(new_area / math.pi)
      new_radius = math.max(new_radius, 0)
      s.radius = new_radius
      s.primitive:set_radius(new_radius)
      
      if new_radius< self.min_radius then
        self.level_map:remove_primitive_from_source_polygonizer(s.primitive)
        table.remove(self.sources, i)
      end
    end
  end
end

function bfs:_update_polygonizer()
  if self.update_timer:isfinished() then
    if self.area_changed then
      self:force_polygonizer_update()
      self.area_changed = false
      --print(math.random())
    end
    self.update_timer:set_length(1/self.polygonizer_update_rate)
    self.update_timer:start()
  end
end

------------------------------------------------------------------------------
function bfs:update(dt)
  self:_shuffle_food_sources()
  self:_update_area(dt)
  self:_calculate_total_area()
  self:_update_polygonizer()
end

------------------------------------------------------------------------------
function bfs:draw()
  if not self.debug then return end
  
  local sources = self.sources
  for i=1,#sources do
    local s = sources[i]
    lg.setColor(255, 0, 0, 255)
    lg.circle("line", s.x, s.y, s.radius)
    
    local sr = s.starting_radius
    local r = s.radius
    local pct = math.floor(((r * r) / (sr * sr)) * 100)
    lg.print(pct.."%", s.x, s.y)
  end
  
end

return bfs















