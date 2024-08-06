-- Quadtree node class
local Quadtree = {}
Quadtree.__index = Quadtree

local font_medium = love.graphics.newFont(20)
local font_small = love.graphics.newFont(8.5)

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
        local ret_unsub = self:unsubdivide_if_empty()
        print(string.format("remove  (uns) %s: %s", self.name, ret_unsub))
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
            return true
    else
        return false
    end
end


function Quadtree:draw()
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.243, 0.443, 0.671, 0.25)
    love.graphics.rectangle("line", self.boundary.x, self.boundary.y, self.boundary.width, self.boundary.height)
    if self.divided then
        self.northeast:draw()
        self.northwest:draw()
        self.southeast:draw()
        self.southwest:draw()
    end
end

function Quadtree:draw_tree( inspect_x, inspect_y )
    love.graphics.setLineWidth(1)
    local depth = 1
    local width = 0
    local quadrant_offset = 0

    ----
    local window_width, window_height = love.graphics.getDimensions()
    ----

    -- self:_draw_tree( x, y, depth, width, quadrant_offset)
    self:_draw_tree( window_width/2, 100, window_width/2.55, 60, depth)
end

function Quadtree:_draw_tree(x,y, spacing_x, spacing_y, depth )
    -- love.graphics.circle("line",x,y, 5)
    
    love.graphics.setColor( 0.35, 1.0, 0.1, .3 )
    love.graphics.line( x,y+1, x, y+10 )
    for i, point in ipairs(self.points) do
        love.graphics.points( x + i *7.5, y )
    end

    -- depth = math.max(0, depth)

    if self.divided then
        local offset_x = spacing_x
        local offset_y = spacing_y
        local children_positions = {
            {x - offset_x/depth, y + spacing_y},
            {x - offset_x/depth/3, y + spacing_y},
            {x + offset_x/depth/3, y + spacing_y},
            {x + offset_x/depth, y + spacing_y}
        }
        
        for i, child in ipairs(children_positions) do
            local child_x, child_y = children_positions[i][1], children_positions[i][2]
            love.graphics.line( x,y +10 , child_x, child_y )
        end
        -- for i = 1,4 do
        --     local child_x, child_y = children_positions[i][1], children_positions[i][2]
        -- end
        depth = depth +1
        self.northeast:_draw_tree( children_positions[1][1],children_positions[1][2], spacing_x/2.75, spacing_y, depth )
        self.northwest:_draw_tree( children_positions[2][1],children_positions[2][2], spacing_x/2.75, spacing_y, depth )
        self.southeast:_draw_tree( children_positions[3][1],children_positions[3][2], spacing_x/2.75, spacing_y, depth )
        self.southwest:_draw_tree( children_positions[4][1],children_positions[4][2], spacing_x/2.75, spacing_y, depth )

    end
end
-- function Quadtree:_draw_tree( x, y, depth, width, quadrant_offset)
--     local p = {x=x, y=y}
--     local depth_m = 50

--     local x_1 = 50 + depth *depth_m
--     local y_1 = 150 + quadrant_offset + (width * 5)  -- 150 + (prev_width) * 75 + width * 5
--     local x_2 = 75 + depth *depth_m
--     local y_2 = y_1

--     if not self:contains( self.boundary, p ) then
--         love.graphics.setColor(0.3, 0.3, 0.3, 0.2)
--     else
--         love.graphics.setColor(0.9, 0.8, 0.2, 0.4)
--     end
    
--     quadrant_offset = quadrant_offset + (depth * width ) *50
--     love.graphics.line( x_1, y_1, x_2, y_2)
--     love.graphics.setFont(font_small)
--     love.graphics.print(string.format("d%d w%d q%d", depth, width, quadrant_offset), x_1, y_1-15)


--     if self.divided then
--         self.northeast:_draw_tree( x, y, depth +1, 0, quadrant_offset )
--         self.northwest:_draw_tree( x, y, depth +1, 1, quadrant_offset )
--         self.southeast:_draw_tree( x, y, depth +1, 2, quadrant_offset )
--         self.southwest:_draw_tree( x, y, depth +1, 3, quadrant_offset )
--     end
-- end



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


------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------

return Quadtree