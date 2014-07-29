local main_menu_load = state:new()
main_menu_load.label = 'main_menu_load'

local state = main_menu_load

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
function main_menu_load.keypressed(key)
end
function main_menu_load.keyreleased(key)
end
function main_menu_load.mousepressed(x, y, button)
end
function main_menu_load.mousereleased(x, y, button)
end

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function main_menu_load.load(str)
  local level = level:new()
  state.level = level
  state.pre_level_load(level)
  level:load()
end

-- PRE LEVEL LOAD FUNCTIONS
function main_menu_load.initialize_audio(level)
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

function main_menu_load.initialize_camera(level)
  local x = TILE_WIDTH * 36
  local y = TILE_HEIGHT * 27
  local start_pos = vector2:new(x, y)
  local camera = camera2d:new(start_pos)
  level:set_camera(camera)
end

function main_menu_load.construct_level_map(level)
  -- colours
  local C_BLACK = {0, 0, 0, 255}
  local ncolors = 10
  
  local dir = "gradients/named/"
  local blend = 0.1
  local g_background = tile_gradient:new(require( dir.."allwhite"), ncolors)
  local g_wall1 = tile_gradient:new(require( dir.."allwhite"), ncolors)
  local g_black = tile_gradient:new(require( dir.."greenyellow"), ncolors)
                                         
  g_wall1:add_diagonals()
  g_wall1:add_border(C_BLACK, blend)
  g_black:add_diagonals()
  g_black:add_border(C_BLACK, 0.2)
  g_background:add_border(C_BLACK, blend)
                                         
  local palette = tile_palette:new()
  palette:add_gradient(g_background, "allwhite")
  palette:add_gradient(g_wall1, "blue")
  palette:add_gradient(g_black, "black")
  palette:load()
  state.level:set_tile_palette(palette)
  
  -- load map
  local map_directory = "images/menu"
  local back = "background.png"
  local wall = "wall1.png"
  local map_data = require(map_directory.."/menu_map_data")
  
  -- source images
  local imgdata_layers = {}
  imgdata_layers[back] = li.newImageData(map_directory.."/"..back)
  
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
  	                               palette:get_gradient("allwhite"), 0, T_WALK)
      tmap:add_tile_layer(layer)
  	end
  	if slice_data[wall] then
  	  --[[
  	  local layer_data = slice_data[wall]
  	  local x, y = layer_data.x, layer_data.y
  	  local w, h = layer_data.width, layer_data.height
  	  local layer = tile_layer:new(imgdata_layers[wall], x, y, w, h,
  	                               palette:get_gradient("blue"), 0, T_WALL)
      tmap:add_tile_layer(layer)
      ]]--
  	end
  	
  	level_map:add_tile_map(tmap, offx, offy)
  end
  level:set_level_map(level_map)
end

function main_menu_load.pre_level_load(level)
  state.initialize_camera(level)
  state.initialize_audio(level)
  state.construct_level_map(level)
end

-- POST LEVEL LOAD FUNCTIONS
function main_menu_load.initialize_player(level)
end
function main_menu_load.initialize_tile_explosions(level)
  local flash_curve_data = require('curves/temp01-raw')
  local flash_curve = curve:new(flash_curve_data, 700)
  local fade_curve_data = require('curves/fade01')
  local fade_curve = curve:new(fade_curve_data, 700)
  level:set_tile_explosion_curves({flash_curve}, {fade_curve})
end
function main_menu_load.initialize_cube_shard_set(level)
end
function main_menu_load.initialize_shard_sets(level)
end
function main_menu_load.initialize_mouse_input(level)
  level:set_mouse(MOUSE_INPUT)
end
function main_menu_load.initialize_audio_objects(level)
end
function main_menu_load.initialize_polygonizer(level)
  local level_map = level:get_level_map()
  local palette = level:get_tile_palette()
  local tile_gradient = palette:get_gradient("black")
  local tile_type = T_WALL
  level_map:set_polygonizer(tile_type, tile_gradient)
  
  --[[
  level_map:add_point_to_polygonizer(1000, 1000, 600)
  level_map:add_point_to_polygonizer(1300, 1000, 300)
  level_map:set_polygonizer_surface_threshold(0.5)
  level_map:update_polygonizer()
  level_map:_reset_edited_tiles()
  ]]--
  
  level_map:set_source_polygonizer(T_WALK, tile_gradient)
end

function main_menu_load.post_level_load(level)
  state.initialize_mouse_input(level)
  state.initialize_player(level)
  state.initialize_shard_sets(level)
  state.initialize_tile_explosions(level)
  state.initialize_audio_objects(level)
  state.initialize_polygonizer(level)
  
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function main_menu_load.update(dt)
  local level = state.level
  level:update(dt)

  if level:is_loaded() then
    state.post_level_load(level)
    INVADERS:load_next_state(level)
  end
end
  

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function main_menu_load.draw()
  love.graphics.setBackgroundColor(0, 0, 0, 255)
  
end

return main_menu_load


















