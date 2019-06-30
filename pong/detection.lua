
local PnDetection = {}

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
	return dis <= (a.radius + b.radius) ^ 2
end

local function pnPointPointCollisionTest(a, b)
	local ax, ay = a.transform:getPosition()
	local bx, by = b.transform:getPosition()
	return ax == bx and ay == by
end

local function pnConvexhullConvexhullCollisionTest(a, b)
	local axes = a:axes()
	local tmp = b:axes()
	for i = 1, #tmp do
		axes[#axes + 1] = tmp[i]
	end
	tmp = nil
	for _, axis in ipairs(axes) do
		p1 = a:project(axis[1], axis[2])
		p2 = b:project(axis[1], axis[2])
		if not (p1.max > p2.min and p1.min < p2.max) then
			return false
		end
	end
	return true
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
		return false
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