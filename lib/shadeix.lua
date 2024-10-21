--[[shadeix shader pipeline

]]

local Shadeix = {}


------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;203m[Shadeix]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end
------------------------------------------------------------------------------------------
print("initialising system .. ")

--- Graph shader graph class
--- @class Graph
--- @field name string 
Shadeix.Graph = {}


---comment
---@param name string The name of the graph
---@return Graph graph
function Shadeix.Graph:new( name )
    Shadeix.Graph.__index = Shadeix.Graph
    local self = setmetatable( {}, Shadeix.Graph )
    self.name = name or "graph"
    return self
end


return Shadeix
