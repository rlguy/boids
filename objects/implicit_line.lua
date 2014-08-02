


--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- implicit_line object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local il = {}
il.table = 'il'
il.debug = true
il.x1 = nil
il.y1 = nil
il.x2 = nil
il.y2 = nil
il.radius = nil
il.weight = 1
il.length = nil
il.bbox = nil
il.p1_bbox = nil
il.p2_bbox = nil

-- for Geoff field function
il.field_a = nil   -- (4/9) * (1/r^6)
il.field_b = nil   -- (17/9) * (1/r^4)
il.field_c = nil   -- (22/9) * (1/r^2)

local il_mt = { __index = il }
function il:new(x1, y1, x2, y2, radius)
  local il = setmetatable({}, il_mt)
  il.x1, il.y1 = x1, y1
  il.x2, il.y2 = x2, y2
  
  local dx, dy = x1 - x2, y1 - y2
  il.length = math.sqrt(dx*dx + dy*dy)
  il.radius = radius
  
  il:_init_bbox()
  il:_init_field_function_coefficients()
  
  return il
end

function il:_init_bbox()
  local r = self.radius
  local b1 = bbox:new(self.x1 - r, self.y1 - r, 2 * r, 2 * r)
  local b2 = bbox:new(self.x2 - r, self.y2 - r, 2 * r, 2 * r)
  self.p1_bbox = b1
  self.p2_bbox = b2
  self.bbox = b1:union(b2)
end

function il:_init_field_function_coefficients()
  local r = self.radius
  self.field_a = (4/9)*(1/(r^6))
  self.field_b = (17/9)*(1/(r^4))
  self.field_c = (22/9)*(1/(r^2))
end

function il:set_line(x1, y1, x2, y2)
  self.x1, self.y1 = x1, y1
  self.x2, self.y2 = x2, y2
  local dx, dy = x1 - x2, y1 - y2
  self.length = math.sqrt(dx*dx + dy*dy)
  self:_init_bbox()
end

function il:set_center(x, y)
  local cx, cy = self:get_center()
  local tx, ty = x - cx, y - cy
  self:translate(tx, ty)
end

function il:translate(tx, ty)
  self.x1, self.y1 = self.x1 + tx, self.y1 + ty
  self.x2, self.y2 = self.x2 + tx, self.y2 + ty
  self.bbox:set_position(self.bbox.x + tx, self.bbox.y + ty)
end

function il:translate_point(tx, ty, n)
  if n == 1 then
    self.x1, self.y1 = self.x1 + tx, self.y1 + ty
  else
    self.x2, self.y2 = self.x2 + tx, self.y2 + ty
  end
  
  self:set_line(self.x1, self.y1, self.x2, self.y2)
end

function il:set_radius(r)
  self.radius = r
  self:_init_bbox()
  self:_init_field_function_coefficients()
end

function il:get_radius()
  return self.radius
end

function il:set_weight(c)
  self.weight = c
end

function il:get_bbox()
  return self.bbox
end

function il:get_field_value(x, y)
  if not self.bbox:contains_coordinate(x, y) then
    return 0
  end
  
  -- Calc where (x, y) is closest to (point or line)
  local v1x, v1y = x - self.x1, y - self.y1
  local v2x, v2y = x - self.x2, y - self.y2
  local v3x, v3y = self.x2 - self.x1, self.y2 - self.y1
  local dot1 = v1x*v3x + v1y*v3y
  local dot2 = -v2x*v3x - v2y*v3y
  
  -- if dot1 and dot2 are positive, closest point is on line
  -- if dot1 is negative, point is closest to point1
  -- if dot2 is negative, point is closes to point 2
  
  local r
  if     dot1 >= 0 and dot2 >= 0 then
    local dx, dy = self.x2 - self.x1, self.y2 - self.y1
    r = math.abs(dy*x - dx*y - self.x1*self.y2 + self.x2*self.y1) / self.length
  elseif dot1 < 0 then
    local dx, dy = x - self.x1, y - self.y1
    r = math.sqrt(dx*dx + dy*dy)
  elseif dot2 < 0 then
    local dx, dy = x - self.x2, y - self.y2
    r = math.sqrt(dx*dx + dy*dy)
  end
  
  if r > self.radius then
    return 0
  end
  
  return self:_evaluate_field_function(r)
end

function il:get_center()
  return self.x1 + 0.5 * (self.x2 - self.x1), self.y1 + 0.5 * (self.y2 - self.y1)
end

function il:_evaluate_field_function(r)
  local val = 1 - self.field_a * r*r*r*r*r*r + self.field_b * r*r*r*r - self.field_c * r*r
  return val * self.weight
end

------------------------------------------------------------------------------
function il:update(dt)
end

------------------------------------------------------------------------------
function il:draw_outline()
  lg.setColor(0, 255, 0, 255)
  lg.setPointSize(5)
  lg.point(self.x1, self.y1)
  lg.point(self.x2, self.y2)
  lg.line(self.x1, self.y1, self.x2, self.y2)
  
  local r = self.radius
  lg.circle("line", self.x1, self.y1, r)
  lg.circle("line", self.x2, self.y2, r)
  
  local perpx, perpy = (self.y1 - self.y2), -(self.x1 - self.x2)
  local len = math.sqrt(perpx*perpx + perpy*perpy)
  perpx, perpy = perpx/len, perpy/len
  local p1x, p1y = self.x1 + r * perpx, self.y1 + r * perpy
  local p2x, p2y = self.x2 + r * perpx, self.y2 + r * perpy
  lg.line(p1x, p1y, p2x, p2y)
  
  local p1x, p1y = self.x1 + -r * perpx, self.y1 + -r * perpy
  local p2x, p2y = self.x2 + -r * perpx, self.y2 + -r * perpy
  lg.line(p1x, p1y, p2x, p2y)
  
  self.bbox:draw()
end

function il:draw()
  if not self.debug then return end
  
  lg.setColor(0, 0, 0, 255)
  lg.setPointSize(5)
  lg.setColor(255, 0, 0, 255)
  lg.point(self.x1, self.y1)
  lg.setColor(0, 0, 255, 255)
  lg.point(self.x2, self.y2)
  lg.line(self.x1, self.y1, self.x2, self.y2)
  
  local r = self.radius
  lg.circle("line", self.x1, self.y1, r)
  lg.circle("line", self.x2, self.y2, r)
  
  local perpx, perpy = (self.y1 - self.y2), -(self.x1 - self.x2)
  local len = math.sqrt(perpx*perpx + perpy*perpy)
  perpx, perpy = perpx/len, perpy/len
  local p1x, p1y = self.x1 + r * perpx, self.y1 + r * perpy
  local p2x, p2y = self.x2 + r * perpx, self.y2 + r * perpy
  lg.line(p1x, p1y, p2x, p2y)
  
  local p1x, p1y = self.x1 + -r * perpx, self.y1 + -r * perpy
  local p2x, p2y = self.x2 + -r * perpx, self.y2 + -r * perpy
  lg.line(p1x, p1y, p2x, p2y)
  
  lg.setColor(0, 0, 255, 255)
  self.bbox:draw()
  
end

return il



