local function class()
	local t = {}
	t.__index = t
	setmetatable(t, { __call = function(self, ...) return self.new(...) end })
	return t
end

local Point = class()

function Point.new(x, y)
	return setmetatable({ x = x, y = y }, Point)
end

function Point.__lt(lhs, rhs)
	return lhs.x < rhs.x or (lhs.x == rhs.x and lhs.y < rhs.y)
end

function Point.__add(lhs, rhs)
	return Point(lhs.x + rhs.x, lhs.y + rhs.y)
end

function Point.__sub(lhs, rhs)
	return Point(lhs.x - rhs.x, lhs.y - rhs.y)
end

function Point.__mul(lhs, rhs)
	if type(rhs) == "table" and rhs.x and rhs.y then
		return Point(lhs.x * rhs.x, lhs.y * rhs.y)
	else
		return Point(lhs.x * rhs, lhs.y * rhs)
	end
end

function Point:length()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

function Point.distance(lhs, rhs)
	return (lhs - rhs):length()
end

function Point:normalize()
	return self * (1 / self:length())
end

function Point:__tostring()
	if self.prev and self.next then
		return self.prev .. " -> <" .. self.x .. ", " .. self.y .. "> -> " .. self.next
	end
	return "<" .. self.x .. ", " .. self.y .. ">"
end

function Point:closestPointIndexInSet(points)
	if #points == 0 then return 0 end
	local closestDist = math.huge
	local closestIndex = 1
	for i, point in pairs(points) do
		if self:distance(point) < closestDist then
			closestIndex = i
			closestDist = self:distance(point)
		end
	end
	return closestIndex
end

local EdgeList = class()

function EdgeList.new()
	return setmetatable({}, EdgeList)
end

-- Iterates fowards along the edge list, starting from index init.
-- The last point output is the one before init.
function EdgeList:iterFrom(init)
	return function(self, point)
		if not point then return self[init] end
		if point.next ~= init then return self[point.next] end
	end, self
end

function EdgeList:link(i, j)
	self[i].next = j
	self[j].prev = i
end

-- Adds the point p after the point index i.
-- Returns the index of the new point.
function EdgeList:addAfter(i, p)
	local j = table.getn(self) + 1

	self[j] = Point(p.x, p.y)

	if self[i] then
		local k = self[i].next
		self:link(i, j)
		self:link(j, k)
	else
		self:link(j, j)
	end

	return j
end

-- Removes the point index i from the list.
function EdgeList:remove(i)
	if not self[i] then return end
	self:link(self[i].prev, self[i].next)
	self[i] = nil
end

-- Splits the edge list into two polygons by adding a new edge from i to j.
-- Returns the index of a point in the first and second polygons.
function EdgeList:split(i, j)
	local b, c = self[i].next, self[j].prev
	local j2 = self:addAfter(c, self[j])
	local i2 = self:addAfter(j2, self[i])
	self:link(i2, b)
	self:link(i, j)
	return i, j2
end

-- Returns a list of indices, sorted by applying the comparator to the points.
function EdgeList:sortedIndices(comparator)
	indices = {}
	for i, _ in pairs(self) do
		indices[i] = i
	end
	return table.sort(indices, function(i, j)
		return comparator(self[i], self[j])
	end)
end

return { Point = Point, EdgeList = EdgeList }