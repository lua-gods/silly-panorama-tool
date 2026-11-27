---@diagnostic disable: lowercase-global, return-type-mismatch

--[[______   __   ___              _       ____                 _      __
  / ____/ | / /  /   | __  _______(_)___ _/ __/___  _  ______ _(_)____/ /
 / / __/  |/ /  / /| |/ / / / ___/ / __ `/ /_/ __ \| |/_/ __ `/ / ___/ / 
/ /_/ / /|  /  / ___ / /_/ / /  / / /_/ / __/ /_/ />  </ /_/ / / /  / /  
\____/_/ |_/  /_/  |_\__,_/_/  /_/\__,_/_/  \____/_/|_|\__, /_/_/  /_/
--A Vectors library                  /____]]

local event = require("lib.GNevent")

---@class Vector4
---@field x number
---@field y number
---@field z number
---@field w number
---@operator add: Vector4
---@operator sub: Vector4
---@operator mul: Vector4
---@operator div: Vector4
---@operator unm: Vector4
---@operator pow: Vector4
---@operator mod: Vector4
---@operator concat: Vector4
---@field VALUES_CHANGED GN.Event
local Vector4 = {}


---@class Vector2
---@field x number
---@field y number
---@operator add: Vector2
---@operator sub: Vector2
---@operator mul: Vector2
---@operator div: Vector2
---@operator unm: Vector2
---@operator pow: Vector2
---@operator mod: Vector2
---@operator concat: Vector2
---@field VALUES_CHANGED GN.Event
local Vector2 = {}


---@class Vector3
---@field x number
---@field y number
---@field z number
---@operator add: Vector3
---@operator sub: Vector3
---@operator mul: Vector3
---@operator div: Vector3
---@operator unm: Vector3
---@operator pow: Vector3
---@operator mod: Vector3
---@operator concat: Vector3
---@field VALUES_CHANGED GN.Event
local Vector3 = {}


---Creates a new Vector2.
---@overload fun(vec2:Vector2): Vector2
---@param x number?
---@param y number?
---@return Vector2
function Vector2.new(x,y)
	local self
	if type(x) == "Vector2" then
		self = x:copy()
	end
	self = {
		x=x or 0,
		y=y or 0,
		VALUES_CHANGED = event.new()
	}
	setmetatable(self,Vector2)
	return self
end


---Creates a new Vector3.
---@overload fun(vec3:Vector3): Vector3
---@param x number?
---@param y number?
---@param z number?
---@return Vector3
function Vector3.new(x,y,z)
	local self
	if type(x) == "Vector3" then
		local v = x
		x,y,z = v.x,v.y,v.z
	end
	self = {
		x=x or 0,
		y=y or 0,
		z=z or 0,
		VALUES_CHANGED = event.new()
	}
	setmetatable(self,Vector3)
	return self
end


---Creates a new Vector4.
---@overload fun(vec4:Vector4): Vector4
---@param x number?
---@param y number?
---@param z number?
---@param w number?
---@return Vector4
function Vector4.new(x,y,z,w)
	local self
	if type(x) == "Vector4" then
		local v = x
		x,y,z,w = v.x,v.y,v.z,v.w
	end
	self = {
		x = x or 0,
		y = y or 0,
		z = z or 0,
		w = w or 0,
		VALUES_CHANGED = event.new()
	}
	setmetatable(self,Vector4)
	return self
end

--────  Vector 2  ────────────────────────────────────────────────────────--




Vector2.__index = function (t,key)
	local val = rawget(Vector2,key)
	if val then
		return val
	elseif type(key) == "string" and key:match('^[xy_]+$') then -- swizzling
		
		if #key == 2 then
			local a = key:sub(1,1)
			local b = key:sub(2,2)
			t.VALUES_CHANGED:invoke()
			return Vector2.new(t[a] or 0, t[b] or 0)
		elseif #key == 3 then
			local a = key:sub(1,1)
			local b = key:sub(2,2)
			local c = key:sub(3,3)
			t.VALUES_CHANGED:invoke()
			return Vector3.new(t[a] or 0, t[b] or 0, t[c] or 0)
		elseif #key == 4 then
			local a = key:sub(1,1)
			local b = key:sub(2,2)
			local c = key:sub(3,3)
			local d = key:sub(4,4)
			t.VALUES_CHANGED:invoke()
			return Vector4.new(t[a] or 0, t[b] or 0, t[c] or 0, t[d] or 0)
		elseif #key == 1 then
			t.VALUES_CHANGED:invoke()
			return t[key]
		end
	end
end
Vector2.__type = "Vector2"
Vector2.__newindex = function (t,key,value)
	if key:match('^[xy_]+$')  then
		local a = key:sub(1,1)
		local b = key:sub(2,2)
		t[a] = value.x
		t[b] = value.y
	else
		error("invalid swizzle, only accepts x,y or _, but recived \"" .. tostring(key:match('^[xy_]+$') ) .. "\"")
	end
end

Vector2.__call = function (t,x,y)
	return Vector2.new(x,y)
end

---Copies a Vector2.
---@return Vector2
function Vector2:copy()
	return Vector2.new(self.x,self.y)
end


Vector2.__eq = function (a,b)
	return a.x == b.x and a.y == b.y
end


Vector2.__add = function (a,b)
	return a:copy():add(b,b)
end


---@return Vector2
Vector2.__sub = function (a,b)
	return a:copy():sub(b,b)
end


---@return Vector2
Vector2.__mul = function (a,b)
	return a:copy():mul(b,b)
end


---@return Vector2
Vector2.__div = function (a,b)
	return a:copy():div(b,b)
end


---@return Vector2
Vector2.__unm = function (a)
	a.x = -a.x
	a.y = -a.y
	return a
end


---@return Vector2
Vector2.__mod = function (a,b)
	return a:copy():mod(b,b)
end


---@return Vector2
Vector2.__pow = function (a, b)
	return a:copy():pow(b,b)
end


Vector2.__clamp = function (a,min,max)
	a.x = math.clamp(a.x,min.x,max.x)
	a.y = math.clamp(a.y,min.y,max.y)
	return a
end


---@return string
Vector2.__tostring = function (a)
	return "("..tostring(a.x) .. ","..tostring(a.y)..")"
end


---@return Vector2
Vector2.__concat = function (a,b)
---@diagnostic disable-next-line: param-type-mismatch
	local new
	new = Vector2.new(tonumber(tostring(a.x) .. tostring(b.x)),tonumber(tostring(a.y) .. tostring(b.y)))
	a.VALUES_CHANGED:invoke(a)
	return new
end


---@return number
Vector2.__len = function (a)
	return Vector2.length(a)
end


---@overload fun(self : Vector2, vec2 : Vector2): Vector2
---@overload fun(self : Vector2, value: number): Vector2
---@param x number
---@param y number
---@return Vector2
function Vector2:set(x,y)
	self:rawset(x,y or x)
	self.VALUES_CHANGED:invoke(self.x,self.y)
	return self
end


---@overload fun(self : Vector2, vec2 : Vector2): Vector2
---@overload fun(self : Vector2, values : number): Vector2
---@param x number
---@param y number
---@return Vector2
function Vector2:rawset(x,y)
	local t = type(x)
	if t == "Vector2" then
		self.x = x.x
		self.y = x.y
	else
		self.x = x
		self.y = (y or x)
	end
	return self
end


---@overload fun(self : Vector2, vec2 : Vector2): Vector2
---@overload fun(self : Vector2, values : number): Vector2
---@param x number
---@param y number
---@return Vector2
function Vector2:add(x,y)
	local t = type(x)
	if t == "Vector2" then
		self.x = self.x + x.x
		self.y = self.y + x.y
	else
		self.x = self.x + x
		self.y = self.y + (y or x)
	end
	self.VALUES_CHANGED:invoke(self.x,self.y)
	return self
end


---@overload fun(self : Vector2, vec2 : Vector2): Vector2
---@overload fun(self : Vector2, value: number): Vector2
---@param x number
---@param y number
---@return Vector2
function Vector2:sub(x,y)
	local t = type(x)
	if t == "Vector2" then
		self.x = self.x - x.x
		self.y = self.y - x.y
	else
		self.x = self.x - x
		self.y = self.y - (y or x)
	end
	self.VALUES_CHANGED:invoke(self.x,self.y)
	return self
end


---@overload fun(self : Vector2, vec2 : Vector2): Vector2
---@overload fun(self : Vector2, value: number): Vector2
---@param x number
---@param y number
---@return Vector2
function Vector2:mul(x,y)
	local t = type(x)
	if t == "Vector2" then
		self.x = self.x * x.x
		self.y = self.y * x.y
	else
		self.x = self.x * x
		self.y = self.y * (y or x)
	end
	self.VALUES_CHANGED:invoke(self.x,self.y)
	return self
end


---@overload fun(self : Vector2, vec2 : Vector2): Vector2
---@overload fun(self : Vector2, value: number): Vector2
---@param x number
---@param y number
---@return Vector2
function Vector2:div(x,y)
	local t = type(x)
	if t == "Vector2" then
		self.x = self.x / x.x
		self.y = self.y / x.y
	else
		self.x = self.x / (x or 1)
		self.y = self.y / (y or x or 1)
	end
	self.VALUES_CHANGED:invoke(self.x,self.y)
	return self
end


---Applies a modulus to the Vector2
---@overload fun(self : Vector2, vec2 : Vector2): Vector2
---@overload fun(self : Vector2, value: number): Vector2
---@param x number
---@param y number
---@return Vector2
function Vector2:mod(x,y)
	local t = type(x)
	if t == "Vector2" then
		self.x = self.x % x.x
		self.y = self.y % x.y
	else
		self.x = self.x % x
		self.y = self.y % (y or x)
	end
	self.VALUES_CHANGED:invoke(self.x,self.y)
	return self
end


---Returns the length squared of the Vector2.
---@return number
function Vector2:lengthSquared()
	return self.x ^ 2 + self.y ^ 2
end


---Returns the length squared of the Vector2.
---@return number
function Vector2:length()
	return math.sqrt(Vector2.lengthSquared(self))
end


---Normalizes the Vector2.
---@return Vector2
function Vector2:normalize()
	local d = self:length()
	self.x = self.x / d
	self.y = self.y / d
	self.VALUES_CHANGED:invoke(self.x,self.y)
	return self
end


---Returns a copy of this Vector2 but normalizd.
---@return Vector2
function Vector2:normalized()
	return self:copy():normalize()
end


---Makes the Vector2 absolute.
---@return Vector2
function Vector2:abs()
	self.x = math.abs(self.x)
	self.y = math.abs(self.y)
	return self
end


---returns two values, x and y
---@return number
---@return number
function Vector2:unpack()
	return self.x, self.y
end


---Returns the cross product of the Vector2.
---@return Vector2
function Vector2:cross(vec2)
	return self.x * vec2.y - self.y * vec2.x
end

---Returns the dot product of the Vector2.
---@return Vector2
function Vector2:dot(vec2)
	return self.x * vec2.y + self.y * vec2.x
end


---Applies the math.floor function.
---@param snap number?
---@return Vector2
function Vector2:floor(snap)
	snap = snap or 1
	self.x = math.floor(self.x / snap) * snap
	self.y = math.floor(self.y / snap) * snap
	return self
end


---Applies the math.ceil Vector2.
---@param snap number?
---@return Vector2
function Vector2:ceil(snap)
	snap = snap or 1
	self.x = math.ceil(self.x / snap) * snap
	self.y = math.ceil(self.y / snap) * snap
	return self
end


---Rotates the Vector2. the angle is in degrees.
---@return Vector2
function Vector2:rotate(angle)
	local d = math.rad(angle)
	self.x = math.cos(d) * self.x - math.sin(d) * self.y
	self.y = math.sin(d) * self.x + math.cos(d) * self.y
	return self
end


---@param w number?
---@return Vector3
function Vector2:augmented(w)
	return Vector3.new(self.x, self.y, w)
end


--────  Vector3  ────────────────────────────────────────────────────────--


Vector3.__index = function (t,k)
	local val = rawget(Vector3,k)
	if val then
		return val
	elseif type(k) == "string" and k:match('^[xyz_]+$') then -- swizzling
		if #k == 4 then
			local x = k:sub(1,1)
			local y = k:sub(2,2)
			local z = k:sub(3,3)
			local w = k:sub(4,4)
			t.VALUES_CHANGED:invoke()
			return Vector4.new(t[x] or 0, t[y] or 0, t[z] or 0, t[w] or 0)
		elseif #k == 3 then
			local x = k:sub(1,1)
			local y = k:sub(2,2)
			local z = k:sub(3,3)
			t.VALUES_CHANGED:invoke()
			return Vector3.new(t[x] or 0, t[y] or 0, t[z] or 0)
		elseif #k == 2 then
			local x = k:sub(1,1)
			local y = k:sub(2,2)
			t.VALUES_CHANGED:invoke()
			return Vector2.new(t[x] or 0, t[y] or 0)
		elseif #k == 1 then
			t.VALUES_CHANGED:invoke()
			return t[k]
		end
	end
end
Vector3.__type = "Vector3"
Vector3.__newindex = function (t,k,v)
	if k:match('^[xy_]+$')  then
		local x = k:sub(1,1)
		local y = k:sub(2,2)
		local z = k:sub(3,3)
		if x then t[x] = v.x end
		if y then t[y] = v.y end
		if z then t[z] = v.z end
	else
		error("invalid swizzle, only accepts x,y,z or _, but recived \"" .. tostring(k:match('^[xyz_]+$') ) .. "\"")
	end
end

Vector3.__call = function (t,x,y,z)
	return Vector3.new(x,y,z)
end


---Copies the given Vector3.
---@return Vector3
function Vector3:copy()
	return Vector3.new(self)
end


Vector3.__eq = function (a,b)
	return a.x == b.x
	and a.y == b.y
	and a.z == b.z
end


Vector3.__add = function (a,b)
	return a:copy():add(b,b)
end


---@return Vector3
Vector3.__sub = function (a,b)
	return a:copy():sub(b,b)
end


---@return Vector3
Vector3.__mul = function (a,b)
	return a:copy():mul(b,b)
end


---@return Vector3
Vector3.__div = function (a,b)
	return a:copy():div(b,b)
end


---@return Vector3
Vector3.__unm = function (a)
	a.x = -a.x
	a.y = -a.y
	a.z = -a.y
	return a
end


---@return Vector3
Vector3.__mod = function (a,b)
	return a:copy():mod(b,b)
end


---@return Vector3
Vector3.__pow = function (a, b)
	return a:copy():pow(b,b)
end


Vector3.__clamp = function (a,min,max)
	a.x = math.clamp(a.x,min.x,max.x)
	a.y = math.clamp(a.y,min.y,max.y)
	a.z = math.clamp(a.z,min.z,max.z)
	return a
end


---@return string
Vector3.__tostring = function (a)
	return "("..tostring(a.x) .. ","..tostring(a.y)..","..tostring(a.z)..")"
end


---@return Vector3
Vector3.__concat = function (a,b)
---@diagnostic disable-next-line: param-type-mismatch
	local new
	new = Vector3.new(
		tonumber(tostring(a.x) .. tostring(b.x)),
		tonumber(tostring(a.y) .. tostring(b.y)),
		tonumber(tostring(a.z) .. tostring(b.z))
	)
	return new
end


---@return number
Vector3.__len = function (a)
	return Vector3.length(a)
end


---@overload fun(self : Vector3, vec3 : Vector3): Vector3
---@overload fun(self : Vector3, value: number): Vector3
---@param x number
---@param y number
---@param z number
---@return Vector3
function Vector3:set(x,y,z)
	self:rawset(x,y or x,z or x)
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z)
	return self
end


---@overload fun(self : Vector3, vec3 : Vector3): Vector3
---@overload fun(self : Vector3, value: number): Vector3
---@param x number
---@param y number
---@param z number
---@return Vector3
function Vector3:rawset(x,y,z)
	local t = type(x)
	if t == "Vector3" then
		self.x = x.x
		self.y = x.y
		self.z = x.z
	else
		self.x = x
		self.y = y
		self.z = z
	end
	return self
end


---@overload fun(self : Vector3, vec3 : Vector3): Vector3
---@overload fun(self : Vector3, value: number): Vector3
---@param x number
---@param y number
---@param z number
---@return Vector3
function Vector3:add(x,y,z)
	local t = type(x)
	if t == "Vector3" then
		self.x = self.x + x.x
		self.y = self.y + x.y
		self.z = self.z + x.z
	else
		self.x = self.x + x
		self.y = self.y + y or x
		self.z = self.z + z or x
	end
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z)
	return self
end


---@overload fun(self : Vector3, vec3 : Vector3): Vector3
---@overload fun(self : Vector3, value: number): Vector3
---@param x number
---@param y number
---@param z number
---@return Vector3
function Vector3:sub(x,y,z)
	local t = type(x)
	if t == "Vector3" then
		self.x = self.x - x.x
		self.y = self.y - x.y
		self.z = self.z - x.z
	else
		self.x = self.x - x
		self.y = self.y - y or x
		self.z = self.z - z or x
	end
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z)
	return self
end


---@overload fun(self : Vector3, vec3 : Vector3): Vector3
---@overload fun(self : Vector3, value : number): Vector3
---@param x number
---@param y number
---@param z number
---@return Vector3
function Vector3:mul(x,y,z)
	local t = type(x)
	if t == "Vector3" then
		self.x = self.x * x.x
		self.y = self.y * x.y
		self.z = self.z * x.z
	else
		self.x = self.x * x
		self.y = self.y * y or x
		self.z = self.z * z or x
	end
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z)
	return self
end


---@overload fun(self : Vector3, vec3 : Vector3): Vector3
---@overload fun(self : Vector3, value: number): Vector3
---@param x number
---@param y number
---@param z number
---@return Vector3
function Vector3:div(x,y,z)
	local t = type(x)
	if t == "Vector3" then
		self.x = self.x / x.x
		self.y = self.y / x.y
		self.z = self.z / x.z
	else
		self.x = self.x / (x or 1)
		self.y = self.y / (y or x or 1)
		self.z = self.z / (z or x or 1)
	end
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z)
	return self
end


---Applies a modulus to the Vector3
---@overload fun(self : Vector3, vec3 : Vector3)
---@param x number
---@param y number
---@param z number
---@return Vector3
function Vector3:mod(x,y,z)
	local t = type(x)
	if t == "Vector3" then
		self.x = self.x % x.x
		self.y = self.y % x.y
		self.z = self.z % x.z
	else
		self.x = self.x % x
		self.y = self.y % (y or x)
		self.z = self.z % (z or x)
	end
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z)
	return self
end


---Returns the length squared of the Vector3.
---@return number
function Vector3:lengthSquared()
	return self.x ^ 2 + self.y ^ 2 + self.z ^ 2
end


function Vector3:length()
	return math.sqrt(self.x*self.x + self.y*self.y + self.z*self.z)
end


---Normalizes the Vector3.
---@return Vector3
function Vector3:normalize()
	local d = self:length()
	self.x = self.x / d
	self.y = self.y / d
	self.z = self.z / d
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z)
	return self
end





---Returns a copy of this Vector3 but normalizd.
---@return Vector3
function Vector3:normalized()
	return self:copy():normalize()
end


---Makes the Vector3 absolute.
---@return Vector3
function Vector3:abs()
	self.x = math.abs(self.x)
	self.y = math.abs(self.y)
	self.z = math.abs(self.z)
	return self
end


---returns two values, x and y
---@return number
---@return number
---@return number
function Vector3:unpack()
	return self.x, self.y, self.z
end


function Vector3:cross(v)
	return Vector3.new(
		self.y * v.z - self.z * v.y,
		self.z * v.x - self.x * v.z,
		self.x * v.y - self.y * v.x
	)
end

function Vector3:dot(v)
	return self.x * v.x + self.y * v.y + self.z * v.z
end


---Applies the math.floor function.
---@param snap number?
---@return Vector3
function Vector3:floor(snap)
	snap = snap or 1
	self.x = math.floor(self.x / snap) * snap
	self.y = math.floor(self.y / snap) * snap
	self.z = math.floor(self.z / snap) * snap
	return self
end


---Applies the math.ceil Vector3.
---@param snap number?
---@return Vector3
function Vector3:ceil(snap)
	snap = snap or 1
	self.x = math.ceil(self.x / snap) * snap
	self.y = math.ceil(self.y / snap) * snap
	self.z = math.ceil(self.z / snap) * snap
	return self
end


---Rotates the Vector3 to a given axis. the angle is in degrees.
---@param angle number
---@param axis Vector3
---@return Vector3
function Vector3:rotate(angle,axis)
	angle = math.deg(angle)
	local k = axis:normalized()
	local cos = math.cos(angle)
	local sin = math.sin(angle)

	local v = self

	local term1 = Vector3.new(
		v.x * cos,
		v.y * cos,
		v.z * cos
	)

	local cross = k:cross(v)
	local term2 = Vector3.new(
		cross.x * sin,
		cross.y * sin,
		cross.z * sin
	)

	local dot = k:dot(v)
	local term3 = Vector3.new(
		k.x * dot * (1 - cos),
		k.y * dot * (1 - cos),
		k.z * dot * (1 - cos)
	)

	return Vector3.new(
		term1.x + term2.x + term3.x,
		term1.y + term2.y + term3.y,
		term1.z + term2.z + term3.z
	)
end


---@param w number?
---@return Vector4
function Vector3:augmented(w)
	return Vector4.new(self.x, self.y, self.z, w or 1)
end


--────  Vector 4  ────────────────────────────────────────────────────────--





Vector4.__index = function (t,k)
	local val = rawget(Vector4,k)
	if val then
		return val
	elseif type(k) == "string" and k:match('^[xyzw_]+$') then -- swizzling
		if #k == 4 then
			local x = k:sub(1,1)
			local y = k:sub(2,2)
			local z = k:sub(3,3)
			local w = k:sub(4,4)
			return Vector4.new(t[x] or 0, t[y] or 0, t[z] or 0, t[w] or 0)
		elseif #k == 3 then
			local x = k:sub(1,1)
			local y = k:sub(2,2)
			local z = k:sub(3,3)
			return Vector3.new(t[x] or 0, t[y] or 0, t[z] or 0)
		elseif #k == 2 then
			local x = k:sub(1,1)
			local y = k:sub(2,2)
			return Vector2.new(t[x] or 0, t[y] or 0)
		elseif #k == 1 then
			return t[k]
		end
	end
end
Vector4.__type = "Vector4"
Vector4.__newindex = function (t,k,v)
	if k:match('^[xy_]+$')  then
		local x = k:sub(1,1)
		local y = k:sub(2,2)
		local z = k:sub(3,3)
		local w = k:sub(3,3)
		if x then t[x] = v.x end
		if y then t[y] = v.y end
		if z then t[z] = v.z end
		if w then t[w] = v.w end
	else
		error("invalid swizzle, only accepts x,y,z or _, but recived \"" .. tostring(k:match('^[xyz_]+$') ) .. "\"")
	end
end

Vector4.__call = function (t,x,y,z,w)
	return Vector4.new(x,y,z,w)
end


---Copies the given Vector4.
---@return Vector4
function Vector4:copy()
	return Vector4.new(self)
end


Vector4.__eq = function (a,b)
	return a.x == b.x
	and a.y == b.y
	and a.z == b.z
	and a.w == b.w
end


Vector4.__add = function (a,b)
	return a:copy():add(b)
end


---@return Vector4
Vector4.__sub = function (a,b)
	return a:copy():sub(b)
end


---@return Vector4
Vector4.__mul = function (a,b)
	return a:copy():mul(b)
end


---@return Vector4
Vector4.__div = function (a,b)
	return a:copy():div(b)
end


---@return Vector4
Vector4.__unm = function (a)
	a.x = -a.x
	a.y = -a.y
	a.z = -a.y
	return a
end


---@return Vector4
Vector4.__mod = function (a,b)
	return a:copy():mod(b,b)
end


---@return Vector4
Vector4.__pow = function (a, b)
	return a:copy():pow(b,b)
end


Vector4.__clamp = function (a,min,max)
	a.x = math.clamp(a.x,min.x,max.x)
	a.y = math.clamp(a.y,min.y,max.y)
	a.z = math.clamp(a.z,min.z,max.z)
	a.w = math.clamp(a.w,min.w,max.w)
	return a
end


---@return string
Vector4.__tostring = function (a)
	return "("..tostring(a.x) .. ","..tostring(a.y)..","..tostring(a.z)..","..tostring(a.w)..")"
end


---@return Vector4
Vector4.__concat = function (a,b)
---@diagnostic disable-next-line: param-type-mismatch
	local new
	new = Vector4.new(
		tonumber(tostring(a.x) .. tostring(b.x)),
		tonumber(tostring(a.y) .. tostring(b.y)),
		tonumber(tostring(a.z) .. tostring(b.z)),
		tonumber(tostring(a.w) .. tostring(b.w))
	)
	a.VALUES_CHANGED:invoke(a)
	return new
end


---@return number
Vector4.__len = function (a)
	return Vector4.length(a)
end


---@overload fun(self : Vector4, vec4 : Vector4)
---@param x number
---@param y number
---@param z number
---@param w number
---@return Vector4
function Vector4:set(x,y,z,w)
	self:rawset(x,y,z,w)
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z)
	return self
end


---@overload fun(self : Vector4, vec3 : Vector4)
---@param x number
---@param y number
---@param z number
---@return Vector4
function Vector4:rawset(x,y,z,w)
	local t = type(x)
	if t == "Vector4" then
		self.x = x.x
		self.y = x.y
		self.z = x.z
		self.w = x.w
	else
		self.x = x
		self.y = y
		self.z = z
		self.w = w
	end
	return self
end


---@overload fun(self : Vector4, vec4 : Vector4)
---@param x number
---@param y number
---@param z number
---@param w number
---@return Vector4
function Vector4:add(x,y,z,w)
	local t = type(x)
	if t == "Vector4" then
		self.x = self.x + x.x
		self.y = self.y + x.y
		self.z = self.z + x.z
		self.w = self.w + x.w
	else
		self.x = self.x + x
		self.y = self.y + y
		self.z = self.z + z
		self.w = self.w + w
	end
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z,self.w)
	return self
end


---@overload fun(self : Vector4, vec4 : Vector4)
---@param x number
---@param y number
---@param z number
---@param w number
---@return Vector4
function Vector4:sub(x,y,z,w)
	local t = type(x)
	if t == "Vector4" then
		self.x = self.x - x.x
		self.y = self.y - x.y
		self.z = self.z - x.z
		self.w = self.w - x.w
	else
		self.x = self.x - x
		self.y = self.y - y
		self.z = self.z - z
		self.w = self.w - w
	end
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z,self.w)
	return self
end


---@overload fun(self : Vector4, vec4 : Vector4)
---@param x number
---@param y number
---@param z number
---@param w number
---@return Vector4
function Vector4:mul(x,y,z,w)
	local t = type(x)
	if t == "Vector4" then
		self.x = self.x * x.x
		self.y = self.y * x.y
		self.z = self.z * x.z
		self.w = self.w * x.w
	else
		self.x = self.x * x
		self.y = self.y * y
		self.z = self.z * z
		self.w = self.w * w
	end
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z,self.w)
	return self
end


---@overload fun(self : Vector4, vec4 : Vector4)
---@param x number
---@param y number
---@param z number
---@param w number
---@return Vector4
function Vector4:div(x,y,z,w)
	local t = type(x)
	if t == "Vector4" then
		self.x = self.x / x.x
		self.y = self.y / x.y
		self.z = self.z / x.z
		self.w = self.w / x.w
	else
		self.x = self.x / (x or 1)
		self.y = self.y / (y or 1)
		self.z = self.z / (z or 1)
		self.w = self.w
	end
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z,self.w)
	return self
end


---Applies a modulus to the Vector4
---@overload fun(self : Vector4, vec4 : Vector4)
---@param x number
---@param y number
---@param z number
---@param w number
---@return Vector4
function Vector4:mod(x,y,z,w)
	local t = type(x)
	if t == "Vector4" then
		self.x = self.x % x.x
		self.y = self.y % x.y
		self.z = self.z % x.z
		self.w = self.w % x.w
	else
		self.x = self.x % x
		self.y = self.y % y
		self.z = self.z % z
		self.w = self.w
	end
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z,self.w)
	return self
end


---Returns the length squared of the Vector4.
---@return number
function Vector4:lengthSquared()
	return self.x ^ 2 + self.y ^ 2 + self.z ^ 2 + self.w ^ 2
end


function Vector4:length()
	return math.sqrt(self.x^2 + self.y^2 + self.z^2 + self.w^2)
end


---Normalizes the Vector4.
---@return Vector4
function Vector4:normalize()
	local d = self:length()
	self.x = self.x / d
	self.y = self.y / d
	self.z = self.z / d
	self.w = self.w / d
	self.VALUES_CHANGED:invoke(self.x,self.y,self.z,self.w)
	return self
end


---Returns a copy of this Vector4 but normalizd.
---@return Vector4
function Vector4:normalized()
	return self:copy():normalize()
end


---Makes the Vector4 absolute.
---@return Vector4
function Vector4:abs()
	self.x = math.abs(self.x)
	self.y = math.abs(self.y)
	self.z = math.abs(self.z)
	self.w = math.abs(self.w)
	return self
end


---returns two values, x and y
---@return number
---@return number
---@return number
---@return number
function Vector4:unpack()
	return self.x, self.y, self.z, self.w
end


function Vector4:cross(b,c)
	local a = self
	return Vector4.new(
		  a.y * (b.z * c.w - b.w * c.z) - a.z * (b.y * c.w - b.w * c.y) + a.w * (b.y * c.z - b.z * c.y),
		-(a.x * (b.z * c.w - b.w * c.z) - a.z * (b.x * c.w - b.w * c.x) + a.w * (b.x * c.z - b.z * c.x)),
		  a.x * (b.y * c.w - b.w * c.y) - a.y * (b.x * c.w - b.w * c.x) + a.w * (b.x * c.y - b.y * c.x),
		-(a.x * (b.y * c.z - b.z * c.y) - a.y * (b.x * c.z - b.z * c.x) + a.z * (b.x * c.y - b.y * c.x))
	)
end

function Vector4:dot(v)
	return self.x * v.x + self.y * v.y + self.z * v.z + self.w * v.w
end


---Applies the math.floor function.
---@param snap number?
---@return Vector4
function Vector4:floor(snap)
	snap = snap or 1
	self.x = math.floor(self.x / snap) * snap
	self.y = math.floor(self.y / snap) * snap
	self.z = math.floor(self.z / snap) * snap
	self.w = math.floor(self.w / snap) * snap
	return self
end


---Applies the math.ceil Vector4.
---@param snap number?
---@return Vector4
function Vector4:ceil(snap)
	snap = snap or 1
	self.x = math.ceil(self.x / snap) * snap
	self.y = math.ceil(self.y / snap) * snap
	self.z = math.ceil(self.z / snap) * snap
	self.w = math.ceil(self.w / snap) * snap
	return self
end

--[[
---Rotates the Vector4 to a given axis. the angle is in degrees.
---@param angle number
---@param axis Vector4
---@return Vector4
function Vector4:rotate(angle,axis)
	angle = math.deg(angle)
	local k = axis:normalized()
	local cos = math.cos(angle)
	local sin = math.sin(angle)

	local v = self

	local term1 = Vector4.new(
		v.x * cos,
		v.y * cos,
		v.z * cos
	)

	local cross = k:cross(v)
	local term2 = Vector4.new(
		cross.x * sin,
		cross.y * sin,
		cross.z * sin
	)

	local dot = k:dot(v)
	local term3 = Vector4.new(
		k.x * dot * (1 - cos),
		k.y * dot * (1 - cos),
		k.z * dot * (1 - cos)
	)

	return Vector4.new(
		term1.x + term2.x + term3.x,
		term1.y + term2.y + term3.y,
		term1.z + term2.z + term3.z
	)
end
]]


--────  UTILITIES  ────────────────────────────────────────────────────────--

---@overload fun(x: number, y:number): Vector2
---@overload fun(x: number, y:number, z:number): Vector3
---@param x number
---@param y number
---@param z number
---@param w number
---@return Vector4
function vec(x,y,z,w)
	if x then
		if y then
			if z then
				if w then
					return Vector4.new(x,y,z,w)
				end
				return Vector3.new(x,y,z)
			end
			return Vector2.new(x,y)
		end
		return x
	end
	error("Invalid Vector Declaration: ("..tostring(x)..","..tostring(y)..","..tonumber(z)..","..tostring(w)..")")
end

local VectorsAPI = {}

function VectorsAPI.hexToRGB(hex)
	local r,g,b = hex:match("#?(%x%x)(%x%x)(%x%x)")
	return vec(tonumber("0x"..r)/255, tonumber("0x"..g)/255, tonumber("0x"..b)/255)
end

function VectorsAPI.angleToDir(pitch,yaw)
	local tp,ty = type(pitch), type(yaw)
	if pitch and (not yaw) then
		local vec = pitch
		pitch = vec.y
		yaw = vec.x
	end
	
	local dir = vec(
		math.cos(yaw) * math.cos(pitch),
		math.sin(yaw) * math.cos(pitch),
		math.sin(pitch)
	)
	return dir
end

VectorsAPI.vec2 = Vector2
VectorsAPI.vec3 = Vector3
VectorsAPI.vec4 = Vector4

vectors = VectorsAPI
