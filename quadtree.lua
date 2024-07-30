-- Quadtree node class
local Quadtree = {}
Quadtree.__index = Quadtree


function Quadtree:new(x, y, width, height, capacity)
    local self = setmetatable({}, Quadtree)
    self.boundary = {x = x, y = y, width = width, height = height}
    self.capacity = capacity or 4
    self.points = {}
    self.divided = false
    return self
end

function Quadtree:subdivide()
    local x, y, w, h = self.boundary.x, self.boundary.y, self.boundary.width, self.boundary.height
    local hw, hh = w / 2, h / 2
    self.northeast = Quadtree:new(x + hw, y, hw, hh, self.capacity)
    self.northwest = Quadtree:new(x, y, hw, hh, self.capacity)
    self.southeast = Quadtree:new(x + hw, y + hh, hw, hh, self.capacity)
    self.southwest = Quadtree:new(x, y + hh, hw, hh, self.capacity)
    self.divided = true
end

function Quadtree:insert(point)
    if not self:contains(self.boundary, point) then
        return false
    end

    if #self.points < self.capacity then
        table.insert(self.points, point)
        return true
    else
        if not self.divided then
            self:subdivide()
        end

        if self.northeast:insert(point) then return true end
        if self.northwest:insert(point) then return true end
        if self.southeast:insert(point) then return true end
        if self.southwest:insert(point) then return true end
    end
end

function Quadtree:contains(boundary, point)
    return point.x >= boundary.x and
           point.x < boundary.x + boundary.width and
           point.y >= boundary.y and
           point.y < boundary.y + boundary.height
end

function Quadtree:intersects(range, boundary)
    return not (range.x > boundary.x + boundary.width or
                range.x + range.width < boundary.x or
                range.y > boundary.y + boundary.height or
                range.y + range.height < boundary.y)
end

function Quadtree:queryRange(range, found)
    if not self:intersects(range, self.boundary) then
        return found
    end

    for _, point in ipairs(self.points) do
        if point.x >= range.x and point.x <= range.x + range.width and
           point.y >= range.y and point.y <= range.y + range.height then
            table.insert(found, point)
        end
    end

    if self.divided then
        self.northeast:queryRange(range, found)
        self.northwest:queryRange(range, found)
        self.southeast:queryRange(range, found)
        self.southwest:queryRange(range, found)
    end

    return found
end

function Quadtree:remove(point)
    if not self:contains(self.boundary, point) then
        return false
    end

    for i, p in ipairs(self.points) do
        if p.x == point.x and p.y == point.y then
            table.remove(self.points, i)
            return true
        end
    end

    if self.divided then
        if self.northeast:remove(point) then return true end
        if self.northwest:remove(point) then return true end
        if self.southeast:remove(point) then return true end
        if self.southwest:remove(point) then return true end
    end

    return false
end


function Quadtree:draw()
    love.graphics.setColor ( 0.0, 0.0, 1.0, 0.25 )
    love.graphics.rectangle("line", self.boundary.x, self.boundary.y, self.boundary.width, self.boundary.height)
    if self.divided then
        self.northeast:draw()
        self.northwest:draw()
        self.southeast:draw()
        self.southwest:draw()
    end
end

------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------

return Quadtree