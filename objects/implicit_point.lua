

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- implicit_point object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local ip = {}
ip.table = 'ip'
ip.debug = true
ip.x = nil
ip.y = nil
ip.radius = nil
ip.weight = 1
ip.bbox = nil
ip.min_radius = 60

-- for Geoff field function
ip.field_a = nil   -- (4/9) * (1/r^6)
ip.field_b = nil   -- (17/9) * (1/r^4)
ip.field_c = nil   -- (22/9) * (1/r^2)

local ip_mt = { __index = ip }
function ip:new(x, y, radius)
  local ip = setmetatable({}, ip_mt)
  ip.x, ip.y = x, y
  ip.radius = radius
  ip.bbox = bbox:new(x - radius, y - radius, 2 * radius, 2 * radius)
  ip:_init_field_function_coefficients()
  
  return ip
end

function ip:_init_field_function_coefficients()
  local r = self.radius
  self.field_a = (4/9)*(1/(r^6))
  self.field_b = (17/9)*(1/(r^4))
  self.field_c = (22/9)*(1/(r^2))
end

function ip:set_position(x, y)
  local tx, ty = x - self.x, y - self.y
  self:translate(tx, ty)
end

function ip:set_center(x, y)
  local cx, cy = self.x, self.y
  local tx, ty = x - cx, y - cy
  self:translate(tx, ty)
end

function ip:translate(tx, ty)
  self.x, self.y = self.x + tx, self.y + ty
  self.bbox:set_position(self.bbox.x + tx, self.bbox.y + ty)
end

function ip:set_radius(r)
  if r < self.min_radius then r = self.min_radius end
  self.radius = r
  self.bbox.x = self.x - r
  self.bbox.y = self.y - r
  self.bbox.width = 2 * r
  self.bbox.height = 2 * r
  self:_init_field_function_coefficients()
end

function ip:get_radius()
  return self.radius
end

function ip:set_weight(c)
  self.weight = c
end

function ip:get_field_value(x, y)
  if not self.bbox:contains_coordinate(x, y) then
    return 0
  end
  
  local dx, dy = x - self.x, y - self.y
  local r = math.sqrt(dx*dx + dy*dy)  
  if r > self.radius then
    return 0
  end
  
  return self:_evaluate_field_function(r)
end

function ip:get_center()
  return self.x, self.y
end

function ip:get_bbox()
  return self.bbox
end

function ip:_evaluate_field_function(r)
  local val = 1 - self.field_a * r*r*r*r*r*r + self.field_b * r*r*r*r - self.field_c * r*r
  return val * self.weight
end

------------------------------------------------------------------------------
function ip:update(dt)
end

------------------------------------------------------------------------------
function ip:draw_outline()
  lg.setColor(0, 255, 0, 255)
  lg.circle("line", self.x, self.y, self.radius)
  self.bbox:draw()
end

function ip:draw()
  if not self.debug then return end
  
  lg.setColor(0, 0, 0, 255)
  lg.setPointSize(3)
  lg.point(self.x, self.y)
  lg.circle("line", self.x, self.y, self.radius)
  
  lg.setColor(0, 0, 255, 255)
  self.bbox:draw()
end

return ip









