local BASEDIR = (...):match("(.-)[^%.]+$")

local class = require(BASEDIR .. "class")
local SpatialHash = require(BASEDIR .. "spatialhash")
local Prototypes = require(BASEDIR .. "collidable").Prototypes
local Helper = require(BASEDIR .. "collidable").Helper
local Types = require(BASEDIR .. "type_info")

local World = class("pong_world")

function World:init(cell, x, y, w, h)
	self.__isWorld = true
	self.cell = cell or 100
	self.x = x or 0
	self.y = y or 0
	self.width = w or love.graphics.getWidth()
	self.height = h or love.graphics.getHeight()
	
	self.spatialHash = SpatialHash.new(self.cell, self.x, self.y, self.width, self.height)
end

function World:setDefaultFilter(filter)
	self.spatialHash:setDefaultFilter(filter)
end

function World:getDefaultFilter()
	return self.spatialHash:getDefaultFilter()
end

function World:add(collidable)
	self.spatialHash:add(collidable)
end

function World:remove(collidable)
	self.spatialHash:remove(collidable)
end

function World:newCircle(x, y, r)
	local collidable = Prototypes.Circle.new(x, y, r)
	self.spatialHash:add(collidable)
	return collidable
end

function World:newConvexPolygon(...)
	local collidable = Prototypes.ConvexPolygon.new(...)
	self.spatialHash:add(collidable)
	return collidable
end

function World:newSegment(x1, y1, x2, y2)
	local collidable = Prototypes.Segment.new(x1, y1, x2, y2)
	self.spatialHash:add(collidable)
	return collidable
end

function World:newPoint(x, y)
	local collidable = Prototypes.Point.new(x, y)
	self.spatialHash:add(collidable)
	return collidable
end

function World:newRectangle(x, y, w, h)
	local collidable = Helper.newRectangle(x, y, w, h)
	self.spatialHash:add(collidable)
	return collidable
end

function World:newRegularPolygon(n, r, x, y)
	local collidable = Helper.newRegularPolygon(n, r, x, y)
	self.spatialHash:add(collidable)
	return collidable
end

function World:collisions(object, filter)
	return self.spatialHash:collisions(object, filter)
end

function World:isCollided(object)
	return self.spatialHash:isCollided(object)
end

function World:drawGrids()
	self.spatialHash:drawGrids()
end

return World