local vector3 = {}
local sqrt = math.sqrt

function vector3.set(v, x, y, z)
  v.x, v.y, v.z = x, y, z
end

function vector3.set_zero(v)
  v.x, v.y, v.z = 0, 0, 0
end


function vector3.clone(source, clone)
  clone.x, clone.y, clone.z = source.x, source.y, source.z
end

function vector3.add(v, x, y, z)
  v.x, v.y, v.z = v.x + x, v.y + y, v.z + z
end

function vector3.len(v)
  return sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
end

return vector3
