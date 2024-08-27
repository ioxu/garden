local Vector = {}


function Vector.rotatePoint(px, py, center_x, center_y, angle)

    -- Translate the point to the origin (relative to the center of the screen)
    local translatedX = px - center_x
    local translatedY = py - center_y

    -- Apply the rotation matrix
    local cosTheta = math.cos(angle)
    local sinTheta = math.sin(angle)
    local rotatedX = translatedX * cosTheta - translatedY * sinTheta
    local rotatedY = translatedX * sinTheta + translatedY * cosTheta

    -- Translate the point back to the center
    local finalX = rotatedX + center_x
    local finalY = rotatedY + center_y

    return finalX, finalY
end


function Vector.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end


function Vector.normalise(x1, y1)
	local l = Vector.distance( 0.0, 0.0, x1, y1 )
	if l > 0 then
		return x1 / l, y1 / l
    else
        return nil
    end
end


return Vector