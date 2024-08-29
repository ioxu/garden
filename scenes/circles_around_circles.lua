local color = require"lib.color"
local shaping = require"lib.shaping"
local vector = require"lib.vector"
local draw = require"lib.draw"
local geometry = require"lib.geometry"
local handles = require"lib.handles"
local signal = require"lib.signal"
math.tau = 2*math.pi

local Circles = {}
Circles.scene_name = "circles_around_circles"
Circles.description = "how to place circles around the circumference of a circle\nwith each circle touching their neighbours\nas well as the center circle"

local font_small = love.graphics.newFont(10)
local font_medium_small = love.graphics.newFont(20)
local font_medium = love.graphics.newFont(40)
local global_time = 0

local rng = love.math.newRandomGenerator()
local base_rng_seed = os.time()
rng:setSeed( base_rng_seed )

local inner_circle = {}
local outer_circles = {}

local is_paused = false

local screen_centre = {love.graphics.getWidth()/2, love.graphics.getHeight()/2}

------------------------------------------------------------------------------------------
-- ANIMATED CIRCLES
local do_animated_circles = false


------------------------------------------------------------------------------------------
-- INTERACTIVE CIRCLES
-- hold handles
local widgets = {}
local interactive_circle_radius = 200
local outer_circle_diameter = 200
------------------------------------------------------------------------------------------
-- Strategy Pattern:
-- create a closure to pass to geometry.circles_surrounding_circle's new_circles_radius_strategy
-- argument

--- local client random radius strategy closure
--- @param rmin number random min
--- @param rmax number random max
local function random_radius_strategy( rmin, rmax )
    return function(cx, cy, radius)
        rr = shaping.remap(rng:random(), 0.0, 1.0, rmin, rmax)
        -- print(string.format("[Random_Radius_Strategy] rmin: %s rmax: %s, %s", rmin, rmax, rr))
        return rr
    end
end

--- local client constant radius strategy closure
--- @param constant_radius number constnt radius to use
local function constant_radius_strategy( constant_radius )
    return function(cx, cy, radius)
        return constant_radius or 25.25
    end
end

-- create the parameterised instance of the closure
local rstrat = constant_radius_strategy( outer_circle_diameter )
-- local rstrat = random_radius_strategy(15.0, 55.0)
-- local rstrat = geometry.csc_random_radius_strategy(15.0, 55.0)

-- generated circles
local circs = {}

function regenerate_circs()
    rng:setSeed(base_rng_seed)
    circs = geometry.circles_surrounding_circle(
        widgets["circle_centre_control"].x,
        widgets["circle_centre_control"].y,
        interactive_circle_radius,
        rstrat
        )
end

local radius_controls_signals = signal:new()


------------------------------------------------------------------------------------------
-- handle events
function on_handle_highlighted(handle)
    print(string.format("'%s' highlighted", handle.name))
end


function on_handle_unhighlighted(handle)
    print(string.format("'%s' unhighlighted", handle.name))
end


function on_handle_pressed(handle)
    print(string.format("'%s' pressed", handle.name))
end


function on_handle_released(handle)
    print(string.format("'%s' released", handle.name))
end

function on_handle_dragged(handle, dx, dy)
    print(string.format("'%s' dragged. dx: %i, dy: %i", handle.name, dx, dy))
end


------------------------------------------------------------------------------------------

function Circles:init()
    print("[circles] init")
    love.graphics.setLineStyle("smooth")

    inner_circle = {x = screen_centre[1], y = screen_centre[2], radius = 200}

    local handle_one = handles.CircleHandle:new("circle_centre_handle",300,screen_centre[2], 7.5)
    handle_one.label = "center"
    handle_one.signals:register("highlighted", on_handle_highlighted)
    handle_one.signals:register("unhighlighted", on_handle_unhighlighted)
    handle_one.signals:register("pressed", on_handle_pressed)
    handle_one.signals:register("released", on_handle_released)
    handle_one.signals:register("dragged", on_handle_dragged)
    widgets["circle_centre_control"] = handle_one


    local handle_radius_control = handles.CircleHandle:new("circle_radius_handle",300+interactive_circle_radius,300, 7.5)
    handle_radius_control.label = "r"
    handle_radius_control.label_offset = {x=-12, y=0.0}
    widgets["circle_radius_control"] = handle_radius_control
    
    local handle_outer_circle_diameter = handles.CircleHandle:new("outer_circle_diameter", 300+interactive_circle_radius+outer_circle_diameter, 300, 7.5)
    handle_outer_circle_diameter.label = "d"
    handle_outer_circle_diameter.label_offset = {x=12, y=0.0}
    widgets["outer_circle_diameter_control"] = handle_outer_circle_diameter

    radius_controls_signals:register( "updated", regenerate_circs )
    regenerate_circs()
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

    widgets["circle_radius_control"].y = widgets["circle_centre_control"].y
    widgets["outer_circle_diameter_control"].y = widgets["circle_centre_control"].y
    
    if widgets["circle_centre_control"].dragging then
        radius_controls_signals:emit("updated")
    end

    if not widgets["circle_radius_control"].dragging then
        widgets["circle_radius_control"].x = widgets["circle_centre_control"].x + interactive_circle_radius
    else
        radius_controls_signals:emit("updated")
        interactive_circle_radius = math.abs( widgets["circle_radius_control"].x - widgets["circle_centre_control"].x )
    end
    
    if not widgets["outer_circle_diameter_control"].dragging then
        widgets["outer_circle_diameter_control"].x = widgets["circle_radius_control"].x + outer_circle_diameter

    else
        radius_controls_signals:emit("updated")
        outer_circle_diameter = math.abs( widgets["outer_circle_diameter_control"].x - widgets["circle_radius_control"].x )
        -- rstrat = random_radius_strategy((outer_circle_diameter/2.0)*0.1, outer_circle_diameter/2.0)
        -- rstrat = geometry.csc_random_radius_strategy((outer_circle_diameter/2.0)*0.1, outer_circle_diameter/2.0)--, base_rng_seed)
        rstrat = constant_radius_strategy( outer_circle_diameter/2.0 )
    end
end



local little_circle_margin = 8





------------------------------------------------------------------------------------------
function Circles:draw(dt)

    local new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1, 1.0 ), 0.85, 0.05)
    love.graphics.clear( new_r, new_g, new_b )
    love.graphics.setLineWidth(1.0)

    if do_animated_circles then
        -- animated circles around circles
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
        

        local average_radius = 0.0
        for k,v in pairs(outer_circles) do
            local cr = math.max(v.radius - little_circle_margin * 3.0, 1.0)
            love.graphics.setLineWidth( math.min(16, cr + little_circle_margin )) -- math.min(16, cr ))
            love.graphics.circle("line", v.x, v.y, cr, 128 )
            average_radius = average_radius + v.radius
        end
        average_radius = average_radius / #outer_circles
        
        
        new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 + 0.3, 1.0 ), 0.85, 0.3)
        love.graphics.setColor( new_r, new_g, new_b )
        love.graphics.setLineWidth(2)
        love.graphics.line( inner_circle.x, inner_circle.y, outer_circles[1].x, outer_circles[1].y )
        
        love.graphics.line( outer_circles[1].x, outer_circles[1].y, outer_circles[2].x, outer_circles[2].y)
        love.graphics.line( inner_circle.x, inner_circle.y, outer_circles[2].x, outer_circles[2].y)
        
        love.graphics.setColor( new_r, new_g, new_b, 0.25 )
        for k = 2,15 do
            draw.dashLine( {x=outer_circles[k-1].x, y=outer_circles[k-1].y}, {x=outer_circles[k].x, y=outer_circles[k].y}, 5, 5, true )
            draw.dashLine( {x=inner_circle.x, y=inner_circle.y}, {x=outer_circles[k].x, y=outer_circles[k].y}, 5, 5, true )
        end

        new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 - 0.15, 1.0 ), 0.85, 0.3)
        love.graphics.setColor( new_r, new_g, new_b )
        love.graphics.print("CIRCLES", screen_centre[1] - fx/2, screen_centre[2] - fy/2)
        
        new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 - 0.25, 1.0 ), 0.85, 0.3)
        love.graphics.setColor( new_r, new_g, new_b )
        love.graphics.setFont(font_medium_small)
        love.graphics.print(string.format("inner circle radius: %s\naverage radius: %0.2f", inner_circle.radius, average_radius), 20, 50)
    end
    
    --------------------------------------------------------------------------------------

    
    -- interactive cricle
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(1.0)

    local wcc_x = widgets["circle_centre_control"].x
    local wcc_y = widgets["circle_centre_control"].y
    local wcc_r = widgets["circle_centre_control"].radius

    local st = geometry.subtending_tangents_angle( wcc_x,
                                                    wcc_y,
                                                    wcc_x + interactive_circle_radius,
                                                    wcc_y,
                                                    widgets["circle_radius_control"].radius
    )
    
    -- draw main inner circle
    st = st/2.0
    love.graphics.arc("line", "open",
            wcc_x,
            wcc_y,
            interactive_circle_radius,
            (2*math.pi) - st, st)
    
            
    local oc_r = (widgets["outer_circle_diameter_control"].x - widgets["circle_radius_control"].x) / 2.0
    local oc_x = widgets["circle_radius_control"].x + oc_r
    local oc_rr = widgets["outer_circle_diameter_control"].x - wcc_x
    local st2 = geometry.subtending_tangents_angle( widgets["outer_circle_diameter_control"].x,
                                                    widgets["outer_circle_diameter_control"].y,
                                                    oc_x,
                                                    widgets["outer_circle_diameter_control"].y,
                                                    widgets["outer_circle_diameter_control"].radius
    )
    
    local st2 = st2/2.0                                                    

    -- draw final outer circle diameter circle
    love.graphics.arc("line", "open",
                        oc_x,
                        widgets["outer_circle_diameter_control"].y,
                        oc_r,
                        math.pi-st2, st2, 32
    )

    love.graphics.arc("line", "open",
                    oc_x,
                    widgets["outer_circle_diameter_control"].y,
                    oc_r,
                    (2*math.pi)-st2, math.pi +st2, 32
    )

    love.graphics.setColor(0.00,0.70,0.70, 0.5)
    
    -- draw actual circles
    love.graphics.setLineWidth(3)
    for k,v in pairs(circs) do
        love.graphics.circle("line", v.x,v.y,v.radius-1.5)
    end
    
    -- draw fullness angles
    love.graphics.setLineWidth(1)
    local tt = 0.0
    local ll = 0.0
    for k,v in pairs(circs) do
        -- to centres
        love.graphics.setColor(0.00,0.70,0.70, 0.25)
        local dir_x, dir_y = v.x - wcc_x, v.y - wcc_y
        -- love.graphics.line( wcc_x, wcc_y, wcc_x+dir_x, wcc_y+dir_y )
        -- to tangent edges
        love.graphics.setColor(0.90,0.70,0.70, 0.25)
        local oc_st_angle = geometry.subtending_tangents_angle( wcc_x, wcc_y, v.x, v.y, v.radius ) / 2.0
        dir_x, dir_y = vector.normalise( dir_x, dir_y )
        local st_dir_x, st_dir_y = vector.rotatePoint( dir_x*oc_rr, dir_y*oc_rr, 0.0, 0.0, oc_st_angle )
        -- love.graphics.line( wcc_x, wcc_y, wcc_x+st_dir_x, wcc_y+st_dir_y )
        
        -- draw the GAP for the final MISSING circle
        if k == 1 then
            -- the first circle
            tt = oc_st_angle * -1
        elseif k == #circs then 
            -- the last circle
            ll = math.atan2( st_dir_y, st_dir_x )
            love.graphics.setColor(1,1,1,0.05)
            love.graphics.arc("fill", "pie", wcc_x, wcc_y, oc_rr, tt, ll )
        end
    end
    
    -- draw the rest of the ornaments
    love.graphics.setLineWidth(3)
    love.graphics.setColor(1,1,1,0.5)
    love.graphics.setFont( font_small )
    local n_circles_text = string.format("%s outer circles", #circs)
    local n_circles_text_width = font_small:getWidth( n_circles_text )
    love.graphics.print(n_circles_text, wcc_x - n_circles_text_width/2.0, wcc_y - 24 )
    love.graphics.points( oc_x, widgets["outer_circle_diameter_control"].y )
    draw.dashLine( {x=wcc_x + wcc_r, y=wcc_y},
                    {x=widgets["circle_radius_control"].x - widgets["circle_radius_control"].radius , y=widgets["circle_radius_control"].y},
                    5, 5, false )
    local fw = font_small:getWidth( tostring( interactive_circle_radius ) )
    local fh = font_small:getHeight()
    love.graphics.print( tostring(interactive_circle_radius),
                    math.floor( math.abs(widgets["circle_radius_control"].x - wcc_x)/2.0 + wcc_x - (fw/2.0) ),
                    widgets["circle_radius_control"].y + 2  )
    
    -- draw interactive controls
    for k,v in pairs(widgets) do
        v:draw()
    end



    --------------------------------------------------------------------------------------
end


function Circles:mousepressed( x, y, button, istouch, presses )
    for k,w in pairs(widgets) do
        w:mousepressed(x,y,button,istouch,presses)
    end
end


function Circles:mousereleased( x, y, button, istouch, presses )
    for k,w in pairs(widgets) do
        w:mousereleased( x, y, button, istouch, presses )
    end
end


function Circles:mousemoved( x, y, dx, dy, ...)
    -- print("[Circles]:mousemoved ", x, y)
    for k,w in pairs(widgets) do
        w:mousemoved( x, y, dx, dy, ...)
    end
end


function Circles:keypressed( key, code, isrepeat )
    if code == "space" then
        is_paused = not is_paused
    end
end


return Circles