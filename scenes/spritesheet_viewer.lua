SpritesheetViewer = {}
SpritesheetViewer.scene_name = "Spretesheet viewer"
SpritesheetViewer.description = "Test for viewing a spritesheet, and experimenting with SpriteBatches."

local signal = require "lib.signal"
local shaping = require "lib.shaping"
local Camera = require "lib.camera"
local camera = Camera( 0.0, 0.0 )
local shadeix = require "lib.shadeix"

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
SpritesheetViewer.spritesheet_image:setFilter( "linear", "nearest" )
print(string.format("%sx%s (%s)",
    SpritesheetViewer.spritesheet_image:getPixelWidth(),
    SpritesheetViewer.spritesheet_image:getPixelHeight(),
    SpritesheetViewer.spritesheet_image:getFormat()
)
)
SpritesheetViewer.is_paused = false

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

navigation.focus = false -- focusing spritebatch vs spritesheet
navigation._focus_damped = shaping.float_damped( 3.5, 0.0 )
navigation.focus_tween = 0.0



------------------------------------------------------------------------------------------
local font_small = love.graphics.newFont(10)
local font_very_large = love.graphics.newFont(90)
local global_time = 0.0
local frame_count = 0
local _last_frame_count_update = 0.0
local _target_frame_fps = 1/25.0

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

control_ui.focus_button = gspot:button( "focus",
    {x=_margin,
        y=control_ui.draw_grid_check.pos.y + _margin,
        w= control_ui.window.pos.w - _margin *2
    },
    control_ui.window
)
control_ui.window:addchild( control_ui.focus_button, 'vertical' )
control_ui.focus_button.click = function (this)
    navigation.focus = not navigation.focus
end

control_ui.window:hide()


---turn the display of the sprite grid on or off
---@param value boolean do display
function SpritesheetViewer.display_sprite_grid( value )
    SpritesheetViewer.do_sprite_grid_display = value
end

------------------------------------------------------------------------------------------

local crt_shadergraph = shadeix.Graph:new("crt_shgraph")

-- canvases for shader effects
local canvas_linearised = 
love.graphics.newCanvas(
    love.graphics.getWidth(),
    love.graphics.getHeight(),
    { ["msaa"] = 0,
    -- ["readable"] = true,
}
)

local canvas_one = love.graphics.newCanvas(
    love.graphics.getWidth(),
    love.graphics.getHeight(),
    { ["msaa"] = 16,
    -- ["readable"] = true,
}
)
canvas_one:setFilter("nearest", "nearest")

local canvas_two = love.graphics.newCanvas(
    love.graphics.getWidth(),
    love.graphics.getHeight(),
    { ["msaa"] = 0,
    -- ["readable"] = true,
}
)
canvas_two:setFilter("nearest", "nearest")


local sh_string = love.filesystem.read( "resources/shaders/linearise.frag" )
local linearise_shader = love.graphics.newShader( sh_string )
linearise_shader:send("gamma", 2.2)

sh_string = love.filesystem.read( "resources/shaders/blur_horizontal.frag" )
local blur_h_shader = love.graphics.newShader( sh_string )

sh_string = love.filesystem.read( "resources/shaders/blur_vertical.frag" )
local blur_v_shader = love.graphics.newShader( sh_string )

sh_string = love.filesystem.read( "resources/shaders/unlinearise.frag" )
local unlinearise_shader = love.graphics.newShader( sh_string )
unlinearise_shader:send("gamma", 2.2)
local gamma_set = true

sh_string = love.filesystem.read( "resources/shaders/threshold.frag" )
local threshold_shader = love.graphics.newShader( sh_string )
threshold_shader:send("PassPrev3Texture", canvas_linearised)

sh_string = love.filesystem.read("other/glsl/crt-easymode-halation.frag")
local crt_easymode_haltion = love.graphics.newShader( sh_string )
crt_easymode_haltion:send("PassPrev4Texture", canvas_linearised)

------------------------------------------------------------------------------------------
-- SpriteBatch stuff
local rng = love.math.newRandomGenerator()
-- local base_rng_seed = os.time()
rng:setSeed( 123 )

local sprite_batch = love.graphics.newSpriteBatch( SpritesheetViewer.spritesheet_image, 10000, "static" )
local source_quads = {}
local n_quads = 50000 --5000


sprite_batch:clear()

for x=0,19 do
    for y =0,19 do
        table.insert( source_quads, love.graphics.newQuad( x*16, y*16, 16, 16, SpritesheetViewer.spritesheet_image))
    end
end


local sprite_ids = {}
local _layout_spread = 1.2
for i = 0, n_quads do
    local rr = rng:random( 1, 20*20 )
    local rs = rng:random(1,2)
    local id = sprite_batch:add( source_quads[ rr ] ,
        rng:random(0,love.graphics.getWidth()*_layout_spread),
        rng:random(0, love.graphics.getHeight()*_layout_spread),
        rng:random() * math.pi*2,
        rs, rs
    )
    -- data needs to be per-sprite-vertex (4 vertices per sprite)
    sprite_ids[i*4+1] = {id,}
    sprite_ids[i*4+2] = {id,}
    sprite_ids[i*4+3] = {id,}
    sprite_ids[i*4+4] = {id,}
end

-- example of setting up user data to pass to a SpriteBatch to use in a shader.
-- attributes must be created on a Mesh object, and then attatched to the SpriteBatch via
-- SpriteBatch:attachAttribute.
-- SpriteBatch's are made from 4 vertex quad geometry, so custom attributes mush be of length
-- sprites * 4
-- sprite_ids table collects the data I want on each sprite's vertex.
-- It seems custom attribute's ndices MUST start at 1.

-- data mesh to hold and attach for custom data (I suppose this is like a VBO)
local data_mesh = love.graphics.newMesh({{"sprite_id", "float", 1}}, sprite_ids, "points", "static")
-- attach data mesh to spritebatch
sprite_batch:attachAttribute( "sprite_id", data_mesh )
-- vertex and fragment shader
print("compile shader")
local sprite_batch_shader = love.graphics.newShader([[
attribute float sprite_id; // read sprite_id into vertex shader
varying float v_sprite_id; // create varying varable to pass through to fragment shader
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	v_sprite_id = sprite_id; // write attribute to varying to pass through
	return transform_projection * vertex_position;
}
]],[[
varying float v_sprite_id; // receive attribute from vertex shader

float hue2rgb(float hue, float saturation, float luminosity){
    if(luminosity < 0.0) luminosity += 1.0;
    if(luminosity > 1.0) luminosity -= 1.0;
    if(luminosity < 1.0/6.0) return hue + (saturation - hue) * 6.0 * luminosity;
    if(luminosity < 1.0/2.0) return saturation;
    if(luminosity < 2.0/3.0) return hue + (saturation - hue) * (2.0/3.0 - luminosity) * 6.0;
    return hue;
}

vec3 hsl2rgb(vec3 color) {
    float hue = color.x;
    float saturation = color.y;
    float luminosity = color.z;

    float r, g, b;

    if (saturation == 0.0) {
        r = g = b = luminosity; // achromatic
    } else {
        float q = luminosity < 0.5 ? luminosity * (1.0 + saturation) : luminosity + saturation - luminosity * saturation;
        float p = 2.0 * luminosity - q;
        r = hue2rgb(p, q, hue + 1.0/3.0);
        g = hue2rgb(p, q, hue);
        b = hue2rgb(p, q, hue - 1.0/3.0);
    }
    return vec3(r, g, b);
}

vec3 hue_shift(vec3 color, float dhue) {
	float s = sin(dhue);
	float c = cos(dhue);
	return (color * c) + (color * s) * mat3(
		vec3(0.167444, 0.329213, -0.496657),
		vec3(-0.327948, 0.035669, 0.292279),
		vec3(1.250268, -1.047561, -0.202707)
	) + dot(vec3(0.299, 0.587, 0.114), color) * (1.0 - c);
}

// fragment shader uses sprite_id to generate a 'random' hue to multiply the sprite texture by
// and also hue-shifts the sprite texture before being being multiplied by a 'random' hue
// also, an extern 'time' receives a sent value to animate the hue
uniform float time;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
{
    vec4 texturecolor = Texel(tex, texture_coords);
    float dd = fract(v_sprite_id/1000.0) ;
    vec3 outc = hsl2rgb( vec3( dd, 1.0, 0.75 ) );

    outc = hue_shift(texturecolor.xyz, fract(dd+0.75)+time) * outc;

    return vec4(outc, texturecolor.a) * color;
}
}
]])

print("shader compilation warnings: ", sprite_batch_shader:getWarnings() )

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
    if not SpritesheetViewer.is_paused then
        global_time = global_time + dt
        sprite_batch_shader:send("time", global_time)
        
        _last_frame_count_update = _last_frame_count_update + dt
        if _last_frame_count_update > _target_frame_fps then
            frame_count = frame_count + 1
            crt_easymode_haltion:send("FrameCount", frame_count)
            _last_frame_count_update = 0.0
        end
    end

    -- frame_count = frame_count + 1
    -- crt_easymode_haltion:send("FrameCount", frame_count)

    if navigation.is_panning then
        local mx, my = camera:mousePosition( )

        navigation.pan_dx = mx - navigation.pan_last_x
        navigation.pan_dy = my - navigation.pan_last_y
        camera:move( -navigation.pan_dx, -navigation.pan_dy )

        local cx,cy = camera:mousePosition( )
        navigation.pan_last_x = cx
        navigation.pan_last_y = cy
    end

    if navigation.focus then
        navigation.focus_tween = navigation._focus_damped(1.0)
    else
        navigation.focus_tween = navigation._focus_damped(0.0)
    end

end


local dw = tonumber(control_ui.sprite_division_width.value)
local dh = tonumber(control_ui.sprite_division_height.value)

function SpritesheetViewer:draw()

    love.graphics.setCanvas( canvas_one )

    love.graphics.clear(0.05, 0.05, 0.05, 1.0)
    love.graphics.setColor(1,1,1,1)
    
    local a = shaping.remap( navigation.focus_tween, 0.0, 1.0, 0.35, 1.0 )
    love.graphics.setColor(a,a,a,1)
    
    love.graphics.setShader( sprite_batch_shader )

    love.graphics.draw( sprite_batch,
        math.sin( global_time * 0.2 ) *100 + love.graphics.getWidth()/2.0,
        math.cos( global_time * 0.2 ) *100 + love.graphics.getHeight()/2.0,
        math.sin( global_time + 2.223 * 0.05 ) * 0.05,
        1.0, 1.0,
        love.graphics.getWidth()*_layout_spread /2.0,
        love.graphics.getHeight()*_layout_spread /2.0
    )

    love.graphics.setShader( )
    ----------------------------------------------------------------------------
    camera:attach()
    
    local a = shaping.remap( navigation.focus_tween, 0.0, 1.0, 1.0, 0.0 )
    love.graphics.setColor(1,1,1,a)

    if not (navigation.focus_tween > 0.995) then
        love.graphics.draw( SpritesheetViewer.spritesheet_image )
        
        local osc = (math.sin(global_time * 22.5) + 1) /2.0
        osc = shaping.remap(shaping.bias(osc, 0.05), 0.0, 1.0, 0.2, 3.0)

        love.graphics.setColor( 1.0*osc, 0.55*osc, 0.025*osc, 1.0 * a )
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line",31*16,22*16,16,16)

        if SpritesheetViewer.do_sprite_grid_display and
            control_ui.sprite_division_width.value and
            control_ui.sprite_division_height.value then
            -- control_ui.sprite_division_width
            -- control_ui.sprite_division_height
            love.graphics.setColor(1.0, 0.5, 0.0, 0.5 * a )
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
        love.graphics.setColor(0.0, 1.0, 0.0, 1.0 * a)
        love.graphics.setLineWidth( 2 )
        love.graphics.line( 0.0, 0.0, edge_indicator_length, 0.0)
        love.graphics.line( 0.0, 0.0, 0.0, edge_indicator_length)
        love.graphics.line( SpritesheetViewer.spritesheet_image:getPixelWidth(), 0.0, SpritesheetViewer.spritesheet_image:getPixelWidth(), edge_indicator_length)
        love.graphics.line( SpritesheetViewer.spritesheet_image:getPixelWidth(), 0.0, SpritesheetViewer.spritesheet_image:getPixelWidth()-edge_indicator_length, 0.0)
        love.graphics.line( 0.0, SpritesheetViewer.spritesheet_image:getPixelHeight(), 0.0, SpritesheetViewer.spritesheet_image:getPixelHeight()-edge_indicator_length )
        love.graphics.line( 0.0, SpritesheetViewer.spritesheet_image:getPixelHeight(), edge_indicator_length, SpritesheetViewer.spritesheet_image:getPixelHeight() )
        love.graphics.line( SpritesheetViewer.spritesheet_image:getPixelWidth(), SpritesheetViewer.spritesheet_image:getPixelHeight(), SpritesheetViewer.spritesheet_image:getPixelWidth()-edge_indicator_length, SpritesheetViewer.spritesheet_image:getPixelHeight())
        love.graphics.line( SpritesheetViewer.spritesheet_image:getPixelWidth(), SpritesheetViewer.spritesheet_image:getPixelHeight(), SpritesheetViewer.spritesheet_image:getPixelWidth(), SpritesheetViewer.spritesheet_image:getPixelHeight()-edge_indicator_length)
    end

    camera:detach()
    ----------------------------------------------------------------------------

    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.setColor(1,1,1,1)

    -- linearise
    love.graphics.setCanvas( canvas_linearised )
    love.graphics.setShader( linearise_shader )
    love.graphics.draw( canvas_one )

    -- h blur
    love.graphics.setCanvas( canvas_one )
    love.graphics.setShader( blur_h_shader )
    love.graphics.draw( canvas_linearised )

    -- v blur
    love.graphics.setCanvas( canvas_two )
    love.graphics.setShader( blur_v_shader )
    love.graphics.draw( canvas_one )

    -- threshold 
    love.graphics.setCanvas( canvas_one )
    love.graphics.setShader( threshold_shader )
    love.graphics.draw( canvas_two )

    -- unlinearise
    -- love.graphics.setCanvas( canvas_two )
    -- love.graphics.setShader( unlinearise_shader )
    -- love.graphics.draw( canvas_one )

    -- crt-easymode-halation
    love.graphics.setCanvas( canvas_two )
    love.graphics.setShader( crt_easymode_haltion )
    love.graphics.draw( canvas_one )

    -- final draw
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.draw( canvas_two )
    



    love.graphics.setFont(font_small)
    local mx, my = love.mouse.getPosition()
    local mwx, mwy = camera:worldCoords( mx, my )
    love.graphics.setColor(0.0, 0.0, 0.0, 0.90)
    love.graphics.rectangle( "fill", mx, my-10, 75, 20 )
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("tile: %s, %s", math.floor(mwx/dw), math.floor(mwy/dh) ), mx+15, my-7.5 )


    if SpritesheetViewer.is_paused then
        love.graphics.setFont(font_very_large)
        local fw = font_very_large:getWidth("PAUSED")
        love.graphics.print("PAUSED", love.graphics.getWidth()/2.0 - fw/2.0 ,20)
    end    
end

function SpritesheetViewer:keypressed(key, code, isrepeat)
    
    -- TODO temporary shader gamma control
    -- if code == "g" then
    --     gamma_set = not gamma_set
    --     if gamma_set then
    --         linearise_shader:send("gamma", 2.2)
    --         unlinearise_shader:send("gamma", 2.2)            
    --         print("un/linearise_shader:send('gamma', 2.2)")
    --     else
    --         linearise_shader:send("gamma", 1.0)
    --         unlinearise_shader:send("gamma", 1.0)            
    --         print("un/linearise_shader:send('gamma', 1.0)")
    --     end
    -- end

    if code == "space" then
        SpritesheetViewer.is_paused = not SpritesheetViewer.is_paused
    end
end

function SpritesheetViewer:mousepressed( x, y, button )
    if button == 3 then -- middle
        navigation.is_panning = true
        local cx,cy = camera:mousePosition( )
        navigation.pan_last_x = cx
        navigation.pan_last_y = cy
    end
end


function SpritesheetViewer:mousereleased( x, y, button )
    if button == 3 then -- middle
        navigation.is_panning = false
    end
end


function SpritesheetViewer:wheelmoved(x,y)
    navigation.zoom = navigation.zoom * ( 1 + (y *0.1))
    navigation.zoom = shaping.clamp( navigation.zoom, .25, 20.0 )
    camera:zoomTo( navigation.zoom )
end


return SpritesheetViewer
