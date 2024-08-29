local vector=require"lib.vector"
local signal=require"lib.signal"
local geometry=require"lib.geometry"
Handles = {}

-- https://stackoverflow.com/questions/65961478/how-to-mimic-simple-inheritance-with-base-and-child-class-constructors-in-lua-t


local font_small = love.graphics.newFont(10)


Handles.Handle = {}
function Handles.Handle:new(name)
    Handles.Handle.__index = Handles.Handle
    local self = setmetatable({}, Handles.Handle)
    self.name = name or "handle"
    self.highlighted = false
    self.selected = false
    self.dragging = false
    
    self.label = nil
    self.label_offset = {x=0.0, y=0.0}

    self.signals = signal:new()
    return self
end

--- Abstract method to check if a point (usually the mouse cursor) is "inside" the control.  
--- *Must be overridden in subclasses.*
--- @abstract
--- @param x number x-coordinate to check
--- @param y number y-coordinate to check
--- @return true|false inside
function Handles.Handle:point_inside( x, y )
    error("Handles.Handle:is_inside() absract; not implemented")
end


function Handles.Handle:mousemoved(x,y,dx,dy,...)
    -- print("Handles.Handle:mousemoved", x, y)
    if self.selected and self.dragging then
        -- drag
        self.signals:emit("dragged", self, dx, dy)
        self.x = self.x + dx
        self.y = self.y + dy
    else
        -- if vector.distance( self.x, self.y, x, y ) < self.radius then
        if self:point_inside(x,y) then
            if not self.highlighted then
                self.signals:emit("highlighted", self)
                self.highlighted = true
            end
        else
            if self.highlighted then
                self.signals:emit("unhighlighted", self)
            end
            self.highlighted = false
        end
    end
end


function Handles.Handle:mousepressed( x, y, button, istouch, presses )
    if self.highlighted then
        self.signals:emit("pressed", self)
        self.selected = true
        self.dragging = true
    else
        self.selected = false
    end
end


function Handles.Handle:mousereleased( x, y, button, istouch, presses )
    if self.selected then
        self.signals:emit("released", self)
    end
    self.selected = false
    self.dragging = false
end


------------------------------------------------------------------------------------------
Handles.CircleHandle = {}
function Handles.CircleHandle:new(name, x, y, radius)
    Handles.CircleHandle.__index =  Handles.CircleHandle
    setmetatable( Handles.CircleHandle, {__index = Handles.Handle} )
    local self = Handles.Handle:new(name)--, radius)
    setmetatable(self, Handles.CircleHandle)
    self.x = x or 0.0
    self.y = y or 0.0
    self.radius = radius or 5
    return self
end


function Handles.CircleHandle:point_inside( x, y )
    return (vector.distance( self.x, self.y, x, y ) < self.radius)
end


function Handles.CircleHandle:draw()
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(1)
    
    if self.highlighted then
        -- love.graphics.setColor(0.9, 0.75, 0.2, 0.85)
        love.graphics.setLineWidth(3.5)
        if self.selected then
            -- love.graphics.setColor(0.9, 0.9, 0.9, 0.95)
            love.graphics.setLineWidth(6)
        else
            -- love.graphics.setColor(0.9, 0.75, 0.2, 0.85)
        end
    else
        -- love.graphics.setColor(0.9, 0.75, 0.2, 0.35)
    end
    love.graphics.circle( "line", self.x, self.y, self.radius, 16 )
    if self.label then
        love.graphics.setFont(font_small)
        love.graphics.setColor(1,1,1,0.5)
        local fw = font_small:getWidth(tostring(self.label))
        local fh = font_small:getHeight()
        love.graphics.print(self.label, self.x - (fw/2) + self.label_offset.x, self.y + fh - 2 + self.label_offset.y )
    end
end

------------------------------------------------------------------------------------------
-- controls

Handles.SliderHandle = {}
--- Makes a slider handle that is constrained to a line between two points.
--- @param factor number the normalised position of the slider on the line (0.0 .. 1.0)
function Handles.SliderHandle:new( name, x1, y1, x2, y2, radius, factor )
    Handles.SliderHandle.__index = Handles.SliderHandle
    setmetatable( Handles.SliderHandle, {__index = Handles.CircleHandle} )
    local self = Handles.CircleHandle:new(name)
    setmetatable( self, Handles.SliderHandle )
    self.x1 = x1 or 0.0
    self.y1 = y1 or 0.0
    self.x2 = x2 or 1.0
    self.y2 = y2 or 1.0
    self.radius = radius or 5.0
    self.factor = factor or 0.0
    
    -- config options
    self.realtime_factor_signal = true -- if false, will only emit "factor_changed" when mouse is released
    self._defer_emit_factor_signal = false -- buffer

    return self
end


function Handles.SliderHandle:update_line()
    if not self.dragging then
        self.x = self.x1 + (self.x2 - self.x1) * self.factor
        self.y = self.y1 + (self.y2 - self.y1) * self.factor
    end
end


function Handles.SliderHandle:mousemoved( x, y, dx, dy,...)
    Handles.CircleHandle.mousemoved(self, x, y, dx, dy)
    if self.dragging then
        local px, py, factor = geometry.closest_point_on_line( self.x1, self.y1, self.x2, self.y2, self.x, self.y )
        self.factor = factor
        self.x, self.y = px, py
        if self.realtime_factor_signal then
            self.signals:emit("factor_changed", self.factor, self)
        else
            self._defer_emit_factor_signal = true
        end
    end
end


function Handles.SliderHandle:mousereleased( x, y, button, istouch, presses )
    Handles.CircleHandle.mousereleased( self, x, y, button, istouch, presses )
    if self._defer_emit_factor_signal then
        self.signals:emit("factor_changed", self.factor, self)
    end
end


function Handles.SliderHandle:draw()
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(2)
    local localx, localy = self.x2 - self.x1, self.y2 - self.y1
    local extrapx, extrapy = vector.normalise(localx, localy)
    local orthx, orthy = extrapy * 3, extrapx * 3
    
    if self.x2 < self.x1 then extrapx = extrapx * - 1 end
    if self.y2 > self.y1 then extrapy = extrapy * - 1 end
    
    local sx = self.x1 - extrapx * self.radius
    local sy = self.y1 - extrapy * self.radius
    local ex = self.x2 + extrapx * self.radius
    local ey = self.y2 + extrapy * self.radius
    
    -- love.graphics.line( sx, sy, ex, ey )
    -- first part of the slider line
    love.graphics.line( sx, sy,
        (self.x1 + localx * self.factor) - extrapx * self.radius,
        (self.y1 + localy * self.factor) - extrapy * self.radius
    )
    love.graphics.line( sx - 1 - orthx, sy + 1 - orthx, sx -1 + orthx, sy +1  + orthx  )

    -- second part of the slider line
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1,1,1,0.15)
    love.graphics.line( ex, ey,
        (self.x1 + localx * self.factor) + extrapx * self.radius,
        (self.y1 + localy * self.factor) + extrapy * self.radius
    )
    

    love.graphics.line( ex + 1 - orthx, ey - 1 - orthx, ex +1 + orthx, ey -1  + orthx  )

    Handles.CircleHandle.draw( self )
end



return Handles