
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- main_menu object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local menu = {}
menu.table = 'main_menu'
menu.debug = false
menu.cx = 0.5 * SCR_WIDTH
menu.cy = 0.5 * SCR_HEIGHT
menu.yoffset = -100
menu.xoffset = 0

menu.button_width = 400
menu.button_height = 35
menu.button_ypad = 45
menu.buttons = nil

menu.min_intensity = 0.7
menu.max_intensity = 1
menu.intensity_decrease_rate = -6
menu.intensity_increase_rate = 10
menu.noise_vx = 0.5
menu.noise_vy = 0
menu.noise_vz = 0
menu.lower_noise_range = 0
menu.upper_noise_range = 0.2
menu.alpha_decrease_rate = -4
menu.alpha_increase_rate = 4

menu.background_button_text = "@@@@@@@@@@@@@@"
menu.background_min_intensity = 0.3
menu.background_max_intensity = 0.5
menu.background_intensity_decrease_rate = -6
menu.background_intensity_increase_rate = 6
menu.background_noise_vx = 0
menu.background_noise_vy = 0
menu.background_noise_vz = 0.5
menu.background_noise_scale = 0.03
menu.background_lower_noise_range = 0
menu.background_upper_noise_range = 0.4
menu.background_alpha_decrease_rate = -4
menu.background_alpha_increase_rate = 4

menu.background_power_meters = nil
menu.background_power_curve = curve:new(
                         require("curves/background_button_power_meter_curve"))
menu.min_crossfade = 1
menu.max_crossfade = 1
menu.bpc_decrease_rate = -3
menu.bpc_increase_rate = 3

menu.font = nil
menu.mouse_input = nil
menu.gradient = "blue"
menu.background_gradient = "blue_no_border"

menu.display_power_meter = nil
menu.dpm_decrease_rate = -12
menu.dpm_increase_rate = 7
menu.background_display_power_meter = nil
menu.bpm_decrease_rate = -6
menu.bpm_increase_rate = 0.15
menu.current_background_alpha = 0

menu.input_enabled = true


local menu_mt = { __index = menu }
function menu:new()
  local menu = setmetatable({}, menu_mt)
  
  menu.events = event_manager:new()
  menu.buttons = {}
  menu.background_buttons = {}
  menu.background_power_meters = {}
  menu.font = FONTS.game_fonts.default_5
  menu.mouse_input = MOUSE_INPUT
  menu.display_power_meter = power_meter:new()
  menu.display_power_meter:set_power_curve(menu.background_power_curve)
  menu.background_display_power_meter = power_meter:new()
  menu.background_display_power_meter:set_power_curve(menu.background_power_curve)
  
  menu:_init_buttons()
  
  local function display() menu:_show() end
  event:new(menu.events, {{action = display, delay = 0}}, 0.3)
  
  return menu
end

function menu:keypressed(key)
  if not self.input_enabled then return end

  --[[
  for i=1,#self.buttons do
    self.buttons[i]:keypressed(key)
  end
  ]]--
end
function menu:keyreleased(key)
  if not self.input_enabled then return end
  --[[
  for i=1,#self.buttons do
    self.buttons[i]:keyreleased(key)
  end
  ]]--
end
function menu:mousepressed(x, y, button)
  if not self.input_enabled then return end

  for i=1,#self.buttons do
    self.buttons[i]:mousepressed(x, y, button)
  end
  for i=1,#self.background_buttons do
    self.background_buttons[i]:mousepressed(x, y, button)
  end
end
function menu:mousereleased(x, y, button)
  if not self.input_enabled then return end

  for i=1,#self.buttons do
    self.buttons[i]:mousereleased(x, y, button)
  end
  for i=1,#self.background_buttons do
    self.background_buttons[i]:mousereleased(x, y, button)
  end
end

function menu:_disable_input()
  for i=1,#self.buttons do
    self.buttons[i]:disable_input()
  end

  self.input_enabled = false
end
function menu:_enable_input()
  for i=1,#self.buttons do
    self.buttons[i]:enable_input()
  end

  self.input_enabled = true
end

function menu:_show()
  self.display_power_meter:set_base_rate(self.dpm_increase_rate)
  self.background_display_power_meter:set_base_rate(self.bpm_increase_rate)
end

function menu:_hide()
  self.display_power_meter:set_base_rate(self.dpm_decrease_rate)
  self.background_display_power_meter:set_base_rate(self.bpm_decrease_rate)
end

function menu:_init_buttons()
  self:_init_start_button()
  self:_init_settings_button()
  self:_init_exit_button()
  self:_init_background_buttons()
  
  for i=1,#self.buttons do
    self.buttons[i]:hide(true)
  end
  for i=1,#self.background_buttons do
    self.background_buttons[i]:hide(true)
  end
end

function menu:_init_start_button()
  local data = {font = self.font,
                gradient = self.gradient,
                text = "NEW GAME",
                id = "start",
                mouse = self.mouse_input}
      
  local x = self.cx - 0.5 * self.button_width + self.xoffset
  local y = self.cy + 0 * self.button_ypad + - 0.5 * self.button_height + self.yoffset
  local width, height = self.button_width, self.button_height
  
  local start_button = self:_create_text_button(data, x, y, width, height)
  start_button:set_on_click_action(self._start_button_clicked)
  self.buttons[#self.buttons + 1] = start_button
end

function menu:_init_settings_button()
  local data = {font = self.font,
                gradient = self.gradient,
                text = "SETTINGS",
                id = "settings",
                mouse = self.mouse_input}
      
  local x = self.cx - 0.5 * self.button_width + self.xoffset
  local y = self.cy + 1 * self.button_ypad + - 0.5 * self.button_height + self.yoffset
  local width, height = self.button_width, self.button_height
  
  local settings_button = self:_create_text_button(data, x, y, width, height)
  settings_button:set_on_click_action(self._settings_button_clicked)
  self.buttons[#self.buttons + 1] = settings_button
end

function menu:_init_exit_button()
  local data = {font = self.font,
                gradient = self.gradient,
                text = "EXIT",
                id = "exit",
                mouse = self.mouse_input}
      
  local x = self.cx - 0.5 * self.button_width + self.xoffset
  local y = self.cy + 2 * self.button_ypad + - 0.5 * self.button_height + self.yoffset
  local width, height = self.button_width, self.button_height
  
  local exit_button = self:_create_text_button(data, x, y, width, height)
  exit_button:set_on_click_action(self._exit_button_clicked)
  self.buttons[#self.buttons + 1] = exit_button
end

function menu:_init_background_buttons()
  local data = {font = self.font,
                gradient = self.background_gradient,
                text = self.background_button_text,
                id = "background_button",
                mouse = self.mouse_input}
                
  for i=1,#self.buttons do 
    local b = self.buttons[i]
    local x, y, width, height = b.x, b.y, self.button_width, self.button_height
    local button = menu:_create_background_button(data, x, y, width, height)                                
    self.background_buttons[i] = button
    local meter = power_meter:new()
    meter:set_power_curve(self.background_power_curve)
    self.background_power_meters[i] = meter
  end
end

function menu:_create_text_button(data, x, y, width, height)
  local button = ui_button:new(data, x, y, width, height)
  button:center_text()
  button:set_intensities(self.min_intensity, self.max_intensity)
  button:set_intensity_rates(self.intensity_decrease_rate, 
                             self.intensity_increase_rate)
  button:set_noise_speed(self.noise_vx, self.noise_vy, self.noise_vz)
  button:set_noise_ranges(self.lower_noise_range, self.upper_noise_range)
  button:set_callback_object(self)
  button:set_on_enter_action(self._text_button_on_enter)
  button:set_on_exit_action(self._text_button_on_exit)
  button:set_alpha_rates(self.alpha_decrease_rate,
                         self.alpha_increase_rate)
  
  return button
end

function menu:_create_background_button(data, x, y, width, height)
  local button = ui_button:new(data, x, y, width, height)
  button:center_text()
  button:set_intensities(self.background_min_intensity, 
                         self.background_max_intensity)
  button:set_intensity_rates(self.background_intensity_decrease_rate, 
                             self.background_intensity_increase_rate)
  button:set_noise_speed(self.background_noise_vx, 
                         self.background_noise_vy, 
                         self.background_noise_vz)
  button:set_noise_scale(self.background_noise_scale)
  button:set_noise_ranges(self.background_lower_noise_range, 
                          self.background_upper_noise_range)
  button:set_alpha_rates(self.background_alpha_decrease_rate,
                         self.background_alpha_increase_rate)
  button:set_crossfade(self.min_crossfade, 0)
  
  return button
end

function menu:_start_button_clicked(id)
  local function fadeout() self:_hide() end
  local function start() INVADERS:load_state("level1_load_state") end
  
  self:_disable_input()
  event:new(self.events, {{action = fadeout, delay = 0}}, 0.5)
  event:new(self.events, {{action = start, delay = 0}}, 1)
end
function menu:_settings_button_clicked(id)
  local function fadeout() self:_hide() end
  
  self:_disable_input()
  event:new(self.events, {{action = fadeout, delay = 0}}, 0.1)
end
function menu:_exit_button_clicked(id)
  local function quit() love.event.push("quit") end
  local function fadeout() self:_hide() end
  
  self:_disable_input()
  event:new(self.events, {{action = fadeout, delay = 0}}, 0.5)
  event:new(self.events, {{action = quit, delay = 0}}, 1)
end

function menu:_text_button_on_enter(id)
  local idx
  if     id == "start" then
    idx = 1
  elseif id == "settings" then
    idx = 2
  elseif id == "exit" then
    idx = 3
  end
  if idx then
    self.background_power_meters[idx]:set_base_rate(self.bpc_increase_rate)
  end
end

function menu:_text_button_on_exit(id)
  local idx
  if     id == "start" then
    idx = 1
  elseif id == "settings" then
    idx = 2
  elseif id == "exit" then
    idx = 3
  end
  if idx then
    self.background_power_meters[idx]:set_base_rate(self.bpc_decrease_rate)
  end
end

function menu:_update_background_crossfades(dt)
  local meters = self.background_power_meters
  local buttons = self.background_buttons
  local min, max = self.min_crossfade, self.max_crossfade
  
  for i=1,#meters do
    meters[i]:update(dt)
    local level = meters[i]:get_power_level()
    buttons[i]:set_crossfade(lerp(min, max, level))
  end
end

function menu:_update_buttons(dt)
  for i=1,#self.buttons do
    self.buttons[i]:update(dt)
  end
  
  self:_update_background_crossfades(dt)
  for i=1,#self.background_buttons do
    self.background_buttons[i]:update(dt)
  end
end

function menu:_update_display_alpha(dt)
  local meter = self.display_power_meter
  meter:update(dt)
  
  local level = meter:get_power_level()
  
  local buttons = self.buttons
  local back_buttons = self.background_buttons
  for i=1,#buttons do
    local r = (i-1) / (#buttons)
    if level > r or level == 1 then
      buttons[i]:show()
      back_buttons[i]:show()
    else
      buttons[i]:hide()
      back_buttons[i]:hide()
    end
  end
  
  self.background_display_power_meter:update(dt)
  local min, max = 0, 255
  local blevel = self.background_display_power_meter:get_power_level()
  self.current_background_alpha = lerp(min, max, 1 - blevel)
end

------------------------------------------------------------------------------
function menu:update(dt)
  self:_update_display_alpha(dt)
  self:_update_buttons(dt)
  
  self.events:update(dt)
end

------------------------------------------------------------------------------
function menu:draw()

  if self.current_background_alpha > 0 then
    lg.setColor(0, 0, 0, self.current_background_alpha)
    lg.rectangle("fill", 0, 0, SCR_WIDTH, SCR_HEIGHT)
  end

  for i=1,#self.background_buttons do
    self.background_buttons[i]:draw()
  end

  for i=1,#self.buttons do
    self.buttons[i]:draw()
  end
  
  if self.debug then
    -- centre lines
    lg.setColor(255, 255, 255, 80)
    lg.line(self.cx, 0, self.cx, SCR_HEIGHT)
    lg.line(0, self.cy, SCR_WIDTH, self.cy)
  end
end

return menu























