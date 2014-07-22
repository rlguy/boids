
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- hero_shape object -- manages custom shape_trail animations for hero
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local hs = {}
hs.table = 'hs'
hs.debug = false
hs.num_shapes = 30
hs.shape_trail = nil
hs.gradient = require("gradients/named/orangeyellow")

local hs_mt = { __index = hs }
function hs:new(points)
  local hs = setmetatable({}, hs_mt)
  
  hs.shape_trail = shape_trail:new(points, self.num_shapes)
  hs.shape_trail:set_length(25)
  hs.shape_trail:set_contraction_speeds(0, 300)
  
  return hs
end

function hs:set_position(x, y)
  self.shape_trail:set_position(x, y)
end

function hs:set_rotation(rot)
   self.shape_trail:set_rotation(rot)
end

------------------------------------------------------------------------------
function hs:update(dt)
  self.shape_trail:update(dt)
end

------------------------------------------------------------------------------
function hs:draw()

  lg.setLineWidth(1)
  local g = self.gradient
  local shapes = self.shape_trail:get_shapes()
  for i=#shapes,1,-1 do
    local progress = 1 - (i-1)/(#shapes)
    local c = g[math.floor(1 + progress * (#g - 1))]
    lg.setColor(c[1], c[2], c[3], 100)
    local segments = shapes[i].segments
    for j=1,#segments do
      if j % 1 == 0 then
        lg.line(segments[j])
      end
    end
  end

  if not self.debug then return end
  self.shape_trail:draw()
end

return hs



