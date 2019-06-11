local BASEDIR = (...):match("(.-)[^%.]+$")

local class = require(BASEDIR .. "class")

local Transform = class("pong_transform")

function Transform:init(x, y, angle, scale)
	self.x = x or 0
	self.y = y or 0
	self.angle = angle or 0
	self.scale = scale or 1
end

function Transform:rotate(phi)
	self.angle = self.angle + phi
end

function Transform:scale(scale)
	scale = scale or 1
	self.scale = self.scale * scale
end

function Transform:setPosition(x, y)
	self.x, self.y = x, y
end

function Transform:setRotationAngle(phi)
	self.angle = phi or 0
end

function Transform:setScale(scale)
	self.scale = scale
end

function Transform:getPosition()
	return self.x, self.y
end

function Transform:getRotationAngle()
	return self.angle
end

function Transform:getScale()
	return self.scale
end

return Transform