

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- ir object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local ir = {}
ir.table = 'ir'
ir.debug = true
ir.x = nil
ir.y = nil
ir.radius = nil
ir.weight = 1
ir.bbox = nil

-- for Geoff field function
ir.field_a = nil   -- (4/9) * (1/r^6)
ir.field_b = nil   -- (17/9) * (1/r^4)
ir.field_c = nil   -- (22/9) * (1/r^2)

local ir_mt = { __index = ir }
function ir:new(x, y, width, height, radius)
  local ir = setmetatable({}, ir_mt)
  ir.x, ir.y = x, y
  ir.width, ir.height = width, height
  ir.radius = radius
  ir:_init_bbox()
  ir:_init_field_function_coefficients()
  
  return ir
end

function ir:_init_bbox()
  local x, y, w, h, r = self.x, self.y, self.width, self.height, self.radius
  
  self.rectangle_bbox = bbox:new(x, y, w, h)
  self.bbox = bbox:new(x - r, y - r, w + 2 * r, h + 2 * r)
end

function ir:_init_field_function_coefficients()
  local r = self.radius
  self.field_a = (4/9)*(1/(r^6))
  self.field_b = (17/9)*(1/(r^4))
  self.field_c = (22/9)*(1/(r^2))
end

function ir:set_position(x, y)
  local tx, ty = x - self.x, y - self.y
  self:translate(tx, ty)
end

function ir:set_center(x, y)
  local cx, cy = self:get_center()
  local tx, ty = x - cx, y - cy
  self:translate(tx, ty)
end

function ir:get_bbox()
  return self.bbox
end

function ir:translate(tx, ty)
  self.x, self.y = self.x + tx, self.y + ty
  self.bbox:set_position(self.bbox.x + tx, self.bbox.y + ty)
  self.rectangle_bbox:set_position(self.rectangle_bbox.x + tx, 
                                   self.rectangle_bbox.y + ty)
end

function ir:set_rectangle(x, y, width, height)
  self:set_position(x, y)
  self:set_dimensions(width, height)
end

function ir:set_dimensions(width, height)
  self.width, self.height = width, height
  self:_init_bbox()
end

function ir:set_radius(r)
  self.radius = r
  self:_init_bbox()
  self:_init_field_function_coefficients()
end

function ir:get_radius()
  return self.radius
end

function ir:set_weight(c)
  self.weight = c
end

function ir:get_field_value(x, y)
  if not self.bbox:contains_coordinate(x, y) then
    return 0
  end
  
  if self.rectangle_bbox:contains_coordinate(x, y) then
    return 1
  end
  
  local left_x, right_x = self.x, self.x + self.width
  local top_y, bot_y = self.y, self.y + self.height
  
  local r
  if     x <= left_x then                   -- left
    if     y <= top_y then                    -- top left corner
      local dx, dy = x - self.x, y - self.y
      r = math.sqrt(dx*dx + dy*dy)
    elseif y > top_y and y < bot_y then      -- middle left segment
      r = left_x - x
    else                                       -- bottom left corner
      local dx, dy = x - self.x, y - (self.y + self.height)
      r = math.sqrt(dx*dx + dy*dy)
    end
  elseif x > left_x and x < right_x then   -- middle
    if y <= top_y then                        -- top middle segment
      r = top_y - y
    else                                       -- bottom middle segment
      r = y - bot_y
    end
  else                                       -- right
    if     y <= top_y then                    -- top right corner
      local dx, dy = x - (self.x + self.width), y - self.y
      r = math.sqrt(dx*dx + dy*dy)
    elseif y > top_y and y < bot_y then      -- middle right segment
      r = x - right_x
    else                                       -- bottom right corner
      local dx, dy = x - (self.x + self.width), y - (self.y + self.height)
      r = math.sqrt(dx*dx + dy*dy)
    end
  end
  
  if r > self.radius then
    return 0
  end
  
  return self:_evaluate_field_function(r)
end

function ir:get_center()
  return self.bbox.x + 0.5 * self.bbox.width, self.bbox.y + 0.5 * self.bbox.height
end

function ir:_evaluate_field_function(r)
  local val = 1 - self.field_a * r*r*r*r*r*r + self.field_b * r*r*r*r - self.field_c * r*r
  return val * self.weight
end

------------------------------------------------------------------------------
function ir:update(dt)
end

------------------------------------------------------------------------------
function ir:draw_outline()
  lg.setColor(0, 255, 0, 255)
  self.rectangle_bbox:draw()
  self.bbox:draw()
end

function ir:draw()
  if not self.debug then return end
  
  lg.setColor(0, 0, 0, 255)
  self.rectangle_bbox:draw()
  lg.setColor(0, 0, 255, 255)
  self.bbox:draw()
  
  lg.setColor(0, 0, 0, 255)
  
  local r = self.radius
  local x, y = self.x, self.y
  lg.circle("line", x, y, r)
  lg.circle("line", x + self.width, y, r)
  lg.circle("line", x + self.width, y + self.height, r)
  lg.circle("line", x, y + self.height, r)
  
end

return ir
















