local vector = require "vector"
if arg[2] == "debug" then
    print("STARTING DEBUGGER")
    require("lldebugger").start()
end

local quadtree_main = {}

local plants = require "plants"
local Quadtree = require "quadtree"
local vector = require "vector"
local shaping = require "shaping"

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
local font_huge = love.graphics.newFont(100)
local font_medium = love.graphics.newFont(20)
local font_small = love.graphics.newFont(12.5)

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
math.randomseed( os.time() )
local rng = love.math.newRandomGenerator()
rng:setSeed( os.time() )
-- ---------------------------------------------------------------------------------------

-- state methods
local state = {}
state.plants = {}

local selected_point_indices_to_remove = {}
local query_boxes = {}


-- ---------------------------------------------------------------------------------------
local function onPlantDie( plant )
    -- signal listener for when a plant emits a die signal
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


local function onPlantSpawned( plant )
    --[[ signal listener for when a plant spawns a new child-plant
    new_plant.signals:register("plant_spawned", onPlantSpawned)
    ]]--
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
-- quadtree events
local subdivided_quads_vis = {}
local unsubdivided_qauds_vis = {}

local function onQuadtreeSubdivided( quadtree )
    print( string.format("[quadtree] subdivided: %s", quadtree.name) )
    table.insert(subdivided_quads_vis, {quad=quadtree, age=1.0})
end

local function onQuadtreeUnsubdivided( quadtree )
    print( string.format("[quadtree] UNsubdivided: %s", quadtree.name) )
    table.insert( unsubdivided_qauds_vis, {quad=quadtree, age=1.0} )
end


tree.signals:register( "subdivided", onQuadtreeSubdivided )
tree.signals:register( "unsubdivided", onQuadtreeUnsubdivided )
-- ---------------------------------------------------------------------------------------

local mem_usage = 0
local mem_usage_update_timer = 0.0

-- collectgarbage("collect")

-- ---------------------------------------------------------------------------------------

-- function love.load()
function quadtree_main.load()
    print("dimensions:", window_width, window_height)

    love.mouse.setVisible( false )

    print("making plants ..")
    for i = 1,8,1 do
        -- local new_plant = plants.plant:new( "qbit"..i, {x=rng:random() * window_width, y=rng:random() * window_height}, 0.0 )
        local spread = window_height * 0.8
        local new_plant = plants.plant:new( "qbit"..i, {x=(rng:random() -0.5) * spread + window_width/2, y=(rng:random() -0.5) * spread + window_height/2}, 0.0 )
        new_plant.max_size = shaping.remap(rng:random() , 0, 1, 5, 20) --rng:random() * 5.0 + 2.5
        new_plant.max_age = rng:random() * 10.0 + 5.0
        
        new_plant.signals:register("plant_died", onPlantDie)
        new_plant.signals:register("plant_spawned", onPlantSpawned)
        table.insert(state.plants, new_plant )
        tree:insert( { x= new_plant.position.x, y = new_plant.position.y, userdata = new_plant} )
    end
    print(" .. done (made " .. #state.plants .. " plants)")

    -- love.graphics.setLineStyle("rough")
end

-- ---------------------------------------------------------------------------------------
local start_update_timer, end_update_timer
local do_update_timer = false
local update_timer_string = ""
local global_frame = 0
local global_time = 0.0
local is_plants_paused = false


-- function love.update(dt)
function quadtree_main.update(dt)
    
    if global_frame % 60 == 0 then
        do_update_timer = true
        start_update_timer = love.timer.getTime()
    end

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

    if love.keyboard.isDown('lctrl') and love.keyboard.isDown('f5') then
        print("BREAK!")
    end

    -- quadtree subdivision visualisation
    for i,v in pairs(subdivided_quads_vis) do
        v.age = v.age - dt
        if v.age < 0 then
            subdivided_quads_vis[i] = nil
        end
    end

    for i,v in pairs(unsubdivided_qauds_vis) do
        v.age = v.age - dt
        if v.age < 0 then
            unsubdivided_qauds_vis[i] = nil
        end
    end

    if do_update_timer then
        end_update_timer = love.timer.getTime() - start_update_timer
        update_timer_string = string.format("%.5fms", end_update_timer) .. string.format(" (%0.2f%% of 60fps)", (end_update_timer/(1.0/60))*100.0 )
        do_update_timer = false
    end
end

-- ---------------------------------------------------------------------------------------
-- local do_draw_quadtree_graph = true
quadtree_main.do_draw_quadtree_graph = true
local do_draw_quadtree_quads = true
local do_draw_subdivision_changes = true
local do_draw_new_plant_query_areas = true
local do_draw_plants = true

local start_draw_timer, end_draw_timer
local do_draw_timer = false
local draw_timer_string = ""

-- function love.draw()
function quadtree_main.draw()
    love.graphics.clear( 0.025,0.025,0.025 )
    -- diagnostics
    if global_frame % 60 == 0 then
        do_draw_timer = true
        start_draw_timer = love.timer.getTime()
    end
    
    -- quadtree
    if do_draw_quadtree_quads then
        tree:draw()
    end

    --
    love.graphics.setLineWidth(2)

    if do_draw_plants then
        for i,v in ipairs(state.plants) do
            love.graphics.setColor( v.color )
            -- love.graphics.setColor( v.color[1], v.color[2], v.color[3], 0.15 )
            love.graphics.circle("line", v.position.x, v.position.y, v.size, 16 )
            -- love.graphics.setColor( v.color )
            -- love.graphics.line(v.position.x, v.position.y, v.position.x, v.position.y - (v.size/v.max_size) * v.max_size * 10)
            -- love.graphics.setColor(1,1,1,1.0)
            -- local m = love.graphics.newMesh( { {v.position.x, v.position.y, 0, 0, 1, 0, 0, 1},
            --                                     {v.position.x, v.position.y - (v.size/v.max_size) * v.max_size * 10, 0, 0, 0, 1, 0, 1}
            --                                 }, "", "stream" )
            -- love.graphics.draw( m )
        end
    end

    --------------------------------------------------------------------------------------
    -- mouse inspect square
    local mx, my = love.mouse.getPosition()
    love.graphics.setColor( {0.9,0.8,0.2,0.15} )
    love.graphics.rectangle("line", mx - 50, my -50, 100, 100)
    love.graphics.setColor( {0.9,0.8,0.2,0.25} )
    love.graphics.line( mx, my, mx + 15, my +15 )

    local in_rect = tree:queryRange( {x = mx-50, y=my-50, width=100, height=100} , {} )

    love.graphics.setColor( 0.5,1.0, 0.0, 0.75 )
    love.graphics.setPointSize(4)
    for k,v in pairs( in_rect ) do
        --love.graphics.points( v.x, v.y )
        love.graphics.circle("fill", v.x, v.y, 2.5, 11)
    end

    if quadtree_main.do_draw_quadtree_graph then
        love.graphics.setPointSize(3)
        tree:draw_tree( mx, my )
    end


    --------------------------------------------------------------------------------------
    
    -- debug
    if do_draw_new_plant_query_areas then
        love.graphics.setColor(0.9,0.8,0.1,0.5)
        for _,v in ipairs(query_boxes) do
            love.graphics.rectangle("line", v.x, v.y, v.width, v.height)
        end
    end

    -- quadtree subdivision visualisation
    if do_draw_subdivision_changes then
        love.graphics.setLineWidth(4)
        for k,v in pairs(subdivided_quads_vis) do
            love.graphics.setColor( 0.0, 1.0, 0.0, v.age )
            love.graphics.rectangle("line",
                                    v.quad.boundary.x,
                                    v.quad.boundary.y,
                                    v.quad.boundary.width,
                                    v.quad.boundary.height
                                )
        end
    
        for k,v in pairs(unsubdivided_qauds_vis) do
            love.graphics.setColor( 1.0, 0.0, 0.0, v.age )
            love.graphics.rectangle("fill",
                                    v.quad.boundary.x,
                                    v.quad.boundary.y,
                                    v.quad.boundary.width,
                                    v.quad.boundary.height
                                )
        end
    end

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
    love.graphics.print( string.format("mem: %0.1f MB\ndraw time: %s\nupdate time: %s",
                                        mem_usage / 102.4,
                                        draw_timer_string,
                                        update_timer_string),
                                        10, 55 )

    
    if is_plants_paused then
        love.graphics.setFont(font_huge)
        local fw = font_huge:getWidth("PAUSED")
        love.graphics.print("PAUSED", window_width/2.0 - fw/2.0 ,20)
    end


    -- cleanup
    query_boxes = {}

end


-- ---------------------------------------------------------------------------------------
-- function love.mousepressed(x,y,button,istouch,presses)
function quadtree_main.mousepressed(x,y,button,istouch,presses)
    --
    if button ==1 then
        -- local ret = tree:inspect( {x = x, y =y} )
        -- print("INSPECT: ", ret)
        
        -- make a new plant at click
        local new_plant = plants.plant:new( "handplaced", {x=x, y=y}, 0.0 )
        new_plant.max_size = shaping.remap(rng:random() , 0, 1, 5, 20) --rng:random() * 5.0 + 2.5
        new_plant.max_age = rng:random() * 10.0 + 5.0
        -- new_plant.child_spawn_max_amount = 0
        -- new_plant.immortal = true
        
        new_plant.signals:register("plant_died", onPlantDie)
        new_plant.signals:register("plant_spawned", onPlantSpawned)
        table.insert(state.plants, new_plant )
        tree:insert( { x= new_plant.position.x, y = new_plant.position.y, userdata = new_plant} )
    end

    -- select points for deletion with mouse right-click
    -- the actual removal is done in the update loop, because
    -- doing it here is the wrong place
    if button == 2 then
        print("[delete] ----------------")
        local in_rect = tree:queryRange( {x = x-50, y=y-50, width=100, height=100} , {} )
        for k,v in pairs( in_rect ) do
            table.insert(selected_point_indices_to_remove, v.userdata)
        end
    end
end


-- function love.keypressed(key, code, isrepeat)
function quadtree_main.keypressed(key, code, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
    if code == "f6" then
        collectgarbage()
    end
    if code == "space" then
        is_plants_paused = not is_plants_paused
    end
    if code == "1" then
        quadtree_main.do_draw_quadtree_graph = not quadtree_main.do_draw_quadtree_graph
    end
    if code == "2" then
        do_draw_quadtree_quads = not do_draw_quadtree_quads
    end
    if code == "3" then
        do_draw_subdivision_changes = not do_draw_subdivision_changes
    end
    if code == "4" then
        do_draw_new_plant_query_areas = not do_draw_new_plant_query_areas
    end
    if code == "5" then
        do_draw_plants = not do_draw_plants
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

return quadtree_main
