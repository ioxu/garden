--

local function func(a)
    return 1,2,3
end

print( {func(1)} )

for i,v in ipairs({func(1)}) do
    print(i, v)
end

-- local t = {1,2,3,4,5,6}

-- print( t[ 0 % #t ] )


-- print("table concat: "..table.concat(t) )


-- local t2 = {}
-- t2[1] = "a"
-- t2[2] = "b"
-- t2[4] = "d"
-- t2[100] = "hundy"
-- print("t2:")
-- for k,v in pairs(t2) do
--     print(k, v)
-- end



