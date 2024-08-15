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

local screen_centre = {love.graphics.getWidth()/2, love.graphics.getHeight()/2}

function Circles:init()
    print("[circles] init")
    love.graphics.setLineStyle("smooth")

    inner_circle = {x = screen_centre[1], y = screen_centre[2], radius = 200}
end

function Circles:update(dt)
    love.graphics.setLineStyle("smooth")
    global_time = global_time + dt

    local ss = math.sin( global_time * 1.5 )
    local rr = shaping.remap( ss, -1.0, 1.0, 20.0, 100) --rng:random(10.0, 50.0)
    outer_circles[1] = {x=inner_circle.x, y=inner_circle.y - inner_circle.radius - rr, radius = rr}
    local ss2 = math.sin( (global_time + 0.735)* 2.5 )
    local rr2 = shaping.remap( ss2, -1.0, 1.0, 20.0, 100)

    -- A = inner circle position
    -- B = 1st outer circle position
    -- C = position of 2nd outer circle
    -- a = distance between BC
    -- b = distance between AC
    -- c = distance between AB
    
    -- distance from A to B
    -- local a = outer_circles[1].radius + rr2
    -- local b = inner_circle.radius + rr2
    -- local bb = b^2
    -- local c = inner_circle.radius + outer_circles[1].radius --vector.distance( inner_circle.x, inner_circle.y, outer_circles[1].x, outer_circles[1].y )
    -- -- normalised c
    -- local c_norm = { x= (outer_circles[1].x - inner_circle.x)/c, y=(outer_circles[1].y - inner_circle.y)/c } -- vector.normalised(  )
    -- -- length of projection of AC onto AB
    -- local c_proj_l = (bb + c^2 - a^2)/(2*c)
    -- -- height of the perpendicular 
    -- local h = math.sqrt( bb - c_proj_l^2 )
    
    -- local x1 = inner_circle.x + c_proj_l * c_norm.x - h * c_norm.y
    -- local y1 = inner_circle.y + c_proj_l * c_norm.y + h * c_norm.x
    -- outer_circles[2] = {x=x1, y=y1, radius = rr2}
    
    -- local x1 = inner_circle.x + c_proj_l * c_norm.x + h * c_norm.y
    -- local y1 = inner_circle.y + c_proj_l * c_norm.y - h * c_norm.x
    -- outer_circles[3] = {x=x1, y=y1, radius = rr2}

    local Cx, Cy = geometry.findThirdTriangleVertex( inner_circle.x,
                                                inner_circle.y,
                                                outer_circles[1].x,
                                                outer_circles[1].y,
                                                inner_circle.radius + outer_circles[1].radius,
                                                inner_circle.radius + rr2,
                                                outer_circles[1].radius + rr2 )
    print("oc2",Cx, Cy)
    outer_circles[2] = {x=Cx, y=Cy, radius=rr2}

end

local little_circle_margin = 4

function Circles:draw(dt)

    local new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1, 1.0 ), 0.85, 0.05)

    love.graphics.clear( new_r, new_g, new_b )
    local fx = font_medium:getWidth("CIRCLES")
    local fy = font_medium:getHeight()
    love.graphics.setFont(font_medium)
    
    new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 - 0.05, 1.0 ), 0.85, 0.3)
    love.graphics.setColor( new_r, new_g, new_b )
    love.graphics.print("CIRCLES", screen_centre[1] - fx/2, screen_centre[2] - fy/2)
    
    love.graphics.setLineWidth(1)
    love.graphics.circle( "line", screen_centre[1], screen_centre[2], 100)
    love.graphics.setLineWidth(4)
    love.graphics.circle( "line", inner_circle.x, inner_circle.y, inner_circle.radius - little_circle_margin )
    
    new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 + 0.05, 1.0 ), 0.85, 0.3)
    love.graphics.setColor( new_r, new_g, new_b )
    for k,v in pairs(outer_circles) do
        love.graphics.circle("line", v.x, v.y, v.radius - little_circle_margin )
    end
    
    
    new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 + 0.3, 1.0 ), 0.85, 0.3)
    love.graphics.setColor( new_r, new_g, new_b )
    love.graphics.setLineWidth(2)
    love.graphics.line( inner_circle.x, inner_circle.y, outer_circles[1].x, outer_circles[1].y )

    draw.dashLine( {x=outer_circles[1].x, y=outer_circles[1].y}, {x=outer_circles[2].x, y=outer_circles[2].y}, 5, 5 )
    draw.dashLine( {x=inner_circle.x, y=inner_circle.y}, {x=outer_circles[2].x, y=outer_circles[2].y}, 5, 5 )
end

function Circles:mousepressed(x,y,button,istouch,presses)
    print("mouse pressed ", global_time)
end

return Circles