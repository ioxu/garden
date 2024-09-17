local font_mono_small = love.graphics.newFont( "resources/fonts/SourceCodePro-Regular.ttf", 10 )

--- @class Log_UI
--- @field name string
--- @field log_text love.Text the drawable text love object
--- @field private _line_h number precomputed height of the log font
--- @field private _nlines number a running total of log lines
local Log_UI = {}

--- @param name string the log's label
--- @return Log_UI log The log.
function Log_UI:new(name)
    Log_UI.__index = Log_UI
    local self = setmetatable({}, Log_UI)
    self.name = name or "log"
    self.log_text = love.graphics.newText( font_mono_small ) -- love.graphics.getFont() )
    self._line_h = font_mono_small:getHeight()
    self._nlines = 0
    return self
end


function Log_UI:n_lines()
    return self._nlines
end


function Log_UI:log( text )
    self.log_text:add( string.format("%05s", self._nlines) .. " : " .. text, 0, self._line_h * self._nlines )
    self._nlines = self._nlines + 1
end


function Log_UI:draw()
    local diff = 0.0
    if self._nlines * self._line_h > love.graphics.getHeight() then
        diff = love.graphics.getHeight() - (self._nlines * self._line_h)
    end
    love.graphics.setColor(1,1,1,0.65)
    love.graphics.push()
    love.graphics.translate(0.0, diff) 
    love.graphics.draw( self.log_text )
    love.graphics.pop()
end


function Log_UI:clear()
    self.log_text:clear()
end


return Log_UI