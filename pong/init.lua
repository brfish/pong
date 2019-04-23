local BASEDIR = (...):match("(.-)[^%.]+$")

local Body = require(BASEDIR.."pong.body")
local SAT = require(BASEDIR.."pong.SAT")
local SpatialHash = require(BASEDIR.."pong.spatialhash")
local World = require(BASEDIR.."pong.world")

local pong = {}

local w, h = love.graphics.getDimensions()
pong.spatialHash = SpatialHash(w, h, 100)
local defaultWorld = World(w, h, 100)

function pong.newRectangle(x, y, w, h)
	local body = defaultWorld:newRectangle(x, y, w, h)
	return body
end

function pong.newCircle(x, y, r)
	local body = defaultWorld:newCircle(x, y, r)
	return body
end

function pong.newCapsule(width, height, cx, cy, rotation)
	local body = defaultWorld:newCapsule(width, height, cx, cy, rotation)
	return body
end

function pong.newPolygon(...)
	local body = defaultWorld:newPolygon(...)
	return body
end

function pong.newPoint(x, y)
	local body = defaultWorld:newPoint(x, y)
	return body
end

function pong.newLine(x1, y1, x2, y2)
	local body = defaultWorld:newLine(x1, y1, x2, y2)
	return body
end

function pong.newRegularPolygon(n, r, x, y)
	local body = defaultWorld:newRegularPolygon(n, r, x, y)
	return body
end

function pong.newGroup()
	local group = defaultWorld:newGroup()
	return group
end

function pong.drawGrids()
	defaultWorld:drawGrids()
end

function pong.collisions(object)
	return defaultWorld:collisions(object)
end

function pong.newWorld(w, h, cell)
	return World(w, h, cell)
end

function pong.setDefaultWorld(world)
	defaultWorld = world
end

return pong