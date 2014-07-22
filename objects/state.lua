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

local state_mt = { __index = state }
function state:new()
  
  return setmetatable({}, state_mt)
end


return state
