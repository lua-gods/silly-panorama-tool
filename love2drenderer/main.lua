local objLoader = require("obj_loader")

local model = nil

local canvasConf = {format = 'rgba16f'}
local canvasConfNoDpi = {dpiscale = 1, format = 'rgba16f'}

local cameraX = 0
local cameraY = 0
local cameraFov = 90
local cameraVelX = 0
local cameraVelY = 0

---@type love.Canvas?
local bgPanorama = nil

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
local mousePosStart = {0, 0}
local cameraPosStart = {0, 0}
local oldCameraRot = {0, 0}
local mouseWasDown = false

local selectedButton = 0
local clickedButton = 0

local infoMessages = {}
local infoMessagesOffset = 0

local exportResolution = 3
local exportResolutions = {
   512, 1024, 2048, 4096, 8192, 16384
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
local shaderAddBg = love.graphics.newShader("add_bg.glsl")
local shaderBgCut = love.graphics.newShader("bg_cut.glsl")
local shaderDiv = love.graphics.newShader("div.glsl")
local shaderPanorama = love.graphics.newShader("panorama.glsl")
local shaderDownscale = love.graphics.newShader("downscale.glsl")

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

-- https://stackoverflow.com/questions/1148309/inverting-a-4x4-matrix/44446912#44446912
local function matrixInvert(m)
   local A2323 = m[11] * m[16] - m[12] * m[15]
   local A1323 = m[10] * m[16] - m[12] * m[14]
   local A1223 = m[10] * m[15] - m[11] * m[14]
   local A0323 = m[9] * m[16] - m[12] * m[13]
   local A0223 = m[9] * m[15] - m[11] * m[13]
   local A0123 = m[9] * m[14] - m[10] * m[13]
   local A2313 = m[7] * m[16] - m[8] * m[15]
   local A1313 = m[6] * m[16] - m[8] * m[14]
   local A1213 = m[6] * m[15] - m[7] * m[14]
   local A2312 = m[7] * m[12] - m[8] * m[11]
   local A1312 = m[6] * m[12] - m[8] * m[10]
   local A1212 = m[6] * m[11] - m[7] * m[10]
   local A0313 = m[5] * m[16] - m[8] * m[13]
   local A0213 = m[5] * m[15] - m[7] * m[13]
   local A0312 = m[5] * m[12] - m[8] * m[9]
   local A0212 = m[5] * m[11] - m[7] * m[9]
   local A0113 = m[5] * m[14] - m[6] * m[13]
   local A0112 = m[5] * m[10] - m[6] * m[9]

   local det = m[1] * ( m[6] * A2323 - m[7] * A1323 + m[8] * A1223 )
      - m[2] * ( m[5] * A2323 - m[7] * A0323 + m[8] * A0223 )
      + m[3] * ( m[5] * A1323 - m[6] * A0323 + m[8] * A0123 )
      - m[4] * ( m[5] * A1223 - m[6] * A0223 + m[7] * A0123 )
   det = 1 / det

   return {
      det *   ( m[6] * A2323 - m[7] * A1323 + m[8] * A1223 ),
      det * - ( m[2] * A2323 - m[3] * A1323 + m[4] * A1223 ),
      det *   ( m[2] * A2313 - m[3] * A1313 + m[4] * A1213 ),
      det * - ( m[2] * A2312 - m[3] * A1312 + m[4] * A1212 ),
      det * - ( m[5] * A2323 - m[7] * A0323 + m[8] * A0223 ),
      det *   ( m[1] * A2323 - m[3] * A0323 + m[4] * A0223 ),
      det * - ( m[1] * A2313 - m[3] * A0313 + m[4] * A0213 ),
      det *   ( m[1] * A2312 - m[3] * A0312 + m[4] * A0212 ),
      det *   ( m[5] * A1323 - m[6] * A0323 + m[8] * A0123 ),
      det * - ( m[1] * A1323 - m[2] * A0323 + m[4] * A0123 ),
      det *   ( m[1] * A1313 - m[2] * A0313 + m[4] * A0113 ),
      det * - ( m[1] * A1312 - m[2] * A0312 + m[4] * A0112 ),
      det * - ( m[5] * A1223 - m[6] * A0223 + m[7] * A0123 ),
      det *   ( m[1] * A1223 - m[2] * A0223 + m[3] * A0123 ),
      det * - ( m[1] * A1213 - m[2] * A0213 + m[3] * A0113 ),
      det *   ( m[1] * A1212 - m[2] * A0212 + m[3] * A0112 ),
   }
end

---@param m number[]
---@param v number[]
---@return number[]
local function matrixApply(m, v)
   local v2 = {}
   for i = 0, 3 do
      local s = 0
      for k = 0, 3 do
         s = s + m[i * 4 + k + 1] * v[k + 1]
      end
      v2[i + 1] = s
   end
   return v2
end

---@param m number[]
---@param v number[]
---@return number[]
local function matrixApply3d(m, v)
   local v2 = matrixApply(m, {v[1], v[2], v[3], 1})
   v2[1] = v2[1] / v2[4]
   v2[2] = v2[2] / v2[4]
   v2[3] = v2[3] / v2[4]
   return v2
end

---@param camMat number[]
---@param v number[]
---@return number[]
local function worldToScreen(camMat, v)
   local v2 = matrixApply3d(camMat, v)

   return {
      v2[1] * 0.5 + 0.5,
      v2[2] * 0.5 + 0.5,
   }
end

---@param camMatInv number[]
---@param v number[]
---@param depth number?
---@return number[]
local function screenToWorld(camMatInv, v, depth)
   depth = depth or 1
   local v0 = {
      v[1] * 2 - 1,
      v[2] * 2 - 1,
      depth
   }
   local v2 = matrixApply3d(camMatInv, v0)

   return v2
end

local function fovToScale(fov)
   return math.tan(math.pi / 180 * fov / 2)
end

---@param fov number?
---@param aspect number?
---@return number[]
local function getPerspectiveMatrix(fov, aspect)
   fov = fov or 90
   aspect = aspect or 1
   local near = 0.0001
   local far = 1000
   local top = near * fovToScale(fov)
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
---@param canvas love.Canvas?
---@return table
local function getCameraMatrix(camX, camY, fov, canvas)
   canvas = canvas or cameraMainCanvas
   local sx, sy = canvas:getWidth(), canvas:getHeight()
   fov = fov or cameraFov
   return matrixMultiply(
      getPerspectiveMatrix(fov, sx / sy),
      getCameraRotMatrix(camX, camY)
   )
end

---@param camX number?
---@param camY number?
---@param fov number?
---@param mainCanvas love.Canvas?
---@param weightSumCanvas love.Canvas?
local function renderCamera(camX, camY, fov, mainCanvas, weightSumCanvas)
   mainCanvas = mainCanvas or cameraMainCanvas
   weightSumCanvas = weightSumCanvas or cameraWeightSumCanvas
   love.graphics.setCanvas(mainCanvas, weightSumCanvas)
   love.graphics.clear()

   local w, h = mainCanvas:getDimensions()
   local camMat = getCameraMatrix(camX, camY, fov, mainCanvas)
   local camMatInv = matrixInvert(camMat)
   love.graphics.setBlendMode("add", "premultiplied")

   if bgPanorama then
      local x, y = bgPanorama:getDimensions()
      love.graphics.setShader()
      love.graphics.setShader(shaderAddBg)
      shaderAddBg:send("projectionMatrix", "row", camMatInv)
      love.graphics.draw(bgPanorama, 0, 0, 0, w / x, h / y)
   end

   love.graphics.setShader(shaderAdd)

   shaderAdd:send(
      "projectionMatrix",
      "row",
      camMat
   )
   if model then
      for _, v in pairs(model) do
         love.graphics.draw(v)
      end
   end

   love.graphics.setBlendMode("alpha", "alphamultiply")

   love.graphics.setCanvas()
   love.graphics.setShader()
end

---@param isCubemap boolean
---@param resolution number?
---@param dontSave boolean?
local function renderPanorama(isCubemap, resolution, dontSave)
   resolution = resolution or exportResolutions[exportResolution]
   local mainCanvas = love.graphics.newCanvas(resolution, resolution, canvasConfNoDpi)
   local mainCanvas2 = love.graphics.newCanvas(resolution, resolution, {dpiscale = 1})
   local weightSumCanvas = love.graphics.newCanvas(resolution, resolution, canvasConfNoDpi)
   ---@type love.Canvas
   local panoramaCanvas = nil
   if not isCubemap then
      panoramaCanvas = love.graphics.newCanvas(resolution * 2, resolution, {dpiscale = 1})
   end
   for i, camRot in pairs(panoramaDirs) do
      renderCamera(camRot[1], camRot[2], cameraFov, mainCanvas, weightSumCanvas)
      love.graphics.setCanvas(mainCanvas2)
      love.graphics.clear()
      love.graphics.setShader(shaderDiv)
      shaderDiv:send("weightTex", weightSumCanvas)
      love.graphics.draw(mainCanvas)
      love.graphics.setShader()
      love.graphics.setCanvas()
      if isCubemap then
         if not dontSave then
            mainCanvas2:newImageData():encode("png", "panorama_"..i..".png")
         end
      else
         love.graphics.setCanvas(panoramaCanvas)
         love.graphics.setShader(shaderPanorama)
         shaderPanorama:send("rotX", camRot[1])
         shaderPanorama:send("rotY", camRot[2])
         love.graphics.draw(mainCanvas2, 0, 0, 0, 2, 1)
         -- love.graphics.setColor(1, 1, 1)
         love.graphics.setShader()
         love.graphics.setCanvas()
      end
   end

   mainCanvas:release()
   mainCanvas2:release()
   weightSumCanvas:release()

   if not isCubemap then
      if dontSave then
         return panoramaCanvas
      else
         panoramaCanvas:newImageData():encode("png", "panorama360.png")
         panoramaCanvas:release()
      end
   end
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

local function lerp(a, b, t)
   return a + (b - a) * t
end

---@param rot number
---@return number
local function clampCamRot(rot)
   return math.min(math.max(rot, -math.pi * 0.5), math.pi * 0.5)
end

---@param path string
local function loadPanorama(path)
   if bgPanorama then
      bgPanorama:release()
   end
   bgPanorama = nil
   model = objLoader.loadObj(path)
   local bgCanvas = renderPanorama(false, 256, true)
   local w, h = bgCanvas:getDimensions()
   local canvas = love.graphics.newCanvas(w, h, {dpiscale = 1})
   local swap = love.graphics.newCanvas(w, h, {dpiscale = 1})
   love.graphics.setBlendMode("replace", "premultiplied")
   local first = true
   for i = 1, 9 do
      local dist = 2 ^ (i - 1)
      for j = 1, 0, -1 do
         shaderDownscale:send("blur_mode", j)
         local myDist = j == 1 and 1 or dist
         for k = 1, 2 do
            shaderDownscale:send("blur_dir", k == 1 and {myDist, 0} or {0, myDist})
            love.graphics.setCanvas(swap)
            love.graphics.clear()
            love.graphics.setShader(shaderDownscale)
            love.graphics.draw(first and bgCanvas or canvas)
            love.graphics.setShader()
            love.graphics.setCanvas()
            swap, canvas = canvas, swap
            first = false
         end
      end
   end
   love.graphics.setCanvas(swap)
   love.graphics.clear()
   shaderBgCut:send("tex_orginal", bgCanvas)
   love.graphics.setShader(shaderBgCut)
   love.graphics.draw(canvas)
   love.graphics.setShader()
   love.graphics.setCanvas()
   swap, canvas = canvas, swap
   love.graphics.setBlendMode("alpha")
   bgPanorama = canvas
end

function love.load()
   loadPanorama("model/model.obj")
   updateCanvases()
end

function love.resize()
   updateCanvases()
end

function love.wheelmoved(rx, ry)
	cameraFov = cameraFov * (1 - ry * 0.1)

	cameraFov = math.max(math.min(cameraFov,120),1)
end

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
         mousePosStart = mousePos
         cameraPosStart = {cameraX, cameraY}
      end
      oldCameraRot = {cameraX, cameraY}
   end

   -- local scaleX = zoomScale

   local moveX, moveY = cameraX, cameraY
   do
      local scale = 4
      local lastBest = 0
      local dirs = {
         {-1, 0},
         {1, 0},
         {0, -1},
         {0, 1},
         {0, 0},
      }
      local camMat = getCameraMatrix(cameraPosStart[1], cameraPosStart[2])
      local camMatInv = matrixInvert(camMat)
      local posOld = screenToWorld(camMatInv, {mousePosStart[1], mousePosStart[2]}, 1)
      for _ = 1, 64 do
         local bestDist = math.huge
         local bestX = moveX
         local bestY = moveY
         for _, dir in pairs(dirs) do
         -- moveX = offsetX * cameraFov / 180 * math.pi * 2
         -- moveX = offsetX * math.pi / 2
         -- moveY = offsetY * math.pi / 2
         -- print(cameraX)
         -- local scaleX = zoomScale ^ (1 + math.cos(cameraX * math.pi) * 0.5)
         local newX = moveX + dir[1] * scale
         local newY = moveY + dir[2] * scale
         newX = clampCamRot(newX)
         -- moveY = * (wx / wy) * 2 * scaleX
         local camMat = getCameraMatrix(newX, newY)
         -- local camMat = getCameraMatrix(moveX, moveY)
         local camMatInv = matrixInvert(camMat)
         -- local posOld = screenToWorld(camMatInv, {mousePosStart[1], mousePosStart[2]}, 1)
         local posNew = screenToWorld(camMatInv, {mousePos[1], mousePos[2]}, 1)
         -- print(posNew[1], posNew[2], posNew[3])

         local dist = (posNew[1] - posOld[1]) ^ 2 + (posNew[2] - posOld[2]) ^ 2 + (posNew[3] - posOld[3]) ^ 2
         if dist < bestDist then
            bestDist = dist
            bestX = newX
            bestY = newY
         end
      end

      moveX = bestX
      moveY = bestY
      scale = scale * 0.6
   end
      moveX = moveX - cameraPosStart[1]
      moveY = moveY - cameraPosStart[2]
   end

   if mouseIsDown and not buttons[selectedButton] then
      local newX = cameraPosStart[1] + moveX
      local newY = cameraPosStart[2] + moveY
      cameraX = newX
      cameraY = newY
   else
      if mouseWasDown and not buttons[selectedButton] then
         cameraVelX = (cameraX - oldCameraRot[1]) / delta
         cameraVelY = (cameraY - oldCameraRot[2]) / delta
      else
         cameraX = cameraX + cameraVelX * delta * 0.5
         cameraY = cameraY + cameraVelY * delta * 0.5
         local velScale = 0.95 ^ (delta * 60)
         cameraVelX = cameraVelX * velScale
         cameraVelY = cameraVelY * velScale
         cameraX = cameraX + cameraVelX * delta * 0.5
         cameraY = cameraY + cameraVelY * delta * 0.5
      end
   end

   --[[
   if mouseIsDown and not buttons[selectedButton] then
      cameraX = cameraX + moveX
      cameraY = cameraY + moveY
      cameraVelX = 0
      cameraVelY = 0
   end

   if mouseWasDown and not buttons[selectedButton] then
      cameraVelX = moveX / delta
      cameraVelY = moveY / delta
   else
      cameraX = cameraX + cameraVelX * delta * 0.5
      cameraY = cameraY + cameraVelY * delta * 0.5
      local velScale = 0.95 ^ (delta * 60)
      cameraVelX = cameraVelX * velScale
      cameraVelY = cameraVelY * velScale
      cameraX = cameraX + cameraVelX * delta * 0.5
      cameraY = cameraY + cameraVelY * delta * 0.5
   end
   --]]

   cameraX = clampCamRot(cameraX)

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
   love.graphics.clear(0.5, 0.5, 0.5)
   renderCamera()

   love.graphics.setShader(shaderDiv)
   shaderDiv:send("weightTex", cameraWeightSumCanvas)
   love.graphics.draw(cameraMainCanvas)
   love.graphics.setShader()

   --[[
   for i = 1, 3 do
      local wx, wy = love.window.getMode()
      local p = {0, 0, 0}
      p[i] = 1
      local pos = worldToScreen(getCameraMatrix(), p)
      love.graphics.circle("fill", pos[1] * wx, pos[2] * wy, 10)
   end--]]

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