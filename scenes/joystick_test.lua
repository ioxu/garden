local shaping = require "lib.shaping"
local vector = require "lib.vector"
local tables = require "lib.tables"
local joystick_diagram = require "lib.joystick_diagram"

local JoystickTest ={}

-- init
-- focus
-- defocus
-- update
-- draw
-- quit
local stick_move_mag = 30
local lstick_pos = {x=200, y= 400}
local font_medium = love.graphics.newFont(15)

------------------------------------------------------------------------------------------
--- @alias side
--- | '"left"' # left stick
--- | '"right"' # right stick

--- draws a tilting circle for a gamepad's joystick
--- @param joystick love.Joystick joystick as returned by love.joystick.getJoysticks()
--- @param side side
--- @param x number x coord
--- @param y number y coord
function draw_joystick( joystick, side, x, y )
    local js_x -- joystick:getGamepadAxis( "leftx" )
    local js_y -- joystick:getGamepadAxis( "lefty" )
    local stick_button_side

    if side == "left" then
        js_x = joystick:getGamepadAxis( "leftx" )
        js_y = joystick:getGamepadAxis( "lefty" )
        stick_button_side = "leftstick"
    elseif side == "right" then
        js_x = joystick:getGamepadAxis( "rightx" )
        js_y = joystick:getGamepadAxis( "righty" )
        stick_button_side = "rightstick"
    end

    local stick_button_colour = {0.2, 0.2, 0.2, 1.0}
    local stick_button_down = 1.0
    local _, stick_button_index, _ = joystick:getGamepadMapping(stick_button_side)
    if joystick:isDown( stick_button_index ) then
        -- love.graphics.circle("line", x, y, 12)
        stick_button_colour = {1.0, 1.0, 1.0, 1.0}
        stick_button_down = 3.0
    end

    love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
    love.graphics.circle("line", x, y, 30)

    local n_lstick_dir_x, n_lstick_dir_y = vector.normalise( js_x, js_y )
    local lstick_mag = 0.0
    
    love.graphics.push()
    love.graphics.translate(
        x + js_x  * stick_move_mag,
        y + js_y * stick_move_mag
    )
    
    if n_lstick_dir_x ~= nil and n_lstick_dir_y ~= nil then
        love.graphics.rotate( math.atan2( n_lstick_dir_y, n_lstick_dir_x ) )
        lstick_mag = vector.length( js_x, js_y )
    end
    
    -- stick button inner
    love.graphics.setColor( stick_button_colour )
    love.graphics.ellipse("line",
        lstick_mag * 10,
        0,
        3 * stick_button_down * shaping.remap( shaping.bias(math.min(lstick_mag, 1.0), 0.25) , 0, 1.0, 1.0, 0.65 ),
        3 * stick_button_down
    )

    -- stick elipse outer
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    love.graphics.ellipse("line",
        0.0,
        0.0,
        30 * shaping.remap( shaping.bias(math.min(lstick_mag, 1.0), 0.25) , 0, 1.0, 1.0, 0.65 ),
        30
    )
    love.graphics.pop()

end

local rect_shape = {
    -14, -6,
    14, -6,
    16, -4,
    16, 4,
    14, 6,
    -14, 6,
    -16, 4,
    -16,-4,
    -14, -6
}


function stretch_rect_shape( amount )
    local rect_shape = {
        -14, -6 -amount,
         14, -6 -amount,
         16, -4 -amount,
         16,  4,
         14,  6,
        -14,  6,
        -16,  4,
        -16, -4 -amount,
        -14, -6 -amount
    }
    return rect_shape
end

--- @param joystick love.Joystick joystick as returned by love.joystick.getJoysticks()
--- @param side side
--- @param x number x coord
--- @param y number y coord
function draw_bumper_and_trigger( joystick, side, x, y )
    local bumper_button_name
    local trigger_amount
    if side == "left" then
        bumper_button_name = "leftshoulder"
        trigger_amount = joystick:getGamepadAxis( "triggerleft" )
    elseif side == "right" then
        bumper_button_name = "rightshoulder"
        trigger_amount = joystick:getGamepadAxis( "triggerright" )
    end

    local tc = shaping.remap(trigger_amount, 0, 1, 0.2, 1.0)

    love.graphics.setColor(0.2,0.2,0.2,1)
    local _, bumper_button_index, _ = joystick:getGamepadMapping( bumper_button_name )
    if joystick:isDown( bumper_button_index ) then
        love.graphics.setColor(1,1,1,1)
    end
    love.graphics.push()
    love.graphics.translate( x,y )
    love.graphics.line(rect_shape)
    
    love.graphics.setColor(0.2,0.2,0.2,1)
    if trigger_amount > 0.02 then
        love.graphics.setColor(tc,tc,tc,1)
    end
    love.graphics.translate( 0, -25 )
    love.graphics.line( stretch_rect_shape( trigger_amount * 80 ) )
    love.graphics.pop()
end


local small_rect_shape = {
    -4, -12,
    4, -12,
    6, -10,
    6, 10,
    4, 12,
    -4, 12,
    -6, 10,
    -6,-10,
    -4, -12
}


--- @param joystick love.Joystick joystick as returned by love.joystick.getJoysticks()
--- @param x number x coord
--- @param y number y coord
--- @param xoff number x offset for the start button
function draw_back_and_start(joystick, x, y, xoff)
    local _, back_button_index, _ = joystick:getGamepadMapping("back")
    local _, start_button_index, _ = joystick:getGamepadMapping("start")
    love.graphics.setColor(.2,.2,.2,1)
    love.graphics.push()
    love.graphics.translate( x,y )
    if joystick:isDown(back_button_index) then
       love.graphics.setColor(1,1,1,1) 
    end
    love.graphics.line( small_rect_shape )
    love.graphics.translate( xoff,0 )
    love.graphics.setColor(0.2,0.2,0.2,1.0)
    if joystick:isDown(start_button_index) then
        love.graphics.setColor(1,1,1,1) 
    end 
    love.graphics.line( small_rect_shape )
    love.graphics.pop()
end


--- @param joystick love.Joystick joystick as returned by love.joystick.getJoysticks()
--- @param x number x coord
--- @param y number y coord
function draw_face_buttons( joystick, x, y )
    local spacing = 30
    local radius = 10
    local bottom_pos = {x=x, y=y+spacing}
    local right_pos = {x=x+spacing, y=y}
    local left_pos = {x=x-spacing, y=y}
    local top_pos = {x=x, y=y-spacing}
    love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
    love.graphics.circle("line", bottom_pos.x, bottom_pos.y, radius)
    love.graphics.circle("line", right_pos.x, right_pos.y, radius)
    love.graphics.circle("line", left_pos.x, left_pos.y, radius)
    love.graphics.circle("line", left_pos.x, left_pos.y, radius)
    love.graphics.circle("line", top_pos.x, top_pos.y, radius)
    love.graphics.setColor(1, 1, 1, 1.0)
    local _, a_index, _ = joystick:getGamepadMapping("a")
    if joystick:isDown( a_index ) then -- bottom
        love.graphics.circle("line", bottom_pos.x, bottom_pos.y, radius)
    end
    local _, b_index, _ = joystick:getGamepadMapping("b")
    if joystick:isDown(b_index) then -- right
        love.graphics.circle("line", right_pos.x, right_pos.y, radius)
    end
    local _, x_index, _ = joystick:getGamepadMapping("x")
    if joystick:isDown(x_index) then -- left
        love.graphics.circle("line", left_pos.x, left_pos.y, radius)
    end
    local _, y_index, _ = joystick:getGamepadMapping("y")
    if joystick:isDown(y_index) then -- top
        love.graphics.circle("line", top_pos.x, top_pos.y, radius)
    end
end


-- a little dpad button shape,
-- like the square arrow dpad buttons on a Playstation DS4
local dpup_line = {
    0, -20,
    -10, -10,
    -10, 8, -- bottom left
    -8, 10, -- bottom left chamfer
    8, 10, -- bottom right chamfer
    10, 8, -- bottom right
    10, -10,
    0, -20
}

local dpup_line = {
    2, -18,
    -2, -18,
    -10, -10,
    -10, 8, -- bottom left
    -8, 10, -- bottom left chamfer
    8, 10, -- bottom right chamfer
    10, 8, -- bottom right
    10, -10,
    2, -18
}


--- @param joystick love.Joystick joystick as returned by love.joystick.getJoysticks()
--- @param x number x coord
--- @param y number y coord
function draw_dpad_buttons( joystick, x, y )
    local spacing = 30
    local radius = 10
    local down_pos = {x=x, y=y+spacing}
    local right_pos = {x=x+spacing, y=y}
    local left_pos = {x=x-spacing, y=y}
    local up_pos = {x=x, y=y-spacing}
    love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
    love.graphics.setColor(1, 1, 1, 1.0)
    local _, dpdown_index, _ = joystick:getGamepadMapping("dpdown")
    if joystick:isDown( dpdown_index ) then -- bottom
        love.graphics.setColor(1, 1, 1, 1.0)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
    end
    love.graphics.push()
    love.graphics.translate(down_pos.x, down_pos.y)
    love.graphics.line(dpup_line)
    love.graphics.pop()

    local _, dpright_index, _ = joystick:getGamepadMapping("dpright")
    if joystick:isDown(dpright_index) then -- right
        love.graphics.setColor(1, 1, 1, 1.0)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
    end
    love.graphics.push()
    love.graphics.translate(right_pos.x, right_pos.y)
    love.graphics.rotate( - math.pi / 2.0 )
    love.graphics.line(dpup_line)
    love.graphics.pop()

    local _, dpleft_index, _ = joystick:getGamepadMapping("dpleft")
    if joystick:isDown(dpleft_index) then -- left
        love.graphics.setColor(1, 1, 1, 1.0)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
    end
    love.graphics.push()
    love.graphics.translate(left_pos.x, left_pos.y)
    love.graphics.rotate( math.pi / 2.0 )
    love.graphics.line(dpup_line)
    love.graphics.pop()

    local _, dpup_index, _ = joystick:getGamepadMapping("dpup")
    if joystick:isDown(dpup_index) then -- top
        love.graphics.setColor(1, 1, 1, 1.0)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
    end
    love.graphics.push()
    love.graphics.translate(up_pos.x, up_pos.y)
    love.graphics.rotate( math.pi )
    love.graphics.line(dpup_line)
    love.graphics.pop()
end

local w = 50
local h = 32.5
local tp_rect = {
    -w+2, -h,
    w-2,-h,
    w,-h+2,
    w,h-2,
    w-2,h,
    -w+2,h,
    -w,h-2,
    -w,-h+2,
    -w+2,-h
}

function draw_touchpad(joystick, x, y)
    love.graphics.setColor(0.2,0.2,0.2,1.0)
    -- local _,tp_button_index, _ = joystick:getGamepadMapping( "touchpad" )
    local tp_button_index = 16
    if joystick:isDown(tp_button_index) then
        love.graphics.setColor(1,1,1,1)
    end
    love.graphics.push()
    love.graphics.translate(x,y)
    love.graphics.line( tp_rect )
    love.graphics.pop()
end


function draw_gamepad_diagram( joystick, x, y )
    love.graphics.setColor(0.2,0.2,0.2,1)
    -- local gms = joystick:getGamepadMappingString()
    -- for i,v in pairs( tables.split_by_comma(gms) ) do
    --     love.graphics.print(v, 0, 50 + i*10)
    -- end
    love.graphics.setFont( font_medium )
    local joystick_name = "'"..joystick:getName().."'"
    love.graphics.print( joystick_name, x +18, y +30)
    
    love.graphics.setLineWidth(5.0)
    draw_face_buttons(joystick, x+210, y-60 )
    draw_dpad_buttons(joystick, x-60, y-60 )
    draw_bumper_and_trigger( joystick, "left", x, y - 130 )
    draw_bumper_and_trigger( joystick, "right", x+150, y - 130 )
    draw_back_and_start(joystick, x, y-90, 150)
    draw_touchpad( joystick, x+75, y - 72 )
    draw_joystick(joystick, "left", x, y )
    draw_joystick(joystick, "right", x+150, y )
end

------------------------------------------------------------------------------------------
local lastbutton = "none"





function JoystickTest:init()
    
end

function JoystickTest:update(dt)
    --
end
    

function JoystickTest:draw()
    love.graphics.setLineStyle("smooth")

    love.graphics.setColor(1,1,1,1)
    local joysticks = love.joystick.getJoysticks()
    for i, joystick in ipairs(joysticks) do
        
        draw_gamepad_diagram( joystick, lstick_pos.x, lstick_pos.y )
        
        love.graphics.setColor(0.2,0.2,0.2,1)
        love.graphics.print("last button: "..lastbutton, lstick_pos.x+18, lstick_pos.y + 50)
    
        joystick_diagram.draw_PS4Controller_diagram( joystick, 450, 700, {0.29, 0.20, 0.36, 1.0}, {1.00, 0.73, 0.42, 1.0} )
    end

end

function JoystickTest:joystickpressed(joystick, button)
    lastbutton = button
end




return JoystickTest