-- tile type 'enums'
-- note: must be in consecutive numerical order starting at 1
-- values 1-100 are reserved for tile types
T_WALK = 1
T_WALL = 2
T_FLASH = 3

TILE_TYPES = {}
TILE_TYPES[T_WALK] = T_WALK
TILE_TYPES[T_WALL] = T_WALL
TILE_TYPES[T_FLASH] = T_FLASH

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- t_template
--[[----------------------------------------------------------------------]]--
--##########################################################################--

local t_template = {}
t_template.table = 't_template'
t_template.parent = nil
t_template.quad = nil
t_template.walkable = false

local t_template_mt = { __index = t_template }
function t_template:new(quad)
  return setmetatable({ quad = quad }, t_template_mt)
end

-----------------------------------------------------------------------------
function t_template:set_quad(quad)
  self.quad = quad
end

-----------------------------------------------------------------------------
function t_template:update(dt)
end

--return t_template

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- t_walk  (walkable tile) 
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local t_walk = {}
t_walk.table = T_WALK
t_walk.parent = nil
t_walk.quad = nil
t_walk.walkable = true

local t_walk_mt = { __index = t_walk }
function t_walk:new(quad)
  return setmetatable({ quad = quad }, t_walk_mt)
end

-----------------------------------------------------------------------------
function t_walk:set_quad(quad)
  self.quad = quad
end

-----------------------------------------------------------------------------
function t_walk:update(dt)
end



--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- t_wall  (non walkable tile) 
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local t_wall = {}
t_wall.table = T_WALL
t_wall.parent = nil        -- tile that type belongs to
t_wall.quad = nil
t_wall.walkable = false

local t_wall_mt = { __index = t_wall }
function t_wall:new(quad)
  return setmetatable({ quad = quad }, t_wall_mt)
end

-----------------------------------------------------------------------------
function t_wall:set_quad(quad)
  self.quad = quad
end

-----------------------------------------------------------------------------
function t_wall:update(dt)
	local quad = map.p_quads[1][math.random(1,#map.p_quads[1])]
	self.parent:set_quad(quad)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- t_flash (colour shifting tile)
--[[----------------------------------------------------------------------]]--
--##########################################################################--

local t_flash = {}
t_flash.table = T_FLASH
t_flash.parent = nil
t_flash.quad = nil
t_flash.start_idx = nil
t_flash.shades = nil
t_flash.f_timer = nil
t_flash.f_time = 3000
t_flash.flash_val = nil
t_flash.min_shade = nil
t_flash.max_shade = nil
t_flash.curve = nil

t_flash.walkable = true

local t_flash_mt = { __index = t_flash }
function t_flash:new(quad, orig_idx, shades)
	local flash_timer = timer:new(t_flash.f_time)
  return setmetatable({ quad = quad,
                        shades = shades,
                        start_idx = orig_idx,
                        f_timer = flash_timer,
                        curve = flash_curve}, t_flash_mt)
end

-- val: 0->1 (higher -> brighter)
function t_flash:flash(val)

	self.flash_val = val
	self.max_shade = self.start_idx
	self.min_shade = self.max_shade - math.floor(self.start_idx*val)

	self.parent:start_update()
	self.f_timer:set_length(self.f_time)
	self.f_timer:start()
	
	if self.curve == nil then
		self.curve = flash_curve
	end
end

-----------------------------------------------------------------------------
function t_flash:set_quad(quad)
  self.quad = quad
end

-----------------------------------------------------------------------------
function t_flash:update(dt)
	local progress = self.f_timer:progress()
	local cval = 1 - self.curve:get(progress)
	local quads = self.shades
	
	local min, max = self.min_shade, self.max_shade
	local idx = min + math.floor((max - min) * cval)
	
	self.parent:set_quad(quads[idx])
	
	if progress == 1 then
		self.parent:halt_update()
		self.parent:set_quad(quads[self.start_idx])
	end
end



return {t_walk, t_wall, t_flash}











