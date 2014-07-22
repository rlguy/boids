
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- point_trail object  - a trail of points behind a moving point
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local pt = {}
pt.table = 'pt'
pt.debug = true
pt.x = nil
pt.y = nil
pt.unused_path_points = nil
pt.path_points = nil
pt.temp_path_point = nil
pt.points = nil
pt.num_path_points = 5
pt.num_points = nil
pt.max_length = 100
pt.current_length = 0
pt.time_between_points = (1/60)
pt.time_accumulator = 0
pt.trail_curve = nil
pt.contraction_curve = nil

pt.min_contract_speed = 50
pt.max_contract_speed = 1000

local pt_mt = { __index = pt }
function pt:new(x, y, num_points)
  local pt = setmetatable({}, pt_mt)
  pt.x, pt.y = x, y
  pt.num_points = num_points
  
  pt:_init_points()
  
  return pt
end

function pt:set_trail_curve(curve)
  self.trail_curve = curve
end

function pt:set_contraction_curve(curve)
  self.contraction_curve = curve
end

function pt:set_length(len)
  self.max_length = len
end

function pt:set_contraction_speeds(min_speed, max_speed)
  self.min_contract_speed = min_speed
  self.max_contract_speed = max_speed
end

function pt:add_point(n)
  n = n or 1
  local points = self.points
  for i=1,n do
    table.insert(points, 1, self:_new_point(self.x, self.y))
  end
  
  self.num_points = self.num_points + n
end

function pt:get_points()
  return self.points
end

function pt:remove_point(n)
  n = n or 1
  
  if #self.points == 0 then
    return
  end
  if n > #self.points then
    n = #self.points
  end
  
  for i=1,n do
    self.points[#self.points] = nil
  end
  
  self.num_points = self.num_points - n
end

function pt:_init_points()
  -- path_points
  local x, y = self.x, self.y
  local n = self.num_path_points
  local unused = {}
  for i=1,n-1 do
    unused[i] = pt:_new_path_point()
  end
  
  self.unused_path_points = unused
  self.path_points = {pt:_new_path_point(self.x, self.y)}
  self.temp_path_point = pt:_new_path_point()
  
  -- points
  local n = self.num_points
  self.points = {}
  for i=1,n do
    self.points[i] = self:_new_point(self.x, self.y)
  end
end

function pt:_new_point(x, y, distance)
  local p = {}
  p.x = x or 0
  p.y = y or 0
  p.distance = distance or 0
  return p
end

function pt:_new_path_point(x, y, lenght)
  local p = {}
  p.x = x or 0
  p.y = y or 0
  p.length = length or 0
  return p
end

function pt:_reset_point(p)
  p.x = 0
  p.y = 0
  p.length = 0
end

function pt:set_position(x, y)
  self.x, self.y = x, y
end

function pt:_get_next_path_point_to_add()

  -- get next point to add
  local new_point
  if #self.unused_path_points > 0 then
    new_point = self.unused_path_points[#self.unused_path_points]
    self.unused_path_points[#self.unused_path_points] = nil
  else
    new_point = self:_new_path_point()
    self.num_path_points = self.num_path_points + 1
  end
  
  return new_point
end

function pt:_update_path(dt)
  local p1 = self.path_points[1]
  if p1.x == self.x and p1.y == self.y then
    return
  end

  local path = self.path_points
  local new_point = self:_get_next_path_point_to_add()
  
  -- add next point to head of path
  local head_x, head_y = path[1].x, path[1].y
  new_point.x = self.x
  new_point.y = self.y
  local dx, dy = head_x - self.x, head_y - self.y
  if dx == 0 and dy == 0 then
    new_point.length = 0
  else
    new_point.length = math.sqrt(dx*dx + dy*dy)
  end
  table.insert(path, 1, new_point)
  
  -- find path length
  local max = self.max_length
  local len = 0
  local last_idx
  for i=1,#path-1 do
    len = len + path[i].length
    if len > max then
      last_idx = i + 1
      break
    end
  end
  self.current_length = len
  
  -- trim path
  if last_idx then
    self.current_length = max
    
    local diff = len - max
    local p1 = path[last_idx - 1]
    local p2 = path[last_idx]
    
    if p1 and p1.length > 0 then
      local r = (p1.length - diff) / p1.length
      local dx = (p2.x - p1.x) * r
      local dy = (p2.y - p1.y) * r
      p2.x, p2.y = p1.x + dx, p1.y + dy
    end
    
    local unused = self.unused_path_points
    for i=#path,last_idx+1,-1 do
      local p = path[i]
      path[i] = nil
      self:_reset_point(p)
      unused[#unused + 1] = p
    end
    path[#path].length = 0
  end
  
end

function pt:_update_points()
  if self.num_points == 0 then
    return
  end

  if self.num_points == 1 then
    self.points[1].x, self.points[1].y = self.x, self.y
    return
  end
  
  if self.current_length == 0 then
    for i=1,#self.points do
      self.points[i].x = self.x
      self.points[i].y = self.y
    end
    return
  end

  local points = self.points
  local path = self.path_points
  local p1 = path[1]
  local length = self.current_length
  
  local prepend_position = false
  if not (p1.x == self.x) or not (p1.y == self.y) then
    prepend_position = true
    local head = self.temp_path_point
    head.x, head.y = self.x, self.y
    local dx, dy = head.x - p1.x, head.y - p1.y
    head.length = math.sqrt(dx*dx + dy*dy)
    table.insert(path, 1, head)
    length = length + head.length
  end
  
  -- find distance for each point
  local n = self.num_points
  local diff = 1/(n-1)
  local progress = 0
  local curve = self.trail_curve
  for i=1,#points do
    if progress > 1 then
      progress = 1
    end
    
    if curve then
      points[i].distance = curve:get(progress) * length
    else
      points[i].distance = progress * length
    end
    progress = progress + diff
  end
  
  -- find position for each point
  points[1].x, points[1].y = self.x, self.y
  
  local path = self.path_points
  local path_idx = 1
  local previous_length = 0
  local current_length = path[path_idx].length
  for i=2,#points do
    local p = points[i]
    local dist = p.distance
    if dist > current_length then
      while dist > current_length and path_idx < #path - 1 do
        path_idx = path_idx + 1
        previous_length = current_length
        current_length = current_length + path[path_idx].length
      end
    end
    
    local p1 = path[path_idx]
    local p2 = path[path_idx + 1]
    local ratio = (dist - previous_length) / (current_length - previous_length)
    local dx, dy = p2.x - p1.x, p2.y - p1.y
    p.x, p.y = p1.x + dx * ratio, p1.y + dy * ratio
  end
  
  if prepend_position then
    table.remove(path, 1)
  end
end

function pt:_update_path_contraction(dt)
  if #self.path_points == 1 then
    return
  end

  local min, max = self.min_contract_speed, self.max_contract_speed
  local speed
  if self.contraction_curve then
    local t = self.contraction_curve:get((self.current_length / self.max_length))
    speed = lerp(min, max, t)
  else
    speed = lerp(min, max, self.current_length / self.max_length)
  end
    
  local decrease = speed * dt
  if decrease > self.current_length then
    decrease = self.current_length
  end
  
  local new_length = self.current_length - decrease
  
  local path = self.path_points
  local pn = path[#path]
  local len = path[#path-1].length
  
  if decrease <= len then
    local pm = path[#path-1]
    local ratio = (len - decrease) / (len)
    local dx, dy = pn.x - pm.x, pn.y - pm.y
    pn.x, pn.y = pm.x + dx * ratio, pm.y + dy * ratio
    pm.length = pm.length - decrease
    self.current_length = new_length
  else
    local total_length = 0
    local last_idx
    for i=1,#path-1 do
      total_length = total_length + path[i].length
      if total_length > new_length then
        last_idx = i + 1
        break
      end
    end
    
    local p1 = path[last_idx-1]
    local p2 = path[last_idx]
    local ratio = (new_length - (total_length - p1.length)) / p1.length
    local dx, dy = p2.x - p1.x, p2.y - p1.y
    p2.x, p2.y = p1.x + dx * ratio,  p1.y + dy * ratio
    p1.length = p1.length * ratio
    p2.length = 0
    
    for i=#path,last_idx+1,-1 do
      local p = path[i]
      path[i] = nil
      self:_reset_point(p)
      self.unused_path_points[#self.unused_path_points + 1] = p
    end
    self.current_length = new_length
  end
end

------------------------------------------------------------------------------
function pt:update(dt)
  self.time_accumulator = self.time_accumulator + dt
  if self.time_accumulator >= self.time_between_points then
    self:_update_path()
    self.time_accumulator = self.time_accumulator - self.time_between_points
  end
  
  self:_update_path_contraction(dt)
  self:_update_points()
end

------------------------------------------------------------------------------
function pt:draw()
   if not self.debug then return end
   
   lg.setColor(255, 0, 0, 200)
   lg.setPointStyle("rough")
   lg.setPointSize(5)
   lg.point(self.x, self.y)
   
   
   local path = self.path_points
   lg.setPointSize(5)
   lg.setColor(255, 0, 0, 255)
   for i=1,#path do
     lg.point(path[i].x, path[i].y)
   end
   
   
   
   local points = self.points
   lg.setPointSize(2)
   lg.setColor(0, 0, 0, 150)
   for i=1,#points do
     lg.circle("line", points[i].x, points[i].y, 50, 4)
   end
   
end

return pt











