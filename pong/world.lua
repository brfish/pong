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
	collidable.world = self
end

function World:remove(collidable)
	if collidable.world ~= self then
		return false
	end
	return self.spatialHash:remove(collidable)
	collidable.world = nil
end

function World:newCircle(x, y, r)
	local collidable = Prototypes.Circle.new(x, y, r)
	self:add(collidable)
	return collidable
end

function World:newConvexPolygon(...)
	local collidable = Prototypes.ConvexPolygon.new(...)
	self:add(collidable)
	return collidable
end

function World:newSegment(x1, y1, x2, y2)
	local collidable = Prototypes.Segment.new(x1, y1, x2, y2)
	self:add(collidable)
	return collidable
end

function World:newPoint(x, y)
	local collidable = Prototypes.Point.new(x, y)
	self:add(collidable)
	return collidable
end

function World:newRectangle(x, y, w, h)
	local collidable = Helper.newRectangle(x, y, w, h)
	self:add(collidable)
	return collidable
end

function World:newRegularPolygon(n, r, x, y)
	local collidable = Helper.newRegularPolygon(n, r, x, y)
	self:add(collidable)
	return collidable
end

function World:collisions(object, filter)
	return self.spatialHash:collisions(object, filter)
end

function World:isCollided(object, filter)
	return self.spatialHash:isCollided(object, filter)
end

function World:queryCircle(x, y, filter)
	local circle = self:newCircle(x, y)
	local result = self:collisions(circle, filter)
	self:remove(circle)
	return result
end

function World:queryBox(x, y, w, h, filter)
	local box = self:newRectangle(x, y, w, h)
	local result = self:collisions(box, filter)
	self:remove(box)
	return result
end

function World:querySegment(x1, y1, x2, y2, filter)
	local segment = self:newSegment(x1, y1, x2, y2)
	local result = self:collisions(segment, filter)
	self:remove(segment)
	return result
end

function World:queryPoint(x, y, filter)
	local point = self:newPoint(x, y)
	local result = self:collisions(point, filter)
	self:remove(point)
	return result
end

function World:drawGrids()
	self.spatialHash:drawGrids()
end

function World:update(dt)
end

return World