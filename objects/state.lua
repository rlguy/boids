--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- state object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local state = {}
state.table = STATE
state.label = nil           -- label/name of state (string)
state.keyboard_layout = nil -- layout name for keyboard (string)
state.load = nil            -- function for load
state.update = nil          -- function for update
state.draw = nil            -- function for draw
state._is_loading_state = false
state.key = nil

local state_mt = { __index = state }
function state:new()
  
  return setmetatable({}, state_mt)
end

function state:set_as_loading_state()
  self._is_loading_state = true
end

function state:is_loading_state()
  return self._is_loading_state
end

function state:set_key(key)
  self.key = key
end

function state:get_key()
  return self.key
end


return state
