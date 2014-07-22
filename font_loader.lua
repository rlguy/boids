local fonts = {}
fonts.courier = love.graphics.newFont("fonts/courierbold.ttf", 30)
fonts.courier_large = love.graphics.newFont("fonts/courierbold.ttf", 72)
fonts.courier_small = love.graphics.newFont("fonts/courierbold.ttf", 20)

fonts.game_fonts = {}

local function create_default_font(size)
  local dfont = game_font:new(require("fonts/default/pattern"), size)
  local grad = dfont:add_gradient(require("gradients/named/orangeyellow"), "orangeyellow")
  grad:add_border({0, 0, 0, 255}, 0.5)
  local grad = dfont:add_gradient(require("gradients/named/green"), "green")
  grad:add_border({0, 0, 0, 255}, 0.4)
  local grad = dfont:add_gradient(require("gradients/named/blue"), "blue")
  grad:add_border({0, 0, 0, 255}, 0.4)
  local grad = dfont:add_gradient(require("gradients/named/blue"), "blue_no_border")
  grad:add_border({0, 0, 0, 255}, 0.03)
  dfont:load()
  return dfont
end

fonts.game_fonts.default_4 = create_default_font(4)
fonts.game_fonts.default_5 = create_default_font(5)
fonts.game_fonts.default_6 = create_default_font(6)


return fonts