---@diagnostic disable: lowercase-global
---@param dir string
---@param recursive boolean
---@param list string[]?
function listFiles(dir,recursive,list)
	dir = dir:gsub("%.","/")
	local luaDir = dir:gsub("/",".")
	list = list or {}
	for _, item in pairs(love.filesystem.getDirectoryItems(dir)) do
		local info = love.filesystem.getInfo(dir.."/"..item)
		if info.type == "file"  -- has to be a file
		and item:find("%.lua$") -- has to be a lua script
		and (not item:find("^%.")) then -- not a hidden file
			list[#list+1] = (luaDir.."."..item):sub(1,-5)
		elseif info.type == "directory" and item ~= "." and item ~= ".." then
			if recursive then
				listFiles(dir.."/"..item, true,list)
			end
		end
	end
	return list
end
