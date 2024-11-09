local Camera = require "lib.camera"
local shaping = require "lib.shaping"
local Navigation = {}

Navigation.is_panning = false
Navigation.pan_last_x = 0.0
Navigation.pan_dx = 0.0
Navigation.pan_last_y = 0.0
Navigation.pan_dy = 0.0
Navigation.zoom = 1.0
Navigation._zoom_damped = shaping.float_damped( 10.5, 1.0 )
Navigation._target_zoom = 1.0
Navigation.camera = Camera( 0.0, 0.0 )

Navigation.update = function(dt)
    -- panning
    if Navigation.is_panning then
        local mx, my = Navigation.camera:mousePosition( )

        Navigation.pan_dx = mx - Navigation.pan_last_x
        Navigation.pan_dy = my - Navigation.pan_last_y
        Navigation.camera:move( -Navigation.pan_dx, -Navigation.pan_dy )

        local cx,cy = Navigation.camera:mousePosition( )
        Navigation.pan_last_x = cx
        Navigation.pan_last_y = cy
    end
    -- zoom
    Navigation.zoom = Navigation._zoom_damped( Navigation._target_zoom )
    Navigation.camera:zoomTo( Navigation.zoom )
end


Navigation.mousepressed = function( x, y, button )
    if button == 3 then -- middle
        Navigation.is_panning = true
        local cx,cy = Navigation.camera:mousePosition( )
        Navigation.pan_last_x = cx
        Navigation.pan_last_y = cy
    end    
end


Navigation.mousereleased = function( x, y, button )
    if button == 3 then -- middle
        Navigation.is_panning = false
    end
end


Navigation.wheelmoved = function( x,y )
    Navigation._target_zoom = Navigation._target_zoom * ( 1 + (y *0.1))
    Navigation._target_zoom = shaping.clamp( Navigation._target_zoom, 0.1, 500.0 )
end

return Navigation