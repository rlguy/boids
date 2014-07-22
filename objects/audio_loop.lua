
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- audio_loop object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local al = {}
al.table = 'al'
al.debug = false
al.crossfade_curve = curve:new(require("curves/cross_fade"))
al.crossfade_time = nil
al.end_crossfade_time = nil
al.start_sound = nil
al.end_sound = nil
al.loop_sounds = nil
al.all_sounds = nil
al.max_duration = 0

al.is_playing = false
al.has_started = false
al.start_sound_finished = false
al.is_finishing = false
al.end_started = false
al.is_crossfading = false

al.current_loop_sound_idx = nil
al.next_loop_sound_idx = nil
al.current_sound = nil
al.next_sound = nil

al.max_volume = 1
al.current_volume = al.max_volume
al.fade_out_progress = 0

al.current_time = 0

local al_mt = { __index = al }
function al:new(start_asset, end_asset, loop_assets, crossfade_time, end_crossfade_time)
  local al = setmetatable({}, al_mt)
  
  al.start_sound = al._new_sound(al, start_asset)
  al.end_sound = al._new_sound(al, end_asset)
  
  local max = math.max(al.start_sound.duration, al.end_sound.duration)
  
  local loop_sounds = {}
  local all_sounds = {al.start_sound, al.end_sound}
  for i=1,#loop_assets do
    loop_sounds[i] = al._new_sound(al, loop_assets[i])
    all_sounds[#all_sounds + 1] = loop_sounds[i]
    max = math.max(max, loop_sounds[i].duration)
  end
  
  if #loop_sounds == 1 then
    loop_sounds[#loop_sounds + 1] = al._clone_sound(al, loop_sounds[1])
    all_sounds[#all_sounds + 1] = loop_sounds[#loop_sounds]
  end
  
  al.loop_sounds = loop_sounds
  al.all_sounds = all_sounds
  al.crossfade_time = crossfade_time
  al.end_crossfade_time = end_crossfade_time or crossfade_time
  al.max_duration = max
  
  return al
end

function al:play()
  if self.is_playing and self.fade_out_progress == 1 then
    self:reset()
  end

  self.is_playing = true
end

function al:force_play()
  self:reset()
  self:play()
end

function al:is_ready_to_play()
  if self.is_playing then
    return self.fade_out_progress == 1
  end
  
  return true
end

function al:stop()
  self.is_finishing = true
end

function al:is_finished()
  return self.is_playing
end

function al:set_volume(v)
  self.max_volume = v
end

function al:reset()
  local sounds = self.all_sounds
  for i=1,#sounds do
    local s = sounds[i]
    if s.source:isPlaying() then
      s.source:stop()
    end
    self:_reset_sound(s)
  end
  
  self.is_playing = false
  self.has_started = false
  self.start_sound_finished = false
  self.is_finishing = false
  self.end_started = false
  self.is_crossfading = false
  self.current_loop_sound_idx = nil
  self.next_loop_sound_idx = nil
  self.current_sound = nil
  self.next_sound = nil
  self.current_volume = self.max_volume
  self.fade_out_progress = 0
  self.current_time = 0
end

function al:_new_sound(sound_asset)
  local sound = {}
  sound.source = sound_asset.source
  sound.duration = sound_asset.duration
  sound.is_playing = false
  sound.current_time = 0
  
  return sound
end

function al:_clone_sound(sound)
  local new_sound = {}
  new_sound.source = sound.source:clone()
  new_sound.duration = sound.duration
  new_sound.is_playing = false
  new_sound.current_time = 0
  
  return new_sound
end

function al:_play_sound(sound)
  if sound.is_playing then
    return
  end
  
  if sound ~= self.end_sound then
    if self.is_finishing then
      sound.source:setVolume(self.current_volume)
    else
      sound.source:setVolume(self.max_volume)
    end
  else
    sound.source:setVolume(self.max_volume)
  end
  
  sound.is_playing = true
  sound.source:play()
end

function al:_reset_sound(sound)
  sound.is_playing = false
  sound.current_time = 0
end

function al:_update_sound(dt, sound)
  local source = sound.source
  
  if not source:isPlaying() then
    self:_reset_sound(sound)
    return
  end
  sound.current_time = source:tell("seconds")
  
  if sound ~= self.end_sound then
    if self.is_finishing then
      source:setVolume(self.current_volume)
    else
      source:setVolume(self.max_volume)
    end
  else
    source:setVolume(self.max_volume)
  end
end

function al:_get_next_loop_sound()
  local idx = self.current_loop_sound_idx
  local loops = self.loop_sounds
  if not idx then
    local idx = math.random(1,#loops)
    return loops[idx], idx
  end
  
  if idx == #loops then
    local idx = math.random(1,#loops-1)
    return loops[idx], idx
  elseif idx == 1 then
    local idx = math.random(2,#loops)
    return loops[idx], idx
  else
    local low = math.random() < 0.5
    local r
    if low then
      r = math.random(1,idx - 1)
    else
      r = math.random(idx+1, #loops)
    end
    return loops[r], r
  end
  
end

function al:_update_sounds(dt)
  local sounds = self.all_sounds
  for i=1,#sounds do
    if sounds[i].is_playing then
      self:_update_sound(dt, sounds[i])
    end
  end
end

function al:_update_playing_sounds(dt)
  if not self.current_sound.is_playing then
    self.current_sound = self.next_sound
    self.current_loop_sound_idx = self.next_loop_sound_idx
    self.next_sound, idx = self:_get_next_loop_sound()
    self.next_loop_sound_idx = idx
    self.is_crossfading = false
  end
  
  local sound = self.current_sound
  local t, duration, fade_time = sound.current_time, sound.duration, self.crossfade_time
  if t >= duration - fade_time and not self.is_crossfading and not self.is_finishing then
    self:_play_sound(self.next_sound)
    self.is_crossfading = true
  end
end

function al:_update_volume(dt)
  local progress = 1 - self.fade_out_progress
  local maxv = self.max_volume
  self.current_volume = self.crossfade_curve:get(progress) * maxv
end

function al:_update_fade_out(dt)
  if not self.end_sound.is_playing then
    self:reset()
  end

  local progress = self.end_sound.current_time / self.end_crossfade_time
  if progress > 1 then
    progress = 1
  end
  self.fade_out_progress = progress
end

------------------------------------------------------------------------------
function al:update(dt)
  if not self.is_playing then
    return
  end
  
  if self.is_finishing and not self.end_started then
    self:_play_sound(self.end_sound)
    self.end_started = true
  end
  
  if self.end_started then
    self:_update_fade_out(dt)
    self:_update_volume(dt)
  end
  
  if not self.is_playing then
    return
  end
  
  if not self.has_started and self.fade_out_progress < 1 then
    self:_play_sound(self.start_sound)
    self.current_sound = self.start_sound
    self.next_sound, idx = self:_get_next_loop_sound()
    self.next_loop_sound_idx = idx
    self.has_started = true
  end
  self.start_sound_finished = not (self.current_sound == self.start_sound)
  
  self:_update_sounds(dt)
  self:_update_playing_sounds(dt)
  
end

------------------------------------------------------------------------------
function al:draw()
  if not self.debug then
    return
  end
  
  local h = 25
  local pad = 10
  local x, y = 100, 500
  local max_width = 500
  
  local start_sound = self.start_sound
  local end_sound = self.end_sound
  local max_t = self.max_duration
  
  local loop_sounds = self.all_sounds
  for i=1,#loop_sounds do
    lg.setColor(200, 200, 200, 255)
    local w = (loop_sounds[i].duration / max_t) * max_width
    lg.rectangle("fill", x, y, w, h)
    lg.setColor(0, 255, 0, 255)
    local w = (loop_sounds[i].current_time / max_t) * max_width
    lg.rectangle("fill", x, y, w, h)
    
    if loop_sounds[i].is_playing then
      local w = (loop_sounds[i].duration / max_t) * max_width
      lg.setColor(255, 255, 255, 255)
      lg.setLineWidth(2)
      lg.rectangle("line", x, y, w, h)
    end
    
    y = y + h + pad
  end
  
  
end

return al
























