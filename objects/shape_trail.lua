
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- shape_trail object - a shape with a trail of itself behind it
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local sin, cos = math.sin, math.cos

local st = {}
st.table = 'st'
st.debug = true
st.x = nil
st.y = nil
st.num_shapes = nil
st.num_sides = nil
st.shape = nil
st.shape_points = nil
st.shape_sides = nil
st.point_trails = nil
st.trail_sides = nil
st.trail_sides_is_current = false
st.shape_trail = nil

st.config = nil

st.num_shapes_to_add = 0
st.num_shapes_to_remove = 0

st.current_length = point_trail.max_length

local st_mt = { __index = st }
--[[
  body_points - in form: {x1, y1, x2, y2, ..., xn, yn}
               - defines shape of body (must be convex)
  num_shapes  - number of trail iterations
]]--
function st:new(points, num_shapes)
  local st = setmetatable({}, st_mt)
  st.num_shapes = num_shapes
  
  st:_init_shape(points)
  st:_init_point_trails()
  st.config = st:_new_side_configuration()
  
  return st
end

-- trail_curve defines how shape iterations are distributed along the trail length
function st:set_trail_curve(trail_curve)
  local tpoints = self.point_trails
  for i=1,#tpoints do
    tpoints[i]:set_trail_curve(trail_curve)
  end
end

-- contraction_curve defines what speed trail contracts depending on length
function st:set_contraction_curve(contraction_curve)
  local tpoints = self.point_trails
  for i=1,#tpoints do
    tpoints[i]:set_contraction_curve(contraction_curve)
  end
end

-- length is the maximum length of trail in pixels
function st:set_length(length)
  local tpoints = self.point_trails
  for i=1,#tpoints do
    tpoints[i]:set_length(length)
  end
  self.current_length = length
end

-- sets min/max speed for trail contraction
function st:set_contraction_speeds(min_speed, max_speed)
  local tpoints = self.point_trails
  for i=1,#tpoints do
    tpoints[i]:set_contraction_speeds(min_speed, max_speed)
  end
end

function st:set_center(cx, cy)
  self.shape:set_center(cx, cy)
  self.trail_sides_is_current = false
end

function st:set_position(x, y)
  self.shape:set_position(x, y)
  self.x, self.y = x, y
  self.trail_sides_is_current = false
end

function st:translate(tx, ty)
  self.shape:translate(tx, ty)
  self.trail_sides_is_current = false
end

function st:set_scale(scale)
  self.shape:set_scale(scale)
  self.trail_sides_is_current = false
end

function st:rotate(rot)
  self.shape:rotate(rot)
  self.trail_sides_is_current = false
end

function st:set_rotation(rot)
  self.shape:set_rotation(rot)
  self.trail_sides_is_current = false
end

-- sets side rotation. Rotates about it's midpoint by rot radians
function st:set_side_rotation(rot)
  self.config.rotation = rot
end

-- rotates sides about it's midpoint by rot radians
function st:rotate_side(rot)
  self.config.rotation = self.config.rotation + rot
end

-- pivots a side about the endpoint of the opposite side
-- If both enpoints are pivoted, the pivots are applied simultaneously using
-- each endpoints original position
function st:set_side_pivot_left(rot)
  self.config.pivot_left = rot
end
function st:set_side_pivot_right(rot)
  self.config.pivot_right = rot
end


-- extrudes sides out/in in the direction of their normals
function st:set_side_extrusion(value)
  value = value or 0
  self.config.extrusion = value
end

function st:set_side_extrusion_left(value)
  self.config.extrusion_left = value
end

function st:set_side_extrusion_right(value)
  self.config.extrusion_right = value
end

-- scale is a factor to scale the length of each side
function st:set_side_scale(scale)
  self.config.scale = scale
end

-- factor is how much to retract a line segment
-- 0 for no retraction, 1 for full retraction
function st:set_side_retraction_right(factor)
  self.config.retraction_right = factor
end

function st:set_side_retraction_left(factor)
  self.config.retraction_left = factor
end

-- Apply offset to sides
function st:set_side_offset(offx, offy)
  self.config.offset.x = offx
  self.config.offset.y = offy
end

function st:set_side_offset_left(offx, offy)
  self.config.offset_left.x = offx
  self.config.offset_left.y = offy
end

function st:set_side_offset_right(offx, offy)
  self.config.offset_right.x = offx
  self.config.offset_right.y = offy
end

-- adds n shapes to the trail
function st:add_shape(n)
  self.num_shapes_to_add = n
end

-- removes n shapes from the trail
function st:remove_shape(n)
  if n > #self.shape_trail then n = #self.shape_trail end
  self.num_shapes_to_remove = n
end

function st:get_side_config(n)
  return self.trail_sides[n].config
end

function st:get_shapes() return self.shape_trail end
function st:get_length() return self.current_length end
function st:get_num_shapes() return self.num_shapes end
function st:get_side_extrusion() return self.current_side_extrusion end
function st:get_side_extrusion_left() return self.current_side_extrusion_left end
function st:get_side_extrusion_right() return self.current_side_extrusion_right end
function st:get_side_scale() return self.current_side_scale end
function st:get_side_retraction_left() return self.current_side_retraction_left end
function st:get_side_retraction_right() return self.current_side_retraction_right end
function st:get_side_rotation() return self.current_side_rotation end
function st:get_side_pivot_left() return self.current_side_pivot_left end
function st:get_side_pivot_right() return self.current_side_pivot_left end
function st:get_position() return self.shape:get_position() end
function st:get_scale() return self.shape:get_scale() end
function st:get_rotation() return self.shape:get_rotation() end


function st:_init_shape(points)
  self.shape = shape:new(points)
  self.shape_points = self.shape:get_points()
  self.shape_sides  = self.shape:get_sides()
  self.x, self.y = self.shape:get_position()
  self.num_sides = #self.shape_sides
  
  self.shape_trail = {}
  for i=1,self.num_shapes do
    self.shape_trail[i] = self:_new_shape_data()
  end
  
  self.trail_sides_is_current = true
end

function st:_new_shape_data()
  local sdata = {}
  sdata.segments = {}
  for i=1,self.num_sides do
    sdata.segments[i] = {}
  end
  
  return sdata
end

function st:_init_point_trails()
  local trail_sides = {}
  local sides = self.shape_sides
  local n = self.num_shapes
  local trails = {}
  
  for i=1,#sides do
    local side = sides[i]
    local tside = {}
    tside.p1 = {x = side.p1.x, y = side.p1.y}
    tside.p2 = {x = side.p2.x, y = side.p2.y}
    tside.normal = {x = side.normal.x, y = side.normal.y}
    tside.tp1 = point_trail:new(tside.p1.x, tside.p1.y, n)
    tside.tp2 = point_trail:new(tside.p1.x, tside.p1.y, n)
    tside.tp1_points = tside.tp1:get_points()
    tside.tp2_points = tside.tp2:get_points()
    tside.config = self:_new_side_configuration()
    
    trails[#trails + 1] = tside.tp1
    trails[#trails + 1] = tside.tp2
    trail_sides[i] = tside
  end
  
  self.point_trails = trails
  self.trail_sides = trail_sides
end

function st:_new_side_configuration()
  local config = {}
  config.offset = {x = 0, y = 0}
  config.offset_left = {x = 0, y = 0}
  config.offset_right = {x = 0, y = 0}
  config.extrusion = 0
  config.extrusion_left = 0
  config.extrusion_right = 0
  config.scale = 1
  config.retraction_left = 0
  config.retraction_right = 0
  config.rotation = 0
  config.pivot_left = 0
  config.pivot_right = 0
  return config
end

function st:_update_sides_to_current_shape()
  local trail_sides = self.trail_sides
  local sides = self.shape_sides
  local ext = self.current_side_extrusion
  local side_scale = self.current_side_scale
  local retract = self.current_side_retraction
  local rot = self.current_side_rotation

  for i=1,#sides do
    local side = sides[i]
    local tside = trail_sides[i]
      
    tside.p1.x, tside.p1.y = side.p1.x, side.p1.y
    tside.p2.x, tside.p2.y = side.p2.x, side.p2.y
    tside.normal.x, tside.normal.y = side.normal.x, side.normal.y
    
  end
  self.trail_sides_is_current = true
end

function st:_apply_transforms_to_side(tside, config)
  local offx, offy = config.offset.x, config.offset.y
  local loffx, loffy = config.offset_left.x, config.offset_left.y
  local roffx, roffy = config.offset_right.x, config.offset_right.y
  local ext = config.extrusion
  local ext_left = config.extrusion_left
  local ext_right = config.extrusion_right
  local rot = config.rotation
  local side_scale = config.scale
  local retract_right = config.retraction_right
  local retract_left = config.retraction_left
  local pivot_left = config.pivot_left
  local pivot_right = config.pivot_right
  
  -- offset
  if offx ~= 0 or offy ~= 0 then
    tside.p1.x, tside.p1.y = tside.p1.x + offx, tside.p1.y + offy
    tside.p2.x, tside.p2.y = tside.p2.x + offx, tside.p2.y + offy
  end
  
  -- endpoint offset
  if loffx ~= 0 or loffy ~= 0 then
    tside.p1.x, tside.p1.y = tside.p1.x + loffx, tside.p1.y + loffy
  end
  if roffx ~= 0 or roffy ~= 0 then
    tside.p2.x, tside.p2.y = tside.p2.x + roffx, tside.p2.y + roffy
  end
  
  -- extrusion
  if ext ~= 0 then
    local nx, ny = tside.normal.x, tside.normal.y
    local offx, offy = ext * nx, ext * ny
    tside.p1.x, tside.p1.y = tside.p1.x + offx, tside.p1.y + offy
    tside.p2.x, tside.p2.y = tside.p2.x + offx, tside.p2.y + offy
  end
  
  -- endpoint extrusion
  if ext_left ~= 0 then
    local nx, ny = tside.normal.x, tside.normal.y
    local offx, offy = ext_left * nx, ext_left * ny
    tside.p1.x, tside.p1.y = tside.p1.x + offx, tside.p1.y + offy
  end
  if ext_right ~= 0 then
    local nx, ny = tside.normal.x, tside.normal.y
    local offx, offy = ext_right * nx, ext_right * ny
    tside.p2.x, tside.p2.y = tside.p2.x + offx, tside.p2.y + offy
  end
  
  -- rotation
  if rot ~= 0 then
    local p1, p2 = tside.p1, tside.p2
    local midx, midy = 0.5 * (p1.x + p2.x), 0.5 * (p1.y + p2.y)
    local x1, y1, x2, y2 = p1.x - midx, p1.y - midy, p2.x - midx, p2.y - midy
    p1.x = (x1 * cos(rot) - y1 * sin(rot)) + midx
    p1.y = (x1 * sin(rot) + y1 * cos(rot)) + midy
    p2.x = (x2 * cos(rot) - y2 * sin(rot)) + midx
    p2.y = (x2 * sin(rot) + y2 * cos(rot)) + midy
  end
  
  -- pivots
  if pivot_left ~= 0 or pivot_right ~= 0 then
    local p1x, p1y = tside.p1.x, tside.p1.y
    local p2x, p2y = tside.p2.x, tside.p2.y
    local p1, p2 = tside.p1, tside.p2
    
    if pivot_left ~= 0 then
      local x1, y1 = p1x - p2x, p1y - p2y
      p1.x = (x1 * cos(pivot_left) - y1 * sin(pivot_left)) + p2x
      p1.y = (x1 * sin(pivot_left) + y1 * cos(pivot_left)) + p2y
    end
    
    if pivot_right ~= 0 then
      local x2, y2 = p2x - p1x, p2y - p1y
      p2.x = (x2 * cos(pivot_right) - y2 * sin(pivot_right)) + p1x
      p2.y = (x2 * sin(pivot_right) + y2 * cos(pivot_right)) + p1y
    end
  end
  
  -- side scale
  if side_scale ~= 1 then
    local p1, p2 = tside.p1, tside.p2
    local midx, midy = 0.5 * (p1.x + p2.x), 0.5 * (p1.y + p2.y)
    p1.x, p1.y = (p1.x - midx) * side_scale + midx, 
                 (p1.y - midy) * side_scale + midy
    p2.x, p2.y = (p2.x - midx) * side_scale + midx, 
                 (p2.y - midy) * side_scale + midy
  end
  
  -- retraction
  if retract_right ~= 0 or retract_left ~= 0 then
    local p1x, p1y = tside.p1.x, tside.p1.y
    local p2x, p2y = tside.p2.x, tside.p2.y
    
    if retract_right ~= 0 then
      local p2 = tside.p2
      local dx, dy = p2x - p1x, p2y - p1y
      p2.x = p1x + (1-retract_right) * dx
      p2.y = p1y + (1-retract_right) * dy
    end
    
    if retract_left ~= 0 then
      local p1 = tside.p1
      local dx, dy = p1x - p2x, p1y - p2y
      p1.x = p2x + (1-retract_left) * dx
      p1.y = p2y + (1-retract_left) * dy
    end
  end
end

function st:_apply_side_transforms()  
  
  local tsides = self.trail_sides
  local cfg = self.config
  for i=1,#tsides do
    local tside = tsides[i]
    self:_apply_transforms_to_side(tside, cfg)
  end
end

function st:_apply_individual_side_transforms()
  local tsides = self.trail_sides
  for i=1,#tsides do
    local tside = tsides[i]
    local cfg = tside.config
    self:_apply_transforms_to_side(tside, cfg)
  end
  
end

function st:_update_point_trails(dt)
  local tsides = self.trail_sides
  for i=1,#tsides do
    local s = tsides[i]
    s.tp1:set_position(s.p1.x, s.p1.y)
    s.tp2:set_position(s.p2.x, s.p2.y)
  end

  local trails = self.point_trails
  for i=1,#trails do
    trails[i]:update(dt)
  end
end

function st:_update_shape_trail_data()
  local shapes = self.shape_trail
  local tsides = self.trail_sides
  
  for i=1,#tsides do
    local s = tsides[i]
    local p1s = s.tp1_points
    local p2s = s.tp2_points
    
    for j=1,#p1s do
      local segment = shapes[j].segments[i]
      segment[1] = p1s[j].x
      segment[2] = p1s[j].y
      segment[3] = p2s[j].x
      segment[4] = p2s[j].y
    end
  end
end

function st:_add_new_shapes()
  local n =  self.num_shapes_to_add
  self.num_shapes = self.num_shapes + n
  
  for i=1,n do
    self.shape_trail[#self.shape_trail + 1] = self:_new_shape_data()
  end
  
  local ptrails = self.point_trails
  for i=1,#ptrails do
    ptrails[i]:add_point(n)
  end
  
  self.num_shapes_to_add = 0
end

function st:_remove_old_shapes()
  local n = self.num_shapes_to_remove
  self.num_shapes = self.num_shapes - n
  
  for i=1,n do
    self.shape_trail[#self.shape_trail] = nil
  end
  
  local ptrails = self.point_trails
  for i=1,#ptrails do
    ptrails[i]:remove_point(n)
  end

  self.num_shapes_to_remove = 0
end

------------------------------------------------------------------------------
function st:update(dt)
  if not self.trail_sides_is_current then
    self:_update_sides_to_current_shape()
  end
  
  if self.num_shapes_to_add > 0 then
    self:_add_new_shapes()
  end
  
  if self.num_shapes_to_remove > 0 then
    self:_remove_old_shapes()
  end
  
  self:_apply_side_transforms()
  self:_apply_individual_side_transforms()
  
  self:_update_point_trails(dt)
  self:_update_shape_trail_data()
end

------------------------------------------------------------------------------
function st:draw()
  if not self.debug then return end
  lg.setLineStyle("smooth")
  
  -- center
  lg.setColor(255, 0, 0, 255)
  lg.setPointStyle("rough")
  lg.setPointSize(4)
  lg.point(self.x, self.y)
  
  -- body points
  local points = self.shape_points
  lg.setColor(0, 0, 0, 255)
  for i=1,#points do
    local p = points[i]
    lg.point(p.x, p.y)
  end
  
  -- shape sides
  local sides = self.shape_sides
  lg.setLineWidth(1)
  for i=1,#sides do
    local s = sides[i]
    local nx, ny = s.normal.x, s.normal.y
    local len = 30
    local midx = 0.5 * (s.p1.x + s.p2.x) 
    local midy = 0.5 * (s.p1.y + s.p2.y)
    local ex, ey = midx + nx * len, midy + ny * len
    
    lg.setColor(0, 255, 0, 100)
    lg.line(midx, midy, ex, ey)
    
    lg.setColor(255, 0, 0, 100)
    lg.line(s.p1.x, s.p1.y, s.p2.x, s.p2.y)
  end
  
  -- trail_sides
  local sides = self.trail_sides
  lg.setLineWidth(1)
  for i=1,#sides do
    local s = sides[i]
    local nx, ny = s.normal.x, s.normal.y
    local len = 30
    local midx = 0.5 * (s.p1.x + s.p2.x) 
    local midy = 0.5 * (s.p1.y + s.p2.y)
    local ex, ey = midx + nx * len, midy + ny * len
    
    lg.setColor(0, 0, 0, 255)
    lg.line(midx, midy, ex, ey)
    
    lg.setColor(0, 0, 0, 255)
    lg.line(s.p1.x, s.p1.y, s.p2.x, s.p2.y)
  end

  
  -- trail points
  lg.setColor(0, 0, 0, 255)
  lg.setPointSize(2)
  local sides = self.trail_sides
  for i=1,#sides do
    local s = sides[i]
    local points1 = s.tp1_points
    local points2 = s.tp2_points
    
    lg.setColor(255, 0, 0, 255)
    for i=1,#points1 do
      lg.point(points1[i].x, points1[i].y)
    end
    lg.setColor(0, 255, 0, 255)
    for i=1,#points2 do
      lg.point(points2[i].x, points2[i].y)
    end
  end 
  
  
  -- shape trail
  lg.setColor(0, 0, 0, 40)
  lg.setLineWidth(1)
  local shapes = self.shape_trail
  for i=1,#shapes do
    local segments = shapes[i].segments
    for j=1,#segments do
      lg.line(segments[j])
    end
  end
  
end

return st






















