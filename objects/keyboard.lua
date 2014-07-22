
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- key object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local key = {}
key.table = KEY
key.const = nil
key.label = nil
key.group = nil
key.enabled = true
key.pressed = false
key.released = false
key.timer = nil
key.timer_is_active = false
key.time_pressed = 0

key.rate_timer = nil
key.rate_threshold = 0.25     -- time in seconds before rate is set to 0
key.total_time = 0
key.counter = 0
key.rate = 0

key.press_action = nil
key.release_action = nil
key.press_enabled = true
key.release_enabled = true

key_mt = { __index = key }
function key:new(const, name, group)
  local keytimer = timer:new()
  local rate_timer = timer:new()
  rate_timer:start()
  
  return setmetatable({const = const,
                       label = name,
                       group = group,
                       timer = keytimer,
                       rate_timer = rate_timer }, key_mt)
end

------------------------------------------------------------------------------
function key:update(dt)

  if self.enabled == false then
    return
  end
  
  if self.timer_is_active then
    self.time_pressed = self.timer:time_elapsed()/1000
  else
    self.time_pressed = 0
  end
  
  -- update press rate
  local time = self.rate_timer:time_elapsed() / 1000
  if time > self.rate_threshold then
    self.rate = 0
  end
  
end


------------------------------------------------------------------------------
function key:is_down()
  if self.enabled then
    return love.keyboard.isDown(self.const)
  else
    return false
  end
end


------------------------------------------------------------------------------
-- returns whether key has been pressed since last call
function key:was_pressed()
  local val = self.pressed
  self.pressed = false
  return val
end


------------------------------------------------------------------------------
-- returns whether key has been released since last call
function key:was_released()
  local val = self.released
  self.released = false
  return val
end


------------------------------------------------------------------------------
-- format of record = { label, key_enabled, press_enabled, release_enabled,
--                      press_action, release_action }
function key:get_record()
  local label = self.label
  local enabled = self.enabled
  local press_enabled = self.press_enabled
  local release_enabled = self.release_enabled
  local press_action = self.press_action
  local release_action = self.release_action
  
  return { label, enabled, press_enabled, release_enabled, 
           press_action, release_action }
end


------------------------------------------------------------------------------
function key:set_record(record)
  self.enabled = record[2]
  self.press_enabled = record[3]
  self.release_enabled = record[4]
  self.press_action = record[5]
  self.release_action = record[6]
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- button object  (mouse buttons)
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local button = {}
button.table = BUTTON
button.const = nil
button.label = nil
button.group = nil
button.enabled = true
button.x = 0
button.y = 0
button.pressed = false
button.released = false
button.timer = nil
button.timer_is_active = false
button.time_pressed = 0

button.rate_timer = nil
button.rate_threshold = 0.25     -- time in seconds before rate is set to 0
button.total_time = 0
button.counter = 0
button.rate = 0

button.press_action = nil
button.release_action = nil
button.press_enabled = true
button.release_enabled = true

button_mt = { __index = button }
function button:new(const, name, group)
  local buttontimer = timer:new()
  local rate_timer = timer:new()
  rate_timer:start()
  
  return setmetatable({const = const,
                       label = name,
                       group = group,
                       timer = buttontimer,
                       rate_timer = rate_timer }, button_mt)
end

------------------------------------------------------------------------------
function button:update(dt)

  if self.enabled == false then
    return
  end
  
  if self.timer_is_active then
    self.time_pressed = self.timer:time_elapsed()/1000
  else
    self.time_pressed = 0
  end
  
  -- update press rate
  local time = self.rate_timer:time_elapsed() / 1000
  if time > self.rate_threshold then
    self.rate = 0
  end
  
end


------------------------------------------------------------------------------
function button:is_down()
  if self.enabled then
    return love.mouse.isDown(self.const)
  else
    return false
  end
end


------------------------------------------------------------------------------
-- returns whether button has been pressed since last call
function button:was_pressed()
  local val = self.pressed
  self.pressed = false
  return val
end


------------------------------------------------------------------------------
-- returns whether button has been released since last call
function button:was_released()
  local val = self.released
  self.released = false
  return val
end


------------------------------------------------------------------------------
-- format of record = { label, button_enabled, press_enabled, release_enabled,
--                      press_action, release_action }
function button:get_record()
  local label = self.label
  local enabled = self.enabled
  local press_enabled = self.press_enabled
  local release_enabled = self.release_enabled
  local press_action = self.press_action
  local release_action = self.release_action
  
  return { label, enabled, press_enabled, release_enabled, 
           press_action, release_action }
end


------------------------------------------------------------------------------
function button:set_record(record)
  self.enabled = record[2]
  self.press_enabled = record[3]
  self.release_enabled = record[4]
  self.press_action = record[5]
  self.release_action = record[6]
end



--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- keyboard object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local keyboard = {}
keyboard.table = KEYBOARD
keyboard.keys = nil
keyboard.buttons = nil
keyboard.layouts = nil

keyboard_mt = { __index = keyboard }
function keyboard:new()
  local keys = {}
  local buttons = {}
  local layouts = {}
  return setmetatable({keys = keys,
                       buttons = buttons,
                       layouts = layouts }, keyboard_mt)
end

------------------------------------------------------------------------------
function keyboard:add_key(name, const, group)
  if group == nil then
    group = 'other'
  end
  
  local newkey = key:new(const, name, group)
  self[name] = newkey
  table.insert(self.keys, newkey)
end

------------------------------------------------------------------------------
function keyboard:add_button(name, const, group)
  if group == nil then
    group = 'other'
  end
  
  local newbutton = button:new(const, name, group)
  self[name] = newbutton
  table.insert(self.buttons, newbutton)
end

------------------------------------------------------------------------------
function keyboard:update(dt)
  for _,v in ipairs(self.keys) do
    v:update(dt)
  end
  for _,v in ipairs(self.buttons) do
    v:update(dt)
  end
end


------------------------------------------------------------------------------
function keyboard:enable_group(name)
  for _,v in ipairs(self.keys) do
    if v.group == name then
      v.enabled = true
    end
  end
  for _,v in ipairs(self.buttons) do
    if v.group == name then
      v.enabled = true
    end
  end
end


------------------------------------------------------------------------------
function keyboard:disable_group(name)
  for _,v in ipairs(self.keys) do
    if v.group == name then
      v.enabled = false
    end
  end
  for _,v in ipairs(self.buttons) do
    if v.group == name then
      v.enabled = false
    end
  end
end


------------------------------------------------------------------------------
function keyboard:enable_all()
  for _,v in ipairs(self.keys) do
    v.enabled = true
  end
  for _,v in ipairs(self.buttons) do
    v.enabled = true
  end
end


------------------------------------------------------------------------------
function keyboard:disable_all()
  for _,v in ipairs(self.keys) do
    v.enabled = false
  end
  for _,v in ipairs(self.buttons) do
    v.enabled = false
  end
end


------------------------------------------------------------------------------
function keyboard:save_layout(name)
  local layout = {}
  layout.label = name
  
  for _,v in ipairs(self.keys) do
    table.insert(layout, v:get_record())
  end
  for _,v in ipairs(self.buttons) do
    table.insert(layout, v:get_record())
  end
  
  table.insert(self.layouts, layout)
end


------------------------------------------------------------------------------
function keyboard:load_layout(name)
  -- find layout in self.layouts
  local layout = nil
  for _,v in ipairs(self.layouts) do
    if v.label == name then
      layout = v
      break
    end
  end
  
  -- set record for each key
  for _,record in ipairs(layout) do
    local key_name = record[1]
    self[key_name]:set_record(record)
  end
end

return {key, button, keyboard}

































