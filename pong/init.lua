local BASEDIR = (...):match("(.-)[^%.]+$")

local CollisionPrototypes = require("pong.collidable").Protypes
local Collidable = require("pong.collidable").Collidable
local Detection = require(BASEDIR.."pong.detection")
local SpatialHash = require(BASEDIR.."pong.spatialhash")
local World = require(BASEDIR.."pong.world")

local pong = {}

pong.Collidable = Collidable
pong.CollisionPrototypes = CollisionPrototypes
pong.SpatialHash = SpatialHash
pong.Detection = Detection

function pong.newWorld(cell, w, h)
	return World.new(cell, w, h)
end

function pong.newCircle(world, x, y, r)
	local collidable = world:newCircle(x, y, r)
	return collidable
end

function pong.newPolygon(world, ...)
	local collidable = world:newPolygon(...)
	return collidable
end

function pong.newSegment(world, x1, y1, x2, y2)
	local collidable = world:newSegment(x1, y1, x2, y2)
	return collidable
end

function pong.newPoint(world, x, y)
	local collidable = world:newPoint(x, y)
	return collidable
end

function pong.newRectangle(world, x, y, w, h)
	local collidable = world:newRectangle(x, y, w, h)
	return collidable
end

function pong.newRegularPolygon(world, n, r, x, y)
	local collidable = world:newRegularPolygon(n, r, x, y)
	return collidable
end

function pong.collisions(object)
	return defaultWorld:collisions(object)
end

pong.debug = {}

function pong.debug.drawGrids(world)
	world:drawGrids()
end


return pong