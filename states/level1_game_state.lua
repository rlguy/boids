local level1_game_state = state:new()
level1_game_state.label = 'level1_game'
level1_game_state.keyboard_layout = 'second_state'

local state = level1_game_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function level1_game_state.keypressed(key)
  state.level:keypressed(key)
  
  if key =='r' then
    tblock = tile_blocks[math.random(1,#tile_blocks)]
    if tblock then
      local tiles = tblock.tile_grid
      local fcurve = state.level.tile_explosion_fade_curves[1]
      for j=1,#tiles do
        for i=1,#tiles[j] do
          if math.random() then
            tiles[j][i]:flash(1, 2 + 0.5 * math.random(), fcurve)
          end
        end
      end
    end
  end
  
  if key == "t" then
    local n = 5
    for i=1,n do
      local r = i/n
      local min, max = 0.03, 0.1
      local power = min + r * (max - min)
      local min, max = 0.5, 8
      local time = min + r * (max - min)
      state.level.camera:shake(power, time)
    end
  end
  
  if key == 'g' then
    loop_sound:force_play()
  end
end

function level1_game_state.keyreleased(key)
  if key == "g" then
    loop_sound:stop()
  end
end

function level1_game_state.mousepressed(x, y, button)
  state.level:mousepressed(x, y, button)
  
  if button == 'r' then
    -- convert to mouse pos to world pos
    local cpos = state.level:get_camera():get_pos()
    local x, y = math.floor(cpos.x + x), math.floor(cpos.y + y)
    local tile = state.level:get_level_map():get_tile_at_position(vector2:new(x, y))
    local x, y = tile.x, tile.y
    local gradient = state.level:get_tile_palette():get_gradient(1)
    
    local area = 10
    local width, height
    if math.random() < 0.5 then
      width = math.random(1, math.floor(math.sqrt(area)))
      height = math.floor(area/width)
    else
      height = math.random(1, math.floor(math.sqrt(area)))
      width = math.floor(area/height)
    end
    local fade_curve = state.level.tile_explosion_fade_curves[1]
    
    local tblock = tile_block:new(state.level, x, y, width, height, gradient, fade_curve)
    tile_blocks[#tile_blocks + 1] = tblock
  end
  
end
function level1_game_state.mousereleased(x, y, button)
  state.level:mousereleased(x, y, button)
end

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function level1_game_state.load(level)  
  state.level = level
  
  -- tile block test
  tile_blocks = {}
  
  local sounds = level:get_audio_set()
  local loop, data = sounds:get_asset_set("pan_flute")
  local fade_time = data.crossfade_time
  local end_fade_time = data.end_crossfade_time
  local start_source = loop[1]
  local end_source = loop[2]
  local loop_sources = {}
  for i=3,#loop do
    loop_sources[#loop_sources + 1] = loop[i]
  end
  
  loop_sound = audio_loop:new(start_source, end_source, loop_sources, 
                              fade_time, end_fade_time)
  loop_sound:set_volume(0.5)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
t = 0
function level1_game_state.update(dt)
  local level = state.level
  
  -- tile light test
  local speed = 5
  if #tile_blocks > 0 then
    local dim = vector2:new(tile_blocks[#tile_blocks].rect_light.dimmer_ratio:get_vals())
    if lk.isDown("k") then dim.x = dim.x + 4 * dt end
    if lk.isDown("m") then dim.x = dim.x - 4 * dt end
    if dim.x < 0 then dim.x = 0 end
    if dim.x > 1 then dim.x = 1 end
    
    local speed = 70
    t = t + math.random() * speed*dt
    local min, max = 0.80,0.85
    dim.x = min + (0.5 + 0.5 * math.sin(t)) * (max - min)
    if tile_blocks[#tile_blocks] then
      tile_blocks[#tile_blocks].rect_light.dimmer_ratio:clone(dim)
    end
  end

  level:update(dt)
  
  for i=1,#tile_blocks do
    local tblock = tile_blocks[i]
    tblock:update(dt)
  end
 
  loop_sound:update(dt)
end
  

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function level1_game_state.draw()
  local screen_canvas = state.level:get_screen_canvas()
  local camera = state.level:get_camera()
  
  screen_canvas:clear()
  lg.setCanvas(screen_canvas)
  state.level:draw()
  lg.setCanvas()
  
  lg.setColor(255, 255, 255, 255)
  lg.draw(screen_canvas, 0, 0)
  
  -- tile block test
  for i=1,#tile_blocks do
    local tblock = tile_blocks[i]
    tblock:update_shader()
  end
  
  camera:set()
  for i=1,#tile_blocks do
    local tblock = tile_blocks[i]
    tblock:draw()
  end  
  camera:unset()
  
  loop_sound:draw()
end

return level1_game_state











