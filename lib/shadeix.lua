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


------------------------------------------------------------------------------------------
-- Graphs

--- Graph shader graph class
--- @class Graph 
--- @field name string the Graph's name
--- @field nodes table the list of nodes in the graph, k i sthe ondex for ordering, value is the Node
--- @field shaders table table of shader names and their index into the .nodes table {["shader_gamma"]=1, ...}
--- @field in_canvas love.Canvas the incoming canvas 
--- @field buffer_a love.Canvas double-buffer canvas
--- @field buffer_b love.Canvas double-buffer canvas
Shadeix.Graph = {}


---The shader ggraph that holds the shader nodes and manages rendering
---@param name string The name of the graph
---@param in_canvas love.Canvas an incoming canvas to start running shaders over 
--- this canvas sets the dimensions for the shader chain Canvases
---@return Graph graph
function Shadeix.Graph:new( name, in_canvas )
    Shadeix.Graph.__index = Shadeix.Graph
    local self = setmetatable( {}, Shadeix.Graph )
    self.name = name or "graph"
    self.nodes = {}
    self.shaders = {}
    self.in_canvas = in_canvas or nil
    self.buffer_a = love.graphics.newCanvas()
    self.buffer_b = love.graphics.newCanvas()
    return self
end


function Shadeix.Graph:type()
    return "Graph"
end


function Shadeix.Graph:__tostring()
    return self:type() .. ": \"" .. self.name .. "\" :" .. string.format("(%s nodes)", #self.nodes)
end


---creates a new shader graph Node
---@param name string teh name of the node
---@param shader_filepath string filepath to a shader file (.glsl)
---@return Node
function Shadeix.Graph:add_node( name, shader_filepath )
    local shader = self:load_shader(shader_filepath)
    local new = Shadeix.Node:new( name, shader )
    new.filepath  = shader_filepath
    --table.insert(self.nodes, new)
    local index = #self.nodes + 1
    self.nodes[ index ] = new
    self.shaders[ name ] = index
    return new
end


---get a node by name
---@param name string the name of the node to retrieve
function Shadeix.Graph:get_node( name )
    return self.nodes[ self.shaders[name] ]
end


---loads a love.Shader from a filepath
---@param filepath any
---@return love.Shader
function Shadeix.Graph:load_shader( filepath )
    local sh_string = love.filesystem.read( filepath )
    local shader = love.graphics:newShader( filepath )
    return shader
end


---flip the buffers
function Shadeix.Graph:flip()
    local tmp_a = self.buffer_a
    self.buffer_a = self.buffer_b
    self.buffer_b = tmp_a
end


function Shadeix.Graph:print_buffers()
    print("a: ", self.buffer_a)
    print("b: ", self.buffer_b)
end


---drawn acanvas throughthe shader Graph
---@param in_canvas love.Canvas input canvas to run the shader Graph over
function Shadeix.Graph:draw( in_canvas )
    -- local previous_blend_mode, previous_alpha_mode = love.graphics.getBlendMode()
    -- local previous_canvas = love.graphics.getCanvas()
    -- local previous_background_color = {love.graphics.getBackgroundColor()}
    -- local previous_color = {love.graphics.getColor()}
    
    self.in_canvas = in_canvas
    love.graphics.setColor( 1,1,1,1 )
    
    love.graphics.setCanvas(self.buffer_a)
    love.graphics.clear()
    local next_draw_canvas = in_canvas
    for k,v in pairs(self.nodes) do
        love.graphics.setShader( v.shader )
        love.graphics.draw( next_draw_canvas )
        
        -- if this node has a stashed canvas
        -- draw to it also
        if v.canvas then
            love.graphics.setCanvas( v.canvas )
            love.graphics.clear()
            love.graphics.draw( next_draw_canvas )
        end

        self:flip()
        love.graphics.setCanvas( self.buffer_a )
        love.graphics.clear()
        next_draw_canvas = self.buffer_b
    end
    
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.clear()
    
    
    love.graphics.draw( next_draw_canvas ) --self.buffer_b )
    
    -- love.graphics.setBlendMode( previous_blend_mode, previous_alpha_mode )
    -- love.graphics.setCanvas( previous_canvas )
    -- love.graphics.setBackgroundColor( previous_background_color )
    -- love.graphics.setColor( previous_color )
end


function Shadeix.Graph:print_graph()
    print(self)
    for k,v in pairs(self.nodes) do
        print("    ", k, " : ", v)
        if v.canvas then
            print("      : stashed canvas : ", v.canvas)
        end
    end
end

------------------------------------------------------------------------------------------
-- Nodes

--- shader graph Node 
--- @class Node
--- @field name string the Node's name
--- @field shader love.Shader a pre-loaded Shader
--- @field filepath string the original shader filepath
--- @field input Node|nil input Node
--- @field canvas love.Canvas|nil stashed Canvas
Shadeix.Node = {}


---comment
---@param name string the name of the new node
---@param shader love.Shader a Shader to use in the node
---@return Node
function Shadeix.Node:new( name, shader )
    Shadeix.Node.__index = Shadeix.Node
    local self = setmetatable(
        { }, Shadeix.Node )

    self.name = name or "node"
    self.shader = shader
    self.filepath = ""
    self.canvas = nil
    return self
end


function Shadeix.Node:type()
    return "Node"
end


function Shadeix.Node:__tostring()
    return self:type() .. ": \"" .. self.name .. "\" : \"" .. self.filepath .. "\""
end

---create an own-Canvas for re-use 
---to later pass to a shader as an additional Texture input
---@param width number
---@param height number
---@param settings table
function Shadeix.Node:stash_canvas(width, height, settings)
    self.canvas = love.graphics.newCanvas( width, height, settings )
end


return Shadeix
