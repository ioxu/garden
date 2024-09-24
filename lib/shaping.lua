-- shaping functions
local Shaping = {}

---common bias
---@param t number value in
---@param b number bias amount 0.0 - 1.0. 0.5 leaves the value unchanged
---@return number
function Shaping.bias( t, b )
    return ( t/((((1.0/b) - 2.0) * (1.0-t))+1.0) )
end


---remap one range to another, does not clamp
---@param value number
---@param start1 number
---@param stop1 number
---@param start2 number
---@param stop2 number
---@return number
function Shaping.remap( value, start1, stop1, start2, stop2)
    return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1))
end

---comment
---@param t1 table
---@param t2 table
---@param factor number lerp factor
---@return table
function Shaping.table_lerp( t1, t2, factor )
    lt = {}
    for i,v in pairs(t1) do
        lt[i] = Shaping.lerp( t1[i], t2[i], factor )
    end
    return lt
end


function Shaping.clamp(x, min, max)
    if x < min then return min end
    if x > max then return max end
    return x
end


function Shaping.lerp( v0, v1, t)
        return (1 - t) * v0 + t * v1
end

return Shaping