local BASEDIR = (...):match("(.-)[^%.]+$")
local SAT = require(BASEDIR.."SAT")

local SpatialHash = class("pong_spatialhash")

function SpatialHash:initialize(w, h, cell)
	self.width = w or love.graphics.getWidth()
	self.height = h or love.graphics.getHeight()
	self.cell = cell or 100
	self.row = math.ceil(self.height / self.cell)
	self.col = math.ceil(self.width / self.cell)
	self.grids = {}
	self.objectCount = {}
	self.defaultFilter = function(object) return true end

	for i = 0, self.row do
		self.grids[i] = {}
		self.objectCount[i] = {}
		for j = 0, self.col do
			self.grids[i][j] = {}
			self.objectCount[i][j] = 0
		end
	end
end

function SpatialHash:register(object)
	local registerFunction = {"move", "rotate", "scale"}
	for _, functionName in ipairs(registerFunction) do
		if object[functionName] then
			local oldFunction = object[functionName]
			object[functionName] = function(this, ...)
				local x1, y1, x2, y2 = this:boundBox()
				oldFunction(this, ...)
				self:update(this, x1, y1, x2, y2, this:boundBox())
			end
		end
	end
	local x1, y1, x2, y2 = object:boundBox()
	x1, y1 = self:gridCoords(x1, y1)
	x2, y2 = self:gridCoords(x2, y2)
	for i = x1, x2 do
		for j = y1, y2 do
			self.grids[i][j][object] = object
			self.objectCount[i][j] = self.objectCount[i][j]+1
		end
	end
end

function SpatialHash:setDefaultFilter(filter)
	if type(filter) == "function" then
		self.defaultFilter = filter
	end
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
				objects[#objects+1] = v
			end
		end
	end
	self.cell = newSize		
	self.row = math.ceil(self.height/self.cell)
	self.col = math.ceil(self.width/self.cell)
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
		self:insert(objects[i])
	end
	objects = {}
end

function SpatialHash:reset(newSize)
	if newSize then
		self:resize(newSize)
		return
	end
	self:clear()
end

function SpatialHash:gridCoords(x, y)
	local col = math.ceil(x / self.cell)
	local row = math.ceil(y / self.cell)
	if row < 0 then row = 1 end
	if col < 0 then col = 1 end
	if row > self.row then row = self.row end
	if col > self.col then col = self.col end
	return row, col
end

function SpatialHash:isObjectIn(object, row, col)
	return not self.grids[row][col][object] == nil
end

function SpatialHash:objectIn(object)
	local ret = {}
	for i = 1, self.row do
		for j = 1, self.col do
			local g = self.grids[i][j]
			for k, v in pairs(g) do
				if v == object then
					ret[#ret+1] = {row = i, col = j}
					break
				end
			end
		end
	end
	return ret
end

function SpatialHash:getCoverGrids(object)
	local csx, csy, cex, cey = object:boundBox()
	local srow, scol = self:gridCoords(csx, csy)
	local erow, ecol = self:gridCoords(cex, cey)
	local ret = {}
	for i = srow, erow do
		for j = scol, ecol do
			ret[#ret+1] = {row = i, col = j}
		end
	end
	return ret
end

--[[function SpatialHash:insert(object)
	local csrow, cscol, cerow, cecol = object:boundBox()
	local srow, scol = self:gridCoords(csrow, cscol)
	local erow, ecol = self:gridCoords(cerow, cecol)
	if object.hasCache then
		if  srow == object.cache_srow and
			scol == object.cache_scol and
			erow == object.cache_erow and
			ecol == object.cache_ecol then
			return
		end
		object.cache_srow = srow
		object.cache_scol = scol
		object.cache_erow = erow
		object.cache_ecol = ecol
		for i = srow, erow do
			for j = scol, ecol do
				self.grids[i][j][object] = object
				self.objectCount[i][j] = self.objectCount[i][j]+1
			end
		end
	else
		object.cache_srow = srow
		object.cache_scol = scol
		object.cache_erow = erow
		object.cache_ecol = ecol
		object.hasCache = true
		for i = srow, erow do
			for j = scol, ecol do
				self.grids[i][j][object] = object
				self.objectCount[i][j] = self.objectCount[i][j]+1
			end
		end
	end
end

function SpatialHash:remove(object)
	local csrow, cscol, cerow, cecol = object:boundBox()
	local srow, scol = self:gridCoords(csrow, cscol)
	local erow, ecol = self:gridCoords(cerow, cecol)

	if object.hasCache then
		if  srow == object.cache_srow and
			scol == object.cache_scol and
			erow == object.cache_erow and
			ecol == object.cache_ecol then
			return
		end
		object.cache_srow = srow
		object.cache_scol = scol
		object.cache_erow = erow
		object.cache_ecol = ecol
		for i = srow, erow do
			for j = scol, ecol do
				self.grids[i][j][object] = nil
				self.objectCount[i][j] = self.objectCount[i][j]-1
			end
		end
	else
		object.cache_srow = srow
		object.cache_scol = scol
		object.cache_erow = erow
		object.cache_ecol = ecol
		object.hasCache = true
		for i = srow, erow do
			for j = scol, ecol do
				self.grids[i][j][object] = nil
				self.objectCount[i][j] = self.objectCount[i][j]-1
			end
		end
	end
end]]

function SpatialHash:update(object, old_x1, old_y1, old_x2, old_y2, new_x1, new_y1, new_x2, new_y2)
	old_x1, old_y1 = self:gridCoords(old_x1, old_y1)
	old_x2, old_y2 = self:gridCoords(old_x2, old_y2)
	new_x1, new_y1 = self:gridCoords(new_x1, new_y1)
	new_x2, new_y2 = self:gridCoords(new_x2, new_y2)
	if old_x1 == new_x1 and old_y1 == new_y1 and
		old_x2 == new_x2 and old_y2 == new_y2 then
		return
	end

	for i = old_x1, old_x2 do
		for j = old_y1, old_y2 do
			self.grids[i][j][object] = nil
			self.objectCount[i][j] = self.objectCount[i][j]-1
		end
	end

	for i = new_x1, new_x2 do
		for j = new_y1, new_y2 do
			self.grids[i][j][object] = object
			self.objectCount[i][j] = self.objectCount[i][j]+1
		end
	end
end

----------------------------------
--local helper function for rough collision detection
----------------------------------
local function AABBDetection(body1, body2)
	local ax1, ay1, ax2, ay2 = body1:boundBox()
	local bx1, by1, bx2, by2 = body2:boundBox()
	if ax1 > bx2 or ax2 < bx1 or ay1 > by2 or ay2 < by1 then
		return false
	end
	return true
end

function SpatialHash:retrieveCollision(object, filter)
	local gridsIndex = self:getCoverGrids(object)
	local ret = {}
	local flag = {}
	for i = 1, #gridsIndex do
		local g = gridsIndex[i]
		for k, v in pairs(self.grids[g.row][g.col]) do
			if k ~= object and v ~= nil and flag[v] ~= true then
				if filter then
					if filter(v) then
						if AABBDetection(object, v) then
							if SAT.isCollided(object, v) then
								ret[#ret + 1] = v
								flag[v] = true
							end
						end
					end
				else
					if self.defaultFilter(v) then
						if AABBDetection(object, v) and SAT.isCollided(object, v) then
							ret[#ret + 1] = v
							flag[v] = true
						end
					end
				end
			end
		end
	end
	flag = nil
	return ret
end

function SpatialHash:neighborhood(object)
	local gridsIndex = self:getCoverGrids(object)
	local ret = {}
	local flag = {}
	for i = 1, #gridsIndex do
		local g = gridsIndex[i]
		for k, v in pairs(self.grids[g.row][g.col]) do
			if k ~= object and v ~= nil and flag[v] ~= true then
				ret[#ret + 1] = v
				flag[v] = true
			end
		end
	end
	flag = nil
	return ret
end

function SpatialHash:isObjectCollided(object)
	local gridsIndex = self:getCoverGrids(object)
	for i = 1, #gridsIndex do
		local g = gridsIndex[i]
		for k, v in pairs(self.grids[g.row][g.col]) do
			if k ~= object and AABBDetection(object, v) and SAT.isCollided(object, v) then
				return true
			end
		end
	end
	return false
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