
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- animation object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local animation = {}
local anim = animation
anim.x = 0
anim.y = 0
anim.width = 0
anim.height = 0
anim.angle = 0
anim.scale = 1
anim.table = 'animation'
anim.spritesheet = nil
anim.quads = nil
anim.num_frames = nil
anim.fps = nil
anim.id = nil

anim.is_active = false
anim.is_playing = false
anim.on_last_frame = false
anim.current_quad = nil
anim.current_frame = nil
anim.current_time = nil
anim.length = nil
anim.inverse_length = nil

local animation_mt = { __index = animation }
function animation:new(spritesheet, quads, fps)
  local anim = setmetatable({}, animation_mt)
  
  anim.spritesheet = spritesheet
  anim.quads = quads
  anim.num_frames = #quads
  anim.fps = fps
  anim.length = (1/fps) * anim.num_frames
  anim.inverse_length = 1 / anim.length
  local x, y, w, h = quads[1]:getViewport()
  anim.width = w
  anim.height = h
  anim.angle = 0
  
  anim.current_quad = quads[1]
  anim.current_frame = 1
  anim.current_time = 0
  anim.speed_factor = 1
  
  return anim
end

function animation:clone()
  local spritesheet = self.spritesheet
  local quads = self.quads
  local fps = self.fps
  return animation:new(spritesheet, quads, fps)
end

function animation:set_speed(speed)
  self.speed_factor = speed
end

function animation:set_id(id)
  self.id = id
end

function animation:get_id()
  return self.id
end

function animation:set_position(x, y)
  self.x, self.y = x, y
end

function animation:set_center(x, y)
  self.x, self.y = x, y
end

function animation:set_rotation(r)
  self.angle = r
end

function animation:set_scale(s)
  self.scale = s
end

function animation:play()
  self.is_playing = true
end

function animation:stop()
  self.is_playing = false
end

function animation:reset()
  self.is_playing = false
  self.current_quad = self.quads[1]
  self.current_frame = 1
  self.current_time = 0
end

function animation:is_running()
  return self.is_playing
end

function animation:progress()
  return self.current_time * self.inverse_length
end

function animation:_init()
  self.is_playing = false
  self.current_quad = self.quads[1]
  self.current_frame = 1
  self.current_time = 0
  self.is_active = true
  self.angle = 0
  self.scale = 1
end

function animation:destroy()
  self.is_active = false
end

function animation:get_last_frame()
  return self.quads[#self.quads]
end

------------------------------------------------------------------------------
function animation:update(dt)
  if not self.is_playing then
    return
  end
  
  if self.on_last_frame then
    self.on_last_frame = false
    self.is_playing = false
    return
  end
  
  local time = self.current_time + self.speed_factor * dt
  if time > self.length then
    time = self.length
    self.on_last_frame = true
  end
  self.current_time = time

  local progress = time / self.length
  local frame = math.floor(1 + progress * (self.num_frames - 1))
  if frame ~= self.current_frame then
    self.current_quad = self.quads[frame]
    self.current_frame = frame
  end
  
end

------------------------------------------------------------------------------
function animation:draw()
  if not self.is_active then
    return
  end
  lg.draw(self.spritesheet, self.current_quad, self.x, self.y, 
          self.angle, self.scale, self.scale, 
          0.5 * self.width, 0.5 * self.height)
end

return animation











