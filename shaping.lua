-- shaping functions
local Shaping = {}

function Shaping.bias( t, b )
    return ( t/((((1.0/b) - 2.0) * (1.0-t))+1.0) )
end


return Shaping