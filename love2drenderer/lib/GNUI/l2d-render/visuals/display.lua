--[[______   __
  / ____/ | / /  by: GNanimates / https://gnon.top / Discord: @gn68s
 / / __/  |/ / name: Display API
/ /_/ / /|  /  desc: handles all the updating for all visuals
\____/_/ |_/ source: link ]]

---@class GNUI.Render.Visual.Task
---@field visible boolean
---@field pos Vector2
---@field size Vector2
---@field [any] any


---@class GNUI.Render.Visual
---@field id integer
---@field visible boolean
---@field index integer
---@field children GNUI.Render.Visual[]
---@field parent GNUI.Render.Visual?
---
---@field pos Vector2
---@field size Vector2
---
---@field tasks GNUI.Render.Visual.Task[]


---@class GNUI.Render.Display
---@field visuals GNUI.Render.Visual[]
local Display = {}
Display.__index = Display


function Display.newDisplay()
	local self = {}
	setmetatable(self,Display)
	---@cast self GNUI.Render.Display
	
	self.visuals = {}
	self:newVisual()
	
	return self
end


---@return integer
function Display:newVisual()
	local id = #self.visuals+1
	local visual = {
		id = id,
		
		index = 1,
		children = {},
		
		visible = true,
		pos = vec(0,0),
		size = vec(0,0),
		
		tasks = {},
	}
	
	self.visuals[id] = visual
	return id
end


---@param visualID integer
function Display:flash(visualID)
	--TODO: implement flashing for debugging
end

---NOTE: INTERNAL USE ONLY
---@param visualID integer
---@param spriteID integer
---@return GNUI.Render.Visual.Task?
function Display:getTask(visualID,spriteID)
	local visual = self.visuals[visualID]
	if not visual then return end
	local task = visual.tasks[spriteID]
	return task
end


---@param vis GNUI.Render.Visual
local function updateChildrenIndexes(vis)
	for i, child in ipairs(vis.children) do
		child.index = i
	end
end


---Updates the dimensions of the visual
---@param visualID integer
function Display:updateDimensions(visualID)
	local vis = self.visuals[visualID]
	-- useless for immidiate renderer
end


---@param visualID integer
---@param childVisualID integer
---@return GNUI.Render.Visual?
function Display:addChild(visualID,childVisualID)
	local vis = self.visuals[visualID]
	local child = self.visuals[childVisualID]
	if not vis then return nil end
	assert(child,"Visual Quad "..tostring(childVisualID).." not found")
	
	child.parent = vis
	local id = #vis.children + 1
	vis.children[id] = child
	child.index = id
	
	self:updateDimensions(child.id)
	self:updateDimensions(vis.id)
	return vis
end


function Display:setVisualChildIndex(visualID,index)
	local vis = self.visuals[visualID]
	if not vis then return end
	local parent = vis.parent
	if parent then
		index = math.clamp(index, 1, #parent.children)
		local ogIndex = vis.index
		if index ~= ogIndex then
			table.remove(parent.children, ogIndex)
			table.insert(parent.children, index, vis)
			updateChildrenIndexes(parent)
			for _, child in ipairs(parent.children) do
				self:updateDimensions(child.id)
			end
			self:updateDimensions(parent.id)
		end
	end
end


---Removes a child from the box
---@param visualID integer
---@param childVisualID integer
function Display:removeChild(visualID,childVisualID)
	local vis = self.visuals[visualID]
	local child = self.visuals[childVisualID]
	if not vis then return end
	if not child then return end
	
	if vis.children[child.index] == child then
		table.remove(vis.children, child.index)
		updateChildrenIndexes(vis)
		child.parent = nil
		self:updateDimensions(child.id)
		self:updateDimensions(vis.id)
	end
	return self
end


---Removes the parent of the box
---@param visualID integer
function Display:removeParent(visualID)
	local vis = self.visuals[visualID]
	if not vis then return end
	
	if vis.parent then
		self:removeChild(vis.parent.id,vis.id)
	end
	return self
end


function Display:removeVisual(visualID)
	local vis = self.visuals[visualID]
	if not vis then return end
	self:removeParent(visualID)
	self.visuals[visualID] = nil
end


---Sets the parent of the box
---@param visualID integer
---@param parentID integer
function Display:setParent(visualID,parentID)
	local vis = self.visuals[visualID]
	local parent = self.visuals[parentID]
	if not vis then return end
	if not parent then return end
	
	self:removeParent(visualID)
	self:addChild(parentID,visualID)
end


function Display:free(visualID)
	if visualID then
		self.visuals[visualID] = nil
	else
		self.visuals = {}
		for index, _ in ipairs(self) do
			self[index] = nil
		end
	end
end


function Display:setPos(visualID,x,y)
	local vis = self.visuals[visualID]
	if not vis then return end
	vis.pos = vec(x,y)
	self:updateDimensions(vis.id)
	self:flash(visualID)
end


function Display:setSize(visualID,x,y)
	local vis = self.visuals[visualID]
	if not vis then return end
	vis.size = vec(x,y)
	for key, task in pairs(vis.tasks) do
		task:setSize(x,y)
	end
	self:updateDimensions(vis.id)
	self:flash(visualID)
end


function Display:setVisible(visualID,visible)
	local vis = self.visuals[visualID]
	if not vis then return end
	self:flash(visualID)
	vis.visible = visible
end


function Display:setColor(visualID,r,g,b)
	local vis = self.visuals[visualID]
	if not vis then return end
	
	for key, task in pairs(vis.tasks) do
		task:setColor(r,g,b)
	end
	self:flash(visualID)
end


local function drawTasks(visual,offset)
	local curOffset = offset + visual.pos
	for key, task in pairs(visual.tasks) do
		if task.visible and not task.isLabel then
			task:draw(curOffset,visual)
		end
	end
	for key, task in pairs(visual.tasks) do
		if task.visible and task.isLabel then
			task:draw(curOffset,visual)
		end
	end
	for vi, childVis in ipairs(visual.children) do
		if childVis.visible then
			drawTasks(childVis,curOffset)
		end
	end
end

function Display:draw()
	if self.visuals[1] and self.visuals[1].visible then
		drawTasks(self.visuals[1],vec(0,0))
	end
end

return Display
