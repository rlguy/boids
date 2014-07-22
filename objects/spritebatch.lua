
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- spritebatch object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local spritebatch = {}
local sb = spritebatch
sb.table = 'spritebatch'
sb.debug = true
sb.sprites_per_batch = nil
sb.spritesheets = nil           -- table of images
sb.layers = nil                 -- table of spritebatch layers indexed by image
sb.total_sprites = 0


local spritebatch_mt = { __index = spritebatch }
function spritebatch:new(spritesheets, sprites_per_batch)
  local sb = setmetatable({}, spritebatch_mt)
  sprites_per_batch = sprite_per_batch or 2000
  
  self.sprites_per_batch = sprites_per_batch
  
  local images = {}
  local layers = {}
  for i=1,#spritesheets do
    local img = spritesheets[i]
    images[i] = img
    layers[img] = spritebatch._new_layer(sb, img, sprites_per_batch)
  end
  self.spritesheets = images
  self.layers = layers
  
  return sb
end

function spritebatch:_new_layer(spritesheet, max_sprites)
  local layer = {}
  layer.spritesheet = spritesheet
  layer.spritebatches = {lg.newSpriteBatch(spritesheet, max_sprites, "dynamic")}
  layer.spritebatch_counts = {0}
  layer.spritebatches_by_sprite_id = {}
  layer.current_sheet = 1
  layer.max_sprites = max_sprites
  
  return layer
end

-- returns 3 identifiers for locating the sprite:
-- sprite_id, the id returned by love's spritebatch
-- spritebatch_id, the spritebatch index in layer.spritebatches
-- layer_id, the layer index in self.layers (a spritesheet image)
function spritebatch:add(spritesheet, quad, x, y, rotation, sx, sy, ox, oy)
  local layer = self.layers[spritesheet]
  local idx = layer.current_sheet
  local counts = layer.spritebatch_counts
  
  if counts[idx] >= layer.max_sprites then
    idx = idx + 1
    layer.spritebatches[idx] = lg.newSpriteBatch(spritesheet, layer.max_sprites, "dynamic")
    counts[idx] = 0
    layer.current_sheet = idx
  end
  local batch = layer.spritebatches[idx]
  local sprite_id = batch:add(quad, x, y, rotation, sx, sy, ox, oy)
  local layer_id = spritesheet
  local spritebatch_id = idx
  
  counts[idx] = counts[idx] + 1
  
  self.total_sprites = self.total_sprites + 1
  return sprite_id, spritebatch_id, layer_id
end

function spritebatch:remove(sprite_id, spritebatch_id, layer_id)
  local layer = self.layers[layer_id]
  local spritebatch = layer.spritebatches[spritebatch_id]
  spritebatch:set(sprite_id, 0, 0, 0, 0, 0)
end

------------------------------------------------------------------------------
function spritebatch:update(dt)
end

------------------------------------------------------------------------------
function spritebatch:draw_layer(spritesheet)
  local layer = self.layers[spritesheet]
  local batches = layer.spritebatches
  for i=1,#batches do
    lg.draw(batches[i], 0, 0)
  end
end

return spritebatch





















