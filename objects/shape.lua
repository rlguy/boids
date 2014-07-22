
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- shape object  -- a shape defined by a set of points
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local sin, cos = math.sin, math.cos

local cs = {}
cs.table = 'st'
cs.debug = true
cs.num_shapes = nil
cs.body_points = nil
cs.sides = nil
cs.num_points = nil
cs.centroid = nil
cs.current_scale = 1
cs.current_rotation = 0

local cs_mt = { __index = cs }
--[[
  body_points - in form: {x1, y1, x2, y2, ..., xn, yn}
               - defines shape of body (must be convex)
]]--
function cs:new(body_points)
  local cs = setmetatable({}, cs_mt)
  
  cs:_init_body_points(body_points)
  cs:_init_sides()
  
  return cs
end

-- points - {x1, y1, x2, y2, ..., xn, yn}
function cs:_init_body_points(points)
  local body = {}
  local cx, cy = 0, 0
  for i=1,#points-1,2 do
    local x, y = points[i], points[i+1]
    cx, cy = cx + x, cy + y
    body[#body + 1] = {x = x, y = y}
  end
  local n = 0.5 * #points
  cx, cy = cx / n, cy / n
  
  self.num_points = n
  self.body_points = body
  self.centroid = {x = cx, y = cy}
end

function cs:_init_sides()
  local body = self.body_points
  local sides = {}
  local cx, cy = self.centroid.x, self.centroid.y
  
  for i=1,#body do
    local s = {}
    s.p1 = body[i]
    if i + 1 > #body then
      s.p2 = body[1]
    else
      s.p2 = body[i + 1]
    end
    local midx, midy = 0.5 * (s.p1.x + s.p2.x), 0.5 * (s.p1.y + s.p2.y)
    
    local nx = s.p2.y - s.p1.y
    local ny = -(s.p2.x - s.p1.x)
    local len = math.sqrt(nx*nx + ny*ny)
    nx, ny = nx / len, ny / len
    
    -- make sure normals are pointing outwards from centre
    local dot = nx * (midx - cx) + ny * (midy - cy)
    if dot < 0 then
      nx, ny = -nx, -ny
    end
    s.normal = {x = nx, y = ny}
    
    sides[i] = s
  end
  self.sides = sides
end

function cs:get_position()
  return self.centroid.x, self.centroid.y
end

function cs:get_rotation()
  return self.current_rotation
end

function cs:get_scale()
  return self.current_scale
end

function cs:get_points()
  return self.body_points
end

function cs:get_sides()
  return self.sides
end

-- sets centroid to (cx, cy)
function cs:set_center(cx, cy)
  self.centroid.x, self.centroid.y = cx, cy
end

function cs:set_position(x, y)
  local current_x, current_y = self.centroid.x, self.centroid.y
  local tx, ty = x - current_x, y -current_y
  self:translate(tx, ty)
end

function cs:translate(tx, ty)
  self.centroid.x = self.centroid.x + tx
  self.centroid.y = self.centroid.y + ty
  
  local body = self.body_points
  for i=1,#body do
    local p = body[i]
    p.x, p.y = p.x + tx, p.y + ty
  end
end

-- scales about centroid
function cs:set_scale(scale)
  if scale == 0 then
    return
  end

  local tx, ty = -self.centroid.x, -self.centroid.y
  
  local body = self.body_points
  for i=1,#body do
    local p = body[i]
    p.x = ((p.x + tx) * (scale / self.current_scale)) - tx
    p.y = ((p.y + ty) * (scale / self.current_scale)) - ty
  end
  
  self.current_scale = scale
end

-- rotates by rot radians about centroid
function cs:rotate(rot)
  local tx, ty = -self.centroid.x, -self.centroid.y
  
  local body = self.body_points
  for i=1,#body do
    local p = body[i]
    local x = (p.x + tx)
    local y = (p.y + ty)
    p.x = (x * cos(rot) - y * sin(rot)) - tx
    p.y = (x * sin(rot) + y * cos(rot)) - ty
  end
  
  local sides = self.sides
  for i=1,#sides do
    local n = sides[i].normal
    local x, y = n.x, n.y
    
    n.x = x * cos(rot) - y * sin(rot)
    n.y = x * sin(rot) + y * cos(rot)
  end
  
  self.current_rotation = self.current_rotation + rot
end

-- rotates to rotation radians from original position about centroid
function cs:set_rotation(rot)
  self:rotate(rot - self.current_rotation)
end

------------------------------------------------------------------------------
function cs:update(dt)
end

------------------------------------------------------------------------------
function cs:draw()
  if not self.debug then return end
  
  -- center
  local pos = self.centroid
  lg.setColor(255, 0, 0, 255)
  lg.setPointStyle("rough")
  lg.setPointSize(4)
  lg.point(pos.x, pos.y)
  
  -- body points
  local points = self.body_points
  lg.setColor(0, 0, 0, 255)
  for i=1,#points do
    local p = points[i]
    lg.point(p.x, p.y)
  end
  
  -- sides
  local sides = self.sides
  lg.setLineWidth(1)
  for i=1,#sides do
    local s = sides[i]
    local nx, ny = s.normal.x, s.normal.y
    local len = 30
    local midx = 0.5 * (s.p1.x + s.p2.x) 
    local midy = 0.5 * (s.p1.y + s.p2.y)
    local ex, ey = midx + nx * len, midy + ny * len
    
    lg.setColor(0, 255, 0, 255)
    lg.line(midx, midy, ex, ey)
    
    lg.setColor(255, 0, 0, 255)
    lg.line(s.p1.x, s.p1.y, s.p2.x, s.p2.y)
  end
  
end

return cs









