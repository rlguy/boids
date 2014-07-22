
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- sound_effect object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local sound_effect = {}
sound_effect.table_name = SOUND_EFFECT
sound_effect.enabled = true
sound_effect.samples = nil
sound_effect.num_samples = nil
sound_effect.index = 1
sound_effect.delay_time = 60
sound_effect.delay_timer = nil

local sound_effect_mt = { __index = sound_effect }
function sound_effect:new(file, num_samples, volume)
  volume = volume or 1
  local samples = {}
  for i=1, num_samples do
    local sound = love.audio.newSource(file)
    sound:setVolume(volume)
    samples[i] = sound
  end
  
  local delay_timer = timer:new(sound_effect.delay_time)
  delay_timer:start()
  return setmetatable({ samples = samples,
                        num_samples = num_samples,
                        delay_timer = delay_timer }, sound_effect_mt)
end

function sound_effect:disable()
  self.enabled = false
end

function sound_effect:enable()
  self.enabled = true
end

------------------------------------------------------------------------------
function sound_effect:play()
  if not self.delay_timer:isfinished() or not self.enabled then
    return
  else
    self.delay_timer:start()
  end

  -- play a sample
  local idx = self.index
  local source = self.samples[idx]
  if source:isStopped() then
    source:play()
  else
    source:rewind()
  end
  
  -- increase index
  idx = idx + 1
  if idx > self.num_samples then idx = 1 end
  self.index = idx
end

return sound_effect



