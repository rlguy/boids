
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- ui_text_input object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local uti = {}
uti.table = 'uti'
uti.debug = false
uti.x = nil
uti.y = nil
uti.bbox = nil

uti.font = nil
uti.gradient = nil
uti.text = nil
uti.cursor_text = nil
uti.id = nil
uti.size = nil
uti.mouse_input = nil

uti.min_intensity = 0.8
uti.max_intensity = 1
uti.min_alpha = 130
uti.max_alpha = 255
uti.alpha_increase_rate = 5
uti.alpha_decrease_rate = -6
uti.intensity_decrease_rate = -8
uti.intensity_increase_rate = 8
uti.box_button = nil

uti.display_cursor = true
uti.cursor_button = nil
uti.cursor_offx = 15
uti.cursor_start_x = nil
uti.cursor_start_y = nil
uti.cursor_min_intensity = 0
uti.cursor_max_intensity = 0.75
uti.cursor_intensity_decrease_rate = -4
uti.cursor_intensity_increase_rate = 16
uti.cursor_pulse_rate = 1
uti.cursor_pulse_time = 0.5
uti.cursor_current_time = 0
uti.cursor_alpha_decrease_rate = -8
uti.cursor_alpha_increase_rate = 8
uti.is_cursor_powering_up = false

uti.backspace_character_constant = "backspace"
uti.input_chars = nil
uti.input_char_buttons = nil
uti.input_string = ""
uti.char_intensity = 1
uti.char_button_offx = -2
uti.char_button_offy = 0
uti.char_lower_noise_range = 0
uti.char_upper_noise_range = 0.2

uti.noise_vx = 0
uti.noise_vy = 0.2
uti.noise_vz = -0.2

uti.is_active = false
uti.is_hidden = false

uti.accepted_chars = nil
uti.callback_object = nil
uti.on_valid_character_action = nil
uti.on_invalid_character_action = nil
uti.on_character_delete_action = nil

--[[
  input_data in form:
    { font = game_font,
    gradient = gradient_key,
    text = "Box outline text string",
    cursor_text = "cursor_character",
    id = reference_key,
    size = max_input_length,
    char_constants = {"a", "b", "c", "d", "e", ...},  -- acceptable input chars
    mouse = mouse_input
]]--
local uti_mt = { __index = uti }
function uti:new(input_data, x, y, width, height)
  local uti = setmetatable({}, uti_mt)
  uti.x, uti.y = x, y
  uti.bbox = bbox:new(x, y, width, height)
  uti.font = input_data.font
  uti.gradient = input_data.gradient
  uti.text = input_data.text
  uti.cursor_text = input_data.cursor_text
  uti.id = input_data.id
  uti.size = input_data.size
  uti.mouse_input = input_data.mouse
  uti.accepted_chars = input_data.char_constants
  uti.input_chars = {}
  uti.input_char_buttons = {}
  
  uti:_init_box()
  uti:_init_cursor()
  
  return uti
end

function uti:_init_box()
  local x, y, width, height = self.x, self.y, self.bbox.width, self.bbox.height
  
  local bdata = {font = self.font,
                 gradient = self.gradient,
                 text = self.text,
                 id = self.id,
                 mouse = self.mouse_input}
  local box = ui_button:new(bdata, 0, 0, 0, 0)
  local str_width, str_height = box:get_text_width(), box:get_text_height()
  local bx = x + 0.5 * self.bbox.width - 0.5 * str_width
  local by = y + 0.5 * self.bbox.height - 0.5 * str_height
  box:set_dimensions(bx, by, str_width, str_height)
  box:set_intensities(self.min_intensity, self.max_intensity)
  box:set_intensity_rates(self.intensity_decrease_rate,
                          self.intensity_increase_rate)
  box.font_string:set_noise_speed(self.noise_vx, self.noise_vy, self.noise_vz)
  box:set_alpha_range(self.min_alpha, self.max_alpha)
  box:set_alpha_rates(self.intensity_decrease_rate,
                      self.intensity_increase_rate)
  
  self.box_button = box
end

function uti:_init_cursor()
  local x, y, width, height = self.x, self.y, self.bbox.width, self.bbox.height

  local bdata = {font = self.font,
                 gradient = self.gradient,
                 text = self.cursor_text,
                 id = self.id,
                 mouse = self.mouse_input}
  local cursor = ui_button:new(bdata, 0, 0, 0, 0)
  local str_width, str_height = cursor:get_text_width(), cursor:get_text_height()
  local cx = self.box_button.x + self.cursor_offx
  local cy = y + 0.5 * self.bbox.height - 0.5 * str_height
  cursor:set_dimensions(cx, cy, str_width, str_height)
  cursor:set_intensities(self.cursor_min_intensity, self.cursor_max_intensity)
  cursor:set_intensity_rates(self.cursor_intensity_decrease_rate,
                             self.cursor_intensity_increase_rate)
  cursor:set_alpha_rates(self.cursor_alpha_decrease_rate,
                         self.cursor_alpha_increase_rate)
  cursor:disable_input()
  cursor:hide()
  
  self.cursor_start_x, self.cursor_start_y = cx, cy

  self.cursor_button = cursor
end

function uti:_new_character_button(char_const)
  local x, y = self.cursor_button.x + self.char_button_offx

  local bdata = {font = self.font,
                 gradient = self.gradient,
                 text = char_const,
                 id = char_const,
                 mouse = self.mouse_input}
  local btn = ui_button:new(bdata, 0, 0, 0, 0)
  local str_width, str_height = btn:get_text_width(), btn:get_text_height()
  local x = self.cursor_button.x + self.char_button_offx
  local y = self.y + 0.5 * self.bbox.height - 0.5 * str_height + self.char_button_offy
  btn:set_dimensions(x, y, str_width, str_height)
  btn:set_intensities(self.char_intensity, self.char_intensity)
  btn:flash()
  btn:set_noise_ranges(self.char_lower_noise_range, self.char_upper_noise_range)
  btn:set_alpha_range(self.min_alpha, self.max_alpha)
  btn:set_alpha_rates(self.intensity_decrease_rate,
                      self.intensity_increase_rate)
  btn:turn_noise_animation_on()
  --btn:disable_input()
 
  
  return btn
end

function uti:keypressed(key)
  if not self.is_active then return end
  if self.is_hidden then return end
  
  if key == self.backspace_character_constant then
    self:_handle_character_removal(key)
    return
  end
  
  local accepted = table.contains(self.accepted_chars, key)
  if not accepted or #self.input_chars == self.size then
    if self.on_invalid_character_action then
      if self.callback_object then
        self.on_invalid_character_action(self.callback_object, self.id, key)
      else
        self.on_invalid_character_action(self.id, key)
      end
    end
  elseif accepted then
    self:_handle_character_input(key)
  end
  
end

function uti:keyreleased(key)
  if not self.is_active then return end
end

function uti:mousepressed(x, y, button)
  self.box_button:mousepressed(x, y, button)
  
  if self.is_hidden then return end
  
  if self.box_button.bbox:contains_coordinate(x, y) then
    if not self.is_active then
      self:_activate()
    end
  else
    if self.is_active then
      self:_deactivate()
    end
  end
end
function uti:mousereleased(x, y, button)
  self.box_button:mousereleased(x, y, button)
end

function uti:_activate()
  self.is_active = true
  self.cursor_button:show()
  
  self.cursor_current_time = 0
  self.is_current_powering_up = false
end

function uti:_deactivate()
  self.is_active = false
  self.cursor_button:hide()
end

function uti:_handle_character_removal(key)
  if #self.input_chars == 0 then  -- nothing to delete
    if self.on_invalid_character_action then
      if self.callback_object then
        self.on_invalid_character_action(self.callback_object, self.id, key)
      else
        self.on_invalid_character_action(self.id, key)
      end
    end
    return
  end

  -- pop last char
  local char = self.input_chars[#self.input_chars]
  self.input_chars[#self.input_chars] = nil
  self.input_char_buttons[#self.input_char_buttons] = nil
  self.display_cursor = true
  
  -- compute input string
  local str = ""
  for i=1,#self.input_chars do
    str = str..self.input_chars[i]
  end
  self.input_string = str
  
  -- position cursor
  local x, y
  if #self.input_chars > 0 then
    local char_button = self.input_char_buttons[#self.input_char_buttons]
    x, y = char_button.x + char_button.bbox.width, self.cursor_button.y
  else
    x, y = self.cursor_start_x, self.cursor_start_y
  end
  self.cursor_button:set_position(x, y)
  
  if self.on_invalid_character_action then
    if self.callback_object then
      self.on_character_delete_action(self.callback_object, self.id, key)
    else
      self.on_character_delete_action(self.id, char)
    end
  end
end

function uti:_handle_character_input(key)
  local char_button = self:_new_character_button(key)
  self.input_chars[#self.input_chars + 1] = key
  self.input_char_buttons[#self.input_char_buttons + 1] = char_button
  
  if #self.input_chars == self.size then
    self.display_cursor = false
  end
  
  local str = ""
  for i=1,#self.input_chars do
    str = str..self.input_chars[i]
  end
  self.input_string = str
  
  -- move cursor
  local x, y = char_button.x + char_button.bbox.width, self.cursor_button.y
  self.cursor_button:set_position(x, y)
  
  if self.on_valid_character_action then
    if self.callback_object then
      self.on_valid_character_action(self.callback_object, self.id, key)
    else
      self.on_valid_character_action(self.id, key)
    end
  end
  
end

function uti:hide()
  self.box_button:hide()
  self.box_button:disable_input()
  self.cursor_button:hide()
  
  for i=1,#self.input_char_buttons do
    self.input_char_buttons[i]:hide()
  end
  
  self.is_hidden = true
end

function uti:show()
  self.box_button:show()
  self.box_button:enable_input()
  
  if self.is_active then
    self.cursor_button:show()
  end
  
  for i=1,#self.input_char_buttons do
    self.input_char_buttons[i]:show()
  end
  
  self.is_hidden = false
end

function uti:get_input_string()
  return self.input_string
end

function uti:set_callback_object(obj)
  self.callback_object = obj
end

function uti:set_on_valid_character_action(func)
  self.on_valid_character_action = func
end
function uti:set_on_invalid_character_action(func)
  self.on_invalid_character_action = func
end
function uti:set_on_character_delete_action(func)
  self.on_character_delete_action = func
end

function uti:_update_cursor(dt)

  if self.is_active then
    self.cursor_current_time = self.cursor_current_time + dt
    local total_time = (1 / self.cursor_pulse_rate)
    if self.cursor_current_time > total_time then
      self.cursor_current_time = self.cursor_current_time - total_time
    end
    local time = self.cursor_current_time
    
    local is_powering = self.is_cursor_powering_up
    if time < self.cursor_pulse_time then
      self.is_cursor_powering_up = true
    else
      self.is_cursor_powering_up = false
    end
    
    if is_powering ~= self.is_cursor_powering_up then
      if self.is_cursor_powering_up then  -- start hover
        self.cursor_button:_mouse_enter()
      else  -- end hover
        self.cursor_button:_mouse_exit()
      end
    end
  end

  self.cursor_button:update(dt)
end

function uti:_update_input_chars(dt)

  for i=1,#self.input_char_buttons do
    self.input_char_buttons[i]:update(dt)
  end
end

------------------------------------------------------------------------------
function uti:update(dt)
  self:_update_input_chars(dt)
  self:_update_cursor(dt)

  self.box_button:update(dt)
end

function uti:_draw_input_chars(dt)

  for i=1,#self.input_char_buttons do
    self.input_char_buttons[i]:draw()
  end
end

------------------------------------------------------------------------------
function uti:draw()

  self.box_button:draw()
  self:_draw_input_chars()
  
  if self.display_cursor then
    self.cursor_button:draw()
  end

  if not self.debug then return end
  
  lg.setColor(0, 255, 0, 255)
  self.bbox:draw()
end

return uti



