local CameraTestOne ={}
CameraTestOne.scene_name = "camera movement test"
CameraTestOne.description = "a test for moving a camera interactively"

local vector = require "lib.vector"
local shaping = require "lib.shaping"

local joystick_diagram = require "lib.joystick_diagram"
local joysticks = love.joystick.getJoysticks()
local joystick = joysticks[1]

local Camera = require "lib.camera"
local camera

local _sprite_sheet = love.graphics.newImage( "resources/sprites/cherrymelon_a_r.png" )
_sprite_sheet:setFilter( "nearest", "nearest")

local player = {}
player.x = 0.0
player.y = 0.0
player.x_damped = shaping.float_damped(7.5, player.x)
player.y_damped = shaping.float_damped(7.5, player.y)
player.target_move_x = 0.0
player.target_move_y = 0.0
player.move_speed = 300
player._quad = love.graphics.newQuad(31*16,22*16,16,16, _sprite_sheet)

local wwidth, wheight = love.graphics.getDimensions()

local bg_mesh = love.graphics.newMesh( 4, "fan", "dynamic" )

-- TODO: move this to a shader module

-- https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
local rgb2hsv_fragment = [[
// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

]]


local grid_fragment = [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    float modx = abs(mod(texture_coords.x*0.01, 1.0) - 0.5) ;
    float mody = abs(mod(texture_coords.y*0.01, 1.0) - 0.5) ;
    float grads = 1-(max(modx,  mody )*2) - 0.1;
    vec2 combine = 1.0 - clamp( grads / fwidth(texture_coords*0.05), 0.0, 1.0 );
    
    // visualising fwidth at different scales (because mesh UVs == world units atm)
    //vec3 grid_c = hsv2rgb( vec3(fwidth(texture_coords*1.0).x, 0.75, 0.5) );
    //vec4 cc = mix(vec4( 0.065, 0.065, 0.065, 1.0 ), vec4( grid_c.r, grid_c.g, grid_c.b, 1.0 ), combine.x );
    
    vec4 cc = mix(vec4( 0.065, 0.065, 0.065, 1.0 ), vec4( 0.12, 0.12, 0.12, 1.0 ), combine.x );
	return cc;
}
]]


local test_shader = love.graphics.newShader( rgb2hsv_fragment .. grid_fragment )


function CameraTestOne:init()
    camera = Camera( player.x, player.x )
    camera.smoother = Camera.smooth.damped(2)
end


function CameraTestOne:focus()
end


function CameraTestOne:defocus()
end


local js_lx
local js_ly
local js_rx
local js_ry
local rot_damped = shaping.float_damped( 5.5 )
local zoom_damped = shaping.float_damped( 5.5, 1.0 )

function CameraTestOne:update(dt)
    js_lx = joystick:getGamepadAxis( "leftx" )
    js_ly = joystick:getGamepadAxis( "lefty" )

    js_rx = joystick:getGamepadAxis( "rightx" )
    js_ry = joystick:getGamepadAxis( "righty" )

    -- camera zoom deadzones
    if math.abs(js_ry) > 0.1 then
        camera.scale = camera.scale * zoom_damped( 1.0 + js_ry*-0.01 )
    else
        camera.scale = camera.scale * zoom_damped( 1.0 )
    end

    -- camera zoom bounds
    if camera.scale  < 0.15 then
        camera.scale = camera.scale * zoom_damped( 1 - (camera.scale - 0.15) )
    elseif camera.scale > 4.5 then
        camera.scale = camera.scale * zoom_damped( 1 + (4.5 - camera.scale) )
    end

    -- damped rotation
    if math.abs(js_lx) > 0.1 then
        camera.rot = rot_damped( js_lx * 0.025 )
    else
        camera.rot = rot_damped( 0.0 )
    end

    -- player move deadzones
    if math.abs(js_lx) < 0.085 then
        js_lx = 0.0
    end
    if math.abs(js_ly) < 0.085 then
        js_ly = 0.0
    end
    if js_lx ~= 0.0 or js_ly ~= 0.0 then
        local n_lstick_dir_x, n_lstick_dir_y = vector.normalise( js_lx, js_ly )
        local lsktick_mag = shaping.clamp(vector.length( js_lx, js_ly ), 0.0, 1.0)
        player.target_move_x =  n_lstick_dir_x * lsktick_mag * player.move_speed * dt
        player.target_move_y =  n_lstick_dir_y * lsktick_mag * player.move_speed * dt
    else
        player.target_move_x = 0.0
        player.target_move_y = 0.0
    end
    player.x = player.x + player.x_damped( player.target_move_x )
    player.y = player.y + player.y_damped( player.target_move_y )

    camera:lockPosition( player.x, player.y )
end


local wmargin = 15.0
function CameraTestOne:draw()
    love.graphics.setShader()
    camera:attach()

    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    love.graphics.setShader(test_shader)


    local tilt = -js_lx * 0.05
    local hw, hh = camera:worldCoords( wwidth/2.0, wheight/2.0 )
    local x, y = camera:worldCoords( wmargin, wmargin )
    bg_mesh:setVertex( 1, x, y, x, y, 1, 1, 1, 1 )
    
    x, y = camera:worldCoords( wwidth - wmargin, wmargin )
    bg_mesh:setVertex( 2, x, y, x, y, 1, 1, 1, 1 )
    
    x, y = camera:worldCoords( wwidth - wmargin, wheight - wmargin )
    bg_mesh:setVertex( 3, x, y, x, y, 1, 1, 1, 1 )
    
    x, y = camera:worldCoords( wmargin, wheight - wmargin )
    bg_mesh:setVertex( 4, x, y, x, y, 1, 1, 1, 1 )
    
    love.graphics.draw(bg_mesh)

    love.graphics.setShader()
    --player 
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw( _sprite_sheet,
        player._quad,
        player.x-(16*4)/2,
        player.y-(16*4),
        0,
        4,
        4
    )

    camera:detach()

    joystick_diagram.draw_PS4Controller_diagram( joystick , 1300, 825)
end


function CameraTestOne:joystickaxis(joystick, axis, value )
    if math.abs(value) > 0.1 then -- deadzone
        --
    end
end


return CameraTestOne