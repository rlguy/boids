
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- audio_sample_set object - launches audio samples from a set
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local aset = {}
aset.table = 'aset'
aset.debug = false
aset.original_sample_set = nil
aset.samples = nil
aset.playing_samples = nil
aset.finished_samples = nil
aset.num_duplicates = 2       -- number of times to duplicate
aset.max_duplicates = 4
aset.max_duration = nil
aset.current_time = 0
aset.default_launch_duration = 0 
aset.default_spread = 0
aset.default_radius = 500

local aset_mt = { __index = aset }
function aset:new(audio_assets)
  local aset = setmetatable({}, aset_mt)
  
  aset:_init_samples(audio_assets)
  aset.playing_samples = {}
  aset.finished_samples = {}
  
  return aset
end

--[[
  num_samples - number of samples to launch
  volume      - volume that will be applied to each sample [0,1]
  launch_time - time interval that samples will be launched over
  x, y        - position of source relative to listener  (sources must be mono)
  radius      - radius for calculating distance attenuation
  spread      - if there are multiple samples, spread is the radius of positions
                samples will be spread over from (x, y) position
]]--
function aset:play(num_samples, volume, launch_time, x, y, radius, spread)
  launch_time = launch_time or self.default_launch_duration
  
  local has_position = false
  if x and y then
    has_position = true
    radius = radius or self.default_radius
    spread = spread or self.default_spread
  end
  
  local samples = self:_reserve_samples(num_samples)
  local current = self.current_time
  for i=1,#samples do
    samples[i].launch_time = current + math.random() * launch_time
    if i == 1 then
      samples[i].launch_time = current -- so that a source is played immediately
    end
    if volume then
      samples[i].source:setVolume(volume)
    end
    
    if has_position then
      local dirx, diry = random_direction2()
      local sx = x + dirx * spread * math.random()
      local sy = y + diry * spread * math.random()
      samples[i].source:setPosition(sx, sy, 0)
      samples[i].source:setAttenuationDistances(0, radius)
    end
  end
end

function aset:_retrieve_finished_samples()
  if #self.finished_samples == 0 then
    return
  end
  local finished = self.finished_samples
  local samples = self.samples
  self:_shuffle_table(finished)
  
  for i=#finished,1,-1 do
    samples[#samples + 1] = finished[i]
    finished[i] = nil
  end
end

function aset:_create_more_samples()
  if self.num_duplicates >= self.max_duplicates then
    return
  end

  local orig = self.original_sample_set
  local samples = self.samples
  local new = {}
  for i=1,#orig do
    new[i] = self:_clone_sample(orig[i])
  end
  self:_shuffle_table(new)
  
  for i=1,#new do
    samples[#samples + 1] = new[i]
  end
  
  self.num_duplicates = self.num_duplicates + 1
end

function aset:_reserve_samples(n)
  local samples = self.samples
  local playing = self.playing_samples
  local set = {}
  
  if n > #samples then
    self:_retrieve_finished_samples()
    if n > #samples then
      self:_create_more_samples()
      if n > #samples then
        n = #samples
      end
    end
  end
  for i=#samples,#samples-n,-1 do
    set[#set + 1] = samples[i]
    playing[#playing + 1] = samples[i]
    samples[i] = nil
  end
  
  return set
end

function aset:_init_samples(assets)
  local samples = {}
  local max_len = 0
  for i=1,#assets do
    samples[i] = self:_new_sample(assets[i])
    if samples[i].duration > max_len then
      max_len = samples[i].duration
    end
  end
  self.original_sample_set = samples
  self.max_duration = max_len
  
  -- create duplicates
  self.samples = {}
  local len = #samples
  for i=1,#samples do
    self.samples[i] = samples[i]
    for j=1,self.num_duplicates-1 do
      self.samples[i + j*len] = self:_clone_sample(samples[i])
    end
  end
  
  -- so clips will be launched in a random order
  self:_shuffle_table(self.samples)
end

-- Fisher–Yates shuffle
function aset:_shuffle_table(tb)
  for i=#tb,2,-1 do
    local j = math.random(1,i)
    tb[i], tb[j] = tb[j], tb[i]
  end
end

function aset:_new_sample(audio_asset)
  local sample = {}
  sample.source = audio_asset.source
  sample.duration = audio_asset.duration
  sample.progress = 0
  sample.launch_time = 0
  sample.is_playing = false
  
  return sample
end

function aset:_reset_sample(sample)
  sample.is_playing = false
  sample.source:setVolume(1.0)
  sample.source:setPosition(0, 0, 0)
  sample.source:setAttenuationDistances(0, 1)
  sample.launch_time = 0
  sample.progress = 0
end

function aset:_clone_sample(sample)
  local s = {}
  s.source = sample.source:clone()
  s.duration = sample.duration
  s.is_playing = false
  
  return s
end

function aset:_play_sample(sample)
  sample.source:play()
  sample.is_playing = true
end

------------------------------------------------------------------------------
function aset:update(dt)
  self.current_time = self.current_time + dt
  local t = self.current_time
  
  local playing = self.playing_samples
  local finished = self.finished_samples
  for i=#playing,1,-1 do
    local sample = playing[i]
    if self.debug then
      sample.progress = sample.source:tell("seconds") / sample.duration
    end
    
    if not sample.is_playing and t > sample.launch_time then
      self:_play_sample(sample)
    end
    
    if sample.is_playing and not sample.source:isPlaying() then
      self:_reset_sample(sample)
      finished[#finished + 1] = sample
      table.remove(playing, i)
    end
  end
end

------------------------------------------------------------------------------
function aset:draw()
  if not self.debug then return end
  
  local samples = self.samples
  
  local x, y = 200, 30
  local maxw = 120
  local maxd = self.max_duration
  local h = 10
  local pad = 5
  
  lg.setColor(255, 255, 255, 255)
  lg.print("#free: "..tostring(#self.samples), x, y - 20)
  for i=1,#samples do
    lg.setColor(200, 200, 200, 255)
    local w = maxw * (samples[i].duration / maxd)
    lg.rectangle("fill", x, y, w, h)

    y = y + h + pad
  end
  
  local x, y = x + maxw + 40, 30
  local samples = self.playing_samples
  lg.setColor(255, 255, 255, 255)
  lg.print("#playing: "..tostring(#self.playing_samples), x, y - 20)
  for i=1,#samples do
    lg.setColor(200, 200, 200, 255)
    local w = maxw * (samples[i].duration / maxd)
    lg.rectangle("fill", x, y, w, h)
    
    lg.setColor(0, 255, 0, 255)
    local w = w * samples[i].progress
    lg.rectangle("fill", x, y, w, h)
    
    y = y + h + pad
  end
  
  local x, y = x + maxw + 40, 30
  local samples = self.finished_samples
  lg.setColor(255, 255, 255, 255)
  lg.print("#finished: "..tostring(#self.finished_samples), x, y - 20)
  for i=1,#samples do
    lg.setColor(200, 200, 200, 255)
    local w = maxw * (samples[i].duration / maxd)
    lg.rectangle("fill", x, y, w, h)
    
    lg.setColor(0, 255, 0, 255)
    local w = w * samples[i].progress
    lg.rectangle("fill", x, y, w, h)
    
    y = y + h + pad
  end
  
end

return aset



























