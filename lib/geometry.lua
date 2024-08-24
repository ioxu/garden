Geometry = {}

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


return Geometry