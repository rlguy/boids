function love.keypressed(key)
  if key == 'escape' then
    love.event.push('quit')
  end
end

local function start_game(scr_width, scr_height, is_fullscreen)
  require('invaders_main')
  love.load({scr_width, scr_height, is_fullscreen})
  local chunk = love.filesystem.load('invaders_main.lua')
  chunk()
end

function love.load(args)
  require("table_utils")
  local utils = require("invaders_utils")
  local settings = utils.load_graphics_settings()
  start_game(settings.window_width, settings.window_height, settings.fullscreen)
end
