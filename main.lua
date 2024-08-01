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

local selected_point_indices_to_remove = {}

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
        
        local t = {x=rem_pos[1], y= rem_pos[2], metadata=rem_value}
        local removed_from_quadtree = tree:remove( t )
        local removed = table.remove( state.plants, rem_index )
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
            -- print("query:", #in_rect)

            local do_add = true
            for k,other in ipairs(in_rect) do
                local rr = (other.userdata.max_size + new_plant.max_size)
                local dist = vector.distance( new_plant.position.x, new_plant.position.y, other.userdata.position.x, other.userdata.position.y )
                -- print("rr", rr, "dist", dist, do_add)


                if dist < rr then
                    -- print("    - REJECT")
                    do_add = false
                    break
                end
            end


            if do_add then
                tree:insert( {x = new_plant.position.x, y = new_plant.position.y, userdata=new_plant}  )
                table.insert(state.plants, new_plant)
            end

        else
            -- print("number of state.plants maximum reached")
        end
    end
end


-- ---------------------------------------------------------------------------------------

local mem_usage = 0
local mem_usage_update_timer = 0.0

-- collectgarbage("collect")


-- ---------------------------------------------------------------------------------------


local font_huge = love.graphics.newFont(100)
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
        local spread = window_height * 0.8
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
local is_plants_paused = false


function love.update(dt)

    mem_usage_update_timer = mem_usage_update_timer + dt
    if mem_usage_update_timer > 2.5 then
        mem_usage = collectgarbage("count")
        mem_usage_update_timer = 0
    end

    global_time = global_time + dt
    global_frame = global_frame + 1

    if not is_plants_paused then
        -- remove selected points
        for i,v in pairs( selected_point_indices_to_remove ) do
            onPlantDie( {v} )
        end
        if #selected_point_indices_to_remove > 0 then
            selected_point_indices_to_remove = {}
        end

        -- update points
        for k,v in pairs( state.plants ) do
            v:update( dt )
        end
    end
end

-- ---------------------------------------------------------------------------------------
local start_draw_timer, end_draw_timer
local do_draw_timer = false
local draw_timer_string = ""

function love.draw()
    love.graphics.clear( 0.025,0.025,0.025 )
    -- diagnostics
    if global_frame % 120 == 0 then
        do_draw_timer = true
        start_draw_timer = love.timer.getTime()
    end
    
    -- quadtree
    --local tree_depth, tree_quadcount = drawquad ( tree, 1, 1 )
    tree:draw()

    --
    love.graphics.setLineWidth(2)

    for i,v in ipairs(state.plants) do
        love.graphics.setColor( v.color )
        love.graphics.circle("fill", v.position.x, v.position.y, v.size, 16 )
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
    if do_draw_timer then
        end_draw_timer = love.timer.getTime() - start_draw_timer
        -- print("[diag] love.draw " .. string.format("%.5f", end_draw_timer) .. string.format(" (%0.2f%% of 60fps)", (end_draw_timer/(1.0/60))*100.0 ) )
        draw_timer_string = string.format("%.5fms", end_draw_timer) .. string.format(" (%0.2f%% of 60fps)", (end_draw_timer/(1.0/60))*100.0 )
        do_draw_timer = false
    end

    --
    love.graphics.setColor( {0.0,0.0,0.0,0.85} )
    love.graphics.rectangle("fill", 8,8,255,85)
    love.graphics.setColor( {1.0,1.0,1.0,0.5} )
    local fps = love.timer.getFPS()
    love.graphics.setFont(font_medium)
    love.graphics.print(string.format("%i",fps), 10, 10)
    love.graphics.print(string.format("%i",#state.plants), 10, 30)
    
    love.graphics.setFont(font_small)
    --love.graphics.print( string.format("depth: %i\nquads: %i", tree_depth, tree_quadcount), 10, 55 )
    love.graphics.print( string.format("mem: %0.1f MB\ndraw time: %s", mem_usage / 102.4, draw_timer_string), 10, 55 )


    
    if is_plants_paused then
        love.graphics.setFont(font_huge)
        local fw = font_huge:getWidth("PAUSED")
        love.graphics.print("PAUSED", window_width/2.0 - fw/2.0 ,20)
    end

    -- debug
    love.graphics.setColor(0.9,0.8,0.1,0.5)
    for _,v in ipairs(query_boxes) do
        love.graphics.rectangle("line", v.x, v.y, v.width, v.height)
    end

    -- cleanup
    query_boxes = {}

end

-- ---------------------------------------------------------------------------------------
function love.mousepressed(x,y,button,istouch,presses)
    
    -- select points for deletion with mouse right-click
    if button == 2 then
        local in_rect = tree:queryRange( {x = x-50, y=y-50, width=100, height=100} , {} )
        for k,v in pairs( in_rect ) do
            table.insert(selected_point_indices_to_remove, v.userdata)
        end
    end
end


function love.keypressed(key, code, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
    if code == "f5" then
        collectgarbage()
    end
    if code == "space" then
        is_plants_paused = not is_plants_paused
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