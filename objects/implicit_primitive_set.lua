

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- implicit_primitive_set object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local POINT = "ip"
local LINE = "il"
local RECTANGLE = "ir"

local ips = {}
ips.bbox = nil
ips.table = 'ips'
ips.level = level
ips.debug = true
ips.primitives = nil
ips.ricci_blend = 2
ips.cell_width = 400
ips.cell_height = 400
ips.collision_table = nil
ips.temp_point = nil

local ips_mt = { __index = ips }
function ips:new(level, x, y, width, height)
  local ips = setmetatable({}, ips_mt)
  ips.primitives = {}
  ips.bbox = bbox:new(x, y, width, height)
  ips.collider = collider:new(level, x, y, width, height, 
                              ips.cell_width, ips.cell_height)
  ips.collision_table = {}
  ips.temp_point = {x=0, y=0}
  
  return ips
end

function ips:add_primitive(ip)
  self.primitives[#self.primitives + 1] = ip
  local bbox = ip:get_bbox()
  self.collider:add_object(bbox, ip)
end

function ips:remove_primitive(primitive)
  for i=#self.primitives,1,-1 do
    if self.primitives[i] == primitive then
      self.collider:remove_object(self.primitives[i]:get_bbox())
      table.remove(self.primitives, i)
      break
    end
  end
end

function ips:set_ricci_blend(k)
  self.ricci_blend = k
end

function ips:get_field_value(x, y)
  local primitives = self.collision_table
  table.clear(primitives)
  local point = self.temp_point
  point.x, point.y = x, y
  self.collider:get_objects_at_position(point, primitives)

  local k = self.ricci_blend
  local f = 0
  for i=1,#primitives do
    if k == 1 then
      f = f + primitives[i]:get_field_value(x, y)
    else
      f = f + primitives[i]:get_field_value(x, y)^k
    end
  end
  
  if k ~= 1 then
    f = f^(1/k)
  end
  
  if f > 1 then 
    f = 1
  elseif f < 0 then 
    f = 0
  end
  
  return f
end


-- currently only works for points
function ips:get_field_normal(x, y)
  local primitives = self.collision_table
  table.clear(primitives)
  local point = self.temp_point
  point.x, point.y = x, y
  self.collider:get_objects_at_position(point, primitives)
  
  local k = self.ricci_blend
  local f = 0
  local nx, ny = 0, 0
  for i=1,#primitives do
    local inc = 0
    if k == 1 then
      inc = primitives[i]:get_field_value(x, y)
    else
      inc = primitives[i]:get_field_value(x, y)^k
    end
    f = f + inc
    
    if inc > 0 then
      local cx, cy = primitives[i]:get_center()
      local vx, vy = x - cx, y - cy
      local len = math.sqrt(vx*vx + vy*vy)
      if len > 0 then
        local invlen = 1 / len
        vx, vy = vx * invlen * inc, vy * invlen * inc
        nx, ny = nx + vx, ny + vy
      end
    end
  end
  
  local len = math.sqrt(nx*nx + ny*ny)
  if len > 0 then
    local invlen = 1 / len
    nx, ny = nx * invlen, ny * invlen
  end
  
  if k ~= 1 then
    f = f^(1/k)
  end
  
  if f > 1 then 
    f = 1
  elseif f < 0 then 
    f = 0
  end

  return nx, ny, f
end

function ips:get_primitives()
  return self.primitives
end

function ips:get_primitive_at_position(x, y)
  local primitives = self.collision_table
  local point = self.temp_point
  point.x, point.y = x, y
  table.clear(primitives)
  self.collider:get_objects_at_position(point, primitives)

  local ip
  for i=1,#primitives do
    local p = primitives[i]
    if     p.table == POINT then
      local dx, dy = x - p.x, y - p.y
      local lensqr = dx*dx + dy*dy
      if lensqr < p.radius * p.radius then
        ip = p
        break
      end
    elseif p.table == LINE then
      local f = p:get_field_value(x, y)
      if f ~= 0 then
        ip = p
        break
      end
    elseif p.table == RECTANGLE then
      local f = p:get_field_value(x, y)
      if f ~= 0 then
        ip = p
        break
      end
    end
  end
  
  return ip
end

------------------------------------------------------------------------------
function ips:update(dt)
  self.collider:update(dt)
end

------------------------------------------------------------------------------
function ips:draw()
  if not self.debug then return end  

  for i=1,#self.primitives do
    self.primitives[i]:draw()
  end
  
  self.collider:draw()
end

return ips




