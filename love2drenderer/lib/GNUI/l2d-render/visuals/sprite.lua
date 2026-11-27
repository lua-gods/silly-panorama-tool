---@diagnostic disable: param-type-mismatch

local BASE = ((...):gsub("/", ".")):match(".+%.GNUI")
local cfg = require(BASE .. ".config") ---@type GNUI.config

---@class GNUI.Render.Display
local Display = require(cfg.RENDER..".visuals.display") ---@type GNUI.Render.Display

---@class GNUI.Render.Visual.Task.Sprite : GNUI.Render.Visual.Task
---@field color Vector3
---@field quad love.Quad?
---@field texturePath string
---@field textureSize Vector2
---@field image love.Image
---@field uv Vector4
---@field pos Vector2
---@field drawPos Vector2
---@field drawScale Vector2
---@field layer number
---@field size Vector2
---@field crop Vector4
---@field hasCustomUV boolean
---@field croppedOut boolean
local Sprite = {}
Sprite.__index = Sprite

local imageCache = {}


---@param visualID integer
---@return integer
function Display:newSprite(visualID)
	local vis = self.visuals[visualID]
	assert(vis,"Visual Quad "..visualID.." not found")
	
	local taskID = #vis.tasks+1
	local self = {
		pos = vec(0, 0),
		drawPos = vec(0, 0),
		drawScale = vec(0, 0),
		layer = 1,
		size = vec(0, 0),
		crop = vec(0, 0, 0, 0),
		uv = vec(0, 0, 1, 1),
		hasCustomUV = false,
		textureSize = vec(1, 1),
		color = vec(1, 1, 1),
		visible = true,
		croppedOut = false,
	}
	
	setmetatable(self,Sprite)
	vis.tasks[taskID] = self
	return taskID
end


---@param task GNUI.Render.Visual.Task.Sprite
local function updateSprite(task)
	local w, h = task.size.x, task.size.y
	local crop = task.crop
	local cL = math.clamp(crop.x, 0, w)
	local cT = math.clamp(crop.y, 0, h)
	local cR = math.clamp(crop.z, 0, w - cL)
	local cB = math.clamp(crop.w, 0, h - cT)

	local visW = w - cL - cR
	local visH = h - cT - cB
	local visX = task.pos.x + cL
	local visY = task.pos.y + cT

	task.drawPos = vec(visX, visY)

	if visW <= 0 or visH <= 0 or not task.image then
		task.croppedOut = true
		return
	end

	local texW, texH = task.textureSize.x, task.textureSize.y
	local uv = task.uv
	local du = uv.z - uv.x
	local dv = uv.w - uv.y

	if du <= 0 or dv <= 0 then
		task.croppedOut = true
		return
	end

	local u1 = (w > 0) and (uv.x + du * (cL / w)) or uv.x
	local u2 = (w > 0) and (uv.z - du * (cR / w)) or uv.z
	local rw = u2 - u1

	local v1 = (h > 0) and (uv.y + dv * (cT / h)) or uv.y
	local v2 = (h > 0) and (uv.w - dv * (cB / h)) or uv.w
	local rh = v2 - v1

	if rw <= 0 or rh <= 0 then
		task.croppedOut = true
		return
	end

	task.croppedOut = false
	task.drawScale = vec(visW / rw, visH / rh)

	if task.quad then
		task.quad:setViewport(u1, v1, rw, rh, texW, texH)
	else
		task.quad = love.graphics.newQuad(u1, v1, rw, rh, texW, texH)
	end
end


---INTERNAL CALLBACK for Display
---@param x number
---@param y number
function Sprite:setSize(x,y)
end


function Sprite:setVisible(visible)
	self.visible = visible
end


function Sprite:setColor(r,g,b)
	self.color = vec(r,g,b)
end


--────────────────────────-< Injected APIs >-────────────────────────--


---@param x number
---@param y number
function Display:setSpriteSize(visualID,taskID,x,y)
	local task = self:getTask(visualID,taskID)
	---@cast task GNUI.Render.Visual.Task.Sprite
	if task then
		task.size = vec(x,y)
		updateSprite(task)
	end
	self:flash(visualID)
end


---Sets the crop (left, up, right, down) of the given task.
---@param visualID integer
---@param taskID integer
---@param l number
---@param t number
---@param r number
---@param b number
function Display:setSpriteCrop(visualID,taskID,l,t,r,b)
	local task = self:getTask(visualID,taskID)
	---@cast task GNUI.Render.Visual.Task.Sprite
	if task then
		l = l or 0
		t = t or 0
		r = r or 0
		b = b or 0
		if task.crop.x == l and task.crop.y == t and task.crop.z == r and task.crop.w == b then
			return
		end
		task.crop = vec(l, t, r, b)
		updateSprite(task)
	end
end


function Display:setSpriteVisible(visualID,taskID,visible)
	local task = self:getTask(visualID,taskID)
	---@cast task GNUI.Render.Visual.Task.Sprite
	if task then
		task.visible = visible
		self:flash(visualID)
	end
end


function Display:setSpriteColor(visualID,taskID,r,g,b)
	local task = self:getTask(visualID,taskID)
	---@cast task GNUI.Render.Visual.Task.Sprite
	if not task then return end
	task.color = vec(r,g,b)
	self:flash(visualID)
end


---@param x number
---@param y number
function Display:setSpritePos(visualID,taskID,x,y,layer)
	local task = self:getTask(visualID,taskID)
	---@cast task GNUI.Render.Visual.Task.Sprite
	if task then
		task.pos = vec(x,y)
		task.layer = layer or task.layer or 1
		updateSprite(task)
	end
end


---@param visualID integer
---@param taskID integer
---@param path string
function Display:setSpriteTexture(visualID,taskID,path)
	local task = self:getTask(visualID,taskID)
	---@cast task GNUI.Render.Visual.Task.Sprite
	if not task then return end
	if path then
		local image = imageCache[path]
		if not image then
			image = love.graphics.newImage(path)
			imageCache[path] = image
		end
		local textureSize = vec(image:getWidth(),image:getHeight())
		task.texturePath = path
		task.textureSize = textureSize
		if not task.hasCustomUV then
			task.uv = vec(0, 0, textureSize.x, textureSize.y)
		end
		task.image = image
		task.visible = true
		updateSprite(task)
	else
		task:setVisible(false)
	end
	self:flash(visualID)
end

---Sets the UV of the visual
---@param visualID integer
---@param u1 number
---@param v1 number
---@param u2 number
---@param v2 number
function Display:setSpriteUV(visualID,taskID,u1,v1,u2,v2)
	local task = self:getTask(visualID,taskID)
	---@cast task GNUI.Render.Visual.Task.Sprite
	if not task then return end
	local uv = vec(u1,v1,u2,v2)
	task.uv = uv
	task.hasCustomUV = true
	updateSprite(task)
	self:flash(visualID)
end


function Display:removeSprite(visualID,taskID)
	local task = self:getTask(visualID,taskID)
	---@cast task GNUI.Render.Visual.Task.Sprite
	if task then
		if task.quad then
			task.quad:release()
		end
		self.visuals[visualID].tasks[taskID] = nil
	end
	self:flash(visualID)
end


---@param pos Vector2
function Sprite:draw(pos,visual)
	if self.quad and self.visible and not self.croppedOut then
		if self.color then
			love.graphics.setColor(self.color.x, self.color.y, self.color.z, 1)
		end
		love.graphics.draw(
			self.image,
			self.quad,
			self.drawPos.x + pos.x,
			self.drawPos.y + pos.y,
			0,
			self.drawScale.x,
			self.drawScale.y
		)
		if self.color then
			love.graphics.setColor(1, 1, 1, 1)
		end
	end
end
