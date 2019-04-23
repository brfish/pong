
--Helper function about vector
local function vecLength(vx, vy)
	return math.sqrt(vx^2+vy^2)
end

local function vecNormalize(vx, vy)
	local len = vecLength(vx, vy)
	return vx/len, vy/len
end

local function vecPerpendicular(vx, vy)
	return vy, -vx
end

local function vecNormal(vx, vy)
	return vecNormalize(vy, -vx)
end

local function vecRotate(vx, vy, phi, x, y)
	local cos, sin = math.cos(phi), math.sin(phi)
	vx, vy = (vx-x)*cos+(vy-y)*sin+x, (vy-y)*cos-(vx-x)*sin+y
	return vx, vy
end

local function vecMul(vx1, vy1, vx2, vy2)
	return vx1*vx2+vy1*vy2
end

local function vecCross(vx1, vy1, vx2, vy2)
	return vx1*vy2-vx2*vy1
end

local BaseShape = class("cherry_pong_BaseShape")
BaseShape.static.total = 0
function BaseShape:initialize()
	self.pointSet = {}
	BaseShape.static.total = BaseShape.static.total+1
	self.shapeID = BaseShape.static.total
end

--[[function BaseShape:getAxis()
	if #self.pointSet == 1 then
		return {self.pointSet[1]:normal()}
	end
	local ret = {}
	for i = 1, #self.pointSet do
		ret[#ret+1] = (self.pointSet[i]-self.pointSet[i-1]):normal()
	end
	return ret
end]]

function BaseShape:drawBound()
	local x, y, w, h = self:boundBox()
	w = w-x
	h = h-y
	love.graphics.rectangle("line", x, y, w, h)
end

function BaseShape:clone()
end

function BaseShape:typeOf()
	return self.class.name
end

function BaseShape:__eq(a)
	return self.shapeID == a.shapeID
end

function BaseShape:__tostring()
	return string.format(
		"%s - %d",
		self.class.name, self.shapeID)
end

local Circle = class("pong_circle", BaseShape)

function Circle:initialize(x, y, r)
	BaseShape.initialize(self)
	self.cx = x
	self.cy = y
	self.r = r
end

function Circle:draw(drawmode)
	if not drawmode then
		love.graphics.circle(m, self.cx, self.cy, self.r)
		return
	end
	if drawmode == "fill" then
		love.graphics.circle(m, self.cx, self.cy, self.r)
	elseif drawmode == "line" then
		love.graphics.circle(m, self.cx, self.cy, self.r)
	else
		error("Error: Unknown drawmode - " .. tostring(drawmode))
	end
end

function Circle:getAxis()
	local x, y = vecNormal(self.cx, self.cy)
	return {{x, y}}
end

function Circle:project(axisX, axisY)
	axisX, axisY = vecNormalize(axisX, axisY)
	local min = vecMul(self.cx, self.cy, axisX, axisY)
	local max = min
	return {max = max + self.r, min = min - self.r}
end

function Circle:boundBox()
	return  self.cx - self.r,
			self.cy - self.r,
			self.cx + self.r,
			self.cy + self.r
end

function Circle:move(disX, disY)
	self.cx = self.cx + disX
	self.cy = self.cy + disY
end

function Circle:moveTo(x, y)
	local disX, disY = x - self.cx, y - self.cy
	self:move(disX, disY)
end

function Circle:scale(s)
	self.r = self.r * s 
end

function Circle:center()
	return self.cx, self.cy
end

function Circle:clone()
	return Circle(self.cx, self.cy, self.r)
end


local Capsule = class("pong_capsule")
function Capsule:initialize(width, height, cx, cy, rotation)

	self.height = height
	self.width = width

	self.cx = cx
	self.cy = cy

	self.keypoints = {
		{self.cx - self.width / 2, self.cy}
		{self.cx + self.width / 2, self.cy}
	}
	
	self.rotation = rotation or 0
end

function Capsule:draw()
	love.graphics.circle("fill", self.keypoints[1][1], self.keypoints[1][2], self.height)
	love.graphics.circle("fill", self.keypoints[2][1], self.keypoints[2][2], self.height)
	love.graphics.rectangle("fill", self.keypoints[1][1], self.keypoints[1][2] - self.height,
									self.keypoints[2][1], self.keypoints[2][2] + self.height)
end

function Capsule:boundBox()
	return 	self.keypoints[1][1], self.keypoints[1][2] - self.height,
			self.keypoints[2][1], self.keypoints[2][2] + self.height
end

function Capsule:move(disX, disY)
	self.cx = self.cx + disX
	self.cy = self.cy + disY
end

function Capsule:moveTo(x, y)
end

local ConvexPolygon = class("cherry_pong_ConvexPolygon", BaseShape)
function ConvexPolygon:initialize(...)
	assert(#{...} >= 6 and #{...} % 2 == 0, 
		"The vertexes of polygon must more than 6")
	BaseShape.initialize(self)

	self.cx = 0
	self.cy = 0

	self.vertexesNum = #{...} / 2
	self.vertexesDelta = {}

	local centerX, centerY = 0, 0
	for i = 1, #{...}, 2 do
		centerX = centerX + select(i, ...)
		centerY = centerY + select(i + 1, ...)
	end

	self.cx, self.cy = centerX / self.vertexesNum, centerY / self.vertexesNum

	for i = 1, self.vertexesNum * 2, 2 do
		local x = select(i, ...)
		local y = select(i + 1, ...)
		self.vertexesDelta[(i + 1) / 2] = {x - self.cx, y - self.cy}
	end
	self.vertexesDelta[0] = self.vertexesDelta[self.vertexesNum]
end

function ConvexPolygon:resumeVertex(vertexID)
	return self.vertexesDelta[vertexID][1] + self.cx, 
			self.vertexesDelta[vertexID][2] + self.cy
end

function ConvexPolygon:getNumOfVertexes()
	return self.vertexesNum
end

function ConvexPolygon:getAxis()
	local ret = {}
	for i = 1, self.vertexesNum do
		local v1x, v1y = self:resumeVertex(i)
		local v2x, v2y = self:resumeVertex(i - 1)
		local x, y = vecNormal(v1x - v2x, v1y - v2y)
		ret[#ret + 1] = {x, y}
	end
	return ret
end

function ConvexPolygon:project(axisX, axisY)
	axisX, axisY = vecNormalize(axisX, axisY)
	local vx, vy = self:resumeVertex(1)
	local min = vecMul(vx, vy, axisX, axisY)
	local max = min
	for i = 1, self.vertexesNum do
		local vx, vy = self:resumeVertex(i)
		local proj = vecMul(vx, vy, axisX, axisY)
		if proj < min then min = proj end
		if proj > max then max = proj end
	end
	return {max = max, min = min}
end

function ConvexPolygon:move(disX, disY)
	self.cx = self.cx + disX
	self.cy = self.cy + disY
end

function ConvexPolygon:moveTo(x, y)
	local disX, disY = x - self.cx, y - self.cy
	self:move(disX, disY)
end

function ConvexPolygon:rotate(phi, x, y)
	x = x or self.cx
	y = y or self.cy
	if x ~= self.cx or y ~= self.cy then
		local rx, ry = vecRotate(self.cx, self.cy, phi, x, y)
		self.cx, self.cy = rx, ry
	end
	for i = 1, self.vertexesNum do
		local vx, vy = self:resumeVertex(i)
		local resultX, resultY = vecRotate(vx, vy, phi, x, y)
		self.vertexesDelta[i][1] = resultX - self.cx
		self.vertexesDelta[i][2] = resultY - self.cy
	end
end

function ConvexPolygon:draw(mode)
	if mode == "fill" or mode == "line" then
		local p = {}
		for i = 1, self.vertexesNum do
			local vx, vy = self:resumeVertex(i)
			p[#p + 1] = vx
			p[#p + 1] = vy
		end
		love.graphics.polygon(mode, unpack(p))
	else
		error("Can't accept the drawmode")
	end
end

function ConvexPolygon:clone()
	return ConvexPolygon(unpack(self.pointSet))
end

function ConvexPolygon:scale(sx, sy)
	sx = sx or 1
	sy = sy or sx
	for i = 1, #self.vertexes do
		local v = self.vertexes[i]
		local dx, dy = v[1]-self.cx, v[2]-self.cy
		dx = dx*sx+self.cx
		dy = dy*sy+self.cy
		v[1], v[2] = dx, dy
	end
end

function ConvexPolygon:boundBox()
	local srow, scol = self:resumeVertex(1)
	local erow, ecol = srow, scol
	for i = 2, self.vertexesNum do
		local vx, vy = self:resumeVertex(i)
		if srow > vx then srow = vx end
		if scol > vy then scol = vy end
		if erow < vx then erow = vx end
		if ecol < vy then ecol = vy end
	end
	return srow, scol, erow, ecol
end

function ConvexPolygon:center()
	return self.cx, self.cy
end

--[A] 2019.01.01 ConcavePolygon 未实现

local ConcavePolygonHelper = {}

function ConcavePolygonHelper.edges(vertexes)
	local ret = {}
	for i = 1, #self.vertexes do
		local v1 = self.vertexes[i-1]
		local v2 = self.vertexes[i]
		ret[#ret+1] = {v2[1]-v1[1], v2[2]-v1[2]}
	end
	return ret
end

function ConcavePolygonHelper.intersection(e1, e2)
	local rx, ry = 0, 0
	if vecCross(e1.x2-e1.x1, e1.y2-e1.y1, e2.x2-e2.x1, e2.y2-e2.y1) == 0 then
		return false
	end
	local t1 = vecCross(e2.x2-e2.x1, e2.y2-e2.y1, e1.x2-e1.x1, e1.y2-e1.y1)
	local t2 = vecCross(e1.x2-e1.x1, e1.y2-e2.y1, e2.x1-e1.x1, e2.y1-e1.y1)
	rx = e2.x1+(e2.x2-e2.x1)*t2/t1
	ry = e2.y1+(e2.y2-e2.y1)*t2/t1

	local function isBetween(n, a, b)
		return n >= math.min(a, b) and n <= math.max(a, b)
	end

	if isBetween(rx, e2.x1, e2.x2) and isBetween(ry. e2.y1, e2.y2) then
		return rx, ry
	end
	return false
end

function ConcavePolygonHelper.split()
end

local ConcavePolygon = class("cherry_pong_ConcavePolygon", BaseShape)
function ConcavePolygon:initialize(...)
	assert(#{...} >= 6 and #{...}%2 == 0, "Can't Accept")

	self.cx = 0
	self.cy = 0

	self.vertexes = {}

	local t = {}
	for _, v in ipairs({...}) do t[#t+1] = v end
	for i = 1, #t, 2 do
		self.vertexes[#self.vertexes+1] = {t[i], t[i+1]}
	end
	self.vertexes[0] = {t[#t-1], t[#t]}
	t = nil

	local centerX, centerY = 0, 0
	for i = 1, #self.vertexes do
		centerX = centerX+self.vertexes[i][1]
		centerY = centerY+self.vertexes[i][2]
	end

	self.edges = ConcavePolygonHelper.edges(self.vertexes)
end

function ConcavePolygon:split()
	
end
--------------------------------------



--[[local Polygon = class("Polygon", BaseShape)
function Polygon:initialize(...)
	assert(#{...} >= 6 and #{...}%2 == 0, "Can't Accept")
	BaseShape.initialize(self)
	self.cx = 0
	self.cy = 0

	local t = {}
	for _, v in ipairs({...}) do t[#t+1] = v end
	for i = 1, #t, 2 do
		self.pointSet[#self.pointSet+1] = Vector(t[i], t[i+1])
	end
	self.pointSet[0] = Vector(t[#t-1], t[#t])
	t = nil

	local center = Vector(0, 0)
	for i = 1, #self.pointSet do
		center = center+self.pointSet[i]
	end
	self.cx, self.cy = center.x/#self.pointSet, center.y/#self.pointSet
	center = nil
end

function Polygon:isConvex()
	local edges = {}
	for i = 1, #self.pointSet do
		edges[#edges+1] = self.pointSet[i]-self.pointSet[i-1]
	end
	for i = 1, #edges, 2 do
		if edges[i]^edges[i+1] < 0 then
			edges = nil
			return false
		end
	end
	return true
end]]

--local Polygon = class("cherry_pong_Polygon", ConvexPolygon)
--function Polygon:initialize(...)
--	ConvexPolygon.initialize(self, ...)
--end

local Point = class("cherry_pong_Point", BaseShape)
function Point:initialize(x, y)
	BaseShape.initialize(self)
	self.cx = x
	self.cy = y
end

function Point:move(disX, disY)
	self.cx = self.cx + disX
	self.cy = self.cy + disY
end

function Point:moveTo(x, y)
	local disX, disY = x - self.cx, y - self.cy
	self:move(disX, disY)
end

function Point:boundBox()
	return self.cx, self.cy, self.cx, self.cy
end

function Point:position()
	return self.cx, self.cy
end

function Point:project(axisX, axisY)
	axisX, axisY = vecNormalize(axisX, axisY)
	local tmp = vecMul(self.cx, self.cy, axisX, axisY)
	return {max = tmp, min = tmp}
end

function Point:draw()
	love.graphics.points(self.cx, self.cy)
end

local Line = class("cherry_pong_Line", BaseShape)
function Line:initialize(x1, y1, x2, y2)
	BaseShape.initialize(self)
	self.x1 = x1
	self.y1 = y1
	self.x2 = x2
	self.y2 = y2
	self.cx, self.cy = (x1 + x2)/2, (y1 + y2)/2
end

function Line:move(disX, disY)
	self.x1 = self.x1 + disX
	self.y1 = self.y1 + disY
	self.x2 = self.x2 + disX
	self.y2 = self.y2 + disY
	self.cx = self.cx + disX
	self.cy = self.cy + disY
end

function Line:moveTo(x, y)
	local disX = x - self.cx
	local disY = y - self.cy
	self:move(disX, disY)
end

function Line:rotate(phi, x, y)
	x = x or self.cx
	y = y or self.cy
	local rx1, ry1 = vecRotate(self.x1, self.y1, phi, x, y)
	local rx2, ry2 = vecRotate(self.x2, self.y2, phi, x, y)
	self.x1, self.y1 = rx1, ry1
	self.x2, self.y2 = rx2, ry2
	self.cx, self.cy = (self.x1 + self.x2) / 2, (self.y1 + self.y2) / 2
end

function Line:scale(s)
	s = s or 1
	local dx, dy = self.x1 - self.cx, self.y1 - self.cy
	dx = dx * s + self.cx
	dy = dy * s + self.cy
	self.x1, self.y1 = dx, dy
	dx, dy = self.x2 - self.cx, self.y2 - self.cy
	dx = dx * s + self.cx
	dy = dy * s + self.cy
	self.x2, self.y2 = dx, dy
end

function Line:boundBox()
	local x1, y1 = self.x1, self.y1
	local x2, y2 = x1, y1
	if self.x2 < x1 then x1 = self.x2 end
	if self.x2 > x2 then x2 = self.x2 end
	if self.y2 < y1 then y1 = self.y2 end
	if self.y2 > y2 then y2 = self.y2 end 
	return x1, y1, x2, y2
end

function Line:center()
	return self.cx, self.cy
end

function Line:getAxis()
	local x, y = vecNormal(self.x2-self.x1, self.y2 - self.y1)
	return {{x, y}}
end

function Line:draw()
	love.graphics.line(self.x1, self.y1, self.x2, self.y2)
end

function Line:project(axisX, axisY)
	axisX, axisY = vecNormalize(axisX, axisY)
	local min = vecMul(self.x1, self.y1, axisX, axisY)
	local max = min
	local proj = vecMul(self.x2, self.y2, axisX, axisY)
	if proj < min then min = proj end
	if proj > max then max = proj end
	return {max = max, min = min}
end

--[A] 2019.01.01 移除Rectangle class 修改为Rectangle function
--local Rectangle = class("cherry_pong_Rectangle", ConvexPolygon)
--function Rectangle:initialize(x, y, w, h)
--	ConvexPolygon.initialize(self, x, y, x+w, y, x+w, y+h, x, y+h)
--end

function Rectangle(x, y, w, h)
	w = w or 10
	h = h or 10
	return ConvexPolygon(x, y, x+w, y, x+w, y + h, x, y + h)
end

function RegularPolygon(n, r, x, y)
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
	return ConvexPolygon(unpack(points))
end

local ShapeGroup = class("cherry_pong_ShapeGroup")
function ShapeGroup:initialize(...)
	self.shapes = {}

	self.cx = 0
	self.cy = 0

	for _, v in ipairs({...}) do
		self:addShape(v)
		local _x, _y = v:center()
		self.cx = self.cx + _x
		self.cy = self.cy + _y
	end

	if select("#", ...) == 0 then
		return
	end
	self.cx = self.cx / select("#", ...)
	self.cy = self.cy / select("#", ...)
end

function ShapeGroup:addShape(shape)
	self.shapes[#self.shapes+1] = shape
	return true
end

function ShapeGroup:removeShape(shape)
	if type(shape) == "number" then
		if shape <= #self.shapes then
			table.remove(self.shapes, shape)
			return
		end
	end
	for i = #self.shapes, 1, -1 do
		if self.shapes[i] == shape then
			table.remove(self.shapes, i)
			break
		end
	end
end

function ShapeGroup:clear()
	self.shapes = {}
	return true
end

function ShapeGroup:union(group)
	local g = group:all()
	for _, v in ipairs(g) do
		self:addShape(v)
	end
end

function ShapeGroup:move(disX, disY)
	self.cx = self.cx + disX
	self.cy = self.cy + disY
	for i = 1, #self.shapes do
		self.shapes[i]:move(disX, disY)
	end
end

function ShapeGroup:moveTo(x, y)
	local disX = x-self.cx
	local disY = y-self.cy
	self:move(disX, disY)
end

function ShapeGroup:center()
	return self.cx, self.cy
end

function ShapeGroup:draw()
	for i = 1, #self.shapes do
		self.shapes[i]:draw()
	end
end

function ShapeGroup:all()
	return self.shapes
end

local Body = {
	Circle = Circle,
	ConvexPolygon = ConvexPolygon,
	ConcavePolygon = ConcavePolygon,
	Polygon = Polygon,
	Point = Point,
	Line = Line,
	RegularPolygon = RegularPolygon,
	Rectangle = Rectangle,
	Group = ShapeGroup
}

return Body