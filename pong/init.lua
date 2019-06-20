local BASEDIR = (...):match("(.-)[^%.]+$")

local CollisionPrototypes = require(BASEDIR .. "pong.collidable").Protypes
local Collidable = require(BASEDIR .. "pong.collidable").Collidable
local Helper = require(BASEDIR .. "pong.collidable").Helper
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

function pong.newCircle(x, y, r)
	local collidable = CollisionPrototypes.Circle(x, y, r)
	return collidable
end

function pong.newPolygon(...)
	local collidable = CollisionPrototypes.Polygon(...)
	return collidable
end

function pong.newSegment(x1, y1, x2, y2)
	local collidable = CollisionPrototypes.Segment(x1, y1, x2, y2)
	return collidable
end

function pong.newPoint(x, y)
	local collidable = CollisionPrototypes.Point(x, y)
	return collidable
end

function pong.newRectangle(x, y, w, h)
	local collidable = Helper.newRectangle(x, y, w, h)
	return collidable
end

function pong.newRegularPolygon(n, r, x, y)
	local collidable = Helper.newRegularPolygon(n, r, x, y)
	return collidable
end

pong.debug = {}

function pong.debug.drawGrids(world)
	world:drawGrids()
end


return pong