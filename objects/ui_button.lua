
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- ui_button object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local uib = {}
uib.table = 'uib'
uib.debug = false
uib.x = nil
uib.y = nil
uib.text_offx = 0
uib.text_offy = 0
uib.bbox = nil
uib.font = nil
uib.gradient = nil
uib.text = nil
uib.id = nil
uib.font_string = nil
uib.string_width = nil
uib.string_height = nil
uib.click_const = 'l'
uib.click_flash_curve =  curve:new(require("curves/button_click_curve"), 300)
uib.click_flash_time = 1
uib.click_flash_power = 1
uib.input_enabled = true
uib.noise_enabled = true

uib.is_highlighted = false
uib.intensity_power_curve = curve:new(require("curves/button_power_curve"), 300)
uib.intensity_meter = nil
uib.intensity_increase_rate = 1
uib.intensity_decrease_rate = -1
uib.intensity_rate = 0
uib.current_itensity = 0
uib.normal_intensity = 0
uib.highlight_intensity = 0

uib.alpha_power_curve = uib.intensity_power_curve
uib.alpha_meter = nil
uib.alpha_increase_rate = 2
uib.alpha_decrease_rate = -2
uib.alpha_rate = uib.alpha_increase_rate
uib.min_alpha = 0
uib.max_alpha = 255
uib.current_crossfade_power = 1

uib.lower_noise_range = 0.2
uib.upper_noise_range = 0.5
uib.noise_vx = 0
uib.noise_vy = 0.6
uib.noise_vz = -0.4
uib.noise_scale = 0.01

-- callbacks
uib.on_enter = nil
uib.on_exit = nil
uib.on_click = nil
uib.on_hover = nil
uib.on_release = nil
uib.callback_object = nil

--[[
  button_data in form:
   {font = game_font object,
    gradient = game_font gradient key
    text = display text string,
    id = identifier for callbacks,
    mouse = mouse_input object}
]]--

local uib_mt = { __index = uib }
function uib:new(button_data, x, y, width, height)
  local uib = setmetatable({}, uib_mt)
  uib.bbox = bbox:new(x, y, width, height)
  uib.x, uib.y = x, y
  uib.font = button_data.font
  uib.text = button_data.text
  uib.gradient = button_data.gradient
  uib.id = button_data.id
  uib.mouse = button_data.mouse
  
  uib.font_string = game_font_string:new(uib.font, uib.text)
  uib.font_string:set_noise_speed(self.noise_vx, self.noise_vy, self.noise_vz)
  uib.font_string:set_noise_ranges(uib.lower_noise_range,
                                   uib.upper_noise_range)
  uib.font_string:load()
  uib.font_string:set_gradient(uib.gradient)
  uib.intensity_meter = power_meter:new()
  uib.intensity_meter:set_power_curve(uib.intensity_power_curve)
  
  uib.alpha_meter = power_meter:new()
  uib.alpha_meter:set_power_curve(uib.alpha_power_curve)
  uib.alpha_meter:set_power_level(1)
  
  return uib
end

function uib:mousepressed(x, y, button)
  if not self.input_enabled then return end

  if button == self.click_const and self.bbox:contains_coordinate(x, y) then
    self:_mouse_click(x, y, button)
  end
end

function uib:mousereleased(x, y, button)
  if not self.input_enabled then return end

  if button == self.click_const and self.bbox:contains_coordinate(x, y) then
    self:_mouse_release(x, y, button)
  end
end

function uib:set_width(width) self.bbox.width = width end
function uib:set_height(height) self.bbox.height = height end

function uib:get_text_width()
  return self.font_string:get_width()
end

function uib:get_text_height()
  return self.font_string:get_height()
end

function uib:set_position(x, y)
  self.x, self.y = x, y
  self.bbox.x, self.bbox.y = x, y
end

function uib:set_noise_ranges(lower_range, upper_range)
  self.font_string:set_noise_ranges(lower_range, upper_range)
  self.lower_noise_range = lower_range
  self.upper_noise_range = upper_range
end

function uib:set_noise_speed(vx, vy, vz)
  self.noise_vx, self.noise_vy, self.noise_vz = vx, vy, vz
  self.font_string:set_noise_speed(vx, vy, vz)
end

function uib:set_noise_scale(nscale)
  self.noise_scale = nscale
  self.font_string:set_noise_scale(nscale)
end

function uib:translate(tx, ty)
  self:set_position(self.x + tx, self.y + ty)
end

function uib:get_position()
  return self.x, self.y
end

function uib:set_dimensions(x, y, width, height)
  self.x, self.y = x, y
  self.bbox.x, self.bbox.y = x, y
  self.bbox.width, self.bbox.height = width, height
end

function uib:set_text_offset(offx, offy)
  self.text_offx, self.text_offy = offx, offy
end

function uib:center_text()
  self.text_offx = 0.5 * self.bbox.width - 0.5 * self:get_text_width()
  self.text_offy = 0.5 * self.bbox.height - 0.5 * self:get_text_height()
end

function uib:disable_input() self.input_enabled = false end
function uib:enable_input() self.input_enabled = true end
function uib:disable_noise() self.noise_enabled = false
                             self.font_string:turn_noise_off() end
function uib:enable_noise() self.noise_enabled = true end

function uib:hide(hide_immediatly) 
  self.alpha_rate = self.alpha_decrease_rate
  self.font_string:turn_noise_off()
  
  if hide_immediatly then
    self.alpha_meter:set_power_level(0)
  end
end
function uib:show(show_immediately) 
  self.alpha_rate = self.alpha_increase_rate
  if show_immediatly then
    self.alpha_meter:set_power_level(1)
  end
end

function uib:set_gradient(gradient_name)
  self.font_string:set_gradient(gradient_name)
end

function uib:set_intensities(normal, highlight)
  self.normal_intensity = normal
  self.highlight_intensity = highlight
end

function uib:set_intensity_rates(decrease, increase)
  self.intensity_increase_rate = increase
  self.intensity_decrease_rate = decrease
end

function uib:set_alpha_rates(decrease, increase)
  self.alpha_increase_rate = increase
  self.alpha_decrease_rate = decrease
end

function uib:set_alpha_range(min_alpha, max_alpha)
  self.min_alpha, self.max_alpha = min_alpha, max_alpha
end

function uib:set_crossfade(power, length, curve)
  self.font_string:set_crossfade(power, length, curve)
  self.current_crossfade_power = power
end

function uib:turn_noise_animation_on()
 self.noise_animation_playing = true
end

function uib:turn_noise_animation_off()
  self.noise_animation_playing = false
  if not self.is_highlighted then
    self.font_string:turn_noise_off()
  end
end

function uib:flash()
  self.font_string:flash(self.click_flash_power, 
                         self.click_flash_time, 
                         self.click_flash_curve)
end

function uib:get_intensity()
  return self.current_intensity
end


function uib:set_callback_object(obj) self.callback_object = obj end
function uib:set_on_enter_action(func) self.on_enter = func end
function uib:set_on_exit_action(func) self.on_exit = func end
function uib:set_on_click_action(func) self.on_click = func end
function uib:set_on_release_action(func) self.on_release = func end

-- action is exectued every frame if mouse if hovering over button
function uib:set_on_hover_action(func) self.on_hover = func end

-- left button by default
function uib:set_click_button(key_const) self.click_const = key_const end

function uib:_mouse_enter()
  self.intensity_rate = self.intensity_increase_rate  
  
  if not self.noise_animation_playing and self.noise_enabled then
    self.font_string:turn_noise_on()
  end
  
  if self.on_enter then
    if self.callback_object then
      self.on_enter(self.callback_object, self.id)
    else
      self.on_enter(self.id)
    end
  end
end

function uib:_mouse_exit()
  self.intensity_rate = self.intensity_decrease_rate
  
  if not self.noise_animation_playing then
    self.font_string:turn_noise_off()
  end
  
  if self.on_exit then
    if self.callback_object then
      self.on_exit(self.callback_object, self.id)
    else
      self.on_exit(self.id)
    end
  end
end

function uib:_mouse_click(x, y, button)
  self.font_string:flash(self.click_flash_power, 
                         self.click_flash_time, 
                         self.click_flash_curve)  
  if self.on_click then
    if self.callback_object then
      self.on_click(self.callback_object, self.id, x, y, button)
    else
      self.on_click(self.id, x, y, button)
    end
  end
end

function uib:_mouse_release(x, y, button)

  if self.on_release then
    if self.callback_object then
      self.on_release(self.callback_object, self.id, x, y, button)
    else
      self.on_release(self.id, x, y, button)
    end
  end
end

function uib:_mouse_hover(x, y)

  if self.on_hover then
    if self.callback_object then
      self.on_hover(self.callback_object, self.id, x, y)
    else
      self.on_hover(self.id, x, y)
    end
  end
end

function uib:_update_highlight_status(dt)
  if not self.input_enabled then return end

  local mpos = self.mouse:get_position()
  local is_highlighted = self.bbox:contains_point(mpos)
  if self.is_highlighted ~= is_highlighted then
    if is_highlighted then
      self:_mouse_enter()
    else
      self:_mouse_exit()
    end
  end
  
  self.is_highlighted = is_highlighted
  if self.is_highlighted then
    local mpos = self.mouse:get_position()
    self:_mouse_hover(mpos.x, mpos.y)
  end
  
  if self.noise_animation_playing and self.noise_enabled then
    self.font_string:turn_noise_on()
  end
end

function uib:_update_intensity(dt)
  self.intensity_meter:set_base_rate(self.intensity_rate)
  self.intensity_meter:update(dt)
  local power = self.intensity_meter:get_power_level()
  local min, max = self.normal_intensity, self.highlight_intensity
  self.current_intensity  = lerp(min, max, power)
  self.font_string:set_intensity(self.current_intensity)
end

function uib:_update_alpha(dt)
  self.alpha_meter:set_base_rate(self.alpha_rate)
  self.alpha_meter:update(dt)
  local power = self.alpha_meter:get_power_level()
  local min, max = self.min_alpha, self.max_alpha
  self.font_string:set_alpha(lerp(min, max, power))
end

------------------------------------------------------------------------------
function uib:update(dt)
  self:_update_highlight_status(dt)
  self:_update_intensity(dt)
  self:_update_alpha(dt)

  self.font_string:update(dt)
end

------------------------------------------------------------------------------
function uib:draw()

  local offx, offy = self.text_offx, self.text_offy
  self.font_string:draw(self.x + offx, self.y + offy)

  if not self.debug then return end
  
  lg.setLineWidth(1)
  lg.setColor(255, 0, 0, 255)
  if self.is_highlighted then
    lg.setColor(0, 255, 0, 255)
  end
  lg.rectangle("line", self.x, self.y, self.bbox.width, self.bbox.height)
end

return uib



