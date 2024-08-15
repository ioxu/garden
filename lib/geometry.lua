Geometry = {}

--- Calculates the third vertex of a triangle if the position of two vertices and all three side-lengths are known.
--- @param Ax number x coord of vertex A
--- @param Ay number y coord of vertex A
--- @param Bx number x coord of vertex B
--- @param By number y coord of vertex B
--- @param AB_length number the length between vertices A and B
--- @param AC_length number the length between vertices A and C
--- @param BC_length number the length between vertices B and C
--- @return number Cx, number Cy x and y coords of vertex C
function Geometry.findThirdTriangleVertex( Ax, Ay, Bx, By, AB_length, AC_length, BC_length )
    -- given a trianle vertices A,B,C
    -- vertices A and B are known
    -- lengths AB, AC, BC are known
    -- calculate vertex C
    -- a = length BC
    -- b = length AC
    -- c = length AB (this COULD be calculated inside this function but it is usual to have it at hand)
    -- returns Cx, Cy
    local bb = AC_length^2
    local c_norm = { x= (Bx - Ax)/AB_length, y=(By - Ay)/AB_length }
    local c_projection_length = (bb + AB_length^2 - BC_length^2)/(2*AB_length)
    local h = math.sqrt( bb - c_projection_length^2 )
    local x = Ax + c_projection_length * c_norm.x - h * c_norm.y
    local y = Ay + c_projection_length * c_norm.y + h * c_norm.x
    return x,y
            
end

------------------------------------------------------------------------------------------
-- DUMMY
function Geometry._thirdVertex()
        -- A = inner circle position
    -- B = 1st outer circle position
    -- C = position of 2nd outer circle
    -- a = distance between BC
    -- b = distance between AC
    -- c = distance between AB
    
    -- distance from A to B
    local a = outer_circles[1].radius + rr2
    local b = inner_circle.radius + rr2
    local bb = b^2
    local c = inner_circle.radius + outer_circles[1].radius --vector.distance( inner_circle.x, inner_circle.y, outer_circles[1].x, outer_circles[1].y )
    -- normalised c
    local c_norm = { x= (outer_circles[1].x - inner_circle.x)/c, y=(outer_circles[1].y - inner_circle.y)/c } -- vector.normalised(  )
    -- length of projection of AC onto AB
    local c_proj_l = (bb + c^2 - a^2)/(2*c)
    -- height of the perpendicular 
    local h = math.sqrt( bb - c_proj_l^2 )

    -- local x1 = inner_circle.x + c_proj_l * ((outer_circles[1].x - inner_circle.x)/c) + h * ((outer_circles[1].y-inner_circle.y)/c)
    -- local y1 = inner_circle.y + c_proj_l * ((outer_circles[1].y - inner_circle.y)/c) - h * ((outer_circles[1].x-inner_circle.x)/c)
    
    local x1 = inner_circle.x + c_proj_l * c_norm.x - h * c_norm.y
    local y1 = inner_circle.y + c_proj_l * c_norm.y + h * c_norm.x
    outer_circles[2] = {x=x1, y=y1, radius = rr2}
    
    local x1 = inner_circle.x + c_proj_l * c_norm.x + h * c_norm.y
    local y1 = inner_circle.y + c_proj_l * c_norm.y - h * c_norm.x
    outer_circles[3] = {x=x1, y=y1, radius = rr2}
end
------------------------------------------------------------------------------------------


return Geometry