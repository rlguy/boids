
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- ui_option_switch object - horizontal toggle to switch between options
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local LEFT = 0
local RIGHT = 1

local uis = {}
uis.table = 'uis'
uis.debug = false
uis.input_enabled = true
uis.is_focused = false
uis.x = nil
uis.y = nil
uis.bbox = nil

uis.font = nil
uis.gradient_key = nil
uis.mouse_input = nil

uis.text_buttons = nil
uis.left_button = nil
uis.right_button = nil
uis.left_button_char = "<"
uis.right_button_char = ">"
uis.toggle_button_width = 40
uis.toggle_button_text_offx = 7
uis.toggle_button_text_offy = 7
uis.toggle_button_min_intensity = 0.6
uis.toggle_button_max_intensity = 1
uis.toggle_button_increase_rate = 8
uis.toggle_button_decrease_rate = -8
uis.toggle_button_min_alpha = 80
uis.toggle_button_max_alpha = 255
uis.toggle_button_alpha_decrease_rate = -6
uis.toggle_button_alpha_increase_rate = 6
uis.button_alpha_increase_rate = 8
uis.button_alpha_decrease_rate = -20

uis.right_char_constants = nil
uis.left_char_constants = nil
uis.click_button_constant = "l"

uis.current_option_idx = 1

uis.on_value_change = nil
uis.callback_object = nil

--[[
  option_data in form:
  { font = game_font object,
    gradient = game_font gradient key,
    id = identifier for callbacks,
    mouse = mouse_input object,
    options = {table of options}}

  option in form:
  { text = string,
    gradient = gradient key,
    id = identifier,
    intensity = [0,1] intensity value
  }
  
]]--
local uis_mt = { __index = uis }
function uis:new(option_data, x, y, width, height)
  local uis = setmetatable({}, uis_mt)
  
  uis.x, uis.y = x, y
  uis.bbox = bbox:new(x, y, width, height)
  uis.font = option_data.font
  uis.gradient_key = option_data.gradient
  uis.mouse_input = option_data.mouse
  uis.id = option_data.id
  
  uis:_init_options(option_data.options)
  uis:_init_toggle_buttons()
  
  return uis
end

function uis:_init_options(options)
  local adec = self.button_alpha_decrease_rate
  local ainc = self.button_alpha_increase_rate
  local min_x, max_x = self.x, self.x + self.bbox.width
  local str_height = self.font:get_char(self.left_button_char):get_height()
  local y = self.y + 0.5 * self.bbox.height - 0.5 * str_height
  local default_idx = self.current_option_idx

  -- init text buttons
  local buttons = {}
  for i=1,#options do
    local data = options[i]
    local bdata = {font = self.font,
                   gradient = data.gradient,
                   text = data.text,
                   id = data.id,
                   mouse = self.mouse_input}
    local btn = ui_button:new(bdata, 0, 0, 0, 0)
    local str_width = btn:get_text_width()
    local x = self.x + 0.5 * self.bbox.width - 0.5 * str_width
    btn:set_dimensions(x, y, str_width, str_height)
    btn:set_intensities(data.intensity, data.intensity)
    btn:set_alpha_rates(adec, ainc)
    
    if i ~= default_idx then
      btn:hide()
      btn:disable_input()
    end
    
    buttons[i] = btn
  end
  
  self.text_buttons = buttons
end

function uis:_init_toggle_buttons()
  -- customization params
  local min = self.toggle_button_min_intensity
  local max = self.toggle_button_max_intensity
  local mina = self.toggle_button_min_alpha
  local maxa = self.toggle_button_max_alpha
  local minai = self.toggle_button_alpha_decrease_rate
  local maxai = self.toggle_button_alpha_increase_rate
  local dec = self.toggle_button_decrease_rate
  local inc = self.toggle_button_increase_rate

  -- left button
  local w, h = self.bbox.width, self.bbox.height
  local char_width = self.toggle_button_width
  local ldata = {font = self.font, 
                 gradient = self.gradient_key,
                 text = self.left_button_char,
                 id = LEFT,
                 mouse = self.mouse_input}
  self.left_button = ui_button:new(ldata, self.x, self.y, char_width, h)
  self.left_button:set_intensities(min, max)
  self.left_button:set_intensity_rates(dec, inc)
  self.left_button:set_text_offset(self.toggle_button_text_offx,
                                   self.toggle_button_text_offy)
  self.left_button:set_callback_object(self)
  self.left_button:set_on_click_action(self._toggle_button_clicked)
  self.left_button:set_alpha_range(mina, maxa)
  self.left_button:set_alpha_rates(minai, maxai)
                                   
  
  -- right button
  local rdata = {font = self.font, 
                 gradient = self.gradient_key,
                 text = self.right_button_char,
                 id = RIGHT,
                 mouse = self.mouse_input}
  self.right_button = ui_button:new(rdata, self.x + w - char_width, self.y, 
                                    char_width, h)
  self.right_button:set_intensities(min, max)
  self.right_button:set_intensity_rates(dec, inc)
  self.right_button:set_text_offset(self.toggle_button_text_offx,
                                    self.toggle_button_text_offy)
  self.right_button:set_callback_object(self)
  self.right_button:set_on_click_action(self._toggle_button_clicked)
  self.right_button:set_alpha_range(mina, maxa)
  self.right_button:set_alpha_rates(minai, maxai)
  
  if self.current_option_idx == 1 then
    self.left_button:hide()
    self.left_button:disable_input()
  elseif self.current_option_idx == #self.text_buttons then
    self.right_button:hide()
    self.right_button:disable_input()
  end
end

function uis:keypressed(key)
  if not self.is_focused or not self.input_enabled then return end

  if     table.contains(self.right_char_constants, key) then
    local x, y = self.right_button.bbox.x, self.right_button.bbox.y
    self.right_button:mousepressed(x, y, self.click_button_constant)
    
  elseif table.contains(self.left_char_constants, key) then
    local x, y = self.left_button.bbox.x, self.left_button.bbox.y
    self.left_button:mousepressed(x, y, self.click_button_constant)
  end
  
end

function uis:mousepressed(x, y, button)
  if not self.input_enabled then return end

  self.left_button:mousepressed(x, y, button)
  self.right_button:mousepressed(x, y, button)
  
  for i=1,#self.text_buttons do
    self.text_buttons[i]:mousepressed(x, y, button)
  end
end

function uis:mousereleased(x, y, button)
  if not self.input_enabled then return end

  self.left_button:mousereleased(x, y, button)
  self.right_button:mousereleased(x, y, button)
end

function uis:_toggle_button_clicked(id)
  if     id == LEFT then
    self:_left()
  elseif id == RIGHT then
    self:_right()
  end
  
  local idx = self.current_option_idx
  if idx == 1 then
    self.left_button:hide()
    self.left_button:disable_input()
  else
    self.left_button:show()
    self.left_button:enable_input()
  end
  
  if idx == #self.text_buttons then
    self.right_button:hide()
    self.right_button:disable_input()
  else
    self.right_button:show()
    self.right_button:enable_input()
  end
end

function uis:_left()
  if self.current_option_idx - 1 < 1 then
    return
  end
  
  local new_idx = self.current_option_idx - 1
  self:set_option(new_idx)
  
  if self.on_value_change then
    local button_id = self.text_buttons[self.current_option_idx].id
    if self.callback_object then
      self.on_value_change(self.callback_object, self.id, button_id)
    else
      self.on_value_change(self.id, button_id)
    end
  end
  
end

function uis:_right()
  if self.current_option_idx + 1 > #self.text_buttons then
    return
  end
  
  local new_idx = self.current_option_idx + 1
  self:set_option(new_idx)
  
  if self.on_value_change then
    local button_id = self.text_buttons[self.current_option_idx].id
    if self.callback_object then
      self.on_value_change(self.callback_object, self.id, button_id)
    else
      self.on_value_change(self.id, button_id)
    end
  end
  
end

function uis:set_position(x, y)
  local tx, ty = x - self.x, y - self.y
  self.x, self.y = x, y
  self.bbox.x, self.bbox.y = x, y
  self.left_button:translate(tx, ty)
  self.right_button:translate(tx, ty)
  
  for i=1,#self.text_buttons do
    self.text_buttons[i]:translate(tx, ty)
  end
end

function uis:set_option(option_idx)
  self.text_buttons[self.current_option_idx]:hide()
  self.text_buttons[self.current_option_idx]:disable_input()
  self.text_buttons[option_idx]:show()
  self.text_buttons[option_idx]:enable_input()
  self.text_buttons[option_idx]:flash()
  self.current_option_idx = option_idx
  
  self:_toggle_button_clicked(nil)
end

function uis:set_callback_object(obj) self.callback_object = obj end

function uis:set_toggle_action(func)
  uis.on_value_change = func
end

function uis:set_gradient(gradient_key)
  self.gradient_key = gradient_key
  self.left_button:set_gradient(gradient_key)
  self.right_button:set_gradient(gradient_key)
  
  for i=1,#self.text_buttons do
    self.text_buttons[i]:set_gradient(gradient_key)
  end
end

function uis:set_focus(bool)
  self.is_focused = bool
end

function uis:get_focus()
  return self.is_focused
end

function uis:get_value()
  return self.text_buttons[self.current_option_idx].id
end

function uis:set_keyboard_input_chars(left_set, right_set)
  if type(left_set) == "string" then
    left_set = {left_set}
  end
  if type(right_set) == "string" then
    right_set = {right_set}
  end
  
  self.right_char_constants = right_set
  self.left_char_constants = left_set
end

function uis:enable()                   
  self.left_button:show()
  self.right_button:show()
  self:_toggle_button_clicked(nil)
  
  local tbutton = self.text_buttons[self.current_option_idx]
  tbutton:set_alpha_range(0, 255)
  tbutton:show()
  
  self.input_enabled = true
  tbutton:enable_input()
  self.left_button:enable_input()
  self.right_button:enable_input()
end

function uis:disable()
  self.left_button:hide()
  self.right_button:hide()
  
  local mina = self.toggle_button_min_alpha
  local maxa = self.toggle_button_max_alpha
  local tbutton = self.text_buttons[self.current_option_idx]
  tbutton:set_alpha_range(mina, maxa)
  tbutton:hide()
  
  self.input_enabled = false
  tbutton:disable_input()
  self.left_button:disable_input()
  self.right_button:disable_input()
end

function uis:_update_buttons(dt)
  self.left_button:update(dt)
  self.right_button:update(dt)
  
  for i=1,#self.text_buttons do
    self.text_buttons[i]:update(dt)
  end
end

------------------------------------------------------------------------------
function uis:update(dt)
  self:_update_buttons(dt)

end

function uis:_draw_buttons()
  self.left_button:draw()
  self.right_button:draw()
  
  for i=1,#self.text_buttons do
    self.text_buttons[i]:draw()
  end
end

------------------------------------------------------------------------------
function uis:draw()

  self:_draw_buttons(dt)

  if not self.debug then return end
  
  lg.setColor(0, 255, 0, 100)
  self.bbox:draw()
  
end

return uis













