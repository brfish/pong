local BASEDIR = (...):match("(.-)[^%.]+$")

local vec = require(BASEDIR .. "vector")

local PnDetection = {}

local function getOverlap(p1, p2)
	-- 保证p1.length一定小于p2.length --
	if p1.max - p1.min > p2.max - p2.min then
		p1, p2 = p2, p1
	end
	if p1.max < p2.min or p2.max < p1.min then
		return 0
	end
	if p1.min > p2.min and p1.max < p2.max then
		return p1.max - p1.min
	end
	if p1.min < p2.min and p1.max < p2.max then
		return p1.max - p2.min
	end
	if p1.min > p2.min and p1.max > p2.max then
		return p2.max - p1.min
	end
end

local function pnAABBAABBDetection(a, b)
	local ax1, ay1, ax2, ay2 = a:AABB()
	local bx1, by1, bx2, by2 = b:AABB()
	if ax1 > bx2 or ax2 < bx1 or ay1 > by2 or ay2 < by1 then
		return false
	end
	return true
end

local function pnCircleCircleCollisionTest(a, b)
	local ax, ay = a.transform:getPosition()
	local bx, by = b.transform:getPosition()
	local dis = (ax - bx) ^ 2 + (ay - by) ^ 2
	if dis > (a.radius + b.radius) ^ 2 then
		return nil
	end
	local minaxis = {0, 0}
	local d = a.radius + b.radius - vec.length(ax - bx, ay - by)
	minaxis[1], minaxis[2] = vec.normalize(ax - bx, ay - by)
	minaxis[1], minaxis[2] = minaxis[1] * d, minaxis[2] * d
	return minaxis
end

local function pnPointPointCollisionTest(a, b)
	local ax, ay = a.transform:getPosition()
	local bx, by = b.transform:getPosition()
	return ax == bx and ay == by
end

local function pnConvexhullConvexhullCollisionTest(a, b)
	local axes1 = a:axes()
	local axes2 = b:axes()
	local minoverlap = math.huge
	local minaxis = {0, 0}

	local acx, acy = a.transform:getScreenPosition()
	local bcx, bcy = b.transform:getScreenPosition()

	for _, axis in ipairs(axes1) do
		local p1 = a:project(axis[1], axis[2])
		local p2 = b:project(axis[1], axis[2])
		local overlap = getOverlap(p1, p2)
		if overlap == 0 then
			return nil
		end
		if overlap < minoverlap then
			minoverlap = overlap
			minaxis[1], minaxis[2] = axis[1], axis[2]
		end
	end
	for _, axis in ipairs(axes2) do
		local p1 = a:project(axis[1], axis[2])
		local p2 = b:project(axis[1], axis[2])
		local overlap = getOverlap(p1, p2)
		if overlap == 0 then
			return nil
		end
		if overlap < minoverlap then
			minoverlap = overlap
			minaxis[1], minaxis[2] = axis[1], axis[2]
		end
	end
	minaxis[1] = math.abs(minaxis[1])
	minaxis[2] = math.abs(minaxis[2])
	minaxis[1], minaxis[2] = minaxis[1] * minoverlap, minaxis[2] * minoverlap
	
	if acx < bcx then minaxis[1] = -minaxis[1] end
	if acy < bcy then minaxis[2] = -minaxis[2] end

	return minaxis
end

--------------------------------------------------------
--				  效率低下还没改                       --
local function pnConvexhullCompoundCollisionTest(a, b)
	for i = 1, #b.collidables do
		if not PnDetection.isCollided(a, b) then
			return false
		end
	end
	return true;
end

local function pnCompoundCompoundCollisionTest(a, b)
	for i = 1, #a.collidables do
		local c = a.collidables[i]
		for j = 1, #b.collidables do
			local d = b.collidables[j]
			if not PnDetection.isCollided(c, d) then
				return false
			end
		end
	end
	return true
end
--------------------------------------------------------

---  	 		1[Circle]	 	2[Polygon]	 	3[Segment]		 4[Point]		5[Compound]
---1[Circle] 		0				0				0				0				0
---2[Polygon]	 					0	
---3[Segment]		 
---4[Point]		
---5[Compound]

local matchTable = {}
for i = 1, 5 do
	matchTable[i] = {}
end

for i = 1, 4 do
	for j = 1, i do
		matchTable[i][j] = pnConvexhullConvexhullCollisionTest
	end
end

for i = 1, 4 do
	matchTable[i][5] = pnConvexhullCompoundCollisionTest
end

matchTable[1][1] = pnCircleCircleCollisionTest
matchTable[4][4] = pnPointPointCollisionTest
matchTable[5][5] = pnCompoundCompoundCollisionTest

function PnDetection.isCollided(a, b)
	if not pnAABBAABBDetection(a, b) then
		return nil
	end

	local type1 = a.ptype
	local type2 = b.ptype
	if type1 < type2 then
		return matchTable[type2][type1](a, b)
	end
	if type1 >= type2 then
		return matchTable[type1][type2](a, b)
	end
end

return PnDetection