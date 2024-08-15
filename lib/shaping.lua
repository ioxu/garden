-- shaping functions
local Shaping = {}


function Shaping.bias( t, b )
    return ( t/((((1.0/b) - 2.0) * (1.0-t))+1.0) )
end


--function Shaping.remap( value, start1, start2, stop1,  stop2)
function Shaping.remap( value, start1, stop1, start2, stop2)
    return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1))
end


return Shaping