
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- vector2 object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local vector2 = {}
vector2.table = VECTOR2
vector2.x = nil
vector2.y = nil

-- METAMETHODS ---------------------------------------------------------------
function vector2.tostring(v)
  return v.x..'\t'..v.y
end

function vector2.unm(v)
  return vector2:new(-v.x, -v.y)
end

function vector2.add(v1, v2)
  return vector2:new(v1.x + v2.x, v1.y + v2.y)
end

function vector2.sub(v1, v2)
  return vector2:new(v1.x - v2.x, v1.y - v2.y)
end

function vector2.mul(p1, p2)
  if     type(p1) == 'number' then
    return vector2:new(p1 * p2.x, p1 * p2.y)
  elseif type(p1) == 'table' then
    return vector2:new(p2 * p1.x, p2 * p1.y)
  end
end

function vector2.div(v, div)
  if type(v) == 'number' then return end
  local idiv = 1/div
  return vector2:new(v.x * idiv, v.y * idiv)
end

function vector2.eq(v1, v2)
  return (v1.x == v2.x and v1.y == v2.y)
end


-- INIT ----------------------------------------------------------------------
local vector2_mt = { __index = vector2,
                     __tostring = vector2.tostring,
                     __unm = vector2.unm,
                     __add = vector2.add,
                     __sub = vector2.sub,
                     __mul = vector2.mul,
                     __div = vector2.div,
                     __eq  = vector2.eq}
function vector2:new(x, y)
  return setmetatable({x=x, y=y}, vector2_mt)
end

function vector2:get_x()
  return self.x
end

function vector2:get_y()
  return self.y
end

------------------------------------------------------------------------------
function vector2:add(v1, v2)
  if v2 == nil then 
    return vector2:new(self.x + v1.x, self.y + v1.y)
  else 
   return vector2:new(v1.x + v2.x, v1.y + v2.y) 
 end
end

------------------------------------------------------------------------------
function vector2:sub(v1, v2)
  if v2 == nil then 
    return vector2:new(self.x - v1.x, self.y - v1.y)
  else 
   return vector2:new(v1.x - v2.x, v1.y - v2.y) 
 end
end

------------------------------------------------------------------------------
function vector2:dot(v1, v2)
  if v2 == nil then
    return self.x * v1.x + self.y * v1.y
  else
    return v1.x * v2.x + v1.y * v2.y
  end
end

------------------------------------------------------------------------------
function vector2:dist(v1, v2)
  if v2 == nil then
    local dx = self.x - v1.x
    local dy = self.y - v1.y
    return math.sqrt(dx*dx + dy*dy)
  else
    local dx = v1.x - v2.x
    local dy = v1.y - v2.y
    return math.sqrt(dx*dx + dy*dy)
  end
end

------------------------------------------------------------------------------
function vector2:dist_sq(v1, v2)
  if v2 == nil then
    local dx = self.x - v1.x
    local dy = self.y - v1.y
    return dx*dx + dy*dy
  else
    local dx = v1.x - v2.x
    local dy = v1.y - v2.y
    return dx*dx + dy*dy
  end
end

------------------------------------------------------------------------------
function vector2:mult(s)
  return vector2:new(self.x * s, self.y * s)
end

------------------------------------------------------------------------------
function vector2:mag()
  return math.sqrt(self.x*self.x + self.y*self.y)
end

------------------------------------------------------------------------------
function vector2:mag_sq()
  return self.x*self.x + self.y*self.y
end

------------------------------------------------------------------------------
function vector2:normalize()
  local mag = math.sqrt(self.x*self.x + self.y*self.y)
  if mag == 0 then
    return VECT_ZERO
  end
  local imag = 1/mag
  return vector2:new(self.x * imag, self.y * imag)
end

------------------------------------------------------------------------------
function vector2:limit(c)
  local mag = math.sqrt(self.x*self.x + self.y*self.y)
  if mag > c then
    local imag = 1/mag
    return vector2:new((self.x * imag) * c, (self.y * imag) * c)
  else
    return vector2:new(self.x, self.y)
  end
end

------------------------------------------------------------------------------
function vector2:set_mag(c)
  local imag = 1/math.sqrt(self.x*self.x + self.y*self.y)
  return vector2:new((self.x * imag) * c, (self.y * imag) * c)
end

------------------------------------------------------------------------------
function vector2:lerp(v, t)
  if t <= 0 then 
    return vector2:new(self.x, self.y) 
  end
  if t >= 1 then 
    return vector2:new(self.x + v.x, self.y + v.y) 
  end
  return vector2:new(self.x + v.x * t, self.y + v.y * t)
end

------------------------------------------------------------------------------
function vector2:get()
  return vector2:new(self.x, self.y)
end

------------------------------------------------------------------------------
function vector2:get_vals()
  return self.x, self.y
end

------------------------------------------------------------------------------
function vector2:set(x, y)
  self.x, self.y = x, y
end

------------------------------------------------------------------------------
function vector2:clone(v)
	self.x, self.y = v.x, v.y
end

------------------------------------------------------------------------------
function vector2:print()
  print(self.x, self.y)
end

-- Math operators that do not create new vectors
function vector2:subtract(v1, v2, result)
  result.x = v1.x - v2.x
  result.y = v1.y - v2.y
  
  return result
end

function vector2:addition(v1, v2, result)
  result.x = v1.x + v2.x
  result.y = v1.y + v2.y
  
  return result
end

function vector2:negate(v, result)
  result.x = -v.x
  result.y = -v.y
  
  return result
end

function vector2:unit_vector(result)
  local mag = math.sqrt(self.x*self.x + self.y*self.y)
  if mag == 0 then
    return VECT_ZERO
  end
  local imag = 1/mag
  
  result:set(self.x * imag, self.y * imag)
  return result
end

return vector2











