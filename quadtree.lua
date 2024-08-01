-- Quadtree node class
local Quadtree = {}
Quadtree.__index = Quadtree


function Quadtree:new(x, y, width, height, capacity, name)
    local self = setmetatable({}, Quadtree)
    self.boundary = {x = x, y = y, width = width, height = height}
    self.capacity = capacity or 4
    self.points = {}
    self.divided = false
    self.name = name or ""
    return self
end


function Quadtree:subdivide()
    local x, y, w, h = self.boundary.x, self.boundary.y, self.boundary.width, self.boundary.height
    local hw, hh = w / 2, h / 2
    self.northeast = Quadtree:new(x + hw, y, hw, hh, self.capacity, self.name.."-NE")
    self.northwest = Quadtree:new(x, y, hw, hh, self.capacity, self.name.."-NW")
    self.southeast = Quadtree:new(x + hw, y + hh, hw, hh, self.capacity, self.name.."-SE")
    self.southwest = Quadtree:new(x, y + hh, hw, hh, self.capacity, self.name.."-SW")
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

function Quadtree:inspect( point )
    --[[return the structure of the quadtree at the position of point
    ]]--
    local n_points = 0

    return self:_inspect( point, n_points )
end


function Quadtree:_inspect(point, n_points)
    
    if not self:contains(self.boundary, point) then
        return 0
    end

    -- n_points = n_points + #self.points
    n_points = #self.points
    
    print(string.format("[inspect] %s %i (%i)", self.name, #self.points, n_points))
    if self.divided then
        n_points = n_points + self.northeast:_inspect( point, n_points )
        n_points = n_points + self.northwest:_inspect( point, n_points )
        n_points = n_points + self.southeast:_inspect( point, n_points )
        n_points = n_points + self.southwest:_inspect( point, n_points )
    end

    return n_points
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
        local removed = self.northeast:remove(point) or
                        self.northwest:remove(point) or
                        self.southeast:remove(point) or
                        self.southwest:remove(point)
        -- if removed then
        --     self:unsubdivide_if_empty()
        -- end
        self:unsubdivide_if_empty()
        return removed
    end
    return false
end


function Quadtree:unsubdivide_if_empty()
    if self.divided and
        #self.points == 0 and
        #self.northeast.points == 0 and
        #self.northwest.points == 0 and
        #self.southeast.points == 0 and
        #self.southwest.points == 0 and
        not self.northeast.divided and
        not self.northwest.divided and
        not self.southeast.divided and
        not self.southwest.divided then
            print(string.format("unsubdivide %s", self.name))
            print(string.format("unsubdivide %s", self.northeast.name))
            self.northeast = nil
            print(string.format("unsubdivide %s", self.northwest.name))
            self.northwest = nil
            print(string.format("unsubdivide %s", self.southeast.name))
            self.southeast = nil
            print(string.format("unsubdivide %s", self.southwest.name))
            self.southwest = nil
            self.divided = false
        end
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