--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- hero object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local hero = {}
hero.table = HERO
hero.debug = false
hero.map = nil

-- input
hero.mouse = nil
hero.input_direction = nil
hero.input_look_direction = nil

hero.input_power = 0
hero.input_thrust = 0               -- [0,1], thrust value

-- direction
hero.direction = nil               -- current direction
hero.look_direction = nil
hero.num_dirs = 10                  -- number of past direcitons to remember
hero.dir_history = nil							-- array of past num_dirs directions
hero.look_dir_history = nil

-- movement
hero.point = nil
hero.pos = VECT_ZERO
hero.max_force = 8
hero.max_velocity = 9
hero.min_velocity = 2
hero.velocity_limit = hero.max_velocity
hero.friction = 1.5

-- camera
hero.camera_point = nil
hero.camera_target = nil
hero.camera = nil
hero.cam_radius = 0          -- current dist camera target is away from hero
hero.act_cam_radius = 0      -- actual radius (target radius for cam_radius)
hero.cam_max_radius = 160
hero.shrink_speed = 3
hero.enlarge_speed = 40
hero.min_approach = 0.4      -- approaching slowing factor for camera arriving
hero.max_approach = 1.5      -- at the camera target

-- camera target
hero.target_dscale = 500
hero.target_mass = 0.1
hero.target_force = 20
hero.target_max_speed = 50
hero.target_radius = 10

-- collision
hero.bbox = nil
hero.body = nil
hero.tx = 1                -- translation since last frame
hero.ty = 1

-- weapon
hero.shoot_button = 'lshift'
hero.gun = nil
hero.shoot_time = 0.13
hero.shoot_timer = nil        -- keeps track of time since last shoot
hero.laser_gun = nil

-- shape
hero.side_length = 32
hero.width_to_side_length_ratio = 0.65
hero.points_per_side = 4    -- minimum 2

-- temporary vectors
hero.gun_pos = nil
hero.input_force = nil
hero.velocity_direction = nil
hero.force_friction = nil
hero.average_direction = nil
hero.double_click_direction = nil
hero.mouse_position = nil
hero.screen_position = nil

-- shape trail
hero.hero_shape = nil
hero.shape_points = nil

local hero_mt = { __index = hero }
function hero:new(level, pos)
  local hero = setmetatable({}, hero_mt)
  
  hero.level = level
  hero.master_timer = level:get_master_timer()
  hero.camera = level:get_camera()
  hero.mouse = level:get_mouse()
	
	hero:_init(level, pos)
  
	-- temporary vectors for update
  hero.gun_pos = vector2:new(0, 0)
  hero.input_force = vector2:new(0, 0)
  hero.velocity_direction = vector2:new(0, 0)
  hero.force_friction = vector2:new(0, 0)
  hero.average_direction = vector2:new(0, 0)
  hero.double_click_direction = vector2:new(0, 0)
  hero.dclick_dir = vector2:new(0, 0)
  hero.mouse_position = vector2:new(0, 0)
  hero.last_mouse_position = vector2:new(0, 0)
  hero.input_direction = vector2:new(0, -1)
  hero.input_look_direction = vector2:new(0, -1)
  hero.camera_target = vector2:new(0, 0)
  hero.screen_position = vector2:new(0, 0)
  hero.temp_vect = vector2:new(0, 0)
  hero.temp_objects_table = {}
  
  return hero
end

function hero:_init(level, pos)
  self:_init_direction()
  self:_init_camera_target()
  self:_init_weapons(level, pos)
  
  self:_init_body(level, pos)
  self:_init_bbox_collision_area(level, pos)
  self:_init_hero_shape(level, pos)
end

function hero:_init_hero_shape()
  self.hero_shape = hero_shape:new(self.shape_points)
end

function hero:_init_body(level, pos)
  self.point = physics.point:new(pos)						
									
	local body_points, shape_points = self:_init_body_points(pos)
  local body = map_body:new(level, body_points)
  local dir = self.look_direction
  local angle = math.atan2(dir.y, dir.x)
  body:set_origin(pos)
  body:set_parent(self)
  
  self.body = body
  self.shape_points = shape_points
end

function hero:_init_body_points(pos)
  -- triangle centred at pos
  local len = self.side_length
  local h = 0.5 * math.sqrt(3) * len
  local w = self.width_to_side_length_ratio * len
  
  local x1, y1 = 2 * h / 3 + pos.x, pos.y
  local x2, y2 = -h / 3 + pos.x, 0.5 * w + pos.y
  local x3, y3 = -h / 3 + pos.x, -0.5 * w + pos.y
  local points = {vector2:new(x1, y1), vector2:new(x2, y2), vector2:new(x3, y3)}
  local shape_points = {x1, y1, x2, y2, x3, y3}
  
  -- Add extra points between for better collision results
  local n = self.points_per_side - 2
  local spacing = len / (n + 1)
  local invlen = 1 / len
  local d1x, d1y = (x2 - x1), (y2 - y1)
  local d2x, d2y = (x3 - x2), (y3 - y2)
  local d3x, d3y = (x1 - x3), (y1 - y3)
  local len1 = math.sqrt(d1x*d1x + d1y*d1y)
  local len2 = math.sqrt(d2x*d2x + d2y*d2y)
  local len3 = math.sqrt(d3x*d3x + d3y*d3y)
  d1x, d1y = d1x / len1, d1y / len1
  d2x, d2y = d2x / len2, d2y / len2
  d3x, d3y = d3x / len3, d3y / len3
  local s1 = len1 / (n + 1)
  local s2 = len2 / (n + 1)
  local s3 = len3 / (n + 1)
  
  for i=1,n do
    points[#points + 1] = vector2:new(x1 + d1x*s1*i, y1 + d1y*s1*i)
    points[#points + 1] = vector2:new(x2 + d2x*s2*i, y2 + d2y*s2*i)
    points[#points + 1] = vector2:new(x3 + d3x*s3*i, y3 + d3y*s3*i)
  end
  
  return points, shape_points
end

function hero:_init_weapons(level, pos)
  -- point gun
  local hero_gun = gun:new(level, pos, self.direction)
  hero_gun:set_parent(self)
  local shoot_timer = timer:new(level:get_master_timer(), self.shoot_time)
  shoot_timer:start()
  
  -- laser
  local laser_gun = laser_gun:new(level, pos, self.direction)
  laser_gun:set_parent(self)
  
  self.shoot_timer = shoot_timer
  self.gun = hero_gun
  self.laser_gun = laser_gun
end

function hero:_init_bbox_collision_area(level, pos)
  local h = 0.5 * math.sqrt(3) * self.side_length
  local width = 4 * h / 3

  local bx = pos.x - 0.5 * width
  local by = pos.y - 0.5 * width
  local bbox = bbox:new(bx, by, width, width)
  bbox.parent = self
  self.bbox = bbox
  
  local collider = level:get_collider()
  collider:add_object(bbox, self)
  self.collider = collider
  
end

function hero:_init_camera_target()
  local target = vector2:new(SCR_WIDTH/2, SCR_HEIGHT/2)
	local cam_point = physics.steer:new()
	cam_point:set_dscale(self.target_dscale)
	cam_point:set_target(target)
	cam_point:set_position(target)
	cam_point:set_mass(self.target_mass)
	cam_point:set_force(self.target_force)
	cam_point:set_max_speed(self.target_max_speed)
  cam_point:set_radius(self.target_radius)
  
  self.camera_point = cam_point
end

function hero:_init_direction()
  self.direction = vector2:new(0, -1)
  self.look_direction = vector2:new(0, -1)
	local dir_history = {}
	local look_dir_history = {}
	for i=1,hero.num_dirs do
	  local dir = vector2:new(self.direction.x, self.direction.y)
		dir_history[i] = dir
		
		local dir = vector2:new(self.direction.x, self.direction.y)
		look_dir_history[i] = dir
	end
	
  self.dir_history = dir_history
  self.look_dir_history = look_dir_history
end



function hero:shoot()
	self.gun:shoot()
end

function hero:shoot_laser()
  self.laser_gun:shoot()
end

------------------------------------------------------------------------------
function hero:update(dt)

  local xi, yi = self.pos.x, self.pos.y
  
	self:_update_input(dt)
	self:_update_direction(dt)
	self:_update_position(dt)
	self:_update_camera_target(dt)
	self:_update_collision(dt);
	self:_update_weapon(dt)
	self:_update_hero_shape(dt)
  
  self.tx, self.ty = self.pos.x - xi, self.pos.y - yi
end

function hero:_update_hero_shape(dt)
  local rot = math.atan2(self.look_direction.y, self.look_direction.x)
  self.hero_shape:set_position(self.pos.x, self.pos.y)
  self.hero_shape:set_rotation(rot)
  self.hero_shape:update(dt)
end

------------------------------------------------------------------------------
function hero:_update_weapon(dt)
	-- set orientation
	local dir = self.look_direction
	local pos = self.gun_pos
	pos.x, pos.y = self.pos.x + 10 * dir.x, self.pos.y + 10 * dir.y
	self.gun:set_position(pos)
	self.gun:set_direction(dir)
	self.gun:update(dt)
	
	self.laser_gun:set_position(pos)
	self.laser_gun:set_direction(dir)
	self.laser_gun:update(dt)
	
	if love.keyboard.isDown(self.shoot_button) or love.mouse.isDown('l') then
		if not self.shoot_timer:isrunning() then
			self:shoot_laser()
			self.shoot_timer:start()
		end
	end
	
	
end

function hero:_collide_with_rectangle(bbox, dt)
  local vx, vy = self.point.vel:get_vals()
  local b = self.bbox
  local tx, ty, nx, ny = rectangle_rectangle_collision(
                                 b.x, b.y, b.width, b.height,
                                 bbox.x, bbox.y, bbox.width, bbox.height, vx, vy)
  if tx then
    self.point.vel:set(get_bounce_velocity_components(self.point.vel.x, self.point.vel.y, 
  	                                                  nx, ny, 0.9, 0.3))
  	local temp_pos = self.temp_vect
  	local jog = 0.1
  	local jogx, jogy = nx * jog, ny * jog
  	temp_pos:set(self.pos.x + tx + jogx, self.pos.y + ty + jogy)
  	self:set_position(temp_pos)
  end
  
end

------------------------------------------------------------------------------
function hero:_update_collision(dt)
	-- update position of bbox
  local bbox = self.bbox
  local pos = self:get_position()
  bbox.x =  pos.x - 0.5 * self.bbox.width
  bbox.y = pos.y - 0.5 * self.bbox.height
  self.collider:update_object(bbox)
  local objects = self.temp_objects_table
  table.clear(objects)
  self.collider:get_collisions(bbox, objects)
  
  -- get world collisions
  local rect
  for i=1,#objects do
    if objects[i].table == TILE_BLOCK then
      rect = objects[i]
      self.collider:report_collision(rect, self)
    end
  end
  
  if rect then
    self:_collide_with_rectangle(rect:get_bbox(), dt)
  end
  
  
  -- update position of body
  local angle = math.atan2(self.look_direction.y, self.look_direction.x)
  self.body:set_position(self:get_position())
  self.body:set_rotation(angle)
  self.body:update(dt)
  local c, n, p, offset, tiles = self.body:get_collision_data()
  if c then
  	local new_pos = self.body:get_position() + offset
  	local success, safe_pos = self.body:update_position(new_pos)
  	if not success then
  		new_pos:clone(safe_pos)
  	end
  	
  	self:set_position(new_pos)
  	self.point.vel:set(get_bounce_velocity_components(self.point.vel.x, self.point.vel.y, 
  	                                                  n.x, n.y, 0.95, 0.3))
  end
  
end

------------------------------------------------------------------------------
function hero:_update_position(dt)
 

	-- calculate pushing force, limit max_velocity
	self.limit_velocity = self.max_velocity
	if self.input_direction then
		local thrust = self.input_thrust
		local power = self.input_power
		local max_force = self.max_force
		local dir = self.input_direction

		local force = self.input_force
		force.x = thrust * power * max_force * dir.x
		force.y = thrust * power * max_force * dir.y
		self.point:add_force(force)
	end

	-- set velocity limit
	local vmag = self.point:get_velocity():mag()
	if self.input_power == 0 then
		self.limit_velocity = self.max_velocity
	else
		local min, max = self.min_velocity, self.max_velocity
		local limit = math.max(min + self.input_power * (max - min), vmag)
		limit = math.min(limit, self.max_velocity)
		self.limit_velocity = limit
	end
	
	-- limit velocity
	local vdir = self.velocity_direction
	local vel = self.point:get_velocity()
	vdir = vel:unit_vector(vdir)
	if vmag > self.limit_velocity then
		self.point:set_velocity(vdir * self.limit_velocity)
	end
	
	-- calculate friction force (only when idle)
	if self.input_power == 0 then
		local vmag = vel:mag()
		local force_fr = self.force_friction
		force_fr.x = -self.friction * vmag * vdir.x
		force_fr.y = -self.friction * vmag * vdir.y
		self.point:add_force(force_fr)
	else
		local vmag = vel:mag()
		local force_fr = self.force_friction
		force_fr.x = -0.25 * self.friction * vmag * vdir.x
		force_fr.y = -0.25 * self.friction * vmag * vdir.y
		self.point:add_force(force_fr)
	end
	
	self.point:update(dt)
	self.pos = self.point:get_position()
	
end

------------------------------------------------------------------------------
function hero:_update_direction(dt)
  -- moving direction
	local next_dir = self.input_direction or self.direction
	local past_dirs = self.dir_history
	
	-- remove value at head, and insert new at tail
	local dir = table.remove(past_dirs, 1)
	dir:clone(next_dir)
	past_dirs[self.num_dirs] = dir
	
	-- find average direction
	local avg = self.average_direction
	avg:set(0, 0)
	for i=1,#past_dirs do
		local dir = past_dirs[i]
		avg.x = avg.x + dir.x
		avg.y = avg.y + dir.y
	end
	avg = avg:unit_vector(avg)
	self.direction:clone(avg)
	
	-- looking direction
	local next_dir = self.input_look_direction or self.look_direction
	local past_dirs = self.look_dir_history
	local dir = table.remove(past_dirs, 1)
	dir:clone(next_dir)
	past_dirs[self.num_dirs] = dir
	
	local avg = self.average_direction
	avg:set(0, 0)
	for i=1,#past_dirs do
		local dir = past_dirs[i]
		avg.x = avg.x + dir.x
		avg.y = avg.y + dir.y
	end
	avg = avg:unit_vector(avg)
	self.look_direction:clone(avg)
	
	
end

------------------------------------------------------------------------------
function hero:_update_input()
	
	-- keyboard input test
	if love.keyboard.isDown('w', 'a', 's', 'd') then
	  local lk = love.keyboard
	  local dir
	  if     lk.isDown('a') and lk.isDown('w') then
	    dir = NORMAL[UPLEFT]
	  elseif lk.isDown('w') and lk.isDown('d') then
	    dir = NORMAL[UPRIGHT]
	  elseif lk.isDown('s') and lk.isDown('d') then
	    dir = NORMAL[DOWNRIGHT]
	  elseif lk.isDown('a') and lk.isDown('s') then
	    dir = NORMAL[DOWNLEFT]
	  elseif lk.isDown('w') then
	    dir = NORMAL[UP]
	  elseif lk.isDown('a') then
	    dir = NORMAL[LEFT]
	  elseif lk.isDown('s') then
	    dir = NORMAL[DOWN]
	  elseif lk.isDown('d') then
	    dir = NORMAL[RIGHT]
	  end
	
		self.input_direction:clone(dir)
		self.input_power = 1
		self.input_length = length
		self.input_thrust = 1
	else
	  self.input_power = 0
		self.input_length = 0
		self.input_thrust = 0
	end
	
	-- so mouse doesn't moove with the camera offset
	local mouse = self.mouse
	local mpos = mouse:get_position()
  local scr_pos = self:get_screen_position()
  local dx, dy = mpos.x - scr_pos.x, mpos.y - scr_pos.y
  local len = math.sqrt(dx*dx + dy*dy)
	if love.keyboard.isDown('w', 'a', 's', 'd') then
    local input_dir = self.input_look_direction
    local last_pos = self.last_mouse_position
    local new_pos = self.mouse_position
    new_pos.x = scr_pos.x + len * input_dir.x + (mpos.x - last_pos.x)
    new_pos.y = scr_pos.y + len * input_dir.y + (mpos.y - last_pos.y)
    mouse:set_position(new_pos)
    self.last_mouse_position:clone(new_pos)
  else
    mouse:set_position(mpos)
    self.last_mouse_position:clone(mpos)
  end
	
	-- look direction
  local ldir = self.input_look_direction
  local dx, dy = mpos.x - scr_pos.x, mpos.y - scr_pos.y
  if dx == 0 and dy == 0 then
    ldir:clone(self.look_direction)
  else
    ldir:set(dx, dy)
    ldir = ldir:unit_vector(ldir)
  end
	
end

------------------------------------------------------------------------------
function hero:_update_camera_target(dt)
	-- calc camera radius
	local vmag = self.point:get_velocity():mag()
	local vratio = vmag / self.max_velocity
	local target_radius = vratio * self.cam_max_radius
	
	-- set radius based on target radius
	local radius = self.cam_radius
	if radius < target_radius then
		radius = math.min(radius + self.enlarge_speed * dt, target_radius)
	else
		radius = math.max(radius - self.shrink_speed * dt, target_radius)
	end
	self.cam_radius = radius

	-- update approaching behavior of camera depending on player speed
	local cam_target = self.camera.target
	local vratio = vmag / self.max_velocity
	local minsf, maxsf = self.min_approach, self.max_approach
	cam_target:set_approach_factor(minsf + vratio * (maxsf - minsf))
	
	-- place camera target on the camera radius in direction of player
	local target = self.camera_target
	target.x = self.point.pos.x + radius * self.direction.x
	target.y = self.point.pos.y + radius * self.direction.y
end


------------------------------------------------------------------------------
function hero:get_camera_target()
	return self.camera_target
end

function hero:get_screen_position()
  local pos = self.screen_position
  local cpos = self.camera:get_pos()
  local scale = self.camera.scale
  pos.x = (self.pos.x - cpos.x) * scale
  pos.y = (self.pos.y - cpos.y) * scale
	return pos
end

function hero:get_position()
	return self.pos
end

function hero:set_position(pos)
	self.pos:clone(pos)
	self.point:set_position(pos)
	
	local bbox = self.bbox
	local pos = self:get_position()
  bbox.x =  pos.x - 0.5 * self.bbox.width
  bbox.y = pos.y - 0.5 * self.bbox.height
  self.collider:update_object(bbox)
end

function hero:set_camera(cam)
	self.camera = camera
end

function hero:get_velocity()
	return self.point:get_velocity()
end

function hero:draw()

  --[[
	lg.setColor(255, 255, 255, 255)
	lg.setLineWidth(2)
	lg.circle('line', self.pos.x, self.pos.y, 5)
	
	local dir = self.look_direction
	local p1x, p1y = self.pos.x, self.pos.y
	local p2x, p2y = p1x + 15 * dir.x, p1y + 15 * dir.y
	lg.line(p1x, p1y, p2x, p2y)
	]]--
	
	self.gun:draw()
	self.laser_gun:draw()
	self.hero_shape:draw()
	
	if self.debug then
		lg.setColor(0, 255, 0, 255)
		lg.setLineWidth(1)
		lg.circle('line', self.pos.x, self.pos.y, self.cam_max_radius)
		lg.setColor(0, 255, 255, 255)
		lg.circle('line', self.pos.x, self.pos.y, self.cam_radius)
		
		local w = 10
		local pos = self.camera_target
		lg.setColor(0, 255, 0, 255)
		lg.rectangle('line', pos.x - w/2, pos.y - w/2, w, w)
		
		-- bbox
		lg.setColor(0, 200, 0, 255)
		self.bbox:draw()
		
		--weapon
		self.gun:draw_debug()
		
		-- body
		self.body:draw()
	end
end

return hero



