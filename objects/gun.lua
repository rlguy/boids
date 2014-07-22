
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- gun object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local gun = {}
gun.table = GUN
gun.debug = false
gun.parent = nil
gun.pos = nil
gun.dir = nil

gun.num_bullets = 700
gun.bullets = nil					-- active bullets
gun.deadpool = nil        -- pool of ready to use bullets

local gun_mt = { __index = gun }
function gun:new(level, position, direction)
  local gun = setmetatable({}, gun_mt)

	-- create bullets with dummy values
	local ammo = {}
	for i=1,gun.num_bullets do
		ammo[i] = bullet:new(level, position, NORMAL[UP], VECT_ZERO)
	end
	
	local collider = level:get_collider()
	
	gun.pos = vector2:new(position.x, position.y)
	gun.dir = vector2:new(direction.x, direction.y)
	gun.deadpool = ammo
	gun.bullets = {}
	gun.collider = collider
	
  return gun
end

-- pos = vector
function gun:set_position(pos)
	self.pos:clone(pos)
end
function gun:get_position()
	return self.pos
end

-- dir = normalized vector
function gun:set_direction(dir)
	self.dir:clone(dir)
end
function gun:get_direction()
	return self.dir
end

function gun:set_parent(obj)
	self.parent = obj
end

function gun:shoot()
	if #self.deadpool == 0 then return end
	
	local bullet = self.deadpool[#self.deadpool]
	self.deadpool[#self.deadpool] = nil
	self.bullets[#self.bullets + 1] = bullet
	
	bullet:set_parent(self)
	bullet:set_owner(self.parent)
	
	bullet:init(self.pos, self.dir, self.parent:get_velocity() * DSCALE)
end

------------------------------------------------------------------------------
function gun:update(dt)
	local bullets = self.bullets
	for i=#bullets,1,-1 do
		local bullet = bullets[i]
		bullet:update(dt)
		if bullet.isdead then
			table.remove(bullets, i)
			self.deadpool[#self.deadpool+1] = bullet
		end
	end
end

------------------------------------------------------------------------------
function gun:draw()
	local bullets = self.bullets
	lg.setColor(255, 255, 255, 255)
	lg.setPointSize(4)
	love.graphics.setPointStyle("rough")
	for i=1,#bullets do
		--lg.setPointSize(bullets[i].size)
		--lg.setColor(bullets[i].color)
		local x = bullets[i].mpoint.pos.x
		local y = bullets[i].mpoint.pos.y
		--lg.point(x, y)
		lg.circle('fill', x, y, 4)
	end
end

------------------------------------------------------------------------------
function gun:draw_debug()
	local pos = self.pos
	local dir = self.dir
	local length = 10
	local endpos = pos + length * dir
	lg.setColor(0,0,0,255)
	lg.setLineWidth(3)
	lg.line(pos.x, pos.y, endpos.x, endpos.y)
end

return gun
































