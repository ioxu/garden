local vector = require "vector"
if arg[2] == "debug" then
    print("STARTING DEBUGGER")
    require("lldebugger").start()
end

local plants = require "plants"
local Quadtree = require "quadtree"
local vector = require "vector"

math.randomseed( os.time() )
io.stdout:setvbuf("no")

-- print("module:", plants)
-- local p = plants.plant:new( "qbit", {-20.0, 50.00}, 0.0 )

-- print( "plant:", p )
-- for k,v in pairs(p) do
--     print("  :", k, v)
-- end

-- ---------------------------------------------------------------------------------------
-- window
local window_width, window_height = love.graphics.getDimensions()

-- ---------------------------------------------------------------------------------------
-- quadtree stuff, https://love2d.org/forums/viewtopic.php?t=83296
local qt_size = 600
local x1, x2, y1, y2 = window_width/2 - qt_size,
                    window_width/2 + qt_size,
                    window_height/2 - qt_size,
                    window_height/2 + qt_size
-- local tree = Quadtree( 0, 0, window_width, window_height ) 
local tree = Quadtree:new( 0, 0, window_width, window_height ) -- Quadtree:new( x1, y1, x2, y2 )
local drawquads = true

-- ---------------------------------------------------------------------------------------

-- state methods
local state = {}
state.plants = {}

local dead_dots = {}

local function onPlantDie( plant )
    for k,v in pairs(plant) do
        -- print("[onPlantDie] "..v.name .." has died.")
        local rem_index = nil
        local rem_value = nil
        local rem_pos = {}
        for i,_plant in ipairs(state.plants) do
            if _plant == v then
                rem_index = i
                rem_value = v
                rem_pos = {_plant.position.x, _plant.position.y}
            end
        end
        
        
        --tree:remove( rem_value )
        
        
        local removed = table.remove( state.plants, rem_index )
        -- print("removed: ".. table.concat(removed) )
        -- for k,v in pairs(removed)do
        --     print("  ", k, v)
        -- end

        -- table.insert( dead_dots, rem_pos[1])
        -- table.insert( dead_dots, rem_pos[2])
    end
end


local query_boxes = {}


local function onPlantSpawned( plant )
    for k,new_plant in pairs(plant) do
        --print("[OnPlantSpawned] "..new_plant.name.." has been spawned.")
        
        if #state.plants < 3000 then
            -- limit positions to within the window with margins
            new_plant.position.x = math.min(math.max(new_plant.position.x, 50.0), window_width - 50.0 )
            new_plant.position.y = math.min(math.max(new_plant.position.y, 50.0), window_height - 50.0 )
            
            local query_size = 60
            local h_query_size = query_size/2.0
            local query_box = {x = new_plant.position.x-h_query_size, y=new_plant.position.y-h_query_size, width=query_size, height=query_size}
            table.insert(query_boxes, query_box )
            local in_rect = tree:queryRange( query_box , {} )
            print("query:", #in_rect)

            local do_add = true
            for k,other in ipairs(in_rect) do
                local rr = (other.userdata.max_size + new_plant.max_size)
                local dist = vector.distance( new_plant.position.x, new_plant.position.y, other.userdata.position.x, other.userdata.position.y )
                print("rr", rr, "dist", dist, do_add)


                if dist < rr then
                    print("    - REJECT")
                    do_add = false
                    break
                end
            end


            if do_add then
                table.insert(state.plants, new_plant)
            end

        else
            print("number of state.plants maximum reached")
        end
    end
end


-- ---------------------------------------------------------------------------------------

local mem_usage = 0
local mem_usage_update_timer = 0.0

-- collectgarbage("collect")


-- ---------------------------------------------------------------------------------------


local font_medium = love.graphics.newFont(20)
local font_small = love.graphics.newFont(12.5)

-- ---------------------------------------------------------------------------------------

function love.load()

    local rng = love.math.newRandomGenerator()
    rng:setSeed( os.time() )
    print("dimensions:", window_width, window_height)

    print("making plants ..")
    for i = 1,8,1 do
        -- local new_plant = plants.plant:new( "qbit"..i, {x=rng:random() * window_width, y=rng:random() * window_height}, 0.0 )
        local spread = window_width * 0.8
        local new_plant = plants.plant:new( "qbit"..i, {x=(rng:random() -0.5) * spread + window_width/2, y=(rng:random() -0.5) * spread + window_height/2}, 0.0 )
        new_plant.max_size = rng:random() * 10.0 + 5.0
        new_plant.max_age = rng:random() * 10.0 + 5.0
        
        new_plant.signals:register("plant_died", onPlantDie)
        new_plant.signals:register("plant_spawned", onPlantSpawned)
        table.insert(state.plants, new_plant )
        tree:insert( { x= new_plant.position.x, y = new_plant.position.y, userdata = new_plant} )
    end
    print(" .. done (made " .. #state.plants .. " plants)")

    
end

-- ---------------------------------------------------------------------------------------
local start_update_timer, end_update_timer
local do_update_timer = false
local global_frame = 0
local global_time = 0.0

function love.update(dt)
    --[ love update callback
    --]

    mem_usage_update_timer = mem_usage_update_timer + dt
    if mem_usage_update_timer > 2.5 then
        mem_usage = collectgarbage("count")
        mem_usage_update_timer = 0
    end


    tree = Quadtree:new( 0, 0, window_width, window_height )

    global_time = global_time + dt
    global_frame = global_frame + 1
    
    -- diagnostics
    if global_frame % 120 == 0 then
        do_update_timer = true
        start_update_timer = love.timer.getTime()
    end


 
    --
    for k,v in pairs( state.plants ) do
        -- print("update", k, v)
        
        --
        --
        --
        --
        --
        --tree:remove( v )
        --
        --
        --
        --
        --

        -- v:update( dt )
        -- v.position.x, v.position.y = rotatePoint( v.position.x, v.position.y, 0.025 * dt )
        -- tree:insert( v, v.position.x, v.position.y )
        tree:insert( {x = v.position.x, y = v.position.y, userdata=v}  )
    end

    -- if #state.plants == 200 then
    --     print("halt")
    -- end

    for k,v in pairs( state.plants ) do
        v:update( dt )
    end

    -- if #state.plants > 1000 then
    --     print("halt")
    -- end

    -- diagnostics
    -- if do_update_timer then
    --     end_update_timer = love.timer.getTime() - start_update_timer
    --     print("[diag] love.update " .. string.format("%.5f", end_update_timer))
    --     do_update_timer = false
    -- end
end

-- ---------------------------------------------------------------------------------------
local start_draw_timer, end_draw_timer
local do_draw_timer = false
function love.draw()
    --[ love update callback
    --]
    -- diagnostics
    if global_frame % 120 == 0 then
        do_draw_timer = true
        start_draw_timer = love.timer.getTime()
    end
    
    -- quadtree
    --local tree_depth, tree_quadcount = drawquad ( tree, 1, 1 )
    tree:draw()

    -- love.graphics.setPointSize( 2 )
    -- love.graphics.setColor( 0.9,0.7,0.2,0.75 )
    -- love.graphics.points(dead_dots)



    --
    love.graphics.setLineWidth(2)

    for i,v in ipairs(state.plants) do
        love.graphics.setColor( v.color )
        love.graphics.circle("line", v.position.x, v.position.y, v.size, 16 )--v.size)--, 8)
        -- love.graphics.setColor( v.color[1], v.color[2], v.color[3], 0.25  )
        -- love.graphics.circle("line", v.position.x, v.position.y, 3)--v.size)--, 8)
    
    end

    --------------------------------------------------------------------------------------
    -- mouse inspect square
    local mx, my = love.mouse.getPosition()
    love.graphics.setColor( {0.0,1.0,0.0,0.5} )
    love.graphics.rectangle("line", mx - 50, my -50, 100, 100)

    local in_rect = tree:queryRange( {x = mx-50, y=my-50, width=100, height=100} , {} )

    love.graphics.setColor( 0.5,1.0, 0.0, 0.75 )
    love.graphics.setPointSize(4)
    for k,v in pairs( in_rect ) do
        --love.graphics.points( v.x, v.y )
        love.graphics.circle("fill", v.x, v.y, 2.5, 11)
    end
    --------------------------------------------------------------------------------------

    -- diagnostics
    -- if do_draw_timer then
    --     end_draw_timer = love.timer.getTime() - start_draw_timer
    --     print("[diag] love.draw " .. string.format("%.5f", end_draw_timer) .. string.format(" (%0.2f%% of 60fps)", (end_draw_timer/(1.0/60))*100.0 ) )
    --     do_draw_timer = false
    -- end

    --
    love.graphics.setColor( {0.0,0.0,0.0,0.5} )
    love.graphics.rectangle("fill", 8,8,30,55)
    love.graphics.setColor( {1.0,1.0,1.0,0.5} )
    local fps = love.timer.getFPS()
    love.graphics.setFont(font_medium)
    love.graphics.print(string.format("%i",fps), 10, 10)
    love.graphics.print(string.format("%i",#state.plants), 10, 30)
    
    love.graphics.setFont(font_small)
    --love.graphics.print( string.format("depth: %i\nquads: %i", tree_depth, tree_quadcount), 10, 55 )
    love.graphics.print( string.format("mem: %0.1f MB\n", mem_usage / 102.4), 10, 55 )


    -- debug
    love.graphics.setColor(0.9,0.8,0.1,0.5)
    for _,v in ipairs(query_boxes) do
        love.graphics.rectangle("line", v.x, v.y, v.width, v.height)
    end

    -- cleanup
    query_boxes = {}

end

-- ---------------------------------------------------------------------------------------

function love.keypressed(key, code, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
    if code == "f5" then
        collectgarbage()
    end
end

-- debug ---------------------------------------------------------------------------------
local love_errorhandler = love.errorhandler

function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    else
        return love_errorhandler(msg)
    end
end