local geometry = require "geometry"

local edgeList = geometry.EdgeList.new()

function love.load()
	love.graphics.setPointSize(6)
	love.graphics.setPointStyle("smooth")
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineJoin("none")
end

local pressedButton
local targetIndex

function love.mousepressed(x, y, button)
	if pressedButton then return end
	pressedButton = button
	local mouse = geometry.Point(love.mouse.getPosition())

	targetIndex = mouse:closestPointIndexInSet(edgeList)
	if button == "l" then -- add a point, drag until release
		targetIndex = edgeList:addAfter(targetIndex, mouse)
	end
end

function love.mousereleased(x, y, button)
	if button ~= pressedButton then return end
	pressedButton = nil

	local mouse = geometry.Point(love.mouse.getPosition())
	local closestIndex = mouse:closestPointIndexInSet(edgeList)

	if button == "r" then
		if targetIndex == closestIndex then
			edgeList:remove(targetIndex)
		else
			edgeList:split(targetIndex, closestIndex)
		end
	end
end

function love.update()
	if pressedButton == "l" or pressedButton == "m" then
		edgeList[targetIndex].x, edgeList[targetIndex].y = love.mouse.getPosition()
	end
end

function geometry.Point:render()
	love.graphics.point(self.x, self.y)
end

function geometry.EdgeList:render()
	for i, p in pairs(self) do
		p:render()
		local q = self[p.next]
		love.graphics.line(p.x, p.y, q.x, q.y)
		
		local r = self[p.prev]
		local averageLineDirection = ((q - p):normalize() + (r - p):normalize()):normalize()
		local textSize = geometry.Point(
			love.graphics.getFont():getWidth(tostring(i)),
			love.graphics.getFont():getHeight()
		)
		local textPos = p - (textSize * 0.5) - averageLineDirection * textSize
		love.graphics.print(tostring(i), textPos.x, textPos.y)
	end
end

function love.draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.print("Left-click to create points, middle-click to move them.\n" ..
	"Right-click to remove points, right-click and drag to split.", 10, 10)
	
	edgeList:render()
	
	local mouse = geometry.Point(love.mouse.getPosition())
	local closestIndex = mouse:closestPointIndexInSet(edgeList)

	local closest = edgeList[closestIndex]
	local target = edgeList[targetIndex]
	
	if pressedButton == "r" and targetIndex ~= closestIndex then
		love.graphics.setColor(128, 0, 128)
		love.graphics.line(closest.x, closest.y, target.x, target.y)
	end

	if closest then
		love.graphics.setColor(0, 255, 0)
		local q = edgeList[closest.next]
		love.graphics.line(closest.x, closest.y, q.x, q.y)
		
		love.graphics.setColor(255, 0, 0)
		closest:render()
	end
end