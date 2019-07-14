local vec = {}

function vec.length(vx, vy)
	return math.sqrt(vx ^ 2 + vy ^ 2)
end

function vec.normalize(vx, vy)
	local len = vec.length(vx, vy)
	return vx / len, vy / len
end

function vec.perpendicular(vx, vy)
	return vy, -vx
end

function vec.normal(vx, vy)
	return vec.normalize(vy, -vx)
end

function vec.rotate(vx, vy, phi, x, y)
	local cos, sin = math.cos(phi), math.sin(phi)
	vx, vy = (vx - x) * cos + (vy - y) * sin + x, (vy - y) * cos - (vx - x) * sin + y
	return vx, vy
end

function vec.mul(vx1, vy1, vx2, vy2)
	return vx1 * vx2 + vy1 * vy2
end

function vec.cross(vx1, vy1, vx2, vy2)
	return vx1 * vy2 - vx2 * vy1
end

return vec