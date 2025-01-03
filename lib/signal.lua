
--- Signal manager class
--- @class Signal
--- @field listeners table
Signal = {}
Signal.__index = Signal


---create a new signaller
---@return Signal signal
function Signal:new()
    local self = setmetatable({}, Signal)
    self.listeners = {}
    return self
end

--- @param event string string signal to register to a function
--- @param listener function callback for emitted string signal
function Signal:register(event, listener)
    if not self.listeners[event] then
        self.listeners[event] = {}
    end
    table.insert(self.listeners[event], listener)
end


function Signal:unregister(event, listener)
    if not self.listeners[event] then return end
    for i, l in ipairs(self.listeners[event]) do
        if l == listener then
            table.remove(self.listeners[event], i)
            break
        end
    end
end

--- @param event string events to emit from this Signal
function Signal:emit( event, ... )
    if not self.listeners[event] then return end
    for _, listener in ipairs(self.listeners[event]) do
        listener( ... )
    end
end


-- testing -------------------------------------------------------------------------------
if arg and arg[0] == "signal.lua" then
    print("signal.lua tests:")

    print("initialise Signal")
    local s = Signal:new()
    
    local function onPlantDie( thing )
        for k,v in pairs(thing) do
            print("--> onPlantDie " .. v.name)
        end
    end

    local plant = {name="oxalis"}
    print("plant.name "..plant.name)

    print("register event to callback")
    s:register("plant_died", onPlantDie)

    print("emit event")
    s:emit("plant_died", {plant})

    print("unregister event from callback")
    s:unregister("plant_died", onPlantDie)

    print("emit event again")
    s:emit("plant_died", {plant})

end


------------------------------------------------------------------------------------------


return Signal