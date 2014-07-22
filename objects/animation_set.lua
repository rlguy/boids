
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- animation_set object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local animation_set = {}
local as = animation_set
as.table = 'animation_set'
as.animations = nil                   -- all unique animations
as.animations_pool = nil              -- pool of available animations
as.active_animations = nil            -- all dispatched animations


local animation_set_mt = { __index = animation_set }
function animation_set:new(spritesheet, data)
  local as = setmetatable({}, animation_set_mt)
  
  local animations = {}
  local imgw, imgh = spritesheet:getWidth(), spritesheet:getHeight()
  for i=1,#data do
    local sheet = data[i]
    local w, h = sheet.width, sheet.height
    local frames = sheet.num_frames
    local fps = sheet.fps
    local sw, sh = sheet.sprite_width, sheet.sprite_height
    local x, y = sheet.x, sheet.y
    
    local quads = {}
    for j=1,frames do
      local q = lg.newQuad(x, y, sw, sh, imgw, imgh)
      quads[frames - (j-1)] = q
      
      x = x + sw
      if x + sw > imgw then
        x = 0
        y = y + sh
      end
    end
    
    animations[i] = animation:new(spritesheet, quads, fps)
    animations[i]:set_id(i)
  end
  as.animations = animations
  
  local pool = {}
  for i=1,#animations do
    pool[i] = animations[i]
  end
  as.animations_pool = pool
  as.active_animations = {}
  as.spritesheet = spritesheet
  
  return as
end

function animation_set:get_animation(id)
  if id then
    return self:_get_animation_by_id(id)
  end

  local pool = self.animations_pool
  local active = self.active_animations
  
  if #pool == 0 then
    for i=1,50 do
      local anims = self.animations
      local rand_anim = anims[math.random(1, #anims)]
      local id = rand_anim:get_id()
      local new_anim = rand_anim:clone()
      new_anim:set_id(id)
      pool[#pool + 1] = new_anim
    end
  end 
  
  local anim = table.remove(pool, math.random(1,#pool))
  anim:_init()
  active[#active + 1] = anim
  
  return anim
end

function animation_set:get_spritesheet()
  return self.spritesheet
end

function animation_set:_get_animation_by_id(id)
  local pool = self.animations_pool
  local active = self.active_animations
  
  local anim_exists = false
  local anim_idx
  for i=1,#pool do
    if pool[i].id == id then
      anim_exists = true
      anim_idx = i
      break
    end
  end
  
  local anim
  if anim_exists then
    anim = table.remove(pool, anim_idx)
    anim:_init()
    active[#active + 1] = anim
  else
    local animations = self.animations
    anim = animations[id]:clone()
    anim:set_id(id)
    anim:_init()
    active[#active + 1] = anim
  end
  
  return anim
  
end

------------------------------------------------------------------------------
function animation_set:update(dt)
  local active = self.active_animations
  for i=#active,1,-1 do
    local anim = active[i]
    anim:update(dt)
    
    if not anim.is_active then
      table.remove(active, i)
      self.animations_pool[#self.animations_pool + 1] = anim
    end
  end
end

------------------------------------------------------------------------------
function animation_set:draw()
end

return animation_set






















