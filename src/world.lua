local BASEDIR = (...):match("(.-)[^%.]+$")
local SpatialHash = require(BASEDIR.."spatialhash")
local Shape = require(BASEDIR.."Shape")

local World = class("cherry_pong_World")

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
	local shape = Shape.Rectangle(x, y, w, h)
	self.spatialHash:register(shape)
	return shape
end

function World:newCircle(x, y, r)
	local shape = Shape.Circle(x, y, r)
	self.spatialHash:register(shape)
	return shape
end

function World:newPolygon(...)
	local shape = Shape.Polygon(...)
	self.spatialHash:register(shape)
	return shape
end

function World:newPoint(x, y)
	local shape = Shape.Point(x, y)
	self.spatialHash:register(shape)
	return shape
end

function World:newLine(x1, y1, x2, y2)
	local shape = Shape.Line(x1, y1, x2, y2)
	self.spatialHash:register(shape)
	return shape
end

function World:newRegularPolygon(n, r, x, y)
	local shape = Shape.RegularPolygon(n, r, x, y)
	self.spatialHash:register(shape)
	return shape
end

function World:newGroup(...)
	local group = Shape.Group(...)
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