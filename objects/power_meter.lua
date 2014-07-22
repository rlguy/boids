
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- power_meter object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local pm = {}
pm.table = 'pm'
pm.debug = true
pm.scale = 1
pm.level = 0
pm.curve_level = 0
pm.min_level = 0
pm.max_level = 1
pm.upper_level = pm.max_level
pm.lower_level = pm.min_level
pm.free_power_rates = nil
pm.active_power_rates = nil
pm.base_rate = 0
pm.direction = 1
pm.added_power = 0
pm.default_power_curve = curve:new(require("curves/linear_curve"))
pm.power_curve = pm.default_power_curve

pm.unique_rate_id = 1

local pm_mt = { __index = pm }
function pm:new()
  local pm = setmetatable({}, pm_mt)
  
  pm.active_power_rates = {}
  pm.free_power_rates = {}
  
  return pm
end

function pm:set_scale(scale)
  self.scale = scale
end

function pm:get_power_level()
  return self.scale * self.curve_level
end

function pm:set_base_rate(r)
  r = r * (1/self.scale)
  self.base_rate = r
end

function pm:set_power_level(clevel)
  clevel = clevel * (1/self.scale)

  clevel = math.min(self.max_level, clevel)
  clevel = math.max(self.min_level, clevel)
  
  local progress = self.power_curve:get_x(clevel)
  self.curve_level = clevel
  
  if progress - self.level >= 0 then
    self:_change_direction(1)
  else
    self:_change_direction(-1)
  end
  
  self.level = progress
end

function pm:add_power(value)
  value = value * (1/self.scale)
  self.added_power = self.added_power + value
end

function pm:add_power_rate(rate, time)
  rate = rate * (1/self.scale)
  local new_rate = self:_new_power_rate(rate, time)
  local id = new_rate.id
  self.active_power_rates[id] = new_rate
  return id
end

function pm:remove_power_rate(id)
  local active, free = self.active_power_rates, self.free_power_rates
  local rate = active[id]
  active[id] = nil
  free[#free + 1] = rate
end

function pm:set_power_curve(curve)
  self.power_curve = curve
end

function pm:_new_power_rate(rate_value, time)
  if #self.free_power_rates == 0 then
    self.free_power_rates[1] = {}
  end
  local rate = self.free_power_rates[#self.free_power_rates]
  self.free_power_rates[#self.free_power_rates] = nil
  
  if not rate.id then
    rate.id = self:_gen_rate_id()
  end
  rate.value = rate_value
  rate.current_time = 0
  rate.lifetime = time
  
  return rate
end

function pm:_gen_rate_id()
  local unique_id = self.unique_rate_id
  self.unique_rate_id = self.unique_rate_id + 1
  return unique_id
end

function pm:_update_power_level(dt)
  local added_power = self.added_power
  local rates = self.active_power_rates
  for id,rate in pairs(rates) do
    if rate.lifetime then
      rate.current_time = rate.current_time + dt
      if rate.current_time > rate.lifetime then
        self:remove_power_rate(rate.id)
      end
    end
    
    added_power = added_power + rate.value * dt
  end
  added_power = added_power + self.base_rate * dt
  
  local new_level = self.level + added_power
  new_level = math.min(self.max_level, new_level)
  new_level = math.max(self.min_level, new_level)

  local diff = new_level - self.level
  local changed_direction = false
  if self.direction == 1 and diff < 0 then
    changed_direction = true
    self:_change_direction(-1)
  elseif self.direction == -1 and diff >= 0 then
    changed_direction = true
    self:_change_direction(1)
  end
  
  self.level = new_level
    
  self.added_power = 0
end

function pm:_change_direction(new_direction)
  if new_direction == self.direction then
    return
  end

  if     new_direction == 1 then
    self.direction = 1
    self.lower_level = self.level
    self.upper_level = self.max_level
  elseif new_direction == -1 then
    self.direction = -1
    self.upper_level = self.level
    self.lower_level = self.min_level
  end
end

function pm:_update_curve_level(dt)
  
  local diff = (self.max_level - self.min_level)
  local prog = (self.level - self.min_level) / diff
  self.curve_level = self.min_level + self.power_curve:get(prog) * diff
  
end

------------------------------------------------------------------------------
function pm:update(dt)
  self:_update_power_level(dt)
  self:_update_curve_level(dt)
end

------------------------------------------------------------------------------
function pm:draw(x, y)
  if not self.debug then return end
  
  x = x or 0
  y = y or 0
  
  -- linear level
  local height = 200
  local width = 50
  local rx, ry = x, y
  local progress = self.level / self.max_level
  local lheight = height * progress
  local lx, ly = x, y + (height - lheight)
  lg.setColor(0, 255, 0, 255)
  lg.rectangle("fill", lx, ly, width, lheight)
  
  lg.setColor(255, 255, 255, 255)
  lg.setLineWidth(3)
  lg.rectangle("line", rx, ry, width, height)
  
  local uprog = self.upper_level / self.max_level
  local uy = y + height - height * uprog
  local w = 100
  lg.setColor(0, 255, 0, 255)
  lg.line(rx + width, uy, rx + width + w, uy)
  
  local lprog = self.lower_level / self.max_level
  local ly = y + height - height * lprog
  local w = 100
  lg.setColor(255, 0, 0, 255)
  lg.line(rx + width, ly, rx + width + w, ly)
  
  -- curve level
  local height = 200
  local width = 50
  local rx, ry = x + 300, y
  local progress = self.curve_level / self.max_level
  local lheight = height * progress
  local lx, ly = rx, y + (height - lheight)
  lg.setColor(0, 255, 0, 255)
  lg.rectangle("fill", lx, ly, width, lheight)
  
  lg.setColor(255, 255, 255, 255)
  lg.setLineWidth(3)
  lg.rectangle("line", rx, ry, width, height)
  
end

return pm







