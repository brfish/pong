
local SAT = {}

function SAT.normalCollisionTest(a, b)
	local axis = a:getAxis()
	local tmp = b:getAxis()
	for i = 1, #tmp do
		axis[#axis + 1] = tmp[i]
	end
	tmp = nil
	for _, v in ipairs(axis) do
		p1 = a:project(v[1], v[2])
		p2 = b:project(v[1], v[2])
		if not (p1.max > p2.min and p1.min < p2.max) then
			return false
		end
	end
	return true
end

function SAT.circlesCollisionTest(a, b)
	local dis = (a.cx - b.cx) ^ 2 + (a.cy - b.cy) ^ 2
	return dis <= (a.r + b.r) ^ 2
end

local Circle, ShapeGroup = "cherry_pong_Circle", "cherry_pong_ShapeGroup"

function SAT.groupsCollisionTest(a, b)
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
end

function SAT.isCollided(a, b)
	local at = a:typeOf()
	local bt = b:typeOf()
	if at == Circle and bt == Circle then
		return SAT.circlesCollisionTest(a, b)
	elseif at == ShapeGroup and bt == ShapeGroup then
		return SAT.groupsCollisionTest(a, b)
	elseif (at == ShapeGroup and bt ~= ShapeGroup) or (bt == ShapeGroup and at ~= ShapeGroup) then
		return SAT.groupWithOtherCollisionTest(a, b)
	else
		return SAT.normalCollisionTest(a, b)
	end
end

return SAT