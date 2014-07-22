
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- bullet object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local bullet = {}
bullet.table = BULLET
bullet.parent = nil         -- gun that sent the bullet
bullet.owner = nil          -- object that triggered the gun
bullet.isdead = false

-- position
bullet.mpoint = nil
bullet.pos = nil
bullet.dir = nil

-- movement
bullet.collider = nil
bullet.fire_speed = 300
bullet.vel = nil
bullet.depth = 0
bullet.max_depth = 2

-- draw
bullet.color = nil
bullet.size = 7

-- temporary vectors
bullet.temp_vector = nil

local bullet_mt = { __index = bullet }
function bullet:new(level, position, direction, velocity)
  local bullet = setmetatable({}, bullet_mt)

  local vel = vector2:new(bullet.fire_speed * direction.x + velocity.x,
                          bullet.fire_speed * direction.y + velocity.y)
	local mpoint = map_point:new(level, position)
	local collider = level:get_collider()
	
	bullet.pos = vector2:new(position.x, position.y)
	bullet.dir = vector2:new(direction.x, direction.y)
	bullet.vel = vector2:new(vel.x, vel.y)
	bullet.mpoint = mpoint
	bullet.collider = collider
	bullet.temp_vector = vector2:new(0, 0)
	bullet.color = {255, 0, 0, 255}
	
  return bullet
end

function bullet:init(position, direction, velocity)
	self.vel:set(self.fire_speed * direction.x + velocity.x,
               self.fire_speed * direction.y + velocity.y)
	self.depth = 0
	self.color[1] = 255
	self.size = 7
	self:set_position(position)
	self:set_direction(direction)
	self.collider:add_object(self.mpoint, self)
	self.isdead = false

	if not self.mpoint.tile.walkable then
		self:die()
	end
end

function bullet:set_parent(obj)
	self.parent = obj
end
function bullet:set_owner(obj)
	self.owner = obj
end
function bullet:set_position(pos)
	self.pos:clone(pos)
	self.mpoint:update_position(self.pos)
end
function bullet:set_direction(dir)
  self.dir:clone(dir)
end

function bullet:die()
	self.isdead = true
	self.collider:remove_object(self.mpoint)
end

------------------------------------------------------------------------------
function bullet:update(dt)
	-- move point
	local newpos = self.temp_vector
	newpos:set(self.pos.x + self.vel.x * dt, self.pos.y + self.vel.y * dt)
	
	local point = self.mpoint	
	point:set_position(newpos)
	point:update(dt)
	local c, n, p, off, tile = point:get_collision_data()
	
	-- collision with tile
	if c then
		self.vel:set(get_bounce_velocity(self.vel, n, 0.8, 0.9))
		self.depth = self.depth + 1
		local result = self.temp_vector
		self:set_direction(self.vel:unit_vector(result))
		newpos:clone(p)
		point:update_position(newpos)
		if self.depth > self.max_depth then
			self:die()
		end
		
		self.color[1] = self.color[1] * 0.9
		self.size = math.ceil(self.size * 0.7)
	end
	
	self.pos:clone(newpos)
	self.collider:update_object(point)
end

------------------------------------------------------------------------------
function bullet:draw()
end

return bullet




























