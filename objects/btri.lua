
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- btri object (bounding triangle)
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local btri = {}
btri.table = BTRI
btri.dir = nil
btri.pos = nil
btri.A = nil
btri.B = nil
btri.C = nil
btri.width = nil
btri.height = nil
btri.h_width = nil
btri.h_height = nil

local btri_mt = { __index = btri }
function btri:new(pos, dir, width, height)
  local h_width, h_height = 0.5*width, 0.5*height
  local normal = vector2:new(dir.y, -dir.x)
  
  local A = pos + h_height * dir
  local B = pos - h_height * dir + h_width * normal
  local C = pos - h_height * dir - h_width * normal
  
  return setmetatable({ A = A, B = B, C = C, pos = pos,
                        dir = dir,
                        width = width,
                        height = height,
                        h_width = h_width,
                        h_height = h_height }, btri_mt)
end

------------------------------------------------------------------------------
function btri:set_direction(dir)
  local normal = vector2:new(dir.y, -dir.x)
  self.dir = dir
  self.A = self.pos + self.h_height * dir
  self.B = self.pos - self.h_height * dir + self.h_width * normal
  self.C = self.pos - self.h_height * dir - self.h_width * normal
end

------------------------------------------------------------------------------
function btri:set_position(pos)
  local diff = pos - self.pos
  self.pos = pos
  
  self.A = self.A + diff
  self.B = self.B + diff
  self.C = self.C + diff
end

------------------------------------------------------------------------------
-- barycentric method
function btri:contains_point(P)
  
  -- vectors for coordinate system/point     
  local AC = self.C - self.A
  local AB = self.B - self.A
  local AP = P - self.A
  
  local AC_dot_AC = vector2:dot(AC, AC)
  local AC_dot_AB = vector2:dot(AC, AB)
  local AC_dot_AP = vector2:dot(AC, AP)
  local AB_dot_AB = vector2:dot(AB, AB)
  local AB_dot_AP = vector2:dot(AB, AP)
  
  -- barycentric coordinates
  local inv_det = 1 / (AC_dot_AC * AB_dot_AB - AC_dot_AB * AC_dot_AB)
  local u = (AB_dot_AB * AC_dot_AP - AC_dot_AB * AB_dot_AP) * inv_det
  local v = (AC_dot_AC * AB_dot_AP - AC_dot_AB * AC_dot_AP) * inv_det
  
  return (u >= 0) and (v >= 0) and (u + v < 1)

end

------------------------------------------------------------------------------
function btri:draw()
  local A = camera:get_screen_vector(self.A)
  local B = camera:get_screen_vector(self.B)
  local C = camera:get_screen_vector(self.C)
  
  lg.setColor(0,0,255,255)
  lg.setPoint(2, 'smooth')
  lg.point(A:get_vals())
  lg.point(B:get_vals())
  lg.point(C:get_vals())
  
  lg.setColor(255, 40, 20, 255)
  lg.polygon('fill', A.x, A.y,
                   B.x, B.y,
                   C.x, C.y,
                   A.x, A.y)
  
  lg.setColor(150,0,0,255) 
  lg.setLine(2)
  lg.line(A.x, A.y,
          B.x, B.y,
          C.x, C.y,
          A.x, A.y)
end

return btri








