local vector = require"lib.vector"
Geometry = {}

math.tau = math.pi * 2.0

--- Calculates the third vertex of a triangle if the position of two vertices and all three side-lengths are known.
--- @param Ax number x coord of vertex A
--- @param Ay number y coord of vertex A
--- @param Bx number x coord of vertex B
--- @param By number y coord of vertex B
--- @param AB_length number the length between vertices A and B
--- @param AC_length number the length between vertices A and C
--- @param BC_length number the length between vertices B and C
--- @param direction '"left"'|'"right"' the direction to choose after the projection
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
--- @class Circle
--- @field x number x coord of new circle
--- @field y number y coord of new circle
--- @field radius number radius of new circle

--- Creates a table of Circles surrounding a centre circle
--- @param cx number the center circle's x coord
--- @param cy number the center circle's y coord
--- @param radius number the center circle's radius
--- @param new_circles_radius_strategy function generator function for the new circles' radii
--- @return table<index, Circle> #A table of the cenerated Circle objects {{x : number, y : number, radius : number}, ...}
function Geometry.circles_surrounding_circle( cx, cy, radius, new_circles_radius_strategy)
    local full = false
    local fullness = 0.0
    local circles = {}

    local i = 1

    local new_pos_x, new_pos_y

    -- the first subtended angle of the first outer circle (/-2 to get the first half-cirle filling the outer)
    -- once a circle 
    local begin_angle = 0.0
    local this_circles_subtended_angle = -1.0
    local this_centre_dir_x, this_centre_dir_y
    local new_centre_angle
    local this_centre_angle = 0.0
    local new_subtended_angle
    -- while not full do
    -- while (fullness < math.tau) do
    
    print("compare", (this_circles_subtended_angle < begin_angle))
    -- while (this_circles_subtended_angle < begin_angle) do
    while (this_circles_subtended_angle < math.tau + begin_angle  ) do
        -- local new_radius = new_circles_radius_strategy( cx, cy, radius)
        local new_radius = new_circles_radius_strategy( cx, cy, radius)
        if i == 1 then
            -- FIRST CIRCLE
            new_pos_x = cx + radius + new_radius
            new_pos_y = cy
            circles[1] = { x= new_pos_x, y = new_pos_y, radius = new_radius}
            -- fullness = fullness + Geometry.subtending_tangents_angle( cx, cy, new_pos_x, new_pos_y, new_radius )
            -- begin_angle = math.tau - (0.5 * Geometry.subtending_tangents_angle( cx, cy, new_pos_x, new_pos_y, new_radius ))
            begin_angle = -0.5 * Geometry.subtending_tangents_angle( cx, cy, new_pos_x, new_pos_y, new_radius )
            print("------------------------------------------------------")
            print("begin_angle", begin_angle)
        else
            new_pos_x, new_pos_y = Geometry.findThirdTriangleVertex( cx, cy,
            circles[i-1].x,
            circles[i-1].y,
            radius + circles[i-1].radius,
            radius + new_radius,
            new_radius + circles[i-1].radius,
            "right"
            )
        
            -- fullness = fullness + Geometry.subtending_tangents_angle( cx, cy, new_pos_x, new_pos_y, new_radius )
            this_centre_dir_x, this_centre_dir_y = vector.normalise( new_pos_x - cx, new_pos_y - cy )
            
            
            new_centre_angle = math.atan2( this_centre_dir_y, this_centre_dir_x  )
            new_centre_angle = ((new_centre_angle + math.pi)/(2*math.pi) + 0.5)%1
            new_centre_angle = new_centre_angle * (2*math.pi)

            -- accumulation check
            if new_centre_angle > this_centre_angle then
                this_centre_angle = new_centre_angle
            else
                this_centre_angle = new_centre_angle + math.tau
            end
            
            print("  this_centre_angle", this_centre_angle, string.format("(%0.2f)", this_centre_angle/math.tau) )
            new_subtended_angle = this_centre_angle + Geometry.subtending_tangents_angle( cx, cy, new_pos_x, new_pos_y, new_radius )/2.0
            print("  new_subtended_angle", new_subtended_angle)
            if new_subtended_angle > this_circles_subtended_angle then
                this_circles_subtended_angle =  new_subtended_angle
            end
            print("this_circles_subtended_angle", this_circles_subtended_angle)
            if this_circles_subtended_angle < math.tau + begin_angle then
                circles[i] =  { x= new_pos_x, y = new_pos_y, radius = new_radius }
            end
            -- end
            print("compare", (this_circles_subtended_angle < math.tau))
        end

        i = i+1
        -- if i == 10 then
        --     print("---- break")
        --     break
        -- end
    end

    return circles
end


return Geometry