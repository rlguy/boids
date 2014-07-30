-- all the states the game
local states = {}
states.main_menu_load_state = require('states/main_menu_load_state')
states.main_menu_state = require('states/main_menu_state')
states.level1_load_state = require('states/level1_load_state')
states.level1_game_state = require('states/level1_game_state')

states.main_screen_load_state = require('states/main_screen_load_state')
states.main_screen_state = require('states/main_screen_state')
states.overview_screen_state = require('states/overview_screen_state')
states.flockmates_screen_state = require('states/flockmates_screen_state')
states.flockmates_demo_load_state = require('states/flockmates_demo_load_state')
states.flockmates_demo_state = require('states/flockmates_demo_state')
--states.query_screen_state = require('states/query_screen_state')
  
return states
