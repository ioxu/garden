-- some drawing functions
Draw={}

local gr = love.graphics

-- https://love2d.org/forums/viewtopic.php?t=83295
-- author: Ref
function Draw.dashLine( p1, p2, dash, gap )
    -- direct
    local dy, dx = p2.y - p1.y, p2.x - p1.x
    local an, st = math.atan2( dy, dx ), dash + gap
    local len	 = math.sqrt( dx*dx + dy*dy )
    local nm	 = ( len - dash ) / st
    gr.push()
       gr.translate( p1.x, p1.y )
       gr.rotate( an )
       for i = 0, nm do
          gr.line( i * st, 0, i * st + dash, 0 )
       end
       gr.line( nm * st, 0, nm * st + dash,0 )
    gr.pop()
 end

return Draw

