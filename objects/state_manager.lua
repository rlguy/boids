
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- state_manager object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local state_manager = {}
state_manager.table = STATE_MANAGER
state_manager.current_state = nil
state_manager.states = nil
state_manager.states_by_key = nil

local state_manager_mt = { __index = state_manager }
function state_manager:new()
  local sm = setmetatable({}, state_manager_mt)
  sm.states = {}
  sm.states_by_key = {}
  return sm
end

--------------------------------------------------------------------------------
function state_manager:add_state(state_obj, key)
  self.states[#self.states+1] = state_obj
  self.states_by_key[key] = state_obj
end

--------------------------------------------------------------------------------
function state_manager:load_state(key, ...)
  local state_obj = self.states_by_key[key]
  if not state_obj then
    print("Error in state_amanage:load_state() - "..key.." state not found")
    return
  end
  
  self.current_state = state_obj
  state_obj.load(...)
  state_obj.update(1/60)
end
  
--------------------------------------------------------------------------------
function state_manager:load_next_state(...)
  local current_state = self.current_state
  local next_state = nil
  
  for i,v in ipairs(self.states) do
    if v == current_state then
      if i == #self.states then return end
      next_state = self.states[i+1]
      break
    end
  end
  
  local state_key = nil
  for k,v in pairs(self.states_by_key) do
    if v == next_state then
      state_key = k
      break
    end
  end
  
  self:load_state(state_key, ...)
end

function state_manager:update(dt)
  self.current_state.update(dt)
end
function state_manager:draw(dt)
  self.current_state.draw(dt)
end

function state_manager:keypressed(key)
  self.current_state.keypressed(key)
end
function state_manager:keyreleased(key)
  self.current_state.keyreleased(key)
end
function state_manager:mousepressed(x, y, button)
  self.current_state.mousepressed(x, y, button)
end
function state_manager:mousereleased(x, y, button)
  self.current_state.mousereleased(x, y, button)
end


return state_manager




















