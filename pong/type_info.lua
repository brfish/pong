
local Types = {}

Types.collidables = {
	[1] = "circle",
	[2] = "polygon",
	[3] = "segment",
	[4] = "point",
	[5] = "compound"
}

function Types.isCollidable(obj)
	return obj.__isCollidable == true
end

function Types.isWorld(obj)
	return obj.__isWorld == true
end

function Types.isTransform(obj)
	return obj.__isTransform == true
end

function Types.isSpatialHash(obj)
	return obj.__isSpatialHash == true
end

function Types.typeinfo(obj)
	if Types.isCollidable(obj) then
		return Types.collidables[obj.ptype]
	elseif Types.isWorld(obj) then
		return "world"
	elseif Types.isTransform(obj) then
		return "transform"
	elseif Types.isSpatialHash(obj) then
		return "spatialhash"
	end
	return type(obj)
end

return Types