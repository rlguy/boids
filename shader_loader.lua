local lg = love.graphics
local shaders = {}
shaders.horizontal_blur = lg.newShader(require('shaders/horizontal_blur_shader'))
shaders.vertical_blur = lg.newShader(require('shaders/vertical_blur_shader'))
shaders.bloom = lg.newShader(require('shaders/bloom_shader'))
shaders.combine = lg.newShader(require('shaders/combine_shader'))

return shaders
