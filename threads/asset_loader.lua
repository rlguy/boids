require "love.filesystem"
require "love.sound"
require "love.image"

local TYPE_IMAGE = 0
local TYPE_SOUND = 1

local args = {...}
local channel = args[1]

local filepaths
while not filepaths do
  filepaths = channel:pop()
end

local types
while not types do
  types = channel:pop()
end

for i=1,#filepaths do
  local path = filepaths[i]
  local asset_type = types[i]
  
  if asset_type == TYPE_IMAGE then
    local image_data = love.image.newImageData(path)
    channel:push(image_data)
  elseif asset_type == TYPE_SOUND then
    local sound_data = love.sound.newSoundData(path)
    channel:push(sound_data)
  end
end
