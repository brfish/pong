local BASEDIR = (...):match("(.-)[^%.]+$")

local SpatialHash = require(BASEDIR.."spatialhash")
local Body = require(BASEDIR.."body")

local World = class("pong_world")

function World:initialize(w, h, cell)
	self.width = w or love.graphics.getWidth()
	self.height = h or love.graphics.getHeight()
	self.cell = cell or 100
	self.spatialHash = SpatialHash(self.width, self.height, self.cell)
end

function World:setDefaultFilter(filter)
	self.spatialHash:setDefaultFilter(filter)
end

function World:getDefaultFilter()
	return self.spatialHash:getDefaultFilter()
end

function World:newRectangle(x, y, w, h)
	local body = Body.Rectangle(x, y, w, h)
	self.spatialHash:register(body)
	return body
end

function World:newCircle(x, y, r)
	local body = Body.Circle(x, y, r)
	self.spatialHash:register(body)
	return body
end

function World:newCapsule(width, height, cx, cy, rotation)
	local body = Body.Capsule(width, height, cx, cy, rotation)
	self.spatialhash:register(body)
	return body
end

function World:newPolygon(...)
	local body = Body.Polygon(...)
	self.spatialHash:register(body)
	return body
end

function World:newPoint(x, y)
	local body = Body.Point(x, y)
	self.spatialHash:register(body)
	return body
end

function World:newLine(x1, y1, x2, y2)
	local body = Body.Line(x1, y1, x2, y2)
	self.spatialHash:register(body)
	return body
end

function World:newRegularPolygon(n, r, x, y)
	local body = Body.RegularPolygon(n, r, x, y)
	self.spatialHash:register(body)
	return body
end

function World:newGroup(...)
	local group = Body.Group(...)
	return group
end

function World:drawGrids()
	self.spatialHash:drawGrids()
end

function World:collisions(object, filter)
	return self.spatialHash:retrieveCollisions(object, filter or self:getDefaultFilter())
end

function World:isObjectCollided(object)
	return self.spatialHash:isObjectCollided(object)
end

return World