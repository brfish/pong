local BASEDIR = (...):match("(.-)[^%.]+$")

local class = require(BASEDIR .. "class")

local Transform = require(BASEDIR .. "transform")
local Types = require(BASEDIR .. "type_info")
local vec = require(BASEDIR .. "vector")


local Collidable = class("pong_collidable")

function Collidable:init(transform)
	self.__isCollidable = true
	self.transform = transform
	self.id = -1
	self.world = nil
	self.enabled = true
end

function Collidable:setEnabled(e)
	if type(e) ~= "boolean" then Types.error(e, "boolean") end
	self.enabled = e
end

function Collidable:axes()
end

function Collidable:project()
end

function Collidable:AABB()
end

function Collidable:OBB()
end

function Collidable:center()
	return self.transform:getScreenPosition()
end

function Collidable:moveTo(x, y)
	return self.transform:setScreenPosition(x, y)
end

function Collidable:move(disX, disY)
	local cx, cy = self.transform:getScreenPosition()
	self:moveTo(cx + disX, cy + disY)
end

function Collidable:scale(sx, sy)
	self.transform:scale(sx, sy)
end

function Collidable:rotate(angle)
	self.transform:rotate(angle)
end

function Collidable:rotateAroundPoint(angle, x, y)
	local cx, cy = self.transform:getScreenPosition()
	local tx, ty = vec.rotate(cx, cy, angle, x, y)
	self.transform:setScreenPosition(tx, ty)
end

function Collidable:rotateAroundOriginPoint(angle)
	local ox, oy = self.transform:getOriginPoint()
	self:rotateAroundPoint(angle, ox, oy)
end

function Collidable:draw()
end

function Collidable:drawAABB()
	local x, y, w, h = self:AABB()
	w = w - x
	h = h - y
	love.graphics.rectangle("line", x, y, w, h)
end


local PnCircle = class("pong_PnCircle", Collidable)
function PnCircle:init(x, y, radius)
	self.super.init(self, Transform.new(x, y))
	self.radius = radius
	self.ptype = 1
end

function PnCircle:axes()
	local cx, cy = self.transform:getScreenPosition()
	local x, y = vec.normal(cx, cy)
	return {{x, y}}
end

function PnCircle:project(axisX, axisY)
	local cx, cy = self.transform:getScreenPosition()
	local scale = self.transform:getScale()
	axisX, axisY = vec.normalize(axisX, axisY)
	local v = vec.mul(cx, cy, axisX, axisY)
	return {max = v + self.radius * scale, min = v - self.radius * scale}
end

function PnCircle:AABB()
	local cx, cy = self.transform:getScreenPosition()
	local scale = self.transform:getScale()
	return  cx - self.radius * scale,
			cy - self.radius * scale,
			cx + self.radius * scale,
			cy + self.radius * scale
end

function PnCircle:rotate()
end

function PnCircle:scale(s)
	self.transform:scale(s)
end

function PnCircle:getRadius()
	return self.radius * self.transform:getScale()
end

function PnCircle:getOriginalRadius()
	return self.radius
end

function PnCircle:draw(drawmode)
	drawmode = dramode or "fill"
	if drawmode ~= "fill" and drawmode ~= "line" then
		error("Error: Unknown drawmode - " .. tostring(drawmode))
		return
	end
	local cx, cy = self.transform:getScreenPosition()
	love.graphics.circle(drawmode, cx, cy, self:getRadius())
end





local PnConvexPolygon = class("pong_PnConvexPolygon", Collidable)
function PnConvexPolygon:init(...)
	self.vertexesCounts = #{...} / 2
	self.fixedValues = {}
	self.ptype = 2
	local centerX, centerY = 0, 0
	for i = 1, #{...}, 2 do
		centerX = centerX + select(i, ...)
		centerY = centerY + select(i + 1, ...)
	end
	centerX = centerX / self.vertexesCounts
	centerY = centerY / self.vertexesCounts
	self.super.init(self, Transform.new(centerX, centerY))

	for i = 1, self.vertexesCounts do
		self.fixedValues[i] = {
			select(i * 2 - 1, ...) - centerX,
			select(i * 2, ...) - centerY}
	end
	self.fixedValues[0] = self.fixedValues[self.vertexesCounts]
end

function PnConvexPolygon:getVertexCounts()
	return self.vertexesCounts
end

function PnConvexPolygon:getVertex(vertexId)
	local cx, cy = self.transform:getScreenPosition()
	local scale = self.transform:getScale()
	local rx, ry = vec.rotate(
			self.fixedValues[vertexId][1] * scale + cx,
			self.fixedValues[vertexId][2] * scale + cy,
			self.transform:getRotationAngle(),
			cx, cy
			)
	return rx, ry
end

function PnConvexPolygon:axes()
	local axes = {}
	for i = 1, self.vertexesCounts do
		local v1x, v1y = self:getVertex(i)
		local v2x, v2y = self:getVertex(i - 1)
		local x, y = vec.normal(v1x - v2x, v1y - v2y)
		axes[#axes + 1] = {x, y}
	end
	return axes
end

function PnConvexPolygon:project(axisX, axisY)
	axisX, axisY = vec.normalize(axisX, axisY)
	local vx, vy = self:getVertex(1)
	local min = vec.mul(vx, vy, axisX, axisY)
	local max = min
	for i = 1, self.vertexesCounts do
		local vx, vy = self:getVertex(i)
		local proj = vec.mul(vx, vy, axisX, axisY)
		if proj < min then min = proj end
		if proj > max then max = proj end
	end
	return {max = max, min = min}
end

function PnConvexPolygon:AABB()
	local x1, y1 = self:getVertex(1)
	local x2, y2 = x1, y1
	for i = 2, self.vertexesCounts do
		local vx, vy = self:getVertex(i)
		if x1 > vx then x1 = vx end
		if y1 > vy then y1 = vy end
		if x2 < vx then x2 = vx end
		if y2 < vy then y2 = vy end
	end
	return x1, y1, x2, y2
end

function PnConvexPolygon:draw(drawmode)
	drawmode = dramode or "fill"
	if drawmode ~= "fill" and drawmode ~= "line" then
		error("Error: Unknown drawmode - " .. tostring(drawmode))
		return
	end
	local p = {}
	for i = 1, self.vertexesCounts do
		local vx, vy = self:getVertex(i)
		p[#p + 1] = vx
		p[#p + 1] = vy
	end
	love.graphics.polygon(drawmode, unpack(p))
end






local PnSegment = class("PnSegment", Collidable)

function PnSegment:init(x1, y1, x2, y2)
	local cx, cy = (x1 + x2) / 2, (y1 + y2) / 2
	self.super.init(self, Transform.new(cx, cy))
	self.fixedValues = {{x1 - cx, y1 - cy}, {x2 - cx, y2 - cy}}
	self.ptype = 3
end

function PnSegment:getPoint(id)
	local cx, cy = self.transform:getScreenPosition()
	local rx, ry = vec.rotate(
			cx + self.fixedValues[id][1] * scale,
			cy + self.fixedValues[id][2] * scale,
			self.transform:getRotationAngle(),
			cx, cy)
	return rx, ry
end

function PnSegment:axes()
	local x1, y1 = self:getPoint(1)
	local x2, y2 = self:getPoint(2)
	local x, y = vec.normal(x2 - x1, y2 - y1)
	return {{x, y}}
end

function PnSegment:project(axisX, axisY)
	local cx, cy = self.transform:getScreenPositon()
	local t1, t2 = self:getPoint(1)
	axisX, axisY = vec.normalize(axisX, axisY)
	local min = vec.mul(t1, t2, axisX, axisY)
	local max = min
	t1, t2 = self:getPoint(2)
	local proj = vec.mul(t1, t2, axisX, axisY)
	if proj < min then min = proj end
	if proj > max then max = proj end
	return {max = max, min = min}
end

function PnSegment:AABB()
	local x1, y1 = self:getPoint(1)
	local x2, y2 = x1, y1
	local o1, o2 = self:getPoint(2)
	if o1 < x1 then x1 = o1 end
	if o1 > x2 then x2 = o1 end
	if o2 < y1 then y1 = o2 end
	if o2 > y2 then y2 = o2 end 
	return x1, y1, x2, y2
end

function PnSegment:draw()
	local x1, y1 = self:getPoint(1)
	local x2, y2 = self:getPoint(2)
	love.graphics.line(x1, y1, x2, y2)
end






local PnPoint = class("pong_PnPoint", Collidable)
function PnPoint:init(x, y)
	self.super.init(self, Transform.new(x, y))
	self.ptype = 4
end

function PnPoint:axes()
	local x, y = self.transform:getScreenPosition()
	local ax, ay = vec.normal(x, y)
	return {{ax, ay}}
end

function PnPoint:project(axisX, axisY)
	axisX, axisY = vec.normalize(axisX, axisY)
	local x, y = self.transform:getScreenPosition()
	local tmp = ve.mul(x, y, axisX, axisY)
	return {max = tmp, min = tmp}
end

function PnPoint:AABB()
	local x, y = self.transform:getScreenPosition()
	return x, y, x, y
end

function PnPoint:draw()
	local x, y = self.transform:getScreenPosition()
	love.graphics.points(x, y)
end







local PnCompound = class("pong_PnCompound", Collidable)

function PnCompound:init(x, y)
	self.super.init(self, Transform.new(x, y))
	self.collidables = {}
end

function PnCompound:add(collidable)
	if not Types.isCollidable(collidable) or collidable.ptype == 5 then
		error("Fail to add collidable to compound: unaccepted object")
	end
	collidable:setOrigin(self:center())
	self.collidables[#self.collidables + 1] = collidable
end

function PnCompound:union(compound)
	if Types.typeinfo(compound) ~= "compound" then
		error("Fail to union two compounds: the other object is not a compound collidable")
	end
	for i = 1, #compound.collidables do
		local collidable = compound.collidables[i]
		collidable:setOrgin(self:center())
		self.collidables[#self.collidables + 1] = collidable
	end
end

function PnCompound:remove(collidable)
	for i = #self.collidables, 1, -1 do
		if collidable == self.collidables[i] then
			table.remove(self.collidables, i)
			return true
		end
	end
	return false
end

function PnCompound:AABB()
	local x1, y1, x2, y2 = self.collidables[1]:AABB()
	for i = 2, #self.collidables do
		local collidable = self.collidables[i]
		local a, b, c, d = collidable:AABB()
		if a < x1 then x1 = a end
		if b < y1 then y1 = b end
		if c < x2 then x2 = c end
		if d < y2 then y2 = d end
	end
	return x1, y1, x2, y2
end

-- collision prototype:
-- [1] circle
-- [2] convexpolygon
-- [3] segment
-- [4] point
-- [5] compound

local function createRectangle(x, y, w, h)
	w = w or 10
	h = h or 10
	return PnConvexPolygon.new(x, y, x + w, y, x + w, y + h, x, y + h)
end

local function createRegularPolygon(n, r, x, y)
	local delta = math.pi * 2 / n
	local points = {}
	r = r or 50
	x = x or r
	y = y or r
	for i = 0, n - 1 do
		local _x = x + r * math.cos(delta * i + math.pi * 1.5)
		local _y = y + r * math.sin(delta * i + math.pi * 1.5)
		points[#points + 1] = _x
		points[#points + 1] = _y
	end
	return PnConvexPolygon.new(unpack(points))
end

return {
	Prototypes = {
		Circle 			= 	PnCircle,
		ConvexPolygon 	= 	PnConvexPolygon,
		Segment 		= 	PnSegment,
		Point 			= 	PnPoint,
		Compound 		= 	PnCompound
	},
	Collidable = Collidable,
	Helper = {
		newRectangle 		= 	createRectangle,
		newRegularPolygon 	= 	createRegularPolygon
	}
}