local objLoader = require("obj_loader")

-- local model = objLoader.loadObj("model/model.obj")
local model = objLoader.loadObj("model/model.obj")

local canvasConf = {format = 'rgba16f'}
local canvasConfNoDpi = {dpiscale = 1, format = 'rgba16f'}

local cameraX = 0
local cameraY = 0
local cameraFov = 90
local cameraVelX = 0
local cameraVelY = 0

local panoramaDirs = {
   [0] = {0, 0},
   {0, 90},
   {0, 180},
   {0, 270},
   {-90, 0},
   {90, 0},
}

for _, v in pairs(panoramaDirs) do
   v[1] = math.rad(v[1])
   v[2] = math.rad(v[2])
end

local font = love.graphics.newFont(16)
love.graphics.setFont(font)
local fontHeight = font:getHeight()
local buttonHeight = font:getHeight() + 16
local buttonWidth = buttonHeight * 5

local mousePos = {0, 0}
local oldMousePos = {0, 0}
local mouseWasDown = false

local selectedButton = 0
local clickedButton = 0

local infoMessages = {}
local infoMessagesOffset = 0

local exportResolution = 3
local exportResolutions = {
   512, 1024, 2048, 4096
}

---@type love.Canvas
local cameraMainCanvas
---@type love.Canvas
local cameraWeightSumCanvas

---@param str string
local function showInfoMessage(str)
   table.insert(infoMessages, 1, {
      text = str,
      time = 0
   })
   infoMessagesOffset = infoMessagesOffset + fontHeight
end

---@param x number?
---@param y number?
local function updateCanvases(x, y)
   if cameraMainCanvas then cameraMainCanvas:release() end
   if cameraWeightSumCanvas then cameraWeightSumCanvas:release() end
   local sx, sy = love.window.getMode()
   x = x or sx
   y = y or sy
   cameraMainCanvas = love.graphics.newCanvas(x, y, canvasConf)
   cameraWeightSumCanvas = love.graphics.newCanvas(x, y, canvasConf)
end

local shaderAdd = love.graphics.newShader("vertex.glsl", "add.glsl")
local shaderDiv = love.graphics.newShader("div.glsl")
local shaderPanorama = love.graphics.newShader("panorama.glsl")

---@param a number[]
---@param b number[]
local function matrixMultiply(a, b)
   local newMat = {}
   for x = 1, 4 do
      newMat[x] = {}
      for y = 1, 4 do
         local n = 0
         for i = 1, 4 do
            n = n + a[i + (y - 1) * 4] * b[x + (i - 1) * 4]
         end
         newMat[x + (y - 1) * 4] = n
      end
   end
   return newMat
end

---@param fov number?
---@param aspect number?
---@return number[]
local function getPerspectiveMatrix(fov, aspect)
   fov = fov or 90
   aspect = aspect or 1
   local near = 0.0001
   local far = 1000
   local top = near * math.tan(math.pi / 180 * fov / 2)
   local right = top * aspect
   local left = -right
   local bottom = -top
   return {
      (2 * near) / (right - left), 0, (right + left) / (right - left), 0,
      0, (2 * near) / (top - bottom), (top + bottom) / (top - bottom), 0,
      0, 0, -(far + near) / (far - near), -(2 * far * near) / (far - near),
      0, 0, -1, 0,
   }
end

---@param x number?
---@param y number?
---@return number[]
local function getCameraRotMatrix(x, y)
   x = x or cameraX
   y = y or cameraY
   local a = math.cos(y)
   local b = math.sin(y)
   local c = math.cos(x)
   local d = math.sin(x)
   return matrixMultiply({
      1, 0, 0, 0,
      0, c, d, 0,
      0, -d, c, 0,
      0, 0, 0, 1
   }, {
      a, 0, b, 0,
      0, 1, 0, 0,
      -b, 0, a, 0,
      0, 0, 0, 1
   })
end

---@param camX number?
---@param camY number?
---@param fov number?
---@param mainCanvas love.Canvas?
---@param weightSumCanvas love.Canvas?
local function renderCamera(camX, camY, fov, mainCanvas, weightSumCanvas)
   mainCanvas = mainCanvas or cameraMainCanvas
   weightSumCanvas = weightSumCanvas or cameraWeightSumCanvas
   fov = fov or cameraFov
   local sx, sy = mainCanvas:getWidth(), mainCanvas:getHeight()
   love.graphics.setCanvas(mainCanvas, weightSumCanvas)
   love.graphics.clear()
   love.graphics.setBlendMode("add", "premultiplied")
   love.graphics.setShader(shaderAdd)

   shaderAdd:send(
      "projectionMatrix",
      "row",
      matrixMultiply(
         getPerspectiveMatrix(fov, sx / sy),
         getCameraRotMatrix(camX, camY)
      )
   )
   for _, v in pairs(model) do
      love.graphics.draw(v)
   end

   love.graphics.setBlendMode("alpha", "alphamultiply")
   love.graphics.setCanvas()
   love.graphics.setShader()
end

---@param isCubemap boolean
local function renderPanorama(isCubemap)
   local resolution = exportResolutions[exportResolution]
   local mainCanvas = love.graphics.newCanvas(resolution, resolution, canvasConfNoDpi)
   local mainCanvas2 = love.graphics.newCanvas(resolution, resolution, {dpiscale = 1})
   local weightSumCanvas = love.graphics.newCanvas(resolution, resolution, canvasConfNoDpi)
   ---@type love.Canvas
   local panoramaCanvas = nil
   if not isCubemap then
      panoramaCanvas = love.graphics.newCanvas(resolution * 2, resolution, {dpiscale = 1})
   end
   for i, camRot in pairs(panoramaDirs) do
      renderCamera(camRot[1], camRot[2], 90, mainCanvas, weightSumCanvas)
      love.graphics.setCanvas(mainCanvas2)
      love.graphics.clear()
      love.graphics.setShader(shaderDiv)
      shaderDiv:send("weightTex", weightSumCanvas)
      love.graphics.draw(mainCanvas)
      love.graphics.setShader()
      love.graphics.setCanvas()
      if isCubemap then
         mainCanvas2:newImageData():encode("png", "panorama_"..i..".png")
      else
         love.graphics.setCanvas(panoramaCanvas)
         love.graphics.setShader(shaderPanorama)
         shaderPanorama:send("rotX", camRot[1])
         shaderPanorama:send("rotY", camRot[2])
         love.graphics.draw(mainCanvas2, 0, 0, 0, 2, 1)
         love.graphics.setColor(1, 1, 1)
         love.graphics.setShader()
         love.graphics.setCanvas()
      end
   end

   mainCanvas:release()
   mainCanvas2:release()
   weightSumCanvas:release()

   if not isCubemap then
      panoramaCanvas:newImageData():encode("png", "panorama360.png")
      panoramaCanvas:release()
   end
end

function love.load()
   updateCanvases()
end

function love.resize()
   updateCanvases()
end

---@type {text: string, func: fun(btn: {text: string})?}[]
local buttons = {
   {
      text = 'resolution '..exportResolutions[exportResolution]..'x',
      func = function(btn)
         exportResolution = exportResolution % #exportResolutions + 1
         btn.text = 'resolution '..exportResolutions[exportResolution]..'x'
      end
   },
   {
      text = 'export panorma',
      func = function()
         renderPanorama(false)
         local dir = love.filesystem.getSaveDirectory()
         showInfoMessage("panorama to "..dir)
      end
   },
   {
      text = 'export cubemap',
      func = function()
         local dir = love.filesystem.getSaveDirectory()
         renderPanorama(true)
         showInfoMessage('exported to '..dir)
      end
   },
   {
      text = 'open folder',
      func = function()
         local dir = love.filesystem.getSaveDirectory()
         showInfoMessage('opening '..dir)
         love.system.openURL("file://"..dir)
      end
   }
}

function love.update(delta)
   if love.keyboard.isDown("escape") then love.event.push("quit") end

   local safeX, safeY, safeW, safeH = love.window.getSafeArea()

   local wx, wy = love.window.getMode()
   local mx, my = love.mouse.getPosition()
   local mouseIsDown = love.mouse.isDown(1)
   if mouseIsDown then
      oldMousePos = mousePos
      mousePos = {mx / wx, my / wy}
      if not mouseWasDown then
         oldMousePos = mousePos
      end
   end

   local moveX = (oldMousePos[2] - mousePos[2]) * 2
   local moveY = (oldMousePos[1] - mousePos[1]) * (wx / wy) * 2

   if mouseIsDown and not buttons[selectedButton] then
      cameraX = cameraX + moveX
      cameraY = cameraY + moveY
      cameraVelX = 0
      cameraVelY = 0
   end

   do
      if mouseWasDown and not buttons[selectedButton] then
         cameraVelX = moveX / delta
         cameraVelY = moveY / delta
      end
      cameraX = cameraX + cameraVelX * delta * 0.5
      cameraY = cameraY + cameraVelY * delta * 0.5

      local velScale = 0.95 ^ (delta * 60)
      cameraVelX = cameraVelX * velScale
      cameraVelY = cameraVelY * velScale

      cameraX = cameraX + cameraVelX * delta * 0.5
      cameraY = cameraY + cameraVelY * delta * 0.5
   end

   cameraX = math.min(math.max(cameraX, -math.pi * 0.5), math.pi * 0.5)

   selectedButton = math.floor((my - 2 - safeY) / buttonHeight) + 1
   if mx > buttonWidth + 2 + safeX or mx < 2 + safeX then
      selectedButton = 0
   end

   if mouseIsDown then
      if not mouseWasDown then
         clickedButton = selectedButton
      end
      if clickedButton ~= selectedButton then
         clickedButton = 0
      end
   else
      if mouseWasDown and buttons[clickedButton] then
         local btn = buttons[clickedButton]
         if btn.func then
            btn.func(btn)
         end
      end
      clickedButton = 0
   end

   mouseWasDown = mouseIsDown

   infoMessagesOffset = infoMessagesOffset * 0.6 ^ (delta * 20)
   for i = #infoMessages, 1, -1 do
      local v = infoMessages[i]
      v.time = v.time + delta
      if v.time > 5 then
         table.remove(infoMessages, i)
      end
   end
end

function love.draw()
   renderCamera()

   love.graphics.setShader(shaderDiv)
   shaderDiv:send("weightTex", cameraWeightSumCanvas)
   love.graphics.draw(cameraMainCanvas)
   love.graphics.setShader()

   local safeX, safeY, safeW, safeH = love.window.getSafeArea()

   for i, v in ipairs(buttons) do
      love.graphics.push()
      love.graphics.translate(2 + safeX, buttonHeight * (i - 1) + 2 + safeY)

      if clickedButton == i then
         love.graphics.setColor(0.35, 0.35, 0.35)
      elseif selectedButton == i then
         love.graphics.setColor(0.2, 0.2, 0.2)
      else
         love.graphics.setColor(0.1, 0.1, 0.1)
      end
      do
         local displayBtnHeight = buttonHeight - 2
         love.graphics.rectangle("fill", 0, 0, buttonWidth, displayBtnHeight, buttonHeight * 0.5)
         local btnStart = 0
         local btnEnd = displayBtnHeight
         if i == 1 then
            btnStart = displayBtnHeight * 0.25
         end
         if i == #buttons then
            btnEnd = displayBtnHeight * 0.75
         end
         love.graphics.rectangle("fill", 0, btnStart, buttonWidth, btnEnd - btnStart, buttonHeight * 0.25)
      end
      love.graphics.setColor(1, 1, 1)

      love.graphics.print(v.text, 12, 6)

      love.graphics.pop()
   end

   for i, v in ipairs(infoMessages) do
      local alpha = math.min((5 - v.time) * 2, 1)
      alpha = 3 * alpha ^ 2 - 2 * alpha ^ 3
      love.graphics.setColor(1, 1, 1, alpha)
      love.graphics.print(v.text, 2, safeY + safeH - i * fontHeight + infoMessagesOffset)
   end
   love.graphics.setColor(1, 1, 1)
end