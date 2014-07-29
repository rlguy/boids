local UP        = 1
local UPRIGHT   = 2
local RIGHT     = 3
local DOWNRIGHT = 4
local DOWN      = 5
local DOWNLEFT  = 6
local LEFT      = 7
local UPLEFT    = 8

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- bbox object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local bbox = {}
bbox.table = BBOX
bbox.x = nil
bbox.y = nil
bbox.width = nil
bbox.height = nil

local bbox_mt = { __index = bbox }
function bbox:new(x, y, width, height)
  return setmetatable({ x = x,
                        y = y,
                        width = width, 
                        height = height }, bbox_mt)
end

------------------------------------------------------------------------------
function bbox:get_x() return self.x end
function bbox:get_y() return self.y end
function bbox:get_width() return self.width end
function bbox:get_height() return self.height end
function bbox:get_dimensions() return self.x, self.y, self.width, self.height end
function bbox:set_position(x, y) self.x, self.y = x, y end
function bbox:translate(tx, ty) self.x, self.y = self.x + tx, self.y + ty end
function bbox:set(x, y, w, h) self.x, self.y, self.width, self.height = x, y, w, h end

function bbox:get_center()
  return self.x + 0.5 * self.width, self.y + 0.5 * self.height
end

function bbox:union(B)
  local A = self
  
  local min_x = math.min(A.x, B.x)
  local max_x = math.max(A.x + A.width, B.x + B.width)
  local min_y = math.min(A.y, B.y)
  local max_y = math.max(A.y + A.height, B.y + B.height)
  
  local width, height = max_x - min_x, max_y - min_y
  return bbox:new(min_x, min_y, width, height)
end

------------------------------------------------------------------------------
function bbox:intersects(B)
  local A = self
  
  local Ahw, Bhw = 0.5 * A.width, 0.5 * B.width
  local inter_x = math.abs(B.x - A.x + Bhw - Ahw) < Ahw + Bhw
  
  if inter_x then
    local Ahh, Bhh = 0.5 * A.height, 0.5 * B.height
    return math.abs(B.y - A.y + Bhh - Ahh) < Ahh + Bhh
  else
    return false
  end
end

------------------------------------------------------------------------------
function bbox:contains_point(p)
  local x, y = self.x, self.y
  return (p.x >= x and p.x < x + self.width) and 
         (p.y >= y and p.y < y + self.height)
end

function bbox:contains_coordinate(px, py)
  local x, y = self.x, self.y
  return (px >= x and px < x + self.width) and 
          (py >= y and py < y + self.height)
end

------------------------------------------------------------------------------
function bbox:contains(B)
  local Ax, Ay = self.x, self.y
  local Bx, By = B.x, B.y
  return (Bx > Ax) and (Bx + B.width < Ax + self.width) and
         (By > Ay) and (By + B.height < Ay + self.height)
end

-- returns true, A's adjacent side, B's adjacent side (UP, RIGHT, DOWNRIGHT...)
-- returns false otherwise
function bbox:is_adjacent(B)
  local A = self
  
  local A_up, A_down, A_left, A_right = A.y, A.y + A.height, A.x, A.x + A.width 
  local B_up, B_down, B_left, B_right = B.y, B.y + B.height, B.x, B.x + B.width
  
  local A_upright_x, A_upright_y = A.x + A.width, A.y
  local A_downright_x, A_downright_y = A.x + A.width, A.y + A.height
  local A_downleft_x, A_downleft_y = A.x, A.y + A.height
  local A_upleft_x, A_upleft_y = A.x, A.y 
  
  local B_upright_x, B_upright_y = B.x + B.width, B.y
  local B_downright_x, B_downright_y = B.x + B.width, B.y + B.height
  local B_downleft_x, B_downleft_y = B.x, B.y + B.height
  local B_upleft_x, B_upleft_y = B.x, B.y 
  
  local Ahw, Bhw = 0.5 * A.width, 0.5 * B.width
  local Ahh, Bhh = 0.5 * A.height, 0.5 * B.height
  local horz_overlap = math.abs(B.x - A.x + Bhw - Ahw) < Ahw + Bhw
  local vert_overlap = math.abs(B.y - A.y + Bhh - Ahh) < Ahh + Bhh
  
  if     A_upright_x == B_downleft_x and A_upright_y == B_downleft_y then
    return true, UPRIGHT, DOWNLEFT
  elseif A_downleft_x == B_upright_x and A_downleft_y == B_upright_y then
    return true, DOWNLEFT, UPRIGHT
  elseif A_downright_x == B_upleft_x and A_downright_y == B_upleft_y then
    return true, DOWNRIGHT, UPLEFT
  elseif A_upleft_x == B_downright_x and A_upleft_y == B_downright_y then
    return true, UPLEFT, DOWNRIGHT
  elseif A_up == B_down and horz_overlap then
    return true, UP, DOWN
  elseif A_down == B_up and horz_overlap then
    return true, DOWN, UP
  elseif A_left == B_right and vert_overlap then
    return true, LEFT, RIGHT
  elseif A_right == B_left and vert_overlap then
    return true, RIGHT, LEFT
  end
  
  return false
  
end

------------------------------------------------------------------------------
function bbox:draw(mode)
  if mode == 'fill' then
    love.graphics.rectangle('fill', math.floor(self.x), math.floor(self.y), 
                                    math.floor(self.width), math.floor(self.height))
  end
  love.graphics.rectangle('line', math.floor(self.x), math.floor(self.y), 
                                  math.floor(self.width), math.floor(self.height))
end

return bbox








