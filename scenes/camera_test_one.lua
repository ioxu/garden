local CameraTestOne ={}
CameraTestOne.scene_name = "camera movement test"
CameraTestOne.description = "a test for moving a camera interactively"

local vector = require "lib.vector"
local shaping = require "lib.shaping"
local shadeix = require "lib.shadeix"

------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;35m[camera_test]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end
------------------------------------------------------------------------------------------

local joystick_diagram = require "lib.joystick_diagram"
local joysticks = love.joystick.getJoysticks()
local joystick = joysticks[1]

local Camera = require "lib.camera"
local camera

local global_frame = 0.0
local _last_frame_count_update = 0.0
local _target_frame_fps = 1/25.0

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

------------------------------------------------------------------------------------------
-- post processing

local base_canvas = love.graphics.newCanvas(
    love.graphics.getWidth(),
    love.graphics.getHeight(),
    {["msaa"] = 16,}
)

print("building post-processes")
------------------------------------------------------------------------------------------
--- UV grid shader
local shader_components = require "resources.shaders.shader_components"
local test_shader = love.graphics.newShader( shader_components.rgb2hsv_function .. shader_components.uv_grid_fragment )

------------------------------------------------------------------------------------------
--- crt post shader
local crt_shgraph = shadeix.Graph:new("crt_shgraph", base_canvas)
local linearise_shnode = crt_shgraph:add_node( "linearise", "resources/shaders/linearise.frag" )
linearise_shnode:stash_canvas( love.graphics.getWidth(), love.graphics.getHeight(), {} )
linearise_shnode.shader:send("gamma", 2.2)
local blur_h_shnode = crt_shgraph:add_node( "blur h", "resources/shaders/blur_horizontal.frag" )
local blur_v_shnode = crt_shgraph:add_node( "blur v", "resources/shaders/blur_vertical.frag" )
local threshold_shnode = crt_shgraph:add_node( "threshold", "resources/shaders/threshold.frag" )
-- threshold_shnode:stash_canvas( love.graphics.getWidth(), love.graphics.getHeight(), {} )
threshold_shnode.shader:send( "PassPrev3Texture", linearise_shnode.canvas )
local crt_easymode_halation_shnode = crt_shgraph:add_node( "crt-easymode-halation", "resources/shaders/crt-easymode-halation.frag" )
crt_easymode_halation_shnode.shader:send( "PassPrev4Texture", linearise_shnode.canvas )
crt_shgraph:print_graph()
------------------------------------------------------------------------------------------


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

local crt_node = crt_shgraph:get_node("crt-easymode-halation")

function CameraTestOne:update(dt)
    
    _last_frame_count_update = _last_frame_count_update + dt
    if _last_frame_count_update > _target_frame_fps then
        global_frame = global_frame + 1.0
        crt_node.shader:send("FrameCount", global_frame)
        _last_frame_count_update = 0.0
    end


    -- print(tostring(node) .." ".. global_frame)

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
    love.graphics.clear()
    love.graphics.setShader()
    
    love.graphics.setCanvas( base_canvas )
    
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

    love.graphics.setCanvas()


    crt_shgraph:draw(base_canvas)
    -- love.graphics.clear()
    -- love.graphics.draw(threshold_shnode.canvas)

    -- love.graphics.draw( base_canvas )
end


function CameraTestOne:joystickaxis(joystick, axis, value )
    if math.abs(value) > 0.1 then -- deadzone
        --
    end
end


return CameraTestOne