local signal = require "lib.signal"
local palette = require "lib.palette"
local shaping = require "lib.shaping"
local tables = require "lib.tables"
local color = require "lib.color"
local vector = require "lib.vector"

Plants = {}

-- Plants.plant = {
--     name = "plant",
--     age = 0.0, 
--     position = {
--         x = 0.0,
--         y = 0.0}
-- }


--- @class plant @define base plant class
Plants.plant = {}
Plants.plant.__index = Plants.plant

local rng = love.math.newRandomGenerator()
rng:setSeed(os.time())


--- @param name string the name of the new plant
--- @param position table x and y position of new plant ({x=,y=})
--- @param age number the initial age of the new plant
function Plants.plant:new( name, position, age )
    --- @class plant @define base plant class
    local instance = setmetatable( {}, Plants.plant )
    -- base
    instance.name = name or Plants.plant.name
    instance.position = position or {x = 0.0, y = 0.0}--Plants.plant.position
    instance.age = age or 0.0
    instance.immortal = false
    instance.size = 0.0
    instance.max_size = 50.0
    instance.max_age = 10.0
    instance.color = palette[ math.floor(rng:random() * 10) + 1 ]
    -- reproduction
    instance.sexual_maturity_age_ratio = 0.35 -- age ratio after which it's possible to spawn children
    instance.child_spawn_max_amount = 5--2
    instance.child_spawn_chance = 0.01--0.0195
    instance.children_spawned = 0
    -- signals
    instance.signals = signal:new()
    return instance
end


function Plants.plant:update( dt )
    if self.age < self.max_age then
        self.age = self.age + dt
        -- self.size = (self.age/self.max_age) * self.max_size
        self.size = shaping.bias( (self.age/self.max_age), 0.95 ) * self.max_size
    elseif self.age >= self.max_age and self.immortal ~= true then
        -- die
        self.signals:emit("plant_died", {self})
    end

    -- reproduction
    if (self.age/self.max_age) > self.sexual_maturity_age_ratio then
        if (rng:random() < self.child_spawn_chance and self.children_spawned < self.child_spawn_max_amount) then
            self.children_spawned = self.children_spawned + 1
            local new_child = Plants.plant:new( self.name .. self.children_spawned ) -- new_position)            
            new_child.max_age = math.max(0.5, self.max_age + ((rng:random() - 0.5)*5.0))
            new_child.max_size = math.min( 22, math.max(2, self.max_size + ((rng:random() - 0.5)*3)))

            local x,y = vector.rotatePoint( self.max_size + new_child.max_size + 0.15, 0.0, 0.0, 0.0, rng:random()*2*math.pi )
            new_child.position = {x=x+self.position.x, y=y+self.position.y}

            local col = {color.rgbToHsl( unpack( self.color ))}
            col[1] = col[1] + (rng:random()-0.5) * 0.03
            col[2] = col[2] + (rng:random()-0.5) * 0.03
            col[2] = col[2] + (rng:random()-0.5) * 0.03
            new_child.color = {color.hslToRgb( unpack( col ) )}

            -- duplicate parent's signals
            new_child.signals.listeners = self.signals.listeners --tables.shallow_copy(self.signals)

            self.signals:emit("plant_spawned", {new_child})
        end
    end

end

------------------------------------------------------------------------------------------
if arg and arg[0] == "plants.lua" then
    print("plants.lua tests:")
    local p = Plants.plant:new("plant_one", {1.0, 2.0}, 0.0)
    print(p)
    p:update( 0.067 )
    p:update( 0.067 )
    p:update( 0.067 )
    print(p.age)

    local function OnPlantDied( plant )
        for k,v in pairs( plant ) do
            print("OnPlantDied ".. v.name)
        end
    end

    p.signals:register("plant_died", OnPlantDied)
    p.signals:emit("plant_died", {p})
end

return Plants