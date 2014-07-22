
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- cubic_spline object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local cubic_spline = {}
cubic_spline.table = 'cubic_spline'
cubic_spline.splines = nil
cubic_spline.last_used_spline = nil  -- stores last used spline for fast access
cubic_spline.min = nil               -- starting x value
cubic_spline.max = nil               -- ending x value

local cubic_spline_mt = { __index = cubic_spline }
function cubic_spline:new(C)
  	-- C is a set of m points where x1 < x2 < x3 < ... < xn
	-- generate the set of splines. For algorithm, see
	-- http://en.wikipedia.org/w/index.php?title=Spline_%28mathematics%29&oldid=
	-- 288288033#Algorithm_for_computing_natural_cubic_splines
	
	local n = #C
	local a, b, c, d, h, l, u, z = {}, {}, {}, {}, {}, {}, {}, {}

	for i=1,n do
		a[i] = C[i].y
	end
	
	for i=1,n-1 do
		h[i] = C[i+1].x - C[i].x
	end
	
	local alpha = {}
	for i=2,n-1 do
		alpha[i] = (3/h[i])*(a[i+1]-a[i]) - (3/h[i-1])*(a[i]-a[i-1])
	end

	l[1], u[1], z[1] = 1, 0 ,0
	l[n], z[n], c[n] = 1, 0, 0
	
	for i = 2,n-1 do
		l[i] = 2*(C[i+1].x - C[i-1].x) - h[i-1]*u[i-1]
		u[i] = h[i]/l[i]
		z[i] = (alpha[i] - h[i-1]*z[i-1])/l[i]
	end
	
	for j=n-1,1,-1 do
		c[j] = z[j] - u[j]*c[j+1]
		b[j] = (a[j+1] - a[j])/h[j] - h[j]*(c[j+1] + 2*c[j])/3
		d[j] = (c[j+1] - c[j])/(3*h[j])
	end
	
	local splines = {}
	for i=1,n-1 do
		local spline = {}
		spline.a = a[i]
		spline.b = b[i]
		spline.c = c[i]
		spline.d = d[i]
		spline.xi = C[i].x
		spline.xf = C[i+1].x
		splines[#splines+1] = spline
	end

	return setmetatable({ splines = splines,
												min = splines[1].xi,
												max = splines[#splines].xf,
												last_used_spline = splines[1]}, cubic_spline_mt)
end


------------------------------------------------------------------------------
function cubic_spline:get_val(x, dx)
	dx = dx or 0

	if x < self.min  or x > self.max then
		return 0
	end
	
	-- find which spline x falls into
	local spline = nil
	if x >= self.last_used_spline.xi and x <= self.last_used_spline.xf then
		spline = self.last_used_spline
	else
		for i=1,#self.splines do
			if x >= self.splines[i].xi and x <= self.splines[i].xf then
				spline = self.splines[i]
				self.last_used_spline = spline
				break
			end
		end
	end
	
	-- calculate value
	local diff = x - spline.xi
	
	if dx == 0 then
		return spline.a + spline.b*(diff) + spline.c*(diff)^2 + spline.d*(diff)^3
	elseif dx == 1 then
		return spline.b + 2*spline.c*(diff) + 3*spline.d*(diff)^2
	elseif dx == 2 then
		return 2*spline.c + 6*spline.d*(diff)
	elseif dx == 3 then
		return 6*spline.d
	elseif dx == 'r' then
		return 1*(((1 + (spline.b + 2*spline.c*(diff) + 
					 3*spline.d*(diff)^2)^2)^(3/2))/
					 math.abs(2*spline.c + 6*spline.d*(diff)))
	end
	
end


------------------------------------------------------------------------------
-- generates a table of x,y coordinates spaced s x values apart
-- {x1,y1,x2,y2,x3,y3,...}
function cubic_spline:get_points(s, dx)
	s = s or 2
	dx = dx or 0
	
	local points = {}
	local i = 1
	for x=self.min,self.max,s do
		points[i] = x
		points[i+1] = self:get_val(x, dx)
		i = i + 2
	end
	
	-- add end point
	points[i] = self.max
	points[i+1] = self:get_val(self.max)
	
	return points
end


------------------------------------------------------------------------------
-- generates a table of lines to draw the spline
function cubic_spline:get_lines()
	 segments = self:get_linear_segments()
	 lines = {}
	 res = 2
	 
	 -- check if first section of curve should be a linear segment or curve
	 if segments[1] ~= self.min then
		 for x=self.min,segments[1]-1,res do
				lines[#lines+1] = x
				lines[#lines+1] = self:get_val(x)
		 end
	 end
	 
	 -- generate rest of sections of curve (line, curve, line, curve, ...)
	 for i=1,#segments-2,2 do
		 local x1 = segments[i]
		 local x2 = segments[i+1]
		 local x3 = segments[i+2]
		 
		 -- linear part
		 lines[#lines+1] = x1
		 lines[#lines+1] = self:get_val(x1)
		 lines[#lines+1] = x2
		 lines[#lines+1] = self:get_val(x2)
		 
		 -- curve part
		 for x=x2+1,x3-1,res do
			 lines[#lines+1] = x
			 lines[#lines+1] = self:get_val(x)
		 end
	 end
	 
	 -- generate last line section
	 lines[#lines+1] = segments[#segments-1]
	 lines[#lines+1] = self:get_val(segments[#segments-1])
	 lines[#lines+1] = segments[#segments]
	 lines[#lines+1] = self:get_val(segments[#segments])
	 
	 -- generate last curve section
	 if segments[#segments] ~= self.max then
		 for x=segments[#segments]+1,self.max,res do
			 lines[#lines+1] = x
			 lines[#lines+1] = self:get_val(x)
		 end
	 end
	 
	 
	 return lines
end


------------------------------------------------------------------------------
function cubic_spline:get_linear_segments(threshold, buffer)
	threshold = threshold or 75
	buffer = buffer or 5
	local segments = {}
	local xi = nil
	
	-- get local min/maximums of the spline
	local maxmins = {}
	local p1 = self:get_val(1)
	local p2 = self:get_val(2)
	local p3 = self:get_val(3)
	for x=self.min, self.max-3 do
		if     p1 > p2 and p3 > p2 then
			maxmins[#maxmins+1] = x
		elseif p1 < p2 and p3 < p2 then
			maxmins[#maxmins+1] = x
		end
		
		p1 = p2
		p2 = p3
		p3 = self:get_val(x+3)
	end
	
	-- calculate a buffer around each local maximum/minimum 
	local buffers = {}
	for i=1,#maxmins do
		local min = maxmins[i] - buffer
		local max = maxmins[i] + buffer
		
		if     #buffers > 1 and min > buffers[#buffers] then
			buffers[#buffers+1] = min
			buffers[#buffers+1] = max
		elseif #buffers > 1 and min < buffers[#buffers] then
			buffers[#buffers] = max
		elseif #buffers < 1 then
			buffers[#buffers+1] = min
			buffers[#buffers+1] = max
		end
	end
	
	-- calculate linear segments
	for x=self.min,self.max do
		local r = self:get_val(x, 'r')
		
		if r >= threshold and xi == nil then
		
			-- check whether x is within a buffer zone
			local inbuffer = false
			for i=1,#buffers,2 do
				if x > buffers[i] and x < buffers[i+1] then
					inbuffer = true
				end
			end
			
			if inbuffer == false then
				xi = x
			end
		elseif r >= threshold and xi ~= nil then
		
			-- terminate segment if x is within a buffer zone
			local inbuffer = false
			for i=1,#buffers,2 do
				if x > buffers[i] and x < buffers[i+1] then
					inbuffer = true
				end
			end
			
			if inbuffer == true then
				segments[#segments+1] = xi
				segments[#segments+1] = x
				xi = nil
			end
			
			if inbuffer == false and x == self.max then
				segments[#segments+1] = xi
				segments[#segments+1] = x
				xi = nil
			end
		
		-- terminate segment if r dips below threshold
		elseif r < threshold and xi ~= nil then
			segments[#segments+1] = xi
			segments[#segments+1] = x
			xi = nil
		end
	end
	
	return segments, buffers, maxmins
end


return cubic_spline



