-- direction enums
UP        = 1
UPRIGHT   = 2
RIGHT     = 3
DOWNRIGHT = 4
DOWN      = 5
DOWNLEFT  = 6
LEFT      = 7
UPLEFT    = 8

-- normals
local diag = 1/math.sqrt(2)
NORMAL = {}
NORMAL[UP]        = vector2:new(0, -1)
NORMAL[UPRIGHT]   = vector2:new(diag, -diag)
NORMAL[RIGHT]     = vector2:new(1, 0)
NORMAL[DOWNRIGHT] = vector2:new(diag, diag)
NORMAL[DOWN]      = vector2:new(0, 1)
NORMAL[DOWNLEFT]  = vector2:new(-diag, diag)
NORMAL[LEFT]      = vector2:new(-1, 0)
NORMAL[UPLEFT]    = vector2:new(-diag, -diag)

local TRACK_BY_DISTANCE = 0
local TRACK_BY_POSITION = 1

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- tile object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local tile = {}
tile.table = TILE
tile.parent = nil    -- tile is child of a tile_map
tile.chunk = nil     -- chunk that the tile belongs to
tile.chunk_id = nil  -- id value that chunk uses to reference tile
tile.x = nil         -- world coordinate
tile.y = nil
tile.batch_x = nil   -- chunk sprite batch coordinate
tile.batch_y = nil
tile.neighbours = nil
tile.is_updating = false

-- attributes
tile.type = nil
tile.gradient = nil
tile.quad = nil
tile.intensity = 0
tile.original_intensity = 0
tile.walkable = true

-- diagonal data
tile.is_diagonal = false
tile.parent_tile = nil
tile.rotation = nil          -- in radians (multiples of pi / 2)
tile.direction = nil         -- NORMAL index as (2, 4, 6 or 8)
tile.diagonal = nil          -- reference to diagonal tile

-- flash
tile.is_flashing = false
tile.active_flashes = nil
tile.dead_flashes = nil
tile.flash_intensity = 0

-- lighting
tile.is_lighting = false
tile.active_lights = nil
tile.dead_lights = nil
tile.light_id_value = 0
tile.light_intensity = 0

-- polygonizer field data
tile.field_data = nil

local tile_mt = { __index = tile }
function tile:new()
  local tile = setmetatable({}, tile_mt)
  tile:_init_field_data()
  return tile
end

function tile:_init_field_data()
  self.field_data = {}
  self.field_data.normal = {x = 0, y = 0, z = 0}
  self.field_data.intensity = 0
end

function tile:get_field_intensity()
  return self.field_data.intensity
end

function tile:get_field_direction()
  return self.field_data.normal.x, self.field_data.normal.y, self.field_data.normal.z
end

function tile:get_field_data()
  return self.field_data
end

function tile:set_field_data(intensity, nx, ny, nz)
  nz = nz or 0
  self.field_data.intensity = intensity
  self.field_data.normal.x = nx
  self.field_data.normal.y = ny
  self.field_data.normal.z = nz
end



-- tile type is an integer, types found in tile_types.lua
function tile:set_type(tile_type)
  local old_type = self.type
  self.type = tile_type
  
  if     tile_type == T_WALK then
    self.walkable = true
  elseif tile_type == T_WALL then
    self.walkable = false
  else
    print("ERROR in tile:set_type() - type not recognized")
    return
  end
  
  if self.chunk and old_type then
    self.chunk:update_type_list(self, old_type, tile_type)
  end
end

function tile:set_diagonal_tile(direction, tile_type, quad, gradient)
	local diag_tile = tile:new(true)
	diag_tile.x = self.x
	diag_tile.y = self.y
	diag_tile.is_diagonal = true
	diag_tile.parent_tile = self
	diag_tile.direction = direction
	diag_tile.rotation = (0.5 * direction - 1) * 0.5 * math.pi
	
	diag_tile:_set_quad(quad)
	diag_tile:set_gradient(gradient)
	diag_tile:set_type(tile_type)
	
	self.diagonal = diag_tile
end

function tile:remove_diagonal_tile()
  local diag = self.diagonal
  self.diagonal = nil
  
  local diag_tiles = self.chunk.diagonal_tiles
  for i=1,#diag_tiles do
    if diag_tiles[i] == diag then
      table.remove(diag_tiles, i)
      break
    end
  end
end

function tile:init_intensity(intensity)
  self.intensity = intensity
  self.original_intensity = intensity
end

function tile:set_intensity(intensity)
  self.intensity = intensity
  local quad
  if not self.is_diagonal then
    quad = self.gradient:get_quad(intensity)
  else
    quad = self.gradient:get_diagonal_quad(intensity)
  end
  
  if quad ~= self.quad then
    self:_set_quad(quad)
  end
end

function tile:get_intensity()
  return self.intensity
end

function tile:has_diagonal_tile()
	if self.diagonal then
		return true
	end
	return false
end

function tile:is_diagonal_tile()
	return self.is_diagonal
end

function tile:set_gradient(gradient)
 self.gradient = gradient
end

function tile:get_gradient()
  return self.gradient
end

function tile:get_type()
  return self.type
end

-- tiles = {up, upright, right, downright, down, downleft, left, upright}
function tile:set_neighbours(tiles)
  self.neighbours = tiles
end

-- parent is a tile_map object
function tile:set_parent(parent) self.parent = parent end
function tile:set_chunk(chunk) self.chunk = chunk end

function tile:_set_quad(quad)
	self.quad = quad
	
	-- update chunk for solid tile case
	if self.chunk then
    self.chunk:update_quad(self)
    
  -- diagonal tile case
  elseif self.parent_tile and self.parent_tile.chunk then
    self.parent_tile.chunk:update_quad(self.parent_tile)
  end
end

function tile:set_chunk_id(id)
	self.chunk_id = id
end

-- position of tile in relation to top left corner of spritebatch
function tile:set_spritebatch_position(x, y)
  self.batch_x = x
  self.batch_y = y
end

function tile:halt_update()
	self.is_updating = false
end

function tile:start_update()
  if not self.is_updating and self.chunk then
    self.chunk:add_tile_to_update_list(self)
  end
	self.is_updating = true
end

------------------------------------------------------------------------------
-- flash methods
function tile:flash(power, time, curve)
  if not self.is_flash_initialized then
    self:_init_flash_data_tables()
  end
  
  self:_new_flash(power, time, curve)
  self:start_update()
  self.is_flashing = true
end

function tile:_new_flash(power, time, curve)
  if #self.dead_flashes == 0 then
    self.dead_flashes[1] = {}
  end
  local fdata = self.dead_flashes[#self.dead_flashes]
  self.dead_flashes[#self.dead_flashes] = nil
  
  fdata.is_negative_flash = false
  if power < 0 then
    power = -power
    fdata.is_negative_flash = true
  end
  
  fdata.power = power
  fdata.lifetime = time
  fdata.inv_lifetime = 1 / time
  fdata.current_time = 0
  fdata.curve = curve
  fdata.min_intensity = self.original_intensity
  local max
  if fdata.is_negative_flash then
    max = fdata.min_intensity - power * fdata.min_intensity
  else
    max = fdata.min_intensity + power * (1 - fdata.min_intensity)
  end
  fdata.max_intensity = max
  fdata.intensity_difference = math.abs(max - fdata.min_intensity)
  fdata.is_finished = false
  
  self.active_flashes[#self.active_flashes + 1] = fdata
end

function tile:_init_flash_data_tables()
  self.active_flashes = {}
  self.dead_flashes = {{}}
  self.is_flash_initialized = true
end

function tile:_stop_flash()
  self.is_flashing = false
end

function tile:_update_flash(dt, current_intensity)
  
  local flashes = self.active_flashes
  local intensity = current_intensity
  local add_intensity = 0
  for i=#flashes,1,-1 do
    local fd = flashes[i]
    fd.current_time = fd.current_time + dt
    local ratio = fd.curve:get(fd.current_time * fd.inv_lifetime)
    if ratio > 1 then
      ratio = 1
    end
    
    local ival
    local min = current_intensity
    local max
    if fd.is_negative_flash then
      max = min - fd.power * min
    else
      max = min + fd.power * (1 - min)
    end
    
    local diff = max - min
    if fd.is_negative_flash then
      ival = min - ratio * diff
    else
      ival = min + ratio * diff
    end
    add_intensity = add_intensity + ival - min
    
    if fd.current_time > fd.lifetime then
      fd.is_finished = true
    end
    
    if fd.is_finished then
      self.dead_flashes[#self.dead_flashes+1] = table.remove(flashes, i)
    end
  end
  
  self.flash_intensity = add_intensity
  
  if #flashes == 0 then
    self:_stop_flash()
  end
end

------------------------------------------------------------------------------
-- lighting methods
function tile:add_point_light(vect_position, vect_dim_ratio, radius, power, fade_curve)
  if not self.is_lighting_initialized then
    self:_init_lighting_data_tables()
  end
  
  local id = self:_generate_light_id()
  self:_new_point_light(id, vect_position, vect_dim_ratio, radius, power, fade_curve)
  self:start_update()
  self.is_lighting = true
  
  return id
end

function tile:add_distance_light(vect_distance, vect_dim_ratio, radius, power, fade_curve)
  if not self.is_lighting_initialized then
    self:_init_lighting_data_tables()
  end
  
  local id = self:_generate_light_id()
  self:_new_distance_light(id, vect_distance, vect_dim_ratio, radius, power, fade_curve)
  self:start_update()
  self.is_lighting = true
  
  return id
end

function tile:remove_light(id)
  local active = self.active_lights
  for i=#active,1,-1 do
    if active[i].id == id then
      active[i].is_finished = true
      break
    end
  end
end

function tile:_generate_light_id()
  local id = self.light_id_value
  self.light_id_value = id + 1
  return id
end

function tile:_init_lighting_data_tables()
  self.active_lights = {}
  self.dead_lights = {{}}
  self.is_lighting_initialized = true
end

function tile:_stop_lighting()
  self.is_lighting = false
end

function tile:_new_point_light(id, vect_position, vect_dim_ratio, radius, power, fade_curve)
  if #self.dead_lights == 0 then
    self.dead_lights[1] = {}
  end
  local ldata = self.dead_lights[#self.dead_lights]
  self.dead_lights[#self.dead_lights] = nil
  
  ldata.darken = false
  if power < 0 then
    ldata.darken = true
    power = -power
  end
  
  ldata.type = TRACK_BY_POSITION
  ldata.id = id
  ldata.x = self.x + 0.5 * TILE_WIDTH
  ldata.y = self.y + 0.5 * TILE_HEIGHT
  ldata.position_vect = vect_position
  ldata.last_light_x = vect_position.x + 1 -- dont want last x to be the same
  ldata.last_light_y = 0                   -- as light x so that update is triggered
  ldata.last_dimmer_value = 0
  ldata.dimmer_vect = vect_dim_ratio
  ldata.radius = radius
  ldata.power = power
  ldata.curve = fade_curve
  ldata.is_finished = false
  ldata.current_intensity_value = 0
  
  self.active_lights[#self.active_lights + 1] = ldata
end

function tile:_new_distance_light(id, vect_distance, vect_dim_ratio, radius, power, fade_curve)
  if #self.dead_lights == 0 then
    self.dead_lights[1] = {}
  end
  local ldata = self.dead_lights[#self.dead_lights]
  self.dead_lights[#self.dead_lights] = nil
  
  ldata.darken = false
  if power < 0 then
    ldata.darken = true
    power = -power
  end
  
  ldata.type = TRACK_BY_DISTANCE
  ldata.id = id
  ldata.distance_vect = vect_distance
  ldata.last_distance = vect_distance.x + 1
  ldata.dimmer_vect = vect_dim_ratio
  ldata.last_dimmer_value = 0
  ldata.radius = radius
  ldata.power = power
  ldata.curve = fade_curve
  ldata.is_finished = false
  ldata.current_intensity_value = 0
  
  self.active_lights[#self.active_lights + 1] = ldata
end

function tile:_update_lights()
  local lights = self.active_lights
  local intensity = self.original_intensity
  local light_intensity = 0
  
  for i=#lights,1,-1 do
    local ld = lights[i]
    if ld.type == TRACK_BY_POSITION then 
      -- TRACK BY POSITION
      local light_x, light_y = ld.position_vect.x, ld.position_vect.y
      local last_x, last_y = ld.last_light_x, ld.last_light_y
      local tx, ty = light_x - last_x, light_y - last_y
      local tdim = ld.last_dimmer_value - ld.dimmer_vect.x
      if not (tx == 0 and ty == 0 and tdim == 0) then
        local dx, dy = light_x - ld.x, light_y - ld.y
        local dist = math.sqrt(dx*dx + dy*dy)
        local dist_ratio = dist / ld.radius
        
        if dist_ratio <= 1 then
          local ratio = ld.curve:get(dist_ratio)
          if ratio > 1 then
            ratio = 1
          end
          
          local min = self.original_intensity
          local ival
          if ld.darken then
            local max = min - min * ld.power * ld.dimmer_vect.x
            ival = min - ratio * (min - max)
          else
            local max = min + (1-min) * ld.power * ld.dimmer_vect.x
            ival = min + ratio * (max - min)
          end
          light_intensity = light_intensity + ival - self.original_intensity
          
          ld.current_intensity_value = ival - self.original_intensity
        else
          ld.current_intensity_value = 0
        end
        
        ld.last_light_x, ld.last_light_y = light_x, light_y
      else
        light_intensity = light_intensity + ld.current_intensity_value
      end
      
      if ld.is_finished then
        self.dead_lights[#self.dead_lights+1] = table.remove(lights, i)
      end
    else
      -- TRACK_BY_DISTANCE
      local light_dist = ld.distance_vect.x
      
      local tx, ty = light_dist - ld.last_distance
      local tdim = ld.last_dimmer_value - ld.dimmer_vect.x
      if not (tx == 0 and ty == 0 and tdim == 0) then
        local dist = light_dist
        local dist_ratio = dist / ld.radius
        
        if dist_ratio <= 1 then
          local ratio = ld.curve:get(dist_ratio)
          if ratio > 1 then
            ratio = 1
          end
          
          local min = self.original_intensity
          local ival
          if ld.darken then
            local max = min - min * ld.power * ld.dimmer_vect.x
            ival = min - ratio * (min - max)
          else
            local max = min + (1-min) * ld.power * ld.dimmer_vect.x
            ival = min + ratio * (max - min)
          end
          light_intensity = light_intensity + ival - self.original_intensity
          
          ld.current_intensity_value = ival - self.original_intensity
        else
          ld.current_intensity_value = 0
        end
        
        ld.last_distance = light_dist
      else
        light_intensity = light_intensity + ld.current_intensity_value
      end
      
      if ld.is_finished then
        self.dead_lights[#self.dead_lights+1] = table.remove(lights, i)
      end
    end
  end
  
  self.light_intensity = light_intensity

  if #lights == 0 then
    self:_stop_lighting()
  end
end


------------------------------------------------------------------------------
function tile:update(dt)
  local is_updating = false

  local new_intensity = self.original_intensity
  if self.is_lighting then
    is_updating = true
    self:_update_lights()
    local intensity = self.light_intensity
    if intensity < -self.original_intensity then
      intensity = -self.original_intensity
    end
    new_intensity = new_intensity + intensity
  end
  
  if new_intensity < 0 then new_intensity = 0 end
  if new_intensity > 1 then new_intensity = 1 end
  if self.is_flashing then
    is_updating = true
    self:_update_flash(dt, new_intensity)
    new_intensity = new_intensity + self.flash_intensity
  end
  
  if self.original_intensity ~= new_intensity then
    if new_intensity < 0 then new_intensity = 0 end
    if new_intensity > 1 then new_intensity = 1 end
    self:set_intensity(new_intensity)
  end
  
  if not is_updating then
    self:halt_update()
  end
end
------------------------------------------------------------------------------
function tile:draw()
end

return tile























