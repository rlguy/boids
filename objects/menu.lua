--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- menu object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local menu = {}
menu.table = MENU
menu.bounds = nil
menu.x = nil
menu.y = nil
menu.width = nil
menu.height = nil

menu.font = nil
menu.entries = nil
menu.current_selection = nil
menu.entry_width = 300
menu.entry_height = 20
menu.entry_xpad = 0
menu.entry_ypad = 10

menu.mouse_pos = vector2:new(0,0)
menu.hover_sound = nil
menu.activate_sound = nil

local menu_mt = { __index = menu }
function menu:new(x, y, width, height, font)
  local bounds = bbox:new(x, y, width, height)
  local hover_sound = sound_effect:new('audio/effect_test2.ogg', 3, 0.5)
  local activate_sound = sound_effect:new('audio/effect_test2.ogg', 10)
  return setmetatable({ bounds = bounds,
                        x = x,
                        y = y,
                        width = width,
                        height = height,
                        entries = {},
                        font = font,
                        hover_sound = hover_sound,
                        activate_sound = activate_sound }, menu_mt)
end

------------------------------------------------------------------------------
function menu:add_entry(text, action)
  local y = self.y + #self.entries * (self.entry_height + self.entry_ypad)
  local x = self.x + self.entry_xpad
  local width = self.width
  local height = self.entry_height
  local entry = menu_entry:new(x, y, width, height, self.font, text, action)
  
  self.entries[#self.entries+1] = entry
  return entry
end

------------------------------------------------------------------------------
function menu:update(dt)
  -- check if mouse has moved since last update
  local pos = MOUSE_INPUT:get_position()
  local mouse_has_moved = (pos ~= self.mouse_pos)
  self.mouse_pos = pos
  if not mouse_has_moved then 
    return 
  end
  
  -- check if mouse is on entry
  local selection = nil
  for _,v in ipairs(self.entries) do
    if v.bounds:contains_point(pos) then
      selection = v
      
      -- set highlight
      self:unhighlight_all()
      selection.is_highlighted = true
      break
    end
  end
  if selection == nil then
    self:unhighlight_all()
  end
  
  -- check if selection has changed since last frame
  local selection_has_changed = selection ~= self.current_selection
  if selection_has_changed then
    self.hover_sound:play()
  end
  self.current_selection = selection
  
end

------------------------------------------------------------------------------
function menu:activate()
  local selection = self.current_selection
  if selection == nil then return end
  self.activate_sound:play()
  selection:activate()
end

------------------------------------------------------------------------------
function menu:unhighlight_all()
  for _,entry in ipairs(self.entries) do
    entry.is_highlighted = false
  end
end

------------------------------------------------------------------------------
function menu:draw()
  for _,v in ipairs(self.entries) do
    v:draw()
  end
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- menu_entry object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local menu_entry = {}
menu_entry.table = MENU_ENTRY
menu_entry.bounds = nil
menu_entry.x = nil
menu_entry.y = nil
menu_entry.width = nil
menu_entry.height = nil

menu_entry.is_highlighted = false
menu_entry.font = nil
menu_entry.text = nil
menu_entry.action = nil

menu_entry.xpad = 5
menu_entry.ypad = 0

local menu_entry_mt = { __index = menu_entry }
function menu_entry:new(x, y, width, height, font, text, action)
  local bounds = bbox:new(x, y, width, height)
  return setmetatable({ bounds = bounds,
                        x = x,
                        y = y,
                        width = width,
                        height = height,
                        text = text,
                        action = action,
                        font = font }, menu_entry_mt)
end

------------------------------------------------------------------------------
function menu_entry:activate()
  self.action()
end

------------------------------------------------------------------------------
function menu_entry:toggle_highlight()
  self.is_highlighted = not self.is_hightlighted
end

------------------------------------------------------------------------------
function menu_entry:draw()
  local x,y = self.bounds.x, self.bounds.y
  local width, height = self.bounds.width, self.bounds.height
  
  -- draw highlight
  if self.is_highlighted then
    lg.setColor(C_RED)
    lg.rectangle('fill', x, y, width, height)
  end
  
  -- draw text
  lg.setColor(C_BLACK)
  lg.setFont(self.font)
  lg.print(self.text, x + self.xpad, y + self.ypad)
end


return {menu_entry, menu}


















