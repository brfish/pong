
local PnDetection = {}

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

---  	 		1[Circle]	 	2[Polygon]	 	3[Segment]		 4[Point]		5[Group]
---1[Circle] 		0				0				0				0				0
---2[Polygon]	 					0	
---3[Segment]		 
---4[Point]		
---5[Group]

local matchTable = {}
for i = 1, 5 do
	matchTable[i] = {nil, nil, nil, nil, nil}
end

for i = 1, 4 do
	for j = 1, i do
		matchTable[i][j] = pnConvexhullConvexhullCollisionTest
	end
end
matchTable[1][1] = pnCircleCircleCollisionTest
matchTable[4][4] = pnPointPointCollisionTest


function PnDetection.isCollided(a, b)
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