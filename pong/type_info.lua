
local Types = {}

Types.collidables = {
	[1] = "circle",
	[2] = "polygon",
	[3] = "segment",
	[4] = "point",
	[5] = "compound"
}

function Types.isCollidable(obj)
	if type(obj) ~= "table" then return false end
	return obj.__isCollidable == true
end

function Types.isWorld(obj)
	if type(obj) ~= "table" then return false end
	return obj.__isWorld == true
end

function Types.isTransform(obj)
	if type(obj) ~= "table" then return false end
	return obj.__isTransform == true
end

function Types.isSpatialHash(obj)
	if type(obj) ~= "table" then return false end
	return obj.__isSpatialHash == true
end

function Types.typeinfo(obj)
	if type(obj) ~= "table" then return type(obj) end
	if Types.isCollidable(obj) then
		return Types.collidables[obj.ptype]
	elseif Types.isWorld(obj) then
		return "world"
	elseif Types.isTransform(obj) then
		return "transform"
	elseif Types.isSpatialHash(obj) then
		return "spatialhash"
	end
	return "table"
end

function Types.error(obj, right)
	error(string.format("Attempt to pass a wrong type: need a %s value instead of %s", Types.typeinfo(right), Types.typeinfo(obj)), 1)
end

return Types