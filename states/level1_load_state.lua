local level1_load_state = state:new()
level1_load_state.label = 'level1_load'

local state = level1_load_state

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local flash_curve = curve:new(require("curves/temp01-raw"))
function level1_load_state.keypressed(key)

  toggle:keypressed(key)
  
  text_input:keypressed(key)
end
function level1_load_state.keyreleased(key)
  text_input:keyreleased(key)
end
function level1_load_state.mousepressed(x, y, button)
  
  toggle:mousepressed(x, y, button)
  
  for i=1,#sliders do
    sliders[i]:mousepressed(x, y, button)
  end
  
  text_input:mousepressed(x, y, button)
end
function level1_load_state.mousereleased(x, y, button)

  toggle:mousereleased(x, y, button)
  
  for i=1,#sliders do
    sliders[i]:mousereleased(x, y, button)
  end
  
  text_input:mousereleased(x, y, button)
end

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function level1_load_state.load(str)
  
  local fade_in = curve:new(require("curves/fast_fade_in"), 600)
  local fade_out = curve:new(require("curves/fade_out"), 600)
  

  local level = level:new()
  state.level = level
  
  -- button test
  font = game_font:new(require("fonts/default/pattern"), 4)
  local grad = font:add_gradient(require("gradients/named/orangeyellow"), "orangeyellow")
  grad:add_border({0, 0, 0, 255}, 0.5)
  local grad = font:add_gradient(require("gradients/named/green"), "green")
  grad:add_border({0, 0, 0, 255}, 0.4)
  local grad = font:add_gradient(require("gradients/named/blue"), "blue")
  grad:add_border({0, 0, 0, 255}, 0.4)
  font:load()
  
  local colors = {"orangeyellow", "green", "blue"}
  
  local modes = love.window.getFullscreenModes()
  table.sort(modes, function(a, b) return a.width*a.height < b.width*b.height end)
 
  
  -- option test
  local options = {}
  local option_data = {}
  option_data.options = options
  option_data.font = font
  option_data.gradient = "orangeyellow"
  option_data.mouse = MOUSE_INPUT
  option_data.id = "t1"
  
  for i=1,#modes do
    local str = ""
    local w, h = modes[i].width, modes[i].height
    if w >= 1000 then
      str = str..tostring(w).."x"
    else
      str = str.." "..tostring(w).."x"
    end
    if h >= 1000 then
      str = str..tostring(h)
    else
      str = str..tostring(h).." "
    end
    
    options[i] = {text = str,
                  gradient = "orangeyellow",
                  id = {w, h},
                  intensity = 0.95}
  end
  
  local x, y, width, height = 460, 20, 390, 40
  toggle = ui_option_switch:new(option_data, x, y, width, height)
  toggle:set_toggle_action(function(id1, id2) print(id1, id2[1], id2[2]) end)
  toggle:set_gradient("blue")
  toggle:set_option(#options)
  toggle:set_keyboard_input_chars({"left", "a"}, {"right", "d"})
  toggle:set_focus(true)
  --toggle:set_position(300, 300)
  
  
  -- slider test
  sliders = {}
  local n = 3
  local x, y, width, height = 460, 75, 390, 40
  
  for i=1,n do
    local slider_data = {font = font,
                         gradient = "blue",
                         text = "---------------",
                         id = i,
                         mouse = MOUSE_INPUT,
                         min_intensity = 0.5,
                         max_intensity = 1}
    slider = ui_slider:new(slider_data, x, y, width, height)
    slider:set_value(0.5)
    slider:set_range(1,3)
    slider:set_on_value_change_action(function(id, val) print(id, val) end)
    sliders[i] = slider
    
    y = y + 50
  end
  
  -- text input test
  local chars = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
  local x, y, width, height = x, y, width, height
  local data = {font = font,
                gradient = "blue",
                text = "[========]",
                cursor_text = "|",
                id = "input1",
                size = 8,
                char_constants = chars,
                mouse = MOUSE_INPUT}
  text_input = ui_text_input:new(data, x, y, width, height)
  --text_input:set_on_valid_character_action(function(id, key) print(id, key, true) end)
  --text_input:set_on_invalid_character_action(function(id, key) print(id, key, false) end)
  --text_input:set_on_character_delete_action(function(id, key) print(id, key, "delete") end)
  
  state.pre_level_load(level)
  level:load()
  
  
end

-- PRE LEVEL LOAD FUNCTIONS
function level1_load_state.initialize_audio(level)
  -- table of all audio filepaths that will be used for this state
  -- key will be used for retrieving audio source once loaded
  local sounds = {}
  
  sounds.test_file = {"audio/test_audio-mono.ogg"}
  sounds.test_file.data = {key3 = 3, key4 = 4}
  
  sounds.set = {"audio/test_audio-mono.ogg", "audio/test_audio-mono.ogg"}
  sounds.set.data = {key1 = 1, key2 = 2}
  
  sounds.pan_flute = {"audio/stereo/loops/pan_flute/start.ogg",
                      "audio/stereo/loops/pan_flute/end.ogg",
                      "audio/stereo/loops/pan_flute/loop01.ogg"}
  sounds.pan_flute.data = {crossfade_time = 0.85, end_crossfade_time = 0.630}
  
  sounds.test_samples = {"audio/mono/temp_bangs/bang01.ogg",
                         "audio/mono/temp_bangs/bang02.ogg",
                         "audio/mono/temp_bangs/bang03.ogg",
                         "audio/mono/temp_bangs/bang04.ogg",
                         "audio/mono/temp_bangs/bang05.ogg",
                         "audio/mono/temp_bangs/bang06.ogg",
                         "audio/mono/temp_bangs/bang07.ogg",
                         "audio/mono/temp_bangs/bang08.ogg",
                         "audio/mono/temp_bangs/bang09.ogg",
                         "audio/mono/temp_bangs/bang10.ogg",
                         "audio/mono/temp_bangs/bang11.ogg",
                         "audio/mono/temp_bangs/bang12.ogg"}
  sounds.test_samples.data = {}
  
  level:add_audio_files(sounds)
end

function level1_load_state.initialize_camera(level)
  local starts = {{TILE_WIDTH * 194, TILE_HEIGHT * 497}} 
  local r = math.random(1,#starts)
  local start_pos = vector2:new(starts[r][1], starts[r][2])
  local camera = camera2d:new(start_pos)
  level:set_camera(camera)
  
  -- initialize shake curves
  local x_curves, y_curves = {}, {}
  local x_curve_files = {"curves/shake-01a","curves/shake-02a","curves/shake-03a"}
  local y_curve_files = {"curves/shake-01b","curves/shake-02b","curves/shake-03b"}
  for i=1,#x_curve_files do
    local xpoints = require(x_curve_files[i])
    local ypoints = require(y_curve_files[i])
    x_curves[i] = curve:new(xpoints, 1000)
    y_curves[i] = curve:new(ypoints, 1000)
  end
  level:set_camera_shake_curves(x_curves, y_curves)
end

function level1_load_state.construct_level_map(level)
  -- colours
  local C_BLACK = {0, 0, 0, 255}
  local ncolors = 5 * math.floor(MAX_IMAGE_WIDTH / TILE_WIDTH)
  print("num_colors: "..tostring(ncolors))
  
  local dir = "gradients/named/"
  local blend = 0.03
  local g_background = tile_gradient:new(require( dir.."orangeyellow"), ncolors)
  local g_wall1 = tile_gradient:new(require( dir.."greenyellow2"), ncolors)
  local g_wall2 = tile_gradient:new(require( dir.."allblack"), ncolors)
  local g_wall3 = tile_gradient:new(require( dir.."allblack"), ncolors)
                                         
  g_wall1:add_diagonals()
  g_wall2:add_diagonals()
  g_wall3:add_diagonals()
  
  g_wall1:add_border(C_BLACK, blend)
  g_wall2:add_border(C_BLACK, blend)
  --g_wall3:add_border(C_BLACK, blend)
  g_background:add_border(C_BLACK, blend)
  
  local bcurve = curve:new(require("curves/linear_curve"))
  g_wall3:add_border_blend_curve({255,255,255,255}, bcurve, 0, 1)
  g_wall3:add_border_gradient(require( dir.."orangeyellow"))
                                         
  local palette = tile_palette:new()
  palette:add_gradient(g_background, 1)
  palette:add_gradient(g_wall1, 2)
  palette:add_gradient(g_wall2, 3)
  palette:add_gradient(g_wall3, 4)
  palette:load()
  state.level:set_tile_palette(palette)
  
  -- load map
  local map_directory = "images/level0"
  local back = "background.png"
  local wall_small = "special_wall.png"
  local wall_medium = "inner_wall.png"
  local wall_large = "outer_wall.png"
  local map_data = require(map_directory.."/level0_map_data")
  
  -- source images
  local imgdata_layers = {}
  imgdata_layers[back] = li.newImageData(map_directory.."/"..back)
  imgdata_layers[wall_small] = li.newImageData(map_directory.."/"..wall_small)
  imgdata_layers[wall_medium] = li.newImageData(map_directory.."/"..wall_medium)
  imgdata_layers[wall_large] = li.newImageData(map_directory.."/"..wall_large)
  
  -- construct level map
  local level_map = level_map:new(level)
  for i=1,#map_data do
  	local slice_data = map_data[i]
  	local offx, offy = slice_data[back].x + 1, slice_data[back].y + 1
  	local w, h = slice_data[back].width, slice_data[back].height
  	
  	local tmap = tile_map:new(level, w, h)
  	if slice_data[back] then
  	  local layer_data = slice_data[back]
  	  local x, y = layer_data.x, layer_data.y
  	  local w, h = layer_data.width, layer_data.height
  	  local layer = tile_layer:new(imgdata_layers[back], x, y, w, h, 
  	                               palette:get_gradient(1), 0, T_WALK)
      tmap:add_tile_layer(layer)
  	end
  	if slice_data[wall_small] then
  	  local layer_data = slice_data[wall_small]
  	  local x, y = layer_data.x, layer_data.y
  	  local w, h = layer_data.width, layer_data.height
  	  local layer = tile_layer:new(imgdata_layers[wall_small], x, y, w, h,
  	                               palette:get_gradient(2), 0, T_WALL)
      tmap:add_tile_layer(layer)
  	end
  	if slice_data[wall_medium] then
  	  local layer_data = slice_data[wall_medium]
  	  local x, y = layer_data.x, layer_data.y
  	  local w, h = layer_data.width, layer_data.height
  	  local layer = tile_layer:new(imgdata_layers[wall_medium], x, y, w, h, 
  	                               palette:get_gradient(3), 0, T_WALL)
      tmap:add_tile_layer(layer)
  	end
  	if slice_data[wall_large] then
  	  local layer_data = slice_data[wall_large]
  	  local x, y = layer_data.x, layer_data.y
  	  local w, h = layer_data.width, layer_data.height
  	  local layer = tile_layer:new(imgdata_layers[wall_large], x, y, w, h, 
  	                               palette:get_gradient(4), 0, T_WALL)
      tmap:add_tile_layer(layer)
  	end
  	
  	level_map:add_tile_map(tmap, offx, offy)
  end
  level:set_level_map(level_map)
end

function level1_load_state.pre_level_load(level)
  state.initialize_camera(level)
  state.initialize_audio(level)
  state.construct_level_map(level)
end

-- POST LEVEL LOAD FUNCTIONS
function level1_load_state.initialize_player(level)
  local cpos = level:get_camera():get_center()
  local hero_pos = level:get_camera():get_center()
  local hero = hero:new(level, hero_pos)
  level:set_player(hero)
end

function level1_load_state.initialize_tile_explosions(level)
  local flash_curve_data = require('curves/temp01-raw')
  local flash_curve = curve:new(flash_curve_data, 700)
  local fade_curve_data = require('curves/fade01')
  local fade_curve = curve:new(fade_curve_data, 700)
  level:set_tile_explosion_curves({flash_curve}, {fade_curve})
end

function level1_load_state.initialize_cube_shard_set(level)
  -- initialize animation sets
  local tetra_anim_data = require('images/animations/cube_animations_data6')
  local tetra_sheet = lg.newImage('images/animations/cube_spritesheet6.png')
  local tetra_shadow_sheet = lg.newImage('images/animations/cube_shadow_spritesheet6.png')
  local anim_set = animation_set:new(tetra_sheet, tetra_anim_data)
  local anim_shadow_set = animation_set:new(tetra_shadow_sheet, tetra_anim_data)
  level:add_animation_set(anim_set)
  level:add_animation_set(anim_shadow_set)
  
  -- initialize shard sets
  local curve_files = {'curves/shard_motion_curve01', 
                        'curves/shard_motion_curve02',
                        'curves/shard_motion_curve03',
                        'curves/shard_motion_curve04'}
  local height_curve_files = {'curves/shard_height_curve01', 
                               'curves/shard_height_curve02',
                               'curves/shard_height_curve03',
                               'curves/shard_height_curve04'}
  local motion_curves = {}
  for i=1,#curve_files do
    local points = require(curve_files[i])
    motion_curves[i] = curve:new(points, 500)
  end
  local height_curves = {}
  for i=1,#height_curve_files do
    local points = require(height_curve_files[i])
    height_curves[i] = curve:new(points, 500)
  end
  
  local l_dir_x, l_dir_y, l_dir_z = -1, 1, -4
  local len = vector3_magnitude(l_dir_x, l_dir_y, l_dir_z)
  l_dir_x, l_dir_y, l_dir_z = l_dir_x / len, l_dir_y / len, l_dir_z / len
  local shard_set = shard_set:new(level, anim_set, anim_shadow_set, 
                                   motion_curves, height_curves,
                                   l_dir_x, l_dir_y, l_dir_z)
  level:add_cube_shard_set(shard_set, motion_curves, height_curves)
end

function level1_load_state.initialize_shard_sets(level)
  state.initialize_cube_shard_set(level)
end

function level1_load_state.initialize_mouse_input(level)
  level:set_mouse(MOUSE_INPUT)
end

function level1_load_state.initialize_audio_objects(level)
  local sounds = level:get_audio_set()
  local bangs = sounds:get_asset_set("test_samples")
  local sample_set = audio_sample_set:new(bangs)
  level:add_explosion_sound_effects(sample_set)
end

function level1_load_state.post_level_load(level)
  state.initialize_mouse_input(level)
  state.initialize_player(level)
  state.initialize_shard_sets(level)
  state.initialize_tile_explosions(level)
  state.initialize_audio_objects(level)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function level1_load_state.update(dt)
  local level = state.level
  level:update(dt)

  if level:is_loaded() then
    state.post_level_load(level)
    INVADERS:load_next_state(level)
  end
  
  -- option test
  toggle:update(dt)
  
  -- slider test
  for i=1,#sliders do
    sliders[i]:update(dt)
  end
  
  -- input test
  text_input:update(dt)
end
  

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function level1_load_state.draw()
  love.graphics.setBackgroundColor(0, 0, 0, 255)
  
  --[[
  lg.setColor(63,165,0,255)
  
  local str = "LOADING"
  lg.setFont(courier_large)
  local str_width = lg.getFont():getWidth(str)
  local str_height = lg.getFont():getHeight(str)
  local x, y = 0.5 * SCR_WIDTH - 0.5 * str_width, 0.5 * SCR_HEIGHT - 0.5 * str_height
  lg.print(str, x, y)
  
  state.level:get_audio_set():draw()
  ]]--
  
  
  -- option test
  toggle:draw()
  
  -- slider test
  for i=1,#sliders do
    sliders[i]:draw()
  end
  
  -- input_test
  text_input:draw()
  
end

return level1_load_state


















