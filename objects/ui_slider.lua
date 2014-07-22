
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- ui_slider object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local us = {}
us.table = 'us'
us.debug = false
us.x = nil
us.y = nil
us.bbox = nil

us.font = nil
us.gradient = nil
us.id = nil
us.mouse_input = nil
us.text = nil
us.click_button_constant = "l"
us.is_mouse_focused = false

us.text_button = nil
us.text_slider = nil
us.slider_x = nil
us.slider_y = nil
us.crossfade_length = 1

us.min_intensity = nil
us.max_intensity = nil

us.slider_value = 0
us.min_slider_value = 0
us.max_slider_value = 1

us.callback_object = nil
us.on_value_change = nil

us.click_flash_curve = curve:new(require("curves/button_click_curve"), 300)
us.click_flash_time = 1
us.click_flash_power = 0.2

us.min_button_intensity = 0.6
us.max_button_intensity = 1
us.intensity_decrease_rate = -8
us.intensity_increase_rate = 8
us.min_noise_range = 0.4
us.max_noise_range = 0.4
us.min_intensity_range = 0.3
us.max_intensity_range = 1
us.noise_scale = 0.05
us.nvx = 0.5
us.nvy = 0.5
us.nvz = 0.1

local LEFT, RIGHT = 0, 1
us.is_crossfading = false
us.crossfade_progress = 0
us.crossfade_direction = nil
us.crossfade_animation_curve = curve:new(require("curves/ui_slider_curve", 300))
us.min_crossfade = nil
us.max_crossfade = nil
us.crossfade_speed = 600
us.current_crossfade_position = 0

--[[
  slider_data in form:
  { font = game_font object,
    gradient = gradient key,
    text = text string,
    id = identifier,
    mouse = mouse_input object,
    min_intensity = [0,1] value,
    max_intensity = [0,1] value }
]]--
local us_mt = { __index = us }
function us:new(slider_data, x, y, width, height)
  local us = setmetatable({}, us_mt)
  
  us.x, us.y = x, y
  us.bbox = bbox:new(x, y, width, height)
  us.font = slider_data.font
  us.gradient = slider_data.gradient
  us.text = slider_data.text
  us.id = slider_data.id
  us.mouse_input = slider_data.mouse
  us.min_intensity = slider_data.min_intensity
  us.max_intensity = slider_data.max_intensity
  
  us:_init_slider()
  
  return us
end

function us:_init_slider()
  
  -- dummy button
  local bdata = {font = self.font,
                 gradient = self.gradient,
                 text = self.text,
                 id = self.id,
                 mouse = self.mouse_input}
  local button = ui_button:new(bdata, 0, 0, 0, 0)
  local str_width = button:get_text_width()
  local str_height = button:get_text_height()
  local x = self.x + 0.5 * self.bbox.width - 0.5 * str_width
  local y = self.y
  local offy = 0.5 * self.bbox.height - 0.5 * str_height
  button:set_dimensions(x, y, str_width, self.bbox.height)
  button:set_intensities(self.min_button_intensity, self.max_button_intensity)
  button:set_intensity_rates(self.intensity_decrease_rate, self.intensity_increase_rate)
  button:set_text_offset(0, offy)
  button:disable_noise()
  button:set_alpha_range(0, 0)
  button:set_callback_object(self)
  button:set_on_click_action(self._slider_clicked)
  button:set_on_enter_action(function() self.text_slider:turn_noise_on() end)
  button:set_on_exit_action(function() self.text_slider:turn_noise_off() end)
  
  self.text_button = button
  
  -- slider graphic
  local text_slider = game_font_string:new(self.font, self.text)
  text_slider:set_noise_ranges(self.min_noise_range, self.max_noise_range)
  text_slider:set_intensity_range(self.min_intensity_range, self.max_intensity_range)
  text_slider:set_noise_scale(self.noise_scale)
  text_slider:set_noise_speed(self.nvx, self.nvy, self.nvz)
  text_slider:load()
  text_slider:set_intensity(self.max_intensity)
  text_slider:set_gradient(self.gradient)
  self.text_slider = text_slider
  self.slider_x = x
  self.slider_y = self.y + 0.5 * self.bbox.height - 0.5 * str_height
end

function us:mousepressed(x, y, button)
  self.text_button:mousepressed(x, y, button)
end
function us:mousereleased(x, y, button)
  self.text_button:mousereleased(x, y, button)
  self.is_mouse_focused = false
  
  if not self.bbox:contains_coordinate(x, y) then
    self.text_slider:turn_noise_off()
  end
end

function us:_slider_clicked(id, x, y, button)
  local min_x = self.slider_x
  local max_x = self.slider_x + self.text_slider:get_width()
  local progress = (x - min_x) / (max_x - min_x)
  local last_crossfade_progress = self.crossfade_progress
  self.crossfade_progress = progress
  self.text_slider:flash(self.click_flash_power, 
                         self.click_flash_time, 
                         self.click_flash_curve)
  
  local min, max = self.min_slider_value, self.max_slider_value
  local new_value = lerp(min, max, progress)
  
  if new_value ~= self.slider_value then
    self.slider_value = lerp(min, max, progress)
    self:_value_changed()
  end
  
  self.is_mouse_focused = true
  
  -- setup crossfade animation
  if progress == self.last_crossfade_progress then
    return
  end
  
  self.is_crossfading = true
  self.current_crossfade_position = 0
  if progress > last_crossfade_progress then  -- moving right
    self.min_crossfade = last_crossfade_progress
    self.max_crossfade = progress
    self.crossfade_direction = RIGHT
  else  -- moving left
    self.min_crossfade = progress
    self.max_crossfade = last_crossfade_progress
    self.crossfade_direction = LEFT
  end
end

function us:_slider_hover()
    
  local x, y = self.mouse_input:get_coordinates()
  local min_x = self.slider_x
  local max_x = self.slider_x + self.text_slider:get_width()
  local progress = (x - min_x) / (max_x - min_x)
  self.crossfade_progress = progress
  self.text_slider:set_crossfade(progress, self.crossfade_length)
  
  local min, max = self.min_slider_value, self.max_slider_value
  local new_value = lerp(min, max, progress)
  
  if new_value ~= self.slider_value then
    self.is_crossfading = false
    self.slider_value = lerp(min, max, progress)
    self:_value_changed()
  end
  
  self.text_slider:turn_noise_on()
end

function us:_value_changed()
  if not self.on_value_change then return end
  
  if self.callback_object then
    self.on_value_change(self.callback_object, self.id, self.slider_value)
  else
    self.on_value_change(self.id, self.slider_value)
  end
end

function us:set_callback_object(obj)
  self.callback_object = obj
end

function us:set_on_value_change_action(func)
  self.on_value_change = func
end

function us:set_value(value)
  local min, max = self.min_slider_value, self.max_slider_value
  value = math.min(max, value)
  value = math.max(min, value)
  local progress = (value - min) / (max - min)
  self.crossfade_progress = progress
  self.text_slider:set_crossfade(progress, self.crossfade_length)
  
  self.slider_value = value
end

function us:get_value()
  return self.slider_value
end

function us:set_range(min, max)
  local mino, maxo = self.min_slider_value, self.max_slider_value
  local curr = self.slider_value
  local progress = (curr - mino) / (maxo - mino)

  self.min_slider_value = min
  self.max_slider_value = max
  self:set_value(lerp(min, max, progress))
end

function us:_update_crossfade(dt)
  local speed = self.crossfade_speed
  local min, max = self.min_crossfade, self.max_crossfade
  local len = self.text_button.bbox.width
  local min_x, max_x = math.floor(min * len), math.floor(max * len)
  
  if min_x == max_x then 
    self.is_crossfading = false
    return
  end
  
  self.current_crossfade_position = self.current_crossfade_position + speed * dt
  if self.current_crossfade_position > max_x - min_x then
    self.current_crossfade_position = max_x - min_x
    self.is_crossfading = false
  end
  
  local min, max = self.min_crossfade, self.max_crossfade
  local progress = self.current_crossfade_position / (max_x - min_x)
  progress = self.crossfade_animation_curve:get(progress) 
  if self.crossfade_direction == LEFT then
    progress = 1 - progress
  end
  local fade_progress = lerp(min, max, progress)
  self.text_slider:set_crossfade(fade_progress, self.crossfade_length)
end

------------------------------------------------------------------------------
function us:update(dt)
  if self.is_mouse_focused then
    self:_slider_hover(dt)
  end

  if self.is_crossfading then
    self:_update_crossfade(dt)
  end
  self.text_slider:set_intensity(self.text_button:get_intensity())
  
  self.text_button:update(dt)
  self.text_slider:update(dt)
  
end

------------------------------------------------------------------------------
function us:draw()

  self.text_button:draw()
  self.text_slider:draw(self.slider_x, self.slider_y)

  if not self.debug then return end
  
  lg.setColor(0, 255, 0, 255)
  self.bbox:draw()
end

return us



