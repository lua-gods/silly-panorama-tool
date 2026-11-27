
---@generic v
---@param v v
---@param min any
---@param max any
---@return v
function math.clamp(v,min,max)
	---@cast v any
	if type(v) == "number" then
		return math.min(math.max(v,min),max)
	else
		if v.__clamp then
			return v:__clamp(min,max)
		end
	end
	return v
end

---@generic v
---@param from v
---@param to v
---@param weight number
---@return v
function math.lerp(from,to,weight)
	return from + (to - from) * weight
end

function math.map(value,aMin,aMax,bMin,bMax)
	return (value - aMin) / (aMax - aMin) * (bMax - bMin) + bMin
end
