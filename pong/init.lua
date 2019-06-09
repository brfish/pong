local BASEDIR = (...):match("(.-)[^%.]+$")

local Body = require(BASEDIR.."pong.body")
local SAT = require(BASEDIR.."pong.SAT")
local SpatialHash = require(BASEDIR.."pong.spatialhash")
local World = require(BASEDIR.."pong.world")

local pong = {}

function pong.newWorld(cell, w, h)
	return World(cell, w, h)
end

function pong.newCircle(world, x, y, r)
	local body = world:newCircle(x, y, r)
	return body
end

function pong.newCapsule(world, width, height, cx, cy, rotation)
	local body = world:newCapsule(width, height, cx, cy, rotation)
	return body
end

function pong.newGroup(world)
	local group = world:newGroup()
	return group
end

function pong.newPolygon(world, ...)
	local body = world:newPolygon(...)
	return body
end

function pong.newPoint(world, x, y)
	local body = world:newPoint(x, y)
	return body
end

function pong.newLine(world, x1, y1, x2, y2)
	local body = world:newLine(x1, y1, x2, y2)
	return body
end

function pong.newRectangle(world, x, y, w, h)
	local body = world:newRectangle(x, y, w, h)
	return body
end

function pong.newRegularPolygon(world, n, r, x, y)
	local body = world:newRegularPolygon(n, r, x, y)
	return body
end

function pong.collisions(object)
	return defaultWorld:collisions(object)
end

pong.debug = {}

function pong.debug.drawGrids(world)
	world:drawGrids()
end


return pong