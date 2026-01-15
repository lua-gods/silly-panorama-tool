-- very basic obj, mtl loader, wont support most stuff
local mod = {}

local vertexFormat = {
   {"VertexPosition", "float", 3},
   {"VertexTexCoord", "float", 2},
}

---@param filePath string
---@param materials table?
function mod.loadMtl(filePath, materials)
   if not materials then
      materials = {}
   end

   local relativeDir = filePath:gsub('[^/\\]+[/\\]?$', '')

   local currentMaterial = ''

   local fileContent = love.filesystem.read(filePath)
   for line in fileContent:gmatch('[^\n\r]+') do
      local parts = {}
      for v in line:gmatch('%S+') do
         table.insert(parts, v)
      end
      if parts[1] == 'newmtl' then
         currentMaterial = parts[2]
      elseif parts[1] == 'map_Kd' then
         local texture = love.graphics.newImage(relativeDir..parts[2])
         materials[currentMaterial] = texture
      end
   end
end

---@param filePath string
---@return love.Mesh[]
function mod.loadObj(filePath)
   local vertexPositions = {}
   local uvs = {}
   local faces = {}

   local currentTexture = nil

   local materials = {}

   local relativeDir = filePath:gsub('[^/\\]+[/\\]?$', '')

   local fileContent = love.filesystem.read(filePath)
   for line in fileContent:gmatch('[^\n\r]+') do
      line = line:gsub('#.+', '')
      local parts = {}
      for v in line:gmatch('%S+') do
         table.insert(parts, v)
      end
      if parts[1] == 'v' then
         table.insert(vertexPositions, {
            tonumber(parts[2]) or 0,
            tonumber(parts[3]) or 0,
            tonumber(parts[4]) or 0
         })
      elseif parts[1] == 'vt' then
         table.insert(uvs, {
            tonumber(parts[2]) or 0,
            tonumber(parts[3]) or 0,
         })
      elseif parts[1] == 'f' then
         local myVertices = {}
         for i = 2, #parts do
            local posI, uvI = parts[i]:match('(%d*)/?(%d*)')
            posI = tonumber(posI)
            uvI = tonumber(uvI)
            local pos = vertexPositions[posI] or {0, 0, 0}
            local uv = uvs[uvI] or {0, 0}
            table.insert(myVertices, {
               pos[1], -pos[2], pos[3],
               uv[1], 1 - uv[2]
            })
         end
         local mesh = love.graphics.newMesh(vertexFormat, myVertices)
         if currentTexture then
            mesh:setTexture(currentTexture)
         end
         table.insert(faces, mesh)
      elseif parts[1] == 'mtllib' then
         mod.loadMtl(relativeDir..parts[2], materials)
      elseif parts[1] == 'usemtl' then
         currentTexture = materials[ parts[2] ]
      end
   end

   return faces
end

return mod