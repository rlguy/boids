local SELECT_MODE = 0
local ADD_MODE = 1

--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- flock_interface object   - UI for managing flock/boids
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local fi = {}
fi.table = 'fi'
fi.debug = false
fi.level = nil
fi.flock = nil

fi.depth_range = 30

fi.left_click_mode = nil
fi.left_click_x = nil
fi.left_click_y = nil

fi.select_boid_radius = 28
fi.select_boid_bbox = nil
fi.selected_boids = nil
fi.temp_collision_table = nil

local fi_mt = { __index = fi }
function fi:new(level, parent_flock)
  local fi = setmetatable({}, fi_mt)
  fi.level = level
  fi.flock = parent_flock
  fi.select_boid_bbox = bbox:new(0, 0, 0, 0)
  fi.selected_boids = {}
  fi.temp_collision_table = {}
  
  return fi
end

function fi:keypressed(key)
end
function fi:keyreleased(key)
end
function fi:mousepressed(x, y, button)
  local x, y = self.level:get_mouse():get_coordinates()
  local cx, cy = self.level:get_camera():get_viewport()
  local x, y = x + cx, y + cy

  -- Add boids
  if button == 'l' and lk.isDown("lctrl") then
    -- dont add boid if boids are selected
    local n = 0
    for _,v in pairs(self.selected_boids) do n = n + 1 end
    
    if n == 0 then
      self.left_click_mode = ADD_MODE
      self.left_click_x, self.left_click_y = x, y
    end
  -- Select boids
  elseif button == 'l' then
    self.left_click_mode = SELECT_MODE
    self.left_click_x, self.left_click_y = x, y
  end
  
  -- Clear selected boids
  if button == 'l' and not lk.isDown("lctrl") then
    table.clear_hash(self.selected_boids)
  end
  
  -- set waypoint for selected boids
  if button == 'r' and self.left_click_mode == SELECT_MODE then
    self:_set_waypoint_for_selected_boids(x, y)
  end
end
function fi:mousereleased(x, y, button)
  local x, y = self.level:get_mouse():get_coordinates()
  local cx, cy = self.level:get_camera():get_viewport()
  local x, y = x + cx, y + cy

  -- add boid on release
  if button == 'l' and self.left_click_mode == ADD_MODE then
    if not self.left_click_x or not self.left_click_y then return end
    
    local dx, dy, dz
    if x == self.left_click_x and y == self.left_click_y then
      dx, dy, dz = random_direction3()
    else
      dx, dy, dz = x - self.left_click_x, y - self.left_click_y, 0
      local invlen = 1 / math.sqrt(dx*dx + dy*dy + dz*dz)
      dx, dy, dz = dx * invlen, dy * invlen, dz * invlen
    end
    
    self:add_boid(self.left_click_x, self.left_click_y, nil, dx, dy, dz)
    self.left_click_mode = false
    self.left_click_x, self.left_click_y = nil, nil
    
  -- select boid(s) on release
  elseif button == 'l' and self.left_click_mode == SELECT_MODE then
    if not self.left_click_x or not self.left_click_y then return end
    
    self:_update_select_bboid_preview_bbox()
    local bbox = self.select_boid_bbox
    local dx, dy = bbox.width, bbox.height
    local bbox_size = math.sqrt(dx * dx, dy * dy)
    
    local storage = self.temp_collision_table
    local selected = self.selected_boids
    table.clear(storage)
    if (x == self.left_click_x and y == self.left_click_y) or bbox_size < self.select_boid_radius then
      local r = self.select_boid_radius
      self.flock:get_boids_in_radius(x, y, r, storage)
      local boid = storage[1]
      if boid then
        if selected[boid] then
          selected[boid] = nil
        else
          selected[boid] = boid
        end
      end
    else
      local bbox = self.select_boid_bbox
      self.flock:get_boids_in_bbox(bbox, storage)
      for i=1,#storage do
        selected[storage[i]] = storage[i]
      end
    end
    
    --self.left_click_mode = false
    self.left_click_x, self.left_click_y = nil, nil
  end
end

function fi:add_boid(x, y, z, dx, dy, dz)
  local depth = self.flock:get_bbox().depth
  local z = z or 0.5 * depth + (-1 + 2*math.random()) * self.depth_range
  z = math.min(depth, z)
  z = math.max(0, z)
  
  if self.flock:contains_point(x, y, z) then
    local boid = self.flock:add_boid(x, y, z)
    boid:set_direction(dx, dy, dz)
  end
end

function fi:_set_waypoint_for_selected_boids(x, y)
  -- calculate z as average z of selected boids
  local z = 0
  local count = 0
  for _,b in pairs(self.selected_boids) do
    z = z + b.position.z
    count = count + 1
  end
  if count == 0 then return end
  z = z / count
  
  for _,b in pairs(self.selected_boids) do
    b:set_waypoint(x, y, z)
  end
end

------------------------------------------------------------------------------
function fi:_update_selected_boids(dt)
  if not self.left_click_mode == select then return end
  
  local track_x, track_y = 0, 0
  local count = 0
  for _,b in pairs(self.selected_boids) do
    track_x, track_y = track_x + b.position.x, track_y + b.position.y
    count = count + 1
  end
  if count == 0 then return end
  track_x = track_x / count
  track_y = track_y / count
  
  local target = vector2:new(track_x, track_y)
  local cam = self.level:get_camera()
  --cam:set_target(target, true)
  
  
end

function fi:update(dt)
  if love.mouse.isDown("l") and love.keyboard.isDown("lctrl") then
    local x, y = self.level:get_mouse():get_coordinates()
    local cx, cy = self.level:get_camera():get_viewport()
    local x, y = x + cx, y + cy
    local dx, dy, dz = random_direction3()
    self:add_boid(x, y, nil, dx, dy, dz)
  end
  
  self:_update_selected_boids(dt)
end

------------------------------------------------------------------------------
function fi:_draw_add_boid_preview()
  if self.left_click_mode ~= ADD_MODE then return end
  if not self.left_click_x or not self.left_click_y then return end
  
  local x, y = self.level:get_mouse():get_coordinates()
  local cx, cy = self.level:get_camera():get_viewport()
  local x2, y2 = x + cx, y + cy
  local x1, y1 = self.left_click_x, self.left_click_y 
  local dx, dy = x2 - x1, y2 - y1
  local len = math.sqrt(dx*dx + dy*dy)
  if len > 0 then
    dx, dy = dx / len, dy / len
    local len = 30
    local xm, ym = x1 + len * dx, y1 + len * dy
    lg.setColor(0, 0, 255, 150)
    lg.setLineWidth(2)
    lg.line(x1, y1, xm, ym)
    
  end
  
  lg.setColor(255, 0, 0, 255)
  local r = 3
  lg.circle("fill", x1, y1, r)
  lg.circle("fill", x2, y2, r)
  lg.setLineWidth(1)
  lg.setColor(255, 0, 0, 100)
  lg.line(x1, y1, x2, y2)
end

function fi:_update_select_bboid_preview_bbox()
  if self.left_click_mode ~= SELECT_MODE then return end
  if not self.left_click_x or not self.left_click_y then return end
  
  local x1, y1 = self.left_click_x, self.left_click_y
  local x, y = self.level:get_mouse():get_coordinates()
  local cx, cy = self.level:get_camera():get_viewport()
  local x2, y2 = x + cx, y + cy
  local width, height = math.abs(x2 - x1), math.abs(y2 - y1) 
  
  local bx = math.min(x1, x2)
  local by = math.min(y1, y2)
  local bbox = self.select_boid_bbox
  bbox.x, bbox.y, bbox.width, bbox.height = bx, by, width, height
end

function fi:_draw_select_boid_preview()
  if self.left_click_mode ~= SELECT_MODE then return end
  if not self.left_click_x or not self.left_click_y then return end
  
  self:_update_select_bboid_preview_bbox()
  local bbox = self.select_boid_bbox
  
  lg.setColor(0, 100, 255, 255)
  lg.setLineWidth(1)
  bbox:draw()
  lg.setColor(0, 0, 255, 20)
  bbox:draw("fill")
  
  local storage = self.temp_collision_table
  table.clear(storage)
  self.flock:get_boids_in_bbox(self.select_boid_bbox, storage)
  
  lg.setLineWidth(1)
  lg.setLineStyle("smooth")
  for i=1,#storage do
    local b = storage[i]
    local x, y = b.position.x, b.position.y
    local r = self.select_boid_radius
    lg.setColor(0, 100, 255, 255)
    lg.circle("line", x, y, r)
    lg.setColor(0, 100, 255, 100)
    lg.circle("line", x, y, r - 3)
  end
  
  
end

function fi:_draw_selected_boids()
  
  lg.setLineWidth(1)
  for _,b in pairs(self.selected_boids) do
    local x, y = math.floor(b.position.x), math.floor(b.position.y)
    local r = self.select_boid_radius
    lg.setColor(0, 200, 0, 255)
    lg.circle("line", x, y, r)
    lg.setColor(0, 200, 0, 100)
    lg.circle("line", x, y, r - 3)
    
    if self.debug then
      b:draw_debug()
    end
  end
  
  
end

function fi:draw()

  self:_draw_add_boid_preview()
  self:_draw_select_boid_preview()
  self:_draw_selected_boids()
end

return fi









