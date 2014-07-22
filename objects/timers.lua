--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- timer object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local timer = {}
timer.table = TIMER
timer.length = 0
timer.start_time = nil

local timer_mt = { __index = timer }
function timer:new(master, length)      -- length in miliseconds
  if type(master) == 'number' then
    length = master
    master = nil
  end
  
  master = master or MASTER_TIMER
  
  length = length or 0
  
  return setmetatable({master_timer = master,
                       length = length}, timer_mt)
end


------------------------------------------------------------------------------
function timer:start()
  self.start_time = self.master_timer:get_time()
end


------------------------------------------------------------------------------
function timer:set_length(length)
  self.length = length
end


------------------------------------------------------------------------------
-- returns elapsed time in milliseconds
-- returns nil if timer has not started
function timer:time_elapsed()
  if self.start_time == nil then
    return 0
  end
  return self.master_timer:get_time() - self.start_time
end


------------------------------------------------------------------------------
-- returns the progress from the start of the timer
-- returns nil if timer has not started
-- t = 0    no time passed
-- t = 0.5  half of the time has passed
-- t = 1.0  full time has passed
function timer:progress()
  if self.start_time == nil then
    return 0
  end
  local current_progress = self:time_elapsed()/self.length
  if current_progress >= 1 then
    current_progress = 1
  end
  
  return current_progress
end


------------------------------------------------------------------------------
-- returns whether the timer is initialized and running (has not finished)
function timer:isrunning()
  if self.start_time == nil or self:isfinished() then
    return false
  end
  
  return true
end

------------------------------------------------------------------------------
function timer:reset()
  self.start_time = nil
end


------------------------------------------------------------------------------
-- returns whether time timer has finished
function timer:isfinished()

  if self:time_elapsed() <= self.length then
    return false
  end
  
  return true
end



--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- master_timer object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local master_timer = {}
master_timer.table = MASTER_TIMER
master_timer.start_time = 0
master_timer.is_stopped = false
master_timer.inactive_time = 0
master_timer.current_time = 0
master_timer.time_scale = 1

local master_timer_mt = { __index = master_timer }
function master_timer:new()
  local start_time = love.timer.getTime()
  
  return setmetatable({ start_time = start_time }, master_timer_mt)
end


------------------------------------------------------------------------------
function master_timer:start()
  self.is_stopped = false
end

------------------------------------------------------------------------------
function master_timer:stop()
  self.is_stopped = true
end

function master_timer:set_time_scale(scale)
  self.time_scale = scale
end

------------------------------------------------------------------------------
function master_timer:update(dt)
  if self.is_stopped == true then
    self.inactive_time = self.inactive_time + dt * self.time_scale
  end
  
  self.current_time = self.current_time + dt * self.time_scale
end


------------------------------------------------------------------------------
-- returns time active since game started
function master_timer:get_time()
  return self.current_time - self.start_time - self.inactive_time
end



return {timer, master_timer}

