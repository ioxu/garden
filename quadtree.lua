local tables = require("tables")
local signal = require "signal"
-- Quadtree node class
local Quadtree = {}
Quadtree.__index = Quadtree

-- TODO: 
-- [✓] fix re-insert after subdivide
-- [ ] fix unsubdivide
-- [✓] draw live inspection of tree based on mouse position

local font_medium = love.graphics.newFont(20)
local font_small = love.graphics.newFont(8.5)

function Quadtree:new(x, y, width, height, capacity, name)
    local self = setmetatable({}, Quadtree)
    self.boundary = {x = x, y = y, width = width, height = height}
    self.capacity = capacity or 4
    self.points = {}
    self.divided = false
    self.name = name or ""
    self.signals = signal:new()
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
    -- signals
    self.northeast.signals.listeners = self.signals.listeners
    self.northwest.signals.listeners = self.signals.listeners
    self.southeast.signals.listeners = self.signals.listeners
    self.southwest.signals.listeners = self.signals.listeners
    self.signals:emit("subdivided", self)
end


function Quadtree:insert(point)
    if not self:contains(self.boundary, point) then
        return false
    end

    if self.divided then
        -- insert point into leaves
        if self.northeast:insert(point) then return true end
        if self.northwest:insert(point) then return true end
        if self.southeast:insert(point) then return true end
        if self.southwest:insert(point) then return true end
    elseif #self.points < self.capacity then
        -- insert points to this leaf
        table.insert( self.points, point )
        return true
    else
        -- subdivide and re-insert points
        if not self.divided then
            self:subdivide()
        end
        local redist_points = {}
        redist_points = tables.shallow_copy( self.points )
        table.insert(redist_points, point)
        self.points = {}
        for _, current_point in ipairs(redist_points) do
            self:insert(current_point)
        end
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
        -- print(string.format("remove  (uns) %s: %s", self.name, ret_unsub))
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
            -- print(string.format("unsubdivide %s", self.name))
            -- print(string.format("unsubdivide %s", self.northeast.name))
            self.signals:emit("unsubdivided", self.northeast)
            self.northeast = nil
            -- print(string.format("unsubdivide %s", self.northwest.name))
            self.signals:emit("unsubdivided", self.northwest)
            self.northwest = nil
            -- print(string.format("unsubdivide %s", self.southeast.name))
            self.signals:emit("unsubdivided", self.southeast)
            self.southeast = nil
            -- print(string.format("unsubdivide %s", self.southwest.name))
            self.signals:emit("unsubdivided", self.southwest)
            self.southwest = nil
            self.divided = false
            return true
    else
        return false
    end
end


function Quadtree:draw()
    -- love.graphics.setLineWidth(1)
    -- love.graphics.setColor(0.243, 0.443, 0.671, 0.05)
    -- love.graphics.rectangle("line", self.boundary.x, self.boundary.y, self.boundary.width, self.boundary.height)
    -- if self.divided then
    --     self.northeast:draw()
    --     self.northwest:draw()
    --     self.southeast:draw()
    --     self.southwest:draw()
    -- end
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.243, 0.443, 0.671, 0.25)
    self:_draw()
end


function Quadtree:_draw()
    if self.divided then
        local x1 = self.boundary.x + self.boundary.width/2
        local y1 = self.boundary.y
        local x2 = x1
        local y2 = self.boundary.y + self.boundary.height
        love.graphics.line(x1, y1, x2, y2 )
        x1 = self.boundary.x
        y1 = self.boundary.y + self.boundary.height / 2
        x2 = self.boundary.x + self.boundary.width
        y2 = y1 
        love.graphics.line(x1, y1, x2, y2 )
        self.northeast:_draw()
        self.northwest:_draw()
        self.southeast:_draw()
        self.southwest:_draw()
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
    self:_draw_tree( window_width/2, 100, window_width/2.55, 60, depth, inspect_x, inspect_y)
end


function Quadtree:_draw_tree(x,y, spacing_x, spacing_y, depth, inspect_x, inspect_y )
    -- love.graphics.circle("line",x,y, 5)
    local hilight_color = {1.0, 0.8, 0.1, .85}
    local lolight_color = {0.35, 1.0, 0.1, 0.1}

    if self:contains(self.boundary, {x=inspect_x,y=inspect_y}) then
        love.graphics.setColor( hilight_color )
    else
        love.graphics.setColor( lolight_color )
    end
    love.graphics.line( x,y+1, x, y+10 )
    for i, point in ipairs(self.points) do
        love.graphics.points( x + i *5, y + i *2.5 )
    end
    
    if self.divided then
        local offset_x = spacing_x
        local offset_y = spacing_y
        local children_positions = {
            {x - offset_x/depth, y + spacing_y},
            {x - offset_x/depth/3, y + spacing_y},
            {x + offset_x/depth/3, y + spacing_y},
            {x + offset_x/depth, y + spacing_y}
        }
        local children = {self.northeast,
                        self.northwest,
                        self.southeast,
                        self.southwest}
        
        for i, child in ipairs(children_positions) do
            if self:contains(children[i].boundary, {x=inspect_x,y=inspect_y}) then
                love.graphics.setColor( hilight_color )
            else
                love.graphics.setColor( lolight_color )
            end

            local child_x, child_y = children_positions[i][1], children_positions[i][2]
            love.graphics.line( x,y +10 , child_x, child_y )
        end

        depth = depth +1
        self.northeast:_draw_tree( children_positions[1][1],children_positions[1][2], spacing_x/2.75, spacing_y, depth, inspect_x, inspect_y )
        self.northwest:_draw_tree( children_positions[2][1],children_positions[2][2], spacing_x/2.75, spacing_y, depth, inspect_x, inspect_y )
        self.southeast:_draw_tree( children_positions[3][1],children_positions[3][2], spacing_x/2.75, spacing_y, depth, inspect_x, inspect_y )
        self.southwest:_draw_tree( children_positions[4][1],children_positions[4][2], spacing_x/2.75, spacing_y, depth, inspect_x, inspect_y )

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


------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------

return Quadtree