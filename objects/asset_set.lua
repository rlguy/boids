
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- asset_set object - manages loading a set of assets (images, audio)
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local TYPE_IMAGE = 0
local TYPE_AUDIO = 1

local as = {}
as.table = 'as'
as.debug = false
as.assets = nil
as.assets_by_key = nil
as.assets_by_filepath = nil
as.asset_sets_by_key = nil
as.asset_data_by_key = nil
as.reserved_assets_by_table = nil
as.load_finished = false
as.is_loading = false
as.load_initialized = false
as.time_loading = 0
as.asset_load_idx = 1
as.assets_to_load = 0
as.assets_loaded = 0

as.unique_id = 0

local as_mt = { __index = as }
function as:new()
  local as = setmetatable({}, as_mt)
  as.assets = {}
  as.assets_by_key = {}
  as.reserved_assets_by_table = {}
  as.reserved_asset_sets_by_key = {}
  as.assets_by_filepath = {}
  as.asset_sets_by_key = {}
  as.asset_data_by_key = {}
  
  as.load_thread = love.thread.newThread("threads/asset_loader.lua")
  as.load_channel = love.thread.newChannel()
  
  return as
end

function as:is_loaded()
  return self.load_finished
end

function as:add_audio(filepath, key)
  if type(key) == "number" then
    print("ERROR in audio_set:add_audio() - key must not be a number value")
    return
  end
  self:_add_asset(filepath, key, TYPE_AUDIO)
end

function as:add_image(filepath, key)
  if type(key) == "number" then
    print("ERROR in audio_set:add_image() - key must not be a number value")
    return
  end
  self:_add_asset(filepath, key, TYPE_IMAGE)
end

function as:add_audio_set(filepaths, key)
  if type(key) == "number" then
    print("ERROR in audio_set:add_audio_set() - key must not be a number value")
    return
  end
  self:_add_asset_set(filepaths, key, TYPE_AUDIO)
end

function as:add_image_set(filepaths, key)
  if type(key) == "number" then
    print("ERROR in audio_set:add_image_set() - key must not be a number value")
    return
  end
  self:_add_asset_set(filepaths, key, TYPE_IMAGE)
end

function as:add_asset_data(data_table, key)
  self.asset_data_by_key[key] = data_table
end

function as:_get_unique_id()
  local id = self.unique_id
  self.unique_id = self.unique_id + 1
  return id
end

function as:_add_asset_set(filepaths, key, asset_type)
  local set = {}
  for i=1,#filepaths do
    local k = self:_get_unique_id()
    set[i] = k
    self:_add_asset(filepaths[i], k, asset_type)
  end
  self.asset_sets_by_key[key] = set
end

function as:_add_asset(filepath, key, asset_type)
  if self.load_finished then
    print("ERROR in asset_set:_add_asset() - asset must be added before load()")
    return
  end
  
  if not love.filesystem.exists(filepath) then
    print("ERROR in asset_set:_add_asset() - file does not exist")
    return
  end
  
  if not self.assets_by_filepath[filepath] then
    self.assets[#self.assets+1] = self:_new_asset(filepath, key, asset_type)
    self.assets_by_filepath[filepath] = self.assets[#self.assets]
  else
    local asset = self.assets_by_filepath[filepath]
    asset.duplicates[#asset.duplicates + 1] = key
  end
  
  self.assets_to_load = self.assets_to_load + 1
end

function as:load()
  if self.load_initialized then
    return
  end

  local filepaths = {}
  local types = {}
  local assets = self.assets
  for i=1,#assets do
    filepaths[i] = assets[i].filepath
    types[i] = assets[i].asset_type
  end

  self.load_thread:start(self.load_channel)
  self.load_channel:supply(filepaths)
  self.load_channel:supply(types)

  self.is_loading = true
  self.load_initialized = true
end

function as:checkout_asset_set(key)
  local sets = self.asset_sets_by_key
  if not sets[key] then
    return false
  end
  local reserved = self.reserved_asset_sets_by_key
  local set = sets[key]
  local source_set = {}
  source_set.key = key
  reserved[source_set] = source_set
  sets[key] = nil
  
  for i=1,#set do
    local key = set[i]
    local source = self:checkout_asset(key)
    source_set[i] = source
  end
  
  local data = self.asset_data_by_key[key]
  
  return source_set, data
end

function as:return_asset_set(source_set)
  local reserved = self.reserved_asset_sets_by_key
  if reserved[source_set] then
    sources = reserved[source_set]
    reserved[source_set] = nil
    local keys = {}
    self.asset_sets_by_key[sources.key] = keys
    for i=1,#sources do
      local key = self:return_asset(sources[i])
      keys[i] = key
    end
  end
end

function as:get_asset_set(key)
  local sets = self.asset_sets_by_key
  if not sets[key] then
    return false
  end
  local keys = sets[key]
  local sources = {}
  for i=1,#keys do
    sources[i] = self:get_asset(keys[i])
  end
  
  local data = self.asset_data_by_key[key]
  
  return sources, data
end

function as:checkout_asset(key)
  local assets = self.assets_by_key
  
  if not assets[key] then
    return false
  end
  local reserved = self.reserved_assets_by_table
  local asset = assets[key]
  reserved[asset] = asset
  
  assets[key] = nil
  
  local data = self.asset_data_by_key[key]
  
  return asset, data
end

function as:return_asset(asset)
  local reserved = self.reserved_assets_by_table
  if reserved[asset] then
    local asset = reserved[asset]
    reserved[asset] = nil
    
    self.assets_by_key[asset.key] = asset
    return asset.key
  end
  
end

function as:get_asset(key)
  local assets = self.assets_by_key
  
  if not assets[key] then
    return false
  end

  return assets[key], self.asset_data_by_key[key]
end

function as:_new_asset(filepath, key, asset_type)
  local a = {}
  a.filepath = filepath
  a.key = key
  a.asset_type = asset_type
  a.source = nil                     -- image or audio source of the asset
  a.is_loaded = false
  a.duplicates = {}    -- if there are duplicate filepaths, this table will hold
                       -- keys for the duplicates for initialization after data
                       -- is loaded
  a.duration = nil     -- for audio assets only
  return a
end

function as:_update_load(dt)
  local err = self.load_thread:getError()
  if err then
    print(err)
    self.is_loading = false
    return
  end
  
  local assets_by_key = self.assets_by_key
  local channel = self.load_channel
  local count = channel:getCount()
  local idx = self.asset_load_idx
  for i=1,count do
    local data = channel:pop()
    local asset = self.assets[idx]
    
    local audio_duration
    if asset.asset_type == TYPE_IMAGE then
      asset.source = love.graphics.newImage(data)
    elseif asset.asset_type == TYPE_AUDIO then
      asset.source = love.audio.newSource(data)
      audio_duration = data:getDuration()
    end
    asset.is_loaded = true
    asset.duration = audio_duration
    self.assets_loaded = self.assets_loaded + 1
    assets_by_key[asset.key] = asset
    
    idx = idx + 1
    
    if #asset.duplicates > 0 then
      local keys = asset.duplicates
      for i=1,#keys do
        local key = keys[i]
        local new_asset = self:_new_asset(asset.filepath, key, asset.asset_type)
        
        local audio_duration
        if asset.asset_type == TYPE_IMAGE then
          new_asset.source = love.graphics.newImage(data)
        elseif asset.asset_type == TYPE_AUDIO then
          new_asset.source = love.audio.newSource(data)
          audio_duration = data:getDuration()
        end
        new_asset.is_loaded = true
        new_asset.duration = audio_duration
        self.assets_loaded = self.assets_loaded + 1
        assets_by_key[new_asset.key] = new_asset
        self.assets[#self.assets + 1] = new_asset
      end
    end
  end
  self.asset_load_idx = idx
  
  if self.assets_loaded == self.assets_to_load then
    self.is_loading = false
    self.load_finished = true
  end
  
  self.time_loading = self.time_loading + dt
end

------------------------------------------------------------------------------
function as:update(dt)
  if self.is_loading then
    self:_update_load(dt)
  end
end

------------------------------------------------------------------------------
function as:draw()
  if not self.debug then return end
  
  lg.setColor(0, 255, 0, 255)
  local x, y = 40, 40
  
  lg.setFont(courier_small)
  lg.print("time_loading: "..tostring(math.floor(self.time_loading*100)/100), x, y)
  y = y + 20
  lg.print("assets_loaded: "..tostring(self.assets_loaded), x, y)
  
  
end

return as









































