local BASEDIR = (...):match("(.-)[^%.]+$")

local class = require(BASEDIR .. "class")
local Detection = require(BASEDIR .. "detection")
local Types = require(BASEDIR .. "type_info")

local SpatialHash = class("pong_spatialhash")

function SpatialHash:init(cell, x, y, w, h)
	self.__isSpatialHash = true
	self.cell = cell or 100
	self.x = x or 0
	self.y = y or 0
	self.width = w or love.graphics.getWidth()
	self.height = h or love.graphics.getHeight()
	self.row = math.ceil(self.height / self.cell)
	self.col = math.ceil(self.width / self.cell)
	self.grids = {}
	self.objectCount = {}
	self.defaultFilter = function(object) return true end
	self.objectPoint = 0

	for i = 0, self.row do
		self.grids[i] = {}
		self.objectCount[i] = {}
		for j = 0, self.col do
			self.grids[i][j] = {}
			self.objectCount[i][j] = 0
		end
	end
end

function SpatialHash:assignId()
	self.objectPoint = self.objectPoint + 1
	return self.objectPoint
end

function SpatialHash:getGridCoords(x, y)
	x = x - self.x
	y = y - self.y
	local col = math.ceil(x / self.cell)
	local row = math.ceil(y / self.cell)
	if row < 0 then row = 1 end
	if col < 0 then col = 1 end
	if row > self.row then row = self.row end
	if col > self.col then col = self.col end
	return row, col
end

function SpatialHash:getCoveredGrids(object)
	local csx, csy, cex, cey = object:AABB()
	local srow, scol = self:getGridCoords(csx, csy)
	local erow, ecol = self:getGridCoords(cex, cey)
	local grids = {}
	for i = srow, erow do
		for j = scol, ecol do
			grids[#grids + 1] = {row = i, col = j}
		end
	end
	return grids
end

function SpatialHash:update(object, old_x1, old_y1, old_x2, old_y2, new_x1, new_y1, new_x2, new_y2)
	old_x1, old_y1 = self:getGridCoords(old_x1, old_y1)
	old_x2, old_y2 = self:getGridCoords(old_x2, old_y2)
	new_x1, new_y1 = self:getGridCoords(new_x1, new_y1)
	new_x2, new_y2 = self:getGridCoords(new_x2, new_y2)
	if old_x1 == new_x1 and old_y1 == new_y1 and
		old_x2 == new_x2 and old_y2 == new_y2 then
		return
	end

	for i = old_x1, old_x2 do
		for j = old_y1, old_y2 do
			self.grids[i][j][object.id] = nil
			self.objectCount[i][j] = self.objectCount[i][j] - 1
		end
	end

	for i = new_x1, new_x2 do
		for j = new_y1, new_y2 do
			self.grids[i][j][object.id] = object
			self.objectCount[i][j] = self.objectCount[i][j] + 1
		end
	end
end

function SpatialHash:add(object)
	if not Types.isCollidable(object) then
		Types.error(object, "collidable")
	end
	object.id = self:assignId()
	local registerFunction = {"moveTo", "rotate", "scale", "rotateAroundPoint"}
	for _, functionName in ipairs(registerFunction) do
		if object[functionName] then
			local oldFunction = object[functionName]
			object[functionName] = function(this, ...)
				local x1, y1, x2, y2 = this:AABB()
				oldFunction(this, ...)
				self:update(this, x1, y1, x2, y2, this:AABB())
			end
		end
	end
	local x1, y1, x2, y2 = object:AABB()
	x1, y1 = self:getGridCoords(x1, y1)
	x2, y2 = self:getGridCoords(x2, y2)
	for i = x1, x2 do
		for j = y1, y2 do
			self.grids[i][j][object.id] = object
			self.objectCount[i][j] = self.objectCount[i][j] + 1
		end
	end
end

function SpatialHash:remove(object)
	if not Types.isCollidable(object) then
		Types.error(object, "collidable")
	end
	if object.id == -1 then
		return false
	end
	local gridsIndexes = self:getCoveredGrids(object)
	for i = 1, #gridsIndexes do
		local g = gridsIndexes[i]
		if self.grids[g.row][g.col][object.id] then
			self.grids[g.row][g.col][object.id] = nil
			self.objectCount[g.row][g.col] = self.objectCount[g.row][g.col] - 1
		end
	end
	object.id = -1
	return true
end

function SpatialHash:collisions(object, filter)
	if not Types.isCollidable(object) then
		Types.error(object, "collidable")
	end
	if filter and type(filter) ~= "function" then
		Types.error(filter, "function")
	end
	local gridsIndexes = self:getCoveredGrids(object)
	local collisions = {}
	local visited = {}
	filter = filter or self.defaultFilter
	for i = 1, #gridsIndexes do
		local g = gridsIndexes[i]
		for _, v in pairs(self.grids[g.row][g.col]) do
			if v ~= object and object.enabled and visited[v] ~= true then
				if filter(v) then
					local MSV = Detection.isCollided(object, v)
					if MSV then
						collisions[#collisions + 1] = {v, MSV}
						visited[v] = true
					end
				end
			end
		end
	end
	visited = nil
	return collisions
end

function SpatialHash:isCollided(object, filter)
	local gridsIndexes = self:getCoveredGrids(object)
	filter = filter or self.defaultFilter
	for i = 1, #gridsIndexes do
		local g = gridsIndexes[i]
		for _, v in pairs(self.grids[g.row][g.col]) do
			if v ~= object and filter(v) and Detection.isCollided(object, v) then
				return true
			end
		end
	end
	return false
end

function SpatialHash:setDefaultFilter(filter)
	if type(filter) ~= "function" then
		Types.error(filter, "function")
	end
	self.defaultFilter = filter
end

function SpatialHash:getDefaultFilter()
	return self.defaultFilter
end

function SpatialHash:clear(row, col)
	if row and col then
		self.grids[row][col] = {}
		self.objectCount[row][col] = 0
		return
	end
	for i = 0, self.row do
		for j = 0, self.col do
			self.grids[i][j] = {}
			self.objectCount[i][j] = 0
		end
	end
end

function SpatialHash:resize(newSize)
	if newSize == self.cell then return end
	local objects = {}
	for i = 0, self.row do
		for j = 0, self.col do
			for _, v in pairs(self.grids[i][j]) do
				objects[#objects + 1] = v
			end
		end
	end
	self.cell = newSize		
	self.row = math.ceil(self.height / self.cell)
	self.col = math.ceil(self.width / self.cell)
	self.grids = {}
	for i = 1, self.row do
		self.grids[i] = {}
		self.objectCount[i] = {}
		for j = 1, self.col do
			self.grids[i][j] = {}
			self.objectCount[i][j] = 0
		end
	end
	for i = 1, #objects do
		self:add(objects[i])
	end
	objects = nil
end

function SpatialHash:reset(newSize)
	if newSize then
		self:resize(newSize)
		return
	end
	self:clear()
end

function SpatialHash:isObjectIn(object, row, col)
	if object.id == -1 then return false end
	return not self.grids[row][col][object.id] == nil
end

function SpatialHash:objectIn(object)
	local grids = {}
	for i = 1, self.row do
		for j = 1, self.col do
			local g = self.grids[i][j]
			for _, v in pairs(g) do
				if v == object then
					grids[#grids + 1] = {row = i, col = j}
					break
				end
			end
		end
	end
	return grids
end

function SpatialHash:neighborhood(object)
	local gridsIndexes = self:getCoveredGrids(object)
	local ret = {}
	local flag = {}
	for i = 1, #gridsIndexes do
		local g = gridsIndexes[i]
		for _, v in pairs(self.grids[g.row][g.col]) do
			if v ~= object and flag[v] ~= true then
				ret[#ret + 1] = v
				flag[v] = true
			end
		end
	end
	flag = nil
	return ret
end

function SpatialHash:drawGrids()
	for i = 1, self.row do
		love.graphics.line(0, i*self.cell, love.graphics.getWidth(), i*self.cell)
	end
	for i = 1, self.col do
		love.graphics.line(i*self.cell, 0, i*self.cell, love.graphics.getHeight())
	end
	love.graphics.setColor(1, 0, 0)
	for i = 1, self.row do
		for j = 1, self.col do
			local x, y = (j-1)*self.cell+self.cell/2, (i-1)*self.cell+self.cell/2 
			love.graphics.print(self.objectCount[i][j], x, y)
		end
	end
	love.graphics.setColor(1, 1, 1)
end

return SpatialHash

---_ _
--|_|_|(row, col)
--|_|_|