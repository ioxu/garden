SpritesheetViewer = {}
SpritesheetViewer.scene_name = "Spretesheet viewer"
SpritesheetViewer.description = "Test for viewing a spritesheet, and experimenting with SpriteBatches."

local shaping = require "lib.shaping"
local Camera = require "lib.camera"
local camera = Camera( 0.0, 0.0 )
------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;75m[spritesheet_viewer\27[38;5;80m.scene\27[38;5;75m]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end
------------------------------------------------------------------------------------------
SpritesheetViewer.spritesheet_image = love.graphics.newImage( "resources/sprites/cherrymelon_a_r.png" )
SpritesheetViewer.spritesheet_image:setFilter( "nearest", "nearest")
print(string.format("%sx%s (%s)",
SpritesheetViewer.spritesheet_image:getPixelWidth(),
SpritesheetViewer.spritesheet_image:getPixelHeight(),
SpritesheetViewer.spritesheet_image:getFormat()
)
)

camera:lookAt(
    SpritesheetViewer.spritesheet_image:getPixelWidth()/2.0,
    SpritesheetViewer.spritesheet_image:getPixelHeight()/2.0
)

------------------------------------------------------------------------------------------
local navigation = {}
navigation.is_panning = false
navigation.pan_last_x = 0.0
navigation.pan_dx = 0.0
navigation.pan_last_y = 0.0
navigation.pan_dy = 0.0
navigation.zoom = 1.0

------------------------------------------------------------------------------------------
local font_small = love.graphics.newFont(10)
local global_time = 0.0

function SpritesheetViewer:init()
end


function SpritesheetViewer:focus()
end


function SpritesheetViewer:defocus()
end


function SpritesheetViewer:update(dt)
    global_time = global_time + dt
    if navigation.is_panning then
        local mx, my = camera:mousePosition( )

        navigation.pan_dx = mx - navigation.pan_last_x
        navigation.pan_dy = my - navigation.pan_last_y
        camera:move( -navigation.pan_dx, -navigation.pan_dy )

        local cx,cy = camera:mousePosition( )
        navigation.pan_last_x = cx
        navigation.pan_last_y = cy
    end
end


function SpritesheetViewer:draw()
    love.graphics.clear(0.05, 0.05, 0.05, 1.0)
    love.graphics.setColor(1,1,1,1)
    
    camera:attach()
    love.graphics.draw( SpritesheetViewer.spritesheet_image )
    
    local osc = (math.sin(global_time * 22.5) + 1) /2.0
    osc = shaping.remap(shaping.bias(osc, 0.05), 0.0, 1.0, 0.2, 3.0)

    love.graphics.setColor( 1.0*osc, 0.55*osc, 0.025*osc, 1.0 )
    love.graphics.rectangle("line",31*16,22*16,16,16)
    camera:detach()

    love.graphics.setFont(font_small)
    local mx, my = love.mouse.getPosition()
    local mwx, mwy = camera:worldCoords( mx, my )
    love.graphics.setColor(0.0, 0.0, 0.0, 0.75)
    love.graphics.rectangle( "fill", mx, my-20, 85, 50 )
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("ms: %0.1f %0.1f",mx, my) , mx +5, my-10 )
    love.graphics.print(string.format("mw: %0.1f %0.1f",mwx, mwy) , mx +5, my+10 )
    local cmx, cmy = camera:mousePosition( )
    love.graphics.print(string.format("mp: %0.1f %0.1f",cmx, cmy) , mx +5, my+20 )
end


function SpritesheetViewer:mousepressed( x, y, button )
    if button == 3 then -- middle
        print("SpritesheetViewer:mousepressed 3")
        navigation.is_panning = true
        local cx,cy = camera:mousePosition( )
        navigation.pan_last_x = cx
        navigation.pan_last_y = cy
    end
end


function SpritesheetViewer:mousereleased( x, y, button )
    if button == 3 then -- middle
        print("SpritesheetViewer:mousereleased 3")
        navigation.is_panning = false
    end
end


function SpritesheetViewer:wheelmoved(x,y)
    navigation.zoom = navigation.zoom * ( 1 + (y *0.1))
    navigation.zoom = shaping.clamp( navigation.zoom, .25, 20.0 )
    camera:zoomTo( navigation.zoom )
end

return SpritesheetViewer
