SpritesheetViewer = {}
SpritesheetViewer.scene_name = "Spretesheet viewer"
SpritesheetViewer.description = "Test for viewing a spritesheet, and experimenting with SpriteBatches."

local signal = require "lib.signal"
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

------------------------------------------------------------------------------------------
-- settings ui
local unit = gspot.style.unit
local _margin = 4

local control_ui = {}
control_ui.signals = signal:new()
control_ui.window = gspot:group("spritesheet controls",{x=25,y=500, w=128,h=180})
control_ui.window.drag = true
control_ui.infobox = gspot:group("info",
{
    x=_margin,
    y=unit+_margin,
    w=control_ui.window.pos.w-_margin*2,
    h=unit*3+_margin
},
control_ui.window
)
control_ui.infobox.style.bg = {0.15,0.15,0.15,1.0}
control_ui.window:addchild( control_ui.infobox )
control_ui.info_spritesheet_dimensions = gspot:text("<dimensions>", {y=0} , control_ui.infobox, true)
control_ui.infobox:addchild( control_ui.info_spritesheet_dimensions, 'vertical' )
control_ui.info_spritesheet_format = gspot:text("<format>",{}, control_ui.infobox, true)
control_ui.infobox:addchild( control_ui.info_spritesheet_format, 'vertical' )

control_ui.sprite_division_width = gspot:input("sprite width:", {x= 80, w = control_ui.window.pos.w-80-_margin}, control_ui.window )
control_ui.sprite_division_width.value = tostring(16)
control_ui.window:addchild( control_ui.sprite_division_width, 'vertical' )

control_ui.sprite_division_height = gspot:input("sprite height:", {x= 80, w = control_ui.window.pos.w-80-_margin}, control_ui.window )
control_ui.sprite_division_height.value = tostring(16)
control_ui.window:addchild( control_ui.sprite_division_height, 'vertical' )

control_ui.draw_grid_check = gspot:checkbox( nil, {x = _margin, r=8}, control_ui.window )
control_ui.window:addchild( control_ui.draw_grid_check, 'vertical' )
control_ui.draw_grid_label = gspot:text( "draw grid", {x=16}, control_ui.draw_grid_check, true )
control_ui.draw_grid_check.click = function(this)
    gspot[ this.elementtype ].click( this )
    if this.value then
        this.style.fg = {1.0, 0.5, 0.0, 1.0}
        SpritesheetViewer.display_sprite_grid( true )
    else
        this.style.fg = {1,1,1,1}
        SpritesheetViewer.display_sprite_grid( false )
    end

end

control_ui.window:hide()


---turn the display of the sprite grid on or off
---@param value boolean do display
function SpritesheetViewer.display_sprite_grid( value )
    SpritesheetViewer.do_sprite_grid_display = value
end

------------------------------------------------------------------------------------------
function SpritesheetViewer:init()
    control_ui.info_spritesheet_dimensions.label = string.format("%sx%s px.", SpritesheetViewer.spritesheet_image:getPixelWidth(), SpritesheetViewer.spritesheet_image:getPixelHeight())
    control_ui.info_spritesheet_format.label = string.format("%s", SpritesheetViewer.spritesheet_image:getFormat())
end


function SpritesheetViewer:focus()
    control_ui.window:show()
end


function SpritesheetViewer:defocus()
    control_ui.window:hide()
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


local dw = tonumber(control_ui.sprite_division_width.value)
local dh = tonumber(control_ui.sprite_division_height.value)

function SpritesheetViewer:draw()
    love.graphics.clear(0.05, 0.05, 0.05, 1.0)
    love.graphics.setColor(1,1,1,1)
    
    ----------------------------------------------------------------------------
    camera:attach()
    love.graphics.draw( SpritesheetViewer.spritesheet_image )
    
    local osc = (math.sin(global_time * 22.5) + 1) /2.0
    osc = shaping.remap(shaping.bias(osc, 0.05), 0.0, 1.0, 0.2, 3.0)

    love.graphics.setColor( 1.0*osc, 0.55*osc, 0.025*osc, 1.0 )
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line",31*16,22*16,16,16)

    if SpritesheetViewer.do_sprite_grid_display and
        control_ui.sprite_division_width.value and
        control_ui.sprite_division_height.value then
        -- control_ui.sprite_division_width
        -- control_ui.sprite_division_height
        love.graphics.setColor(1.0, 0.5, 0.0, 0.5 )
        love.graphics.setLineWidth( 1/camera.scale )


        dw = tonumber(control_ui.sprite_division_width.value)
        dh = tonumber(control_ui.sprite_division_height.value)

        if dw and dh then
            dw = math.max(dw, 1)
            dh = math.max(dh, 1)
            for xx =0, SpritesheetViewer.spritesheet_image:getPixelWidth()/dw do
                local xp = xx * dw
                love.graphics.line( xp, 0.0, xp, SpritesheetViewer.spritesheet_image:getPixelHeight( ) )
            end
            for yy=0, SpritesheetViewer.spritesheet_image:getPixelHeight()/dh do
                local yp = yy *  dh
                love.graphics.line( 0, yp, SpritesheetViewer.spritesheet_image:getPixelWidth( ), yp )
            end
        end
    end
    
    -- corner indicators
    local edge_indicator_length = 20.0
    love.graphics.setColor(0.0, 1.0, 0.0, 1.0 )
    love.graphics.setLineWidth( 2 )
    love.graphics.line( 0.0, 0.0, edge_indicator_length, 0.0)
    love.graphics.line( 0.0, 0.0, 0.0, edge_indicator_length)
    love.graphics.line( SpritesheetViewer.spritesheet_image:getPixelWidth(), 0.0, SpritesheetViewer.spritesheet_image:getPixelWidth(), edge_indicator_length)
    love.graphics.line( SpritesheetViewer.spritesheet_image:getPixelWidth(), 0.0, SpritesheetViewer.spritesheet_image:getPixelWidth()-edge_indicator_length, 0.0)
    love.graphics.line( 0.0, SpritesheetViewer.spritesheet_image:getPixelHeight(), 0.0, SpritesheetViewer.spritesheet_image:getPixelHeight()-edge_indicator_length )
    love.graphics.line( 0.0, SpritesheetViewer.spritesheet_image:getPixelHeight(), edge_indicator_length, SpritesheetViewer.spritesheet_image:getPixelHeight() )
    love.graphics.line( SpritesheetViewer.spritesheet_image:getPixelWidth(), SpritesheetViewer.spritesheet_image:getPixelHeight(), SpritesheetViewer.spritesheet_image:getPixelWidth()-edge_indicator_length, SpritesheetViewer.spritesheet_image:getPixelHeight())
    love.graphics.line( SpritesheetViewer.spritesheet_image:getPixelWidth(), SpritesheetViewer.spritesheet_image:getPixelHeight(), SpritesheetViewer.spritesheet_image:getPixelWidth(), SpritesheetViewer.spritesheet_image:getPixelHeight()-edge_indicator_length)

    camera:detach()
    ----------------------------------------------------------------------------

    love.graphics.setFont(font_small)
    local mx, my = love.mouse.getPosition()
    local mwx, mwy = camera:worldCoords( mx, my )
    love.graphics.setColor(0.0, 0.0, 0.0, 0.90)
    love.graphics.rectangle( "fill", mx, my-10, 75, 20 )
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("tile: %s, %s", math.floor(mwx/dw), math.floor(mwy/dh) ), mx+15, my-7.5 )
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
