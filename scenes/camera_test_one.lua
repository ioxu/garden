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
player.move_speed = 300
player._quad = love.graphics.newQuad(31*16,22*16,16,16, _sprite_sheet)

local wwidth, wheight = love.graphics.getDimensions()

local bg_mesh = love.graphics.newMesh( 4, "fan", "dynamic" )

-- TODO: move this to a shader module
local test_shader = love.graphics.newShader[[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    float modx = abs(mod(texture_coords.x*0.01, 1.0) - 0.5) ;
    float mody = abs(mod(texture_coords.y*0.01, 1.0) - 0.5) ;
    float grads = 1-(max(modx,  mody )*2) - 0.01;
    vec2 combine = 1.0 - clamp( grads / fwidth(texture_coords*0.05), 0.0, 1.0 );
    vec4 cc = mix(vec4( 0.065, 0.065, 0.065, 1.0 ), vec4( 0.12, 0.12, 0.12, 1.0 ), combine.x );
	return cc;
}
]]


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


    print("camera.scale %s", camera.scale)

    if math.abs(js_ry) > 0.1 then
        camera.scale = camera.scale * zoom_damped( 1.0 + js_ry*0.01 )
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
        camera.rot = rot_damped( js_lx * 0.075 )
    else
        camera.rot = rot_damped( 0.0 )
    end

    -- deadzones
    if math.abs(js_lx) < 0.085 then
        js_lx = 0.0
    end
    if math.abs(js_ly) < 0.085 then
        js_ly = 0.0
    end
    if js_lx ~= 0.0 or js_ly ~= 0.0 then
        local n_lstick_dir_x, n_lstick_dir_y = vector.normalise( js_lx, js_ly )
        local lsktick_mag = shaping.clamp(vector.length( js_lx, js_ly ), 0.0, 1.0)

        player.x = player.x + n_lstick_dir_x * lsktick_mag * player.move_speed * dt
        player.y = player.y + n_lstick_dir_y * lsktick_mag * player.move_speed * dt

        local dx,dy = player.x - camera.x, player.y - camera.y
    end
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