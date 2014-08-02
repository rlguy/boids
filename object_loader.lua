local loader = {}
loader.load_objects = function()

  -- object table identifiers
  HERO           = 101
  BBOX           = 111
  MAP_POINT      = 126
  SHARD          = 134
  TILE_BLOCK     = 135
  
  -- Supporting Objects
  vector2 = require('objects/vector2')
  state = require('objects/state')
  state_manager = require('objects/state_manager')
  timers = require('objects/timers')
  timer, master_timer = timers[1], timers[2]
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
  map_point = require('objects/map_point')
  level_collider = require('objects/level_collider')
  collider = require('objects/collider')
  curve = require('objects/curve')
  animation = require('objects/animation')
  animation_set = require('objects/animation_set')
  asset_set = require('objects/asset_set')
  

  -- Polygonizer objects
  implicit_point = require("objects/implicit_point")
  implicit_line = require("objects/implicit_line")
  implicit_rectangle = require("objects/implicit_rectangle")
  implicit_primitive_set = require("objects/implicit_primitive_set")
  polygonizer = require("objects/polygonizer")
  
  -- Boids objects
  seeker = require("objects/seeker")
  boid_graphic = require("objects/boid_graphic")
  boid = require("objects/boid")
  flock = require("objects/flock")
  flock_interface = require("objects/flock_interface")
  boid_emitter = require("objects/boid_emitter")
  boid_food_source = require("objects/boid_food_source")
end

return loader












