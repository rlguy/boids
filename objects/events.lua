
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- event_manager object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local event_manager = {}
event_manager.table = EVENT_MANAGER
event_manager.events = nil

local event_manager_mt = { __index = event_manager }
function event_manager:new()
  local events = {}
  return setmetatable({ events = events }, event_manager_mt)
end

------------------------------------------------------------------------------
function event_manager:add_event(event)
  self.events[#self.events+1] = event
end

------------------------------------------------------------------------------
function event_manager:update(dt)
  for i=#self.events,1,-1 do
    local event = self.events[i]
    event:update(dt)
    
    if event.has_finished then
      table.remove(self.events, i)
    end
  end
  
end

------------------------------------------------------------------------------
function event_manager:draw()
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- event object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local event = {}
event.table_name = 'event'
event.delay = nil
event.actions = nil
event.current_action = 1
event.mode = nil
event.has_finished = false
event.delay_timer = nil
event.max_repetitions = nil
event.repetitions = 1

local event_mt = { __index = event }
function event:new(event_manager, event_list, delay, mode, repetitions)
  delay = delay or 0
  mode = mode or 'once'
  
  local actions = {}
  for i=1,#event_list do
    local func = event_list[i].action
    local time = event_list[i].delay
    local timer = timer:new(time)
    
    local action = {}
    action.func = func
    action.timer = timer
    actions[#actions+1] = action
  end
  
  delay_timer = timer:new(delay)
  delay_timer:start()
  
  local event = setmetatable({ actions = actions,
                        delay = delay,
                        mode = mode,
                        delay_timer = delay_timer,
                        max_repetitions = repetitions}, event_mt)
  
  event_manager:add_event(event)           
  return event
end

------------------------------------------------------------------------------
function event:update(dt)
  if self.delay_timer:progress() < 1 or self.has_finished then
    return
  end
  
  local current_action = self.actions[self.current_action]
  local progress = current_action.timer:progress()
  if progress == 0 then
    current_action.timer:start()
    current_action.func()
    
  elseif progress == 1 then
    self.actions[self.current_action].timer:reset()
    self.current_action = self.current_action + 1
    
    local is_last_action = self.current_action > #self.actions
    if     is_last_action and self.mode == 'once' then
      self.has_finished = true
      
    elseif is_last_action and self.mode == 'repeat' then
      self.repetitions = self.repetitions + 1
      if self.max_repetitions ~= nil and self.repetitions > self.max_repetitions then
        self.has_finished = true
      end
      self.current_action = 1
    end
    
  end
  
end

------------------------------------------------------------------------------
function event:cancel()
  self.has_finished = true
end

------------------------------------------------------------------------------
function event:draw()
end

return {event, event_manager}








