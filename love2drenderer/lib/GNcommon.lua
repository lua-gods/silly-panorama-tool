--[[______   __
  / ____/ | / / Name: GN COMMON LIBRARY v1.0.0
 / / __/  |/ /  Desc: contains all sorts of goodies that are generally useful
/ /_/ / /|  / Author: GNanimates | https://gnon.top | @gn68s
\____/_/ |_/ License: MIT ]]
---@diagnostic disable: param-type-mismatch

---@class GNCommon
local gnc = {}


---@alias Color string|Vector3|Vector4

---Parses a color from different formats into a Vector4.
---@overload fun(hex:string): Vector4
---@overload fun(rgb: Vector3,a: number?): Vector4
---@overload fun(rgba: Vector4): Vector4
---@param r number
---@param g number
---@param b number
---@param a number?
function gnc.color(r,g,b,a)
	local tr,tg,tb,ta=type(r),type(g),type(b),type(a)
	if (tr == "string") then
		return vectors.hexToRGB(r):augmented()
	elseif (tr == "Vector3") then
		return vec(r.x,r.y,r.z,1)
	else
		return vec(r,g,b,a or 1)
	end
end


---Unpacks a Vector, Matrix or table into its components
---@param x number|Vector.any|Matrix.any
---@return number 
---@return number?
---@return number?
---@return number?
---@return number?
---@return number?
---@return number?
---@return number?
---@return number?
---@return number?
function gnc.unpack(x)
	local tx = type(x)
	if tx:find("Vector") then
		return x:unpack()
	elseif tx:find("Matrix") then
		return x:unpack()
	elseif tx == "table" then
		return table.unpack(x)
	else
		---@cast x number
		return x
	end
end


---Combines any combination of Vector4, Vector3, Vector2 and numbers into a new Vector.
---
---```lua
---GNCommon.packToVector(1,2,3,4)
---GNCommon.packToVector(vec(1,2),vec(3,4))
---GNCommon.packToVector(vec(1,2,3),4)
---``` 
---^ all outputs a `Vector4(1,2,3,4)`
---***
---NOTE:
---this uses an average of `121` instructions. use `GNCommmon.vec2`/`GNCommon.vec3`/`GNCommon.vec4` instead
---@param ... number|Vector3|Vector3|Vector4
function gnc.packToVector(...)
	local components = {}
	
	-- convert all Vectors/numbers into an array
	for index, value in ipairs{...} do
		components[index] = {gnc.unpack(value)}
	end
	--- concatinate all arrays and convert into a vector.
	return vec(table.unpack(gnc.appendArrays(table.unpack(components))))
end



---Combines tables into one, t2 takes priority
---@param ... table
---@return table
function gnc.combineTables(...)
	local finalTable = {}
	for _, t in ipairs{...} do
		for k,table in pairs(t) do
			finalTable[k] = table
		end
	end
	return finalTable
end


---Concatinates arrays into one long array.
---@param ... table
---@return table
function gnc.appendArrays(...)
	local finalArray = {}
	local c = 0
	for _, t in ipairs{...} do
		for _,v in ipairs(t) do
			c = c + 1
			finalArray[c] = v
		end
	end
	return finalArray
end


---Parses Vector2 variants into a single unified Vector2.
---uses an average of `20` instructions
---@overload fun(xy: Vector2,default: Vector2?): Vector2
---@param x number?
---@param y number?
---@param default Vector2?
function gnc.vec2(x,y,default)
	local tx,ty=type(x), type(y)
	if (tx == "Vector2" and ty == "nil") then
		return x
	elseif default and (tx == "number" or ty == "number") then
		---@cast tx Vector2
		return vec(x or default.x,y or default.y)
	elseif (tx == "number" and ty == "number") then
		return vec(x,y)
	else
		error(("Invalid Vector2 parameter, expected (number, number), instead got (%s, %s)"):format(tx,ty),3)
	end
end


---Parses Vector3 variants into a single unified Vector3.
---uses an average of `26` instructions
---@overload fun(xyz: Vector3,default: Vector3?): Vector3
---@param x number?
---@param y number?
---@param z number?
---@param default Vector3?
---@return Vector3
function gnc.vec3(x,y,z,default)
	local tx,ty,tz=type(x), type(y), type(z)
	if (tx == "Vector3" and ty == "nil" and tz == "nil") then
		return x
	elseif default and (tx == "number" or ty == "number" or tz == "number") then
		---@cast tx Vector3
		return vec(x or default.x,y or default.y,z or default.z)
	elseif (tx == "number" and ty == "number" and tz == "number") then
		return vec(x,y,z)
	else
		error(("Invalid Vector3 parameter, expected (number, number, number), instead got (%s, %s, %s)"):format(tx,ty,tz),3)
	end
end



---Parses Vector4 variants into a single unified Vector4.
---uses an average of `32` instructions
---@overload fun(xyzw: Vector4,default: Vector4?): Vector4
---@overload fun(xy: Vector2, zw: Vector2, default: Vector4?): Vector4
---@param x number?
---@param y number?
---@param z number?
---@param w number?
---@param default Vector4?
---@return Vector4
function gnc.vec4(x,y,z,w,default)
	local tx,ty,tz,tw=type(x), type(y), type(z), type(w)
	if (tx == "Vector4" and ty == "nil" and tz == "nil" and tw == "nil") then
		return x
	elseif default and (tx == "number" or ty == "number" or tz == "number" or tw == "number") then
		---@cast tx Vector4
		return vec(x or default.x,y or default.y,z or default.z,w or default.w)
	elseif (tx == "number" and ty == "number" and tz == "number" and tw == "number") then
		return vec(x,y,z,w)
	else
		error(("Invalid Vector4 parameter, expected (number, number, number, number), instead got (%s, %s, %s, %s)"):format(tx,ty,tz,tw),3)
	end
end

return gnc
