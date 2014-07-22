
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- curve object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local curve = {}
curve.table = CURVE
curve.length = nil
curve.inv_length = nil
curve.values = nil

-- points: table of vector 2's starting at x=0, ending at x=1
--         x values listed in ascending order
-- num_idx: number of indices to generate. Higher -> more precision
local curve_mt = { __index = curve }
function curve:new(points, num_idx)
  num_idx = num_idx or 200

	-- generate splines
	local spline = cubic_spline:new(points)
	local step = 1 / num_idx
	local xval = 0
	local values = {}
	for i=1,num_idx do
		local y = spline:get_val(xval)
		if i == num_idx then
		  y = spline:get_val(1)
		end
		
		xval = xval + step
		
		values[i] = {x = xval, y = y}
	end

  return setmetatable({ values = values,
                        length = num_idx,
                        inv_length = step}, curve_mt)
end

function curve:get(x)
	local idx = math.floor(x * self.length)
	if idx > self.length then
		idx = self.length
	elseif idx <= 0 then
		idx = 1
	end
	
	return self.values[idx].y
end

function curve:get_x(y)
  for i=2,#self.values do
    local y1, y2 = self.values[i-1].y, self.values[i].y
    if y2 > y1 then
      if y >= y1 and y <= y2 then
        return self.values[i-1].x
      end
    else
      if y >= y2 and y <= y1 then
        return self.values[i-1].x
      end
    end
  end
  
  return y
end

------------------------------------------------------------------------------
function curve:update(dt)
end

------------------------------------------------------------------------------
function curve:draw()
end

return curve



