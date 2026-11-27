local ogType = type

---@param obj any
---@return string
function type(obj)
	local t = ogType(obj)
	if t == "table" then
		return obj.__type or "table"
	else
		return t
	end
end
