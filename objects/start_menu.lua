
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- start_menu object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local lg = love.graphics

local sm = {}
sm.table = 'sm'
sm.debug = false
sm.x = nil
sm.y = nil
sm.width = 200
sm.height = 300
sm.entries = nil
sm.original_scr_width = nil
sm.original_scr_height = nil

sm.entry_pad = 10
sm.entry_width = 600
sm.entry_height = 60
sm.text_xoff = 3
sm.text_yoff = -6

sm.selected_entry_idx = 1

sm.text_color = {200, 200, 200, 255}
sm.selected_color = {0, 255, 40, 50}
sm.selected_text_color = {255, 255, 255, 255}

sm.last_mouse_x = nil
sm.last_mouse_y = nil

local sm_mt = { __index = sm }
function sm:new(scr_width, scr_height)
  local sm = setmetatable({}, sm_mt)
  
  sm.original_scr_width = scr_width
  sm.original_scr_height = scr_height
  sm._init(sm, scr_width, scr_height)
  
  return sm
end

function sm:keypressed(key)
  if key == 'd' or key == 'return' then
    self.entries[1].action()
  end
  
  if key == 'f' then
    self.entries[2].action()
  end
end

function sm:mousepressed(x, y, button)
  if self.selected_entry_idx and button == 'l' then
    if self.entries[self.selected_entry_idx].action then
      self.entries[self.selected_entry_idx].action()
    end
  end
end

function sm:_init(scr_width, scr_height)
  local x = (3/8)*scr_width - self.width
  local y = 0.5 * scr_height - 0.5 * self.height
  self.x, self.y = x, y
  
  self.entries = {}
  
  local demo = {}
  demo.text = "DEMO"
  demo.action = function() self:_start_game() end
  
  local fullscreen = {}
  fullscreen.text = "DEMO FULLSCREEN"
  
  -- For some reason love.mouse.isDown() is set to true when
  -- only toggling once, so get around this by toggling thrice
  -- ???
  fullscreen.action = function() self:_toggle_fullscreen()
                                   self:_toggle_fullscreen()
                                   self:_toggle_fullscreen()
                                   self:_start_game() end
  
  local exit = {}
  exit.text = "EXIT"
  exit.action = function() love.event.push("quit") end
  
  self.entries = {demo, fullscreen, exit}
  for i=1,#self.entries do
    local entry = self.entries[i]
    entry.x = x
    entry.y = y + (i-1) * (self.entry_height + self.entry_pad)
    entry.width = self.entry_width
    entry.height = self.entry_height
  end
  
  self.last_mouse_x, self.last_mouse_y = love.mouse:getPosition()
  self:_update_selection()
end

function sm:_toggle_fullscreen()
  local fullscreen = not love.window.getFullscreen()
  if fullscreen then
    local modes = love.window.getFullscreenModes()
    table.sort(modes, function(a, b) return a.width*a.height > b.width*b.height end)
    SCR_WIDTH = modes[1].width
    SCR_HEIGHT = modes[1].height
    local w, h, flags = love.window.getMode( )
    flags.fullscreen = true
    love.window.setMode(SCR_WIDTH, SCR_HEIGHT, flags)
    self:_init(SCR_WIDTH, SCR_HEIGHT)
  else
    SCR_WIDTH, SCR_HEIGHT = self.original_scr_width, self.original_scr_height
    local w, h, flags = love.window.getMode( )
    flags.fullscreen = false
    love.window.setMode(SCR_WIDTH, SCR_HEIGHT, flags)
    self:_init(self.original_scr_width, self.original_scr_height)
  end
end

function sm:_start_game()
  local width, height = lg.getWidth(), lg.getHeight()
  require('invaders_main')
  love.load({1, width, height})
  local chunk = love.filesystem.load('invaders_main.lua')
  chunk()
end

function sm:_update_selection()
  local mx, my = love.mouse:getPosition()
  for i=1,#self.entries do
    local e = self.entries[i]
    if mx > e.x and mx < e.x + e.width and my > e.y and my < e.y + e.height then
      self.selected_entry_idx = i
      return
    end
  end
  
  self.selected_entry_idx = false
end

------------------------------------------------------------------------------
function sm:update(dt)
  local mx, my = love.mouse:getPosition()
  if mx == self.last_mouse_x and my == self.last_mouse_y then
    return
  end
  
  self:_update_selection()
  
  self.last_mouse_x, self.last_mouse_y = mx, my
end

------------------------------------------------------------------------------
function sm:draw()
  local x, y = self.x, self.y
  local pad = self.entry_pad
  local w, h = self.entry_width, self.entry_height
  local entries = self.entries
  
  for i=1,#entries do
    local e = entries[i]
    
    if i == self.selected_entry_idx then
      lg.setColor(self.selected_color)
      lg.rectangle("fill", e.x, e.y, e.width, e.height)
    end
    
    lg.setColor(self.text_color)
    if i == self.selected_entry_idx then
      lg.setColor(self.selected_text_color)
    end
    lg.print(e.text, e.x + self.text_xoff, e.y + self.text_yoff)
  end
  
  if self.debug then
  end
end

return sm


















