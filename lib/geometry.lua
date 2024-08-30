local vector = require"lib.vector"
Geometry = {}

math.tau = math.pi * 2.0


function Geometry.closest_point_on_line(x1, y1, x2, y2, px, py)
    -- Vector AB
    local abx = x2 - x1
    local aby = y2 - y1
 
    -- Vector AP
    local apx = px - x1
    local apy = py - y1

    -- Dot products
    local ab_ab = abx * abx + aby * aby
    local ap_ab = apx * abx + apy * aby

    -- Projection scalar
    local t = ap_ab / ab_ab

    -- Clamp t to [0, 1]
    t = math.max(0, math.min(1, t))

    -- Closest point C
    local cx = x1 + t * abx
    local cy = y1 + t * aby

    return cx, cy, t
end


--- Calculates the third vertex of a triangle if the position of two vertices and all three side-lengths are known.
--- @param Ax number x coord of vertex A
--- @param Ay number y coord of vertex A
--- @param Bx number x coord of vertex B
--- @param By number y coord of vertex B
--- @param AB_length number the length between vertices A and B
--- @param AC_length number the length between vertices A and C
--- @param BC_length number the length between vertices B and C
--- @param direction '"left"'|'"right"'? (optional) the direction to choose after the projection
--- @return number Cx, number Cy x and y coords of vertex C
function Geometry.findThirdTriangleVertex( Ax, Ay, Bx, By, AB_length, AC_length, BC_length, direction )
    -- given a trianle vertices A,B,C
    -- vertices A and B are known
    -- lengths AB, AC, BC are known
    -- calculate vertex C
    -- a = length BC
    -- b = length AC
    -- c = length AB (this COULD be calculated inside this function but it is usual to have it at hand)
    -- returns Cx, Cy
    local bb = AC_length^2
    --normalised c
    local c_norm = { x= (Bx - Ax)/AB_length, y=(By - Ay)/AB_length }
    -- length of projection of AC onto AB
    local c_projection_length = (bb + AB_length^2 - BC_length^2)/(2*AB_length)
    -- height of the perpendicular of the projection
    local h = math.sqrt( bb - c_projection_length^2 )
    
    local x,y
    -- there are two solutions
    direction = direction or "right"
    if direction== "right" then
        x = Ax + c_projection_length * c_norm.x - h * c_norm.y
        y = Ay + c_projection_length * c_norm.y + h * c_norm.x
    elseif direction == "left" then
        x = Ax + c_projection_length * c_norm.x + h * c_norm.y
        y = Ay + c_projection_length * c_norm.y - h * c_norm.x
    end


    return x,y
end


--- calculates the angle between tangents drawn from a given external point to a circle
--- @param x1 number circle point x
--- @param y1 number circle point y
--- @param x2 number external point x
--- @param y2 number external point y
--- @param radius number circle's radius
--- @return number sigma the angle between the tangents in radians
function Geometry.subtending_tangents_angle( x1, y1, x2, y2, radius)
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx * dx + dy * dy)
    -- assert( distance > radius, string.format("distance between external point and circle center needs to be greater that the circle's radius (distance is %s, radius is %s)", distance, radius) )
    return 2.0 * math.asin(radius / distance)
end

------------------------------------------------------------------------------------------
-- circles_surrounding_circle

local csc_rng = math.random
local csc_baseseed = os.clock()

--- *circles_surrounding_circle* radius strategy  
--- instanciate like this before passing to `Geometry.circles_surrounding_circle()`:  
--- `local rstrat = random_radius_strategy(15.0, 55.0)`  
--- @param rmin number minimum random radius
--- @param rmax number maximum random radius
--- @param seed number|nil optional seed for RNG
--- @return function closure the strategy closure for circles_surrounding_circle
function Geometry.csc_random_radius_strategy( rmin, rmax, seed )
    seed = seed or csc_baseseed
    math.randomseed(seed)
    return function(cx, cy, radius)
        return rmin + (rmax - rmin) * ((csc_rng() - 0.0) / (1.0 - 0.0))
    end
end


function Geometry.csc_constant_radius_strategy( constant_radius )
    return function(cx, cy, radius)
        return constant_radius or 25.25
    end
end

--- @alias CircleType Circle
--- @class Circle
--- @field x number x coord of new circle
--- @field y number y coord of new circle
--- @field radius number radius of new circle

--- Creates a table of Circles surrounding a centre circle  
--- This function generates a table of circles tangent to an inner circle, and tangent to their neighbouring outer circles.  
---
--- It uses the *Strategy Pattern* to let a client define how new radii are generated.  
--- This is passed in via the `new_circles_radius_strategy` argument.  
---
--- Returns an indexed table of [Circle](lua://CircleType) tables, e.g:  
--- `{1 = {x=0.0, y= 0.0, radius = 1.0}, 2={x= 0.0, y = 0.0, radius= 3.0}, ... }`  
--- ---
--- @param cx number the center circle's x coord
--- @param cy number the center circle's y coord
--- @param radius number the center circle's radius
--- @param new_circles_radius_strategy function the generator function (closure) for the new circles' radii
--- @return table<index, Circle> #An indexed table of the cenerated [Circle](lua://CircleType) objects {1=Circle1, 2=Circle2 ...}
function Geometry.circles_surrounding_circle( cx, cy, radius, new_circles_radius_strategy)
    local circles = {} -- return table
    local i = 1

    local new_pos_x, new_pos_y

    local begin_angle = 0.0 -- the first subtended angle of the first outer circle (/-2 to get the first half-cirle filling the outer)
    local this_circles_subtended_angle = -1.0 -- the 'leading' subtended tangent for the latest outer circle
    local this_centre_dir_x, this_centre_dir_y -- the direction from the innner circle centre to the new outer circle centre
    local new_centre_angle -- temp new angle from innner circle centre to the new outer circle centre
    local this_centre_angle = 0.0 -- final angle from circle centre to the new outer circle centre
    local new_subtended_angle -- current 'leading' subtended tangent for latest outer circle
    local new_trailing_subtended_angle -- current 'leading' subtended tangent for latest outer circle
       
    -- if the latest outer circle's edge doesn't exceed the first outer circle's trailing edge
    while (this_circles_subtended_angle < math.tau + begin_angle  ) do

        -- get new radius from strategy
        local new_radius = new_circles_radius_strategy( cx, cy, radius)
        if i == 1 then
            -- FIRST CIRCLE
            new_pos_x = cx + radius + new_radius
            new_pos_y = cy
            circles[1] = { x= new_pos_x, y = new_pos_y, radius = new_radius}
            begin_angle = -0.5 * Geometry.subtending_tangents_angle( cx, cy, new_pos_x, new_pos_y, new_radius )
        else
            -- THE REST OF THE CIRCLES
            -- get next outer circle based on radii
            new_pos_x, new_pos_y = Geometry.findThirdTriangleVertex( cx, cy,
                circles[i-1].x,
                circles[i-1].y,
                radius + circles[i-1].radius,
                radius + new_radius,
                new_radius + circles[i-1].radius,
                "right"
            )
        
            this_centre_dir_x, this_centre_dir_y = vector.normalise( new_pos_x - cx, new_pos_y - cy )

            -- use atan2 to convert new circle direction to a polar angle, remapped from
            -- -pi .. pi, to 0.0 to 1.0, then 0.0 to tau
            new_centre_angle = math.atan2( this_centre_dir_y, this_centre_dir_x  )
            new_centre_angle = ((new_centre_angle + math.pi)/math.tau + 0.5)%1
            new_centre_angle = new_centre_angle * math.tau

            -- full rotation accumulation check (this_centre_angle becomes small again after passing 2pi.)
            if new_centre_angle > this_centre_angle then
                this_centre_angle = new_centre_angle
            else
                this_centre_angle = new_centre_angle + math.tau
            end
            
            -- find angle of new leading tangent
            local st = Geometry.subtending_tangents_angle( cx, cy, new_pos_x, new_pos_y, new_radius )/2.0
            new_subtended_angle = this_centre_angle + st
            new_trailing_subtended_angle = this_centre_angle - st
            -- sometimes if the new circle is smaller than the previous circle, the tangent is at less of an angle
            if new_subtended_angle > this_circles_subtended_angle then
                this_circles_subtended_angle =  new_subtended_angle
            end

            -- if this new leading tangent doesn't surpass the 1st circle's trailing tangent, add the circle
            if this_circles_subtended_angle < math.tau + begin_angle then
                circles[i] =  { x= new_pos_x, y = new_pos_y, radius = new_radius }
            else
                --draw filler circle
                -- radius is found by rule of sines (SOH) between centre-distance between inner circle and outer circle (hypotenuse),
                -- angle at inner circle centre (half subtending angle, found by the gap)
                -- and the unsolved outer circle radius (opposite)
                -- the position is solved once the radius is found.
                local theta = (math.tau + begin_angle) - new_trailing_subtended_angle
                theta = theta/2.0
                local r = (radius * math.sin( theta )) / ( 1 -  math.sin( theta ) )
                local new_x = cx + (radius + r)*math.cos( theta - begin_angle )
                local new_y = cy - (radius + r)*math.sin( theta - begin_angle )
                circles[i] = {x = new_x, y=new_y, radius = r}
            end
        end
        i = i+1
    end

    return circles
end


return Geometry