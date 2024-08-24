-- some drawing functions
Draw={}

local gr = love.graphics

-- https://love2d.org/forums/viewtopic.php?t=83295
-- author: Ref

--- draw an immediate mode dashed line
--- @param p1 table point one in {x=0.0, y=0.0} form
--- @param p2 table point two in {x=0.0, y=0.0} form
--- @param dash number length of dash
--- @param gap number length of gap
--- @param last_dash true|false draw an additional last dash at the end
function Draw.dashLine( p1, p2, dash, gap, last_dash )
    -- direct
    --last_dash = last_dash or false
   if last_dash == nil then last_dash = true end
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
      if last_dash then gr.line( nm * st, 0, nm * st + dash,0 ) end
   gr.pop()
end

return Draw

