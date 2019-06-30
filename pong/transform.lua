local BASEDIR = (...):match("(.-)[^%.]+$")

local class = require(BASEDIR .. "class")

local Transform = class("pong_transform")

function Transform:init(x, y, angle, scaleX, scaleY, ox, oy)
	self.__isTransform = true
	self.x = x or 0
	self.y = y or 0
	self.angle = angle or 0
	self.scaleX = scaleX or 1
	self.scaleY = scaleY or self.scaleX
	self.originX = ox or 0
	self.originY = oy or 0
end

function Transform:setPosition(x, y)
	self.x, self.y = x, y
end

function Transform:setScreenPosition(x, y)
	x = x - self.originX
	y = y - self.originY
	self.x, self.y = x, y
end

function Transform:setRotationAngle(phi)
	self.angle = phi or 0
end

function Transform:setScale(sx, sy)
	sx = sx or 1
	sy = sy or sx
	self.sx = sx
	self.sy = sy
end

function Transform:getOriginPoint()
	return self.originX, self.originY
end

function Transform:getPosition()
	return self.x, self.y
end

function Transform:getScreenPosition()
	return self.x + self.originX, self.y + self.originY
end

function Transform:getRotationAngle()
	return self.angle
end

function Transform:getScale()
	return self.scaleX, scaleY
end

function Transform:rotate(angle)
	self.angle = self.angle + angle
	if self.angle >= math.pi * 2 then
		self.angle = self.angle - math.pi * 2
	end
end

function Transform:scale(sx, sy)
	sx = sx or 1
	sy = sy or sx
	self.scaleX = self.scaleX * sx
	self.scaleY = self.scaleY * sy
end

return Transform