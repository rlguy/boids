local loader = {}
loader.load_objects = function()

  -- object table identifiers
  HERO           = 101
  BBOX           = 111
  MAP_POINT      = 126
  SHARD          = 134
  TILE_BLOCK     = 135
  
  -- object tables
  vector2 = require('objects/vector2')
  state = require('objects/state')
  state_manager = require('objects/state_manager')
  
  timers = require('objects/timers')
  timer, master_timer = timers[1], timers[2]
  
  events = require('objects/events')
  event, event_manager = events[1], events[2]
  
  bbox = require('objects/bbox')
  
  mouse_input = require('objects/mouse_input')
  
  tile_types = require('objects/tile_types')
  tile = require('objects/tile')
  tile_chunk = require("objects/tile_chunk")
  tile_gradient = require('objects/tile_gradient')
  tile_palette = require('objects/tile_palette')
  tile_layer = require('objects/tile_layer')
  tile_map = require('objects/tile_map')
  level_map = require('objects/level_map')
  level = require('objects/level')
  
  camera2d = require("objects/camera2d")
  
  physics = require("objects/physics")
  
  cubic_spline = require('objects/cubic_spline')
  
  hero_shape = require('objects/hero_shape')
  hero = require('objects/hero')
  
  map_point = require('objects/map_point')
  map_body = require('objects/map_body')
  
  level_collider = require('objects/level_collider')
  collider = require('objects/collider')
  
  gun = require('objects/gun')
  laser_gun = require('objects/laser_gun')
  bullet = require('objects/bullet')
  laser_bullet = require('objects/laser_bullet')

  curve = require('objects/curve')
  power_meter = require("objects/power_meter")
  
  ray = require('objects/ray')
  rectangle_tile_cover = require('objects/rectangle_tile_cover')
  
  spritebatch = require('objects/spritebatch')
  animation = require('objects/animation')
  animation_set = require('objects/animation_set')
  shard = require('objects/shard')
  shard_set = require('objects/shard_set')
  shard_explosion = require('objects/shard_explosion')
  
  tile_explosion = require('objects/tile_explosion')
  tile_light = require('objects/tile_light')
  rectangle_tile_light = require('objects/rectangle_tile_light')
  tile_block = require('objects/tile_block')
  
  bloom_effect = require('objects/bloom_effect')
  
  asset_set = require('objects/asset_set')
  
  audio_sample_set = require('objects/audio_sample_set')
  audio_loop = require('objects/audio_loop')
  
  point_trail = require("objects/point_trail")
  
  shape = require('objects/shape')
  shape_trail = require('objects/shape_trail')
  
  game_font_char = require('objects/game_font_char')
  game_font = require('objects/game_font')
  game_font_string = require('objects/game_font_string')
  
  ui_button = require("objects/ui_button")
  ui_option_switch = require("objects/ui_option_switch")
  ui_slider = require("objects/ui_slider")
  ui_text_input = require("objects/ui_text_input")
  
  main_menu = require("objects/main_menu")
  
  seeker = require("objects/seeker")
  boid_graphic = require("objects/boid_graphic")
  boid = require("objects/boid")
  flock = require("objects/flock")
  flock_interface = require("objects/flock_interface")
  
  implicit_point = require("objects/implicit_point")
  implicit_line = require("objects/implicit_line")
  implicit_rectangle = require("objects/implicit_rectangle")
  implicit_primitive_set = require("objects/implicit_primitive_set")
  polygonizer = require("objects/polygonizer")
  
  boid_emitter = require("objects/boid_emitter")
  boid_food_source = require("objects/boid_food_source")
end

return loader












