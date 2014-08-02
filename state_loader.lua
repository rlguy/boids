-- all the states the program
local states = {}
states.main_screen_load_state = require('states/main_screen_load_state')
states.main_screen_state = require('states/main_screen_state')
states.overview_screen_state = require('states/overview_screen_state')

states.flockmates_screen_state = require('states/flockmates_screen_state')
states.flockmates_demo_load_state = require('states/flockmates_demo_load_state')
states.flockmates_demo_state = require('states/flockmates_demo_state')

states.query_screen_state = require('states/query_screen_state')
states.query_demo_load_state = require('states/query_demo_load_state')
states.query_demo_state = require('states/query_demo_state')

states.rules_screen_state = require('states/rules_screen_state')
states.rule_alignment_screen_state = require('states/rule_alignment_screen_state')
states.rule_cohesion_screen_state = require('states/rule_cohesion_screen_state')
states.rule_separation_screen_state = require('states/rule_separation_screen_state')
states.rules_demo_load_state = require('states/rules_demo_load_state')
states.rules_demo_state = require('states/rules_demo_state')

states.obstacle_screen_state = require('states/obstacle_screen_state')
states.obstacle_demo_load_state = require('states/obstacle_demo_load_state')
states.obstacle_demo_state = require('states/obstacle_demo_state')

states.food_screen_state = require('states/food_screen_state')
states.food_demo_load_state = require('states/food_demo_load_state')
states.food_demo_state = require('states/food_demo_state')
  
states.emitter_screen_state = require('states/emitter_screen_state')
states.emitter_demo_load_state = require('states/emitter_demo_load_state')
states.emitter_demo_state = require('states/emitter_demo_state')

states.graph_screen_state = require('states/graph_screen_state')
states.graph_demo_load_state = require('states/graph_demo_load_state')
states.graph_demo_state = require('states/graph_demo_state')

states.animation_screen_state = require('states/animation_screen_state')
states.animation_demo_load_state = require('states/animation_demo_load_state')
states.animation_demo_state = require('states/animation_demo_state')

states.exit_screen_state = require('states/exit_screen_state')

return states
