local BASEDIR = (...):match("(.-)[^%.]+$")

local Shape = require(BASEDIR.."pong.shape")
local SAT = require(BASEDIR.."pong.SAT")
local SpatialHash = require(BASEDIR.."pong.spatialhash")
local World = require(BASEDIR.."pong.world")

local pong = {}

local w, h = love.graphics.getDimensions()
pong.spatialHash = SpatialHash(w, h, 100)
local defaultWorld = World(w, h, 100)

function pong.newRectangle(x, y, w, h)
	local shape = defaultWorld:newRectangle(x, y, w, h)
	return shape
end

function pong.newCircle(x, y, r)
	local shape = defaultWorld:newCircle(x, y, r)
	return shape
end

function pong.newPolygon(...)
	local shape = defaultWorld:newPolygon(...)
	return shape
end

function pong.newPoint(x, y)
	local shape = defaultWorld:newPoint(x, y)
	return shape
end

function pong.newLine(x1, y1, x2, y2)
	local shape = defaultWorld:newLine(x1, y1, x2, y2)
	return shape
end

function pong.newRegularPolygon(n, r, x, y)
	local shape = defaultWorld:newRegularPolygon(n, r, x, y)
	return shape
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