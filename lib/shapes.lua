local Shapes = {}
---@alias point {x:number, y:number} a sinlge point table 
---@alias pointList point[] a list of points of form `{{x1,y1}, .. {xn, yn}}`

---draws lines along a table of points, according to a distance along the shape.
---the distance can be normalised using the return value **totalDistance** from `calc_distances(points)`
---@param distance number the distance along the shape to draw lines, in the same units as the points
---@param points pointList a table of points
---@param distances table  a table of the distances from between points
function Shapes.draw_line_interp_points(distance, points, distances)
    local accumulatedDistance = 0

    -- Find the current segment based on the distance covered
    for i = 1, #distances do
        local segmentDistance = distances[i]
        
        if accumulatedDistance + segmentDistance >= distance and
            distance ~= 0.0
            and distance > accumulatedDistance
            then
            local segmentProgress = (distance - accumulatedDistance) / segmentDistance
            local p1 = points[i]
            local p2 = points[i + 1]
            
            local x = p1[1] + (p2[1] - p1[1]) * segmentProgress
            local y = p1[2] + (p2[2] - p1[2]) * segmentProgress
            
            love.graphics.line( p1[1], p1[2], x, y )
        end
        
        accumulatedDistance = accumulatedDistance + segmentDistance

        if distance > accumulatedDistance then
            local p1 = points[i]
            local p2 = points[i + 1]
            love.graphics.line( p1[1], p1[2], p2[1], p2[2] )
        end
    end
end 


---calculate the distances from point-to-point from a table of points
---@param points pointList
---@return table distances a table of the distances from point to point
---@return number totalDistance total accumulcated distance
function Shapes.calc_distances(points)
    local distances = {}
    local totalDistance = 0
    for i =1, #points -1 do
        local dx = points[i+1][1] - points[i][1]
        local dy = points[i+1][2] - points[i][2]
        local dist = math.sqrt( dx * dx + dy * dy )
        distances[i] = dist
        totalDistance = totalDistance + dist
    end
    return distances, totalDistance
end


return Shapes