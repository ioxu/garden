local Tables = {}


function Tables.shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end


--- splits a string by a vertical pipe delimiter, e.g "one|two|three" returns {"one", "two", "three"}
--- @param input string input string
--- @return table
function Tables.split_by_pipe(input)
    local result = {}
    for part in string.gmatch(input, "([^|]+)") do
        table.insert(result, part)
    end
    return result
end



return Tables