
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

--[[function SAT.groupsCollisionTest(a, b)
	local ag, bg = a:all(), b:all()
	for i = 1, #ag do
		for j = 1, #bg do
			ao = ag[i]
			bo = bg[i]
			if ao:typeOf() == Circle and bo:typeOf() == Circle then
				if SAT.circlesCollisionTest(ao, bo) then
					ag = nil
					bg = nil
					return true
				end
			else
				if SAT.normalCollisionTest(ao, bo) then
					ag = nil
					bg = nil
					return true
				end
			end
		end
	end
	return false
end

function SAT.groupWithOtherCollisionTest(a, b)
	local group = nil
	local other = nil
	if a:typeOf() == ShapeGroup then
		group = a
		other = b
	else
		group = b
		other = a
	end
	group = group:all()
	for i = 1, #group do
		o = group[i]
		if o:typeOf() == Circle and other:typeOf() == Circle then
			if SAT.circlesCollisionTest(o, other) then
				return true
			end
		else
			if SAT.normalCollisionTest(o, other) then
				return true
			end
		end
	end
	return false
end]]