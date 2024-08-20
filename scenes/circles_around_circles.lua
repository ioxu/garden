local color = require"lib.color"
local shaping = require"lib.shaping"
local vector = require"lib.vector"
local draw = require"lib.draw"
local geometry = require"lib.geometry"

local Circles = {}
Circles.description = "how to place circles around the circumference of a circle\nwith each circle touching their neighbours\nas well as the center circle"

local font_medium = love.graphics.newFont(40)
local global_time = 0

local rng = love.math.newRandomGenerator()
rng:setSeed( os.time() )

local inner_circle = {}
local outer_circles = {}

local is_paused = false

local screen_centre = {love.graphics.getWidth()/2, love.graphics.getHeight()/2}


function Circles:init()
    print("[circles] init")
    love.graphics.setLineStyle("smooth")

    inner_circle = {x = screen_centre[1], y = screen_centre[2], radius = 200}
end

function Circles:update(dt)
    love.graphics.setLineStyle("smooth")

    if is_paused then
        return
    else
        global_time = global_time + dt

        local ss = math.sin( global_time * 1.5 )
        local rr = shaping.remap( ss, -1.0, 1.0, 20.0, 100) --rng:random(10.0, 50.0)
        outer_circles[1] = {x=inner_circle.x, y=inner_circle.y - inner_circle.radius - rr, radius = rr}

        for k=2,15 do

            local ss2 = math.sin( (global_time + k * 3.5 ) * 2.5 )
            -- local ss2 = math.sin( (global_time + k * 3.5 ) * shaping.remap(math.fmod(k*1.7013553,1.0), 0.0, 1.0, 1.5, 4.5 ) )
            local rr2 = shaping.remap( ss2, -1.0, 1.0, 20.0, 100)
            -- local rr2 = shaping.remap( ss2, -1.0, 1.0, 10.0, 20.0)
            
            local Cx, Cy = geometry.findThirdTriangleVertex( inner_circle.x,
                inner_circle.y,
                outer_circles[k-1].x,
                outer_circles[k-1].y,
                inner_circle.radius + outer_circles[k-1].radius,
                inner_circle.radius + rr2,
                outer_circles[k-1].radius + rr2) --,"right" )


            outer_circles[k] = {x=Cx, y=Cy, radius=rr2}
        end

    end
end

local little_circle_margin = 8


function Circles:draw(dt)

    local new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1, 1.0 ), 0.85, 0.05)

    love.graphics.clear( new_r, new_g, new_b )
    local fx = font_medium:getWidth("CIRCLES")
    local fy = font_medium:getHeight()
    love.graphics.setFont(font_medium)
    
    new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 - 0.05, 1.0 ), 0.85, 0.3)
    love.graphics.setColor( new_r, new_g, new_b )
    -- love.graphics.print("CIRCLES", screen_centre[1] - fx/2, screen_centre[2] - fy/2)
    
    love.graphics.setLineWidth(1)
    love.graphics.circle( "line", screen_centre[1], screen_centre[2], 100)
    love.graphics.setLineWidth(4)
    love.graphics.circle( "line", inner_circle.x, inner_circle.y, inner_circle.radius - little_circle_margin )
    
    
    love.graphics.setLineWidth(4)
    new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 + 0.05, 1.0 ), 0.85, 0.3)
    love.graphics.setColor( new_r, new_g, new_b )
    for k,v in pairs(outer_circles) do
        love.graphics.circle("line", v.x, v.y, v.radius - little_circle_margin, 128 )
    end
    
    new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 - 0.1, 1.0 ), 0.3, 0.5)
    love.graphics.setColor( new_r, new_g, new_b, 1.0 )
    
    for k,v in pairs(outer_circles) do
        local cr = math.max(v.radius - little_circle_margin * 3.0, 1.0)
        love.graphics.setLineWidth( math.min(16, cr + little_circle_margin )) -- math.min(16, cr ))
        love.graphics.circle("line", v.x, v.y, cr, 128 )
    end


    
    new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 + 0.3, 1.0 ), 0.85, 0.3)
    love.graphics.setColor( new_r, new_g, new_b )
    love.graphics.setLineWidth(2)
    love.graphics.line( inner_circle.x, inner_circle.y, outer_circles[1].x, outer_circles[1].y )
    
    love.graphics.line( outer_circles[1].x, outer_circles[1].y, outer_circles[2].x, outer_circles[2].y)
    love.graphics.line( inner_circle.x, inner_circle.y, outer_circles[2].x, outer_circles[2].y)
    
    love.graphics.setColor( new_r, new_g, new_b, 0.25 )
    for k = 2,15 do
        draw.dashLine( {x=outer_circles[k-1].x, y=outer_circles[k-1].y}, {x=outer_circles[k].x, y=outer_circles[k].y}, 5, 5 )
        draw.dashLine( {x=inner_circle.x, y=inner_circle.y}, {x=outer_circles[k].x, y=outer_circles[k].y}, 5, 5 )
    end

    new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 - 0.15, 1.0 ), 0.85, 0.3)
    love.graphics.setColor( new_r, new_g, new_b )
    love.graphics.print("CIRCLES", screen_centre[1] - fx/2, screen_centre[2] - fy/2)

end

function Circles:mousepressed(x,y,button,istouch,presses)
    -- print("mouse pressed ", global_time)
end

function Circles:keypressed( key, code, isrepeat )
    if code == "space" then
        is_paused = not is_paused
    end
end
 
return Circles