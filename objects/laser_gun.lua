
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- laser_gun object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local laser_gun = {}
local lsg = laser_gun
laser_gun.table = 'laser_gun'
lsg.level = nil
lsg.debug = false
lsg.parent = nil
lsg.pos = nil             -- vector
lsg.dir = nil             -- normalized vector
lsg.ray = nil
lsg.max_depth = 3

lsg.num_bullets = 100
lsg.active_bullets = nil
lsg.deadpool = nil        -- pool of ready to use bullets
lsg.collider = nil

local laser_gun_mt = { __index = laser_gun }
function laser_gun:new(level, position, direction)
  local lsg = setmetatable({}, laser_gun_mt)
  lsg.level = level
  
  -- create bullets with dummy values
	local ammo = {}
	for i=1,lsg.num_bullets do
		ammo[i] = laser_bullet:new(level)
	end
	
	lsg.pos = vector2:new(position.x, position.y)
	lsg.dir = vector2:new(direction.x, direction.y)
	lsg.deadpool = ammo
	lsg.active_bullets = {}
	lsg.collider = level:get_collider()
	lsg.ray = ray:new(level, position, direction)
  
  return lsg
end

function laser_gun:set_position(pos)
	self.pos:clone(pos)
end
function laser_gun:get_position()
	return self.pos
end

function laser_gun:set_direction(dir)
	self.dir:clone(dir)
end
function laser_gun:get_direction()
	return self.dir
end

function laser_gun:set_parent(obj)
	self.parent = obj
end

function laser_gun:shoot(dt)
  if #self.deadpool == 0 then return end
	
	local bullet = self.deadpool[#self.deadpool]
	self.deadpool[#self.deadpool] = nil
	self.active_bullets[#self.active_bullets + 1] = bullet
	
	bullet:set_parent(self)
	bullet:set_owner(self.parent)
	
	bullet:init(self.pos, self.dir, self.ray, self.max_depth)
	
	self.level:spawn_tile_explosion(self.pos.x, self.pos.y, 0.2, 200)
	-- sound effect
  local listener = self.owner
  self.level:spawn_explosion_sound_effect(nil, nil, 1)
end

------------------------------------------------------------------------------
function laser_gun:update(dt)
  local bullets = self.active_bullets
	for i=#bullets,1,-1 do
		local bullet = bullets[i]
		bullet:update(dt)
		if bullet.is_dead then
			table.remove(bullets, i)
			self.deadpool[#self.deadpool+1] = bullet
		end
	end
end

------------------------------------------------------------------------------
function laser_gun:draw()
  local bullets = self.active_bullets
  for i=1,#bullets do
    bullets[i]:draw()
  end

  if self.debug then
    local x1, y1 = self.pos:get_vals()
    local dx, dy = self.dir:get_vals()
    local len = 15
    local x2, y2 = x1 + len * dx, y1 + len * dy 
    
    lg.setColor(255, 0, 0, 255)
    lg.setLineWidth(4)
    lg.line(x1, y1, x2, y2)
  end
end

return laser_gun




















