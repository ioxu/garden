local vector=require"lib.vector"
Handles = {}

-- https://stackoverflow.com/questions/65961478/how-to-mimic-simple-inheritance-with-base-and-child-class-constructors-in-lua-t


Handles.Handle = {}
function Handles.Handle:new(name)
    Handles.Handle.__index = Handles.Handle
    local self = setmetatable({}, Handles.Handle)
    self.name = name or "handle"
    self.highlighted = false
    self.selected = false
    self.dragging = false
    return self
end


function Handles.Handle:mousemoved(x,y,dx,dy,...)
    -- print("Handles.Handle:mousemoved", x, y)
    if self.selected and self.dragging then
        -- drag
        self.x = self.x + dx
        self.y = self.y + dy
    else
        if vector.distance( self.x, self.y, x, y ) < self.radius then
            self.highlighted = true
        else
            self.highlighted = false
        end
    end
end


function Handles.Handle:mousepressed( x, y, button, istouch, presses )
    if self.highlighted then
        self.selected = true
        self.dragging = true
    else
        self.selected = false
    end
end


function Handles.Handle:mousereleased( x, y, button, istouch, presses )
    self.selected = false
    self.dragging = false
end


Handles.CircleHandle = {}
function Handles.CircleHandle:new(name, x, y, radius)
    Handles.CircleHandle.__index =  Handles.CircleHandle
    setmetatable( Handles.CircleHandle, {__index = Handles.Handle} )
    local self = Handles.Handle:new(name, radius)
    setmetatable(self, Handles.CircleHandle)
    self.x = x
    self.y = y
    self.radius = radius or 5
    return self
end


function Handles.CircleHandle:draw()
    love.graphics.setLineWidth(1)
    if self.highlighted then
        love.graphics.setColor(0.9, 0.75, 0.2, 0.85)
        if self.selected then
            love.graphics.setColor(0.9, 0.9, 0.9, 0.95)
        else
            love.graphics.setColor(0.9, 0.75, 0.2, 0.85)
        end
    else
        love.graphics.setColor(0.9, 0.75, 0.2, 0.35)
    end
    love.graphics.circle( "line", self.x, self.y, self.radius )
end


return Handles