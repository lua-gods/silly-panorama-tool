local previewModel = models:newPart('', 'World')

local preHudRendermodel = models:newPart('', 'Hud')

local colorOnlyPreview = true

local whitePixel = textures.whitePixel or textures:newTexture('whitePixel', 1, 1):setPixel(0, 0, 1, 1, 1)

local screenshotDelay = client:hasShaderPack() and 60 or 10
previewModel:scale(16)

---@type {model: ModelPart, texture: Texture, sprite: SpriteTask, rot: Vector2, size: Vector2, hue: number}[]
local screenshots = {}

local screenshotTimer = -1

-- modified version of screen to world space made by GNamimates, used to get fov
local function screenToWorldSpace(distance, pos, fov, rot)
   local mat = matrices.mat4()
   local win_size = client:getWindowSize()
   local mpos = (pos / win_size - vec(0.5, 0.5)) * vec(win_size.x/win_size.y,1)
   if renderer:getCameraMatrix() then mat:multiply(renderer:getCameraMatrix()) end
   mat:translate(mpos.x*-fov*distance,mpos.y*-fov*distance,0)
   mat:rotate(rot.x, -rot.y, rot.z)
   mat:translate(client:getCameraPos())
   pos = (mat * vectors.vec4(0, 0, distance, 1)).xyz
   return pos
end

local function getRealFov(cameraRot)
   local fov = math.tan(math.rad(client.getFOV() / 2)) * 2
   local pos = vectors.worldToScreenSpace(screenToWorldSpace(1, vec(0, 0), fov, cameraRot)).xy
   local fovErr =  vec(-1, -1):length() / pos:length()
   return fov * fovErr
end

---@param path string
---@param str string
---@param isBase64 boolean?
local function writeFile(path, str, isBase64)
   local buffer = data:createBuffer()
   if isBase64 then
      buffer:writeBase64(str)
   else
      buffer:writeByteArray(str)
   end
   buffer:setPosition(0)
   local stream = file:openWriteStream(path)
   buffer:writeToStream(stream)
   stream:close()
   buffer:close()
end

local function progress(i,N,text)
   host:setActionbar(('[{"text":"'..("|"):rep(i)..'","color":"red"},{"text":"'..("|"):rep(N-i)..'","color":"gray"},{"text":" '..text..'","color":"white"}]'))
end

local notRam = {}
local totalCount, currentCount = 0,0
local queryAction = {}
local cooldownSave = 0

function events.world_render()
   if cooldownSave < 0 then
      if queryAction[1] then
         local q = queryAction[1]
         
         cooldownSave = 10 -- let 10 frames to process first to avoid disconnection
         if q.action == "save" then
            notRam[q.id] = q.texture:save()
            progress(currentCount, totalCount, 'Caching Texture '..q.id)
         elseif q.action == "writeTex" then
            writeFile(q.path, notRam[q.id], true)
            progress(currentCount, totalCount, 'Saving Texture '..q.path)
         elseif q.action == "writeTxt" then
            writeFile(q.path, q.content)
            progress(currentCount, totalCount, 'Saving Model File '..q.path)
         end
         currentCount = currentCount + 1
         table.remove(queryAction, 1)
         if #queryAction == 0 then
            host:setActionbar('{"text":"Complete!","color":"green"}')
         end
      else
         totalCount = 0
         currentCount = 0
      end
   else
      cooldownSave = cooldownSave - 1
   end
end

local function addQuery(data)
   totalCount = totalCount + 1
   queryAction[#queryAction+1] = data
end

local function exportObj()
   local dirPath = "panorama-model"
   if not file:exists(dirPath) then
      file:mkdir(dirPath)
   end

   local objFile = {}
   local mtlFile = {}

   table.insert(objFile, 'mtllib materials.mtl')

   table.insert(objFile, 'vt 0.0 0.0')
   table.insert(objFile, 'vt 0.0 1.0')
   table.insert(objFile, 'vt 1.0 0.0')
   table.insert(objFile, 'vt 1.0 1.0')


   local vertexId = 1
   for i, screenshot in ipairs(screenshots) do
      -- make material
      local materialName = 'materialImage'..i
      local imageFileName = 'image'..i..'.png'
      table.insert(mtlFile, 'newmtl '..materialName)
      table.insert(mtlFile, 'Ka 1.000 1.000 1.000')
      table.insert(mtlFile, 'Kd 1.000 1.000 1.000')
      table.insert(mtlFile, 'Ks 0.000 0.000 0.000')
      table.insert(mtlFile, 'd 1.0')
      table.insert(mtlFile, 'illum 2')
      table.insert(mtlFile, 'map_Kd '..imageFileName)
      -- use material
      table.insert(objFile, 'usemtl '..materialName)
      -- save texture
      
      
      -- generate vertices
      local mat = matrices.mat4()
      mat:scale(screenshot.size.x * 0.5, screenshot.size.y * 0.5, 1)
      mat:translate(0, 0, 1)
      mat:rotate(screenshot.rot)
      mat:scale(-1, 1, 1)
      mat:scale(10)
      for x = -1, 1, 2 do
         for y = -1, 1, 2 do
            local pos = mat:apply(x, y, 0)
            table.insert(objFile, 'v '..string.format('%f %f %f', pos.x, pos.y, pos.z))
         end
      end
      table.insert(objFile, 'f '..(vertexId)..'/1 '..(vertexId + 1)..'/2 '..(vertexId + 2)..'/3')
      table.insert(objFile, 'f '..(vertexId + 1)..'/2 '..(vertexId + 2)..'/3 '..(vertexId + 3)..'/4')
      -- update vertex id
      vertexId = vertexId + 4
   end

   -- query save texture
   
   for i, screenshot in ipairs(screenshots) do
      addQuery{
         action="save",
         texture = screenshot.texture,
         id = i
      }
   end
   
   for i, screenshot in ipairs(screenshots) do
      local imageFileName = 'image'..i..'.png'
      addQuery{
         action = "writeTex",
         path = dirPath..'/'..imageFileName,
         id = i
      }
   end
   
   -- print(table.concat(tbl, '\n'))
   
   addQuery{
      action = "writeTxt",
      content = table.concat(objFile, '\n'),
      path = dirPath..'/model.obj'
   }
   
   addQuery{
      action = "writeTxt",
      content = table.concat(mtlFile, '\n'),
      path = dirPath..'/materials.mtl'
   }
   
   --writeFile(dirPath..'/model.obj', table.concat(objFile, '\n'))
   --writeFile(dirPath..'/materials.mtl', table.concat(mtlFile, '\n'))
end

local function updateSpriteTasks()
   for i, v in pairs(screenshots) do
      if colorOnlyPreview then
         v.sprite:setColor(vectors.hsvToRGB(v.hue, 0.5, 1))
         v.sprite:setTexture(whitePixel, 1, 1)
      else
         v.sprite:setColor(1, 1, 1)
         v.sprite:setTexture(v.texture, 1, 1)
      end
   end
end

local function takeScreenshot()
   local id = #screenshots + 1

   local camPos = client.getCameraPos()
   local camRot = client.getCameraRot()
   if math.abs(math.abs(camRot.x) - 90) < 0.1 then -- fix for figura bug
      camRot.z = 0
      local pos = vectors.worldToScreenSpace(camPos + vec(1, 0, 0) + client.getCameraDir())
      pos.xy = pos.xy * client.getScaledWindowSize() -- aspect ratio fix
      local rot = math.deg(math.atan2(pos.x, pos.y))
      rot = rot + 90
      if camRot.x < 0 then
         rot = -rot
      end
      camRot.y = rot
   end

   local fov = getRealFov(camRot)

   local texture = host:screenshot('screenshot_'..id)
   local textureSize = texture:getDimensions()

   local model = previewModel:newPart('screenshot'..id)

   local size = vec(1 * textureSize.x / textureSize.y, 1) * fov

   local sprite = model:newSprite('')
   sprite:setTexture(texture, 1, 1)
   -- sprite:setColor(vectors.hsvToRGB(math.random(), 0.5, 1))
   sprite:setScale(size.x, size.y, 1)
   sprite:setPos(size.x * 0.5, size.y * 0.5, 1)

   sprite:setRenderType("EMISSIVE_SOLID")

   model:setRot(camRot.x, -camRot.y, 0)

   screenshots[id] = {
      model = model,
      sprite = sprite,
      texture = texture,
      rot = camRot,
      size = size,
      hue = math.random()
   }

   updateSpriteTasks()

   -- exportObj()
end

local function beginScreenshot()
   screenshotTimer = math.max(screenshotTimer, 0)
end

-- beginScreenshot()

function events.world_render(delta)
   previewModel:setPos(client.getCameraPos() * 16)
end

function events.world_render()
   if screenshotTimer < 0 then
      previewModel:setVisible(true)
      renderer:setRenderHUD(true)
      renderer:setRenderLeftArm()
      renderer:setRenderRightArm()
      renderer:setBlockOutlineColor()
      return
   end
   previewModel:setVisible(false)
   renderer:setRenderHUD(false)
   renderer:setRenderLeftArm(false)
   renderer:setRenderRightArm(false)
   renderer:setBlockOutlineColor(0, 0, 0, 0)
   screenshotTimer = screenshotTimer + 1
   if screenshotTimer >= screenshotDelay + 2 then
      screenshotTimer = -1
      takeScreenshot()
   end
end

preHudRendermodel.preRender = function()
   if screenshotTimer >= screenshotDelay then
      screenshotTimer = -1
      takeScreenshot()
   end
end

keybinds:of('', 'key.keyboard.v').press = beginScreenshot

local page = action_wheel:newPage()
action_wheel:setPage(page)

page:newAction()
   :setItem('minecraft:spyglass')
   :setTitle("screenshot\nyou can also screenshot with [V]")
   :onLeftClick(beginScreenshot)

page:newAction()
   :setItem('minecraft:glass')
   :setTitle("colors only preview")
   :setToggled(colorOnlyPreview)
   :onToggle(function(state)
      colorOnlyPreview = state
      updateSpriteTasks()
   end)

page:newAction()
   :setItem('minecraft:diamond')
   :setTitle('export obj')
   :setOnLeftClick(exportObj)