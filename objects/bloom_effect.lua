
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- bloom_effect object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local be = {}
be.table = 'be'
be.debug = false
be.level = nil
be.bbox = nil
be.canvases = nil
be.shaders = nil
be.bloom_canvas = nil
be.screen_canvas = nil
be.screen_quad = nil
be.effect_quad = nil

-- shader settings
be.threshold = 0.5
be.blur_size = 1
be.base_intensity = 1
be.bloom_intensity = 1
be.base_saturation = 1
be.bloom_saturation = 0.7

local be_mt = { __index = be }
function be:new(level, x, y, effect_layer)
  local be = setmetatable({}, be_mt)
  be.level = level
  local width, height = effect_layer:getWidth(), effect_layer:getHeight()
  be.bbox = bbox:new(x, y, width, height)
  
  local canvases = {}
  canvases.effect_layer = effect_layer
  canvases.bloom = lg.newCanvas(width, height)
  canvases.screen = lg.newCanvas(width, height)
  canvases.horizontal_blur = lg.newCanvas(width, height)
  canvases.vertical_blur = lg.newCanvas(width, height)
  canvases.result = lg.newCanvas(width, height)
  be.canvases = canvases
  be.screen_quad = lg.newQuad(0, 0, 0, 0, SCR_WIDTH, SCR_HEIGHT)
  be.effect_quad = lg.newQuad(0, 0, width, height, width, height)
  
  local shaders = {}
  shaders.bloom = SHADERS.bloom
  shaders.horizontal_blur = SHADERS.horizontal_blur
  shaders.vertical_blur = SHADERS.vertical_blur
  shaders.combine = SHADERS.combine
  be.shaders = shaders
  
  be._refresh_screen_canvas(be)
  be._refresh_effect(be)
  
  return be
end

function be:set_blur_size(blur_size)
  self.blur_size = blur_size
end
function be:set_threshold(threshold)
  self.threshold = threshold
end

function be:set_position(x, y)
  self.bbox.x, self.bbox.y = x, y
end

------------------------------------------------------------------------------
function be:update(dt)
end

function be:_refresh_screen_canvas()
  local x, y = self.bbox.x, self.bbox.y
  local viewport = self.level:get_camera_viewport()
  local scr_offx, scr_offy = x - viewport.x, y - viewport.y
  local screen = self.level:get_screen_canvas()
  local screen_canvas = self.canvases.screen
  local screen_quad = self.screen_quad
  screen_quad:setViewport(scr_offx, scr_offy, self.bbox.width, self.bbox.height)
  
  lg.setCanvas(screen_canvas)
  lg.setColor(255, 255, 255, 255)
  lg.draw(screen, screen_quad, 0, 0)
  lg.draw(self.canvases.effect_layer, self.effect_quad, 0, 0)
  lg.setCanvas()
end

function be:_refresh_effect()
  lg.setColor(255, 255, 255, 255)
  
  local canvases, shaders = self.canvases, self.shaders
  local blendmode = lg.getBlendMode()
  lg.setBlendMode("premultiplied")
  
  -- apply bloom threshold
  shaders.bloom:send("threshold", self.threshold)
  lg.setCanvas(canvases.bloom)
  lg.setShader(shaders.bloom)
  lg.draw(canvases.effect_layer, self.effect_quad, 0, 0)
  
  -- apply horizontal blur
  shaders.horizontal_blur:send("canvas_w", self.bbox.width * self.blur_size)
  canvases.horizontal_blur:clear()
  lg.setCanvas(canvases.horizontal_blur)
  lg.setShader(shaders.horizontal_blur)
  lg.draw(canvases.bloom, self.effect_quad, 0, 0)
  
  -- apply vertical blur
  shaders.vertical_blur:send("canvas_h", self.bbox.height * self.blur_size)
  canvases.vertical_blur:clear()
  lg.setCanvas(canvases.vertical_blur)
  lg.setShader(shaders.vertical_blur)
  lg.draw(canvases.horizontal_blur, self.effect_quad, 0, 0)
  
  -- combine blur and screen canvases
  shaders.combine:send("baseintensity", self.base_intensity)
  shaders.combine:send("bloomintensity", self.bloom_intensity)
  shaders.combine:send("basesaturation", self.base_saturation)
  shaders.combine:send("bloomsaturation", self.bloom_saturation)
  shaders.combine:send("bloomtex", canvases.vertical_blur)
  lg.setCanvas(canvases.result)
  lg.setShader(shaders.combine)
  lg.draw(canvases.screen, self.effect_quad, 0, 0)
  
  lg.setShader()
  lg.setCanvas()
  lg.setBlendMode(blendmode)
end

function be:_clear_canvases()
  local canvases = self.canvases
  canvases.bloom:clear()
  canvases.screen:clear()
  canvases.horizontal_blur:clear()
  canvases.vertical_blur:clear()
  canvases.result:clear()
end

function be:update_draw()
  self:_clear_canvases()
  self:_refresh_screen_canvas()
  self:_refresh_effect()
end

------------------------------------------------------------------------------
function be:draw()
  lg.setColor(255, 255, 255, 255)
  lg.draw(self.canvases.result, self.bbox.x, self.bbox.y)
  
  if self.debug then
    lg.setColor(0, 255, 0, 255)
    lg.setLineWidth(2)
    self.bbox:draw()
    
    local x, y = self.bbox.x, self.bbox.y
    lg.setColor(255, 255, 255, 255)
    lg.draw(self.canvases.screen, x, y + 100)
    lg.draw(self.canvases.horizontal_blur, x, y + 200)
    lg.draw(self.canvases.vertical_blur, x, y + 300)
    lg.draw(self.canvases.effect_layer, x + 100, y)
    
    lg.setColor(255, 255, 255, 255)
    --lg.draw(self.canvases.screen, self.bbox.x, self.bbox.y)
  end
end

return be



