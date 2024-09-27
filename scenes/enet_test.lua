-- Server scene
local EnetTest ={}
EnetTest.scene_name = "Enet networking components test"
EnetTest.description = "testing ground for the networking components"

local enet_ui = require "lib.enet_test_ui" -- some utils
local net = require "lib.network" -- main networking objects
-- local gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"
local log_ui = require "lib.log_ui"
local tables = require "lib.tables"
local entities = require "lib.entities"

------------------------------------------------------------------------------------------
local server = net.Server:new("The Garden")

------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;221m[enet_test]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end

------------------------------------------------------------------------------------------
local font_small = love.graphics.newFont(10)
local font_mono_small = love.graphics.newFont( "resources/fonts/SourceCodePro-Regular.ttf", 10 )
local font_medium = love.graphics.newFont(25)
local font_large = love.graphics.newFont(40)

-- local bg_image
------------------------------------------------------------------------------------------
-- log panel
local log_display = log_ui:new("server log display")

------------------------------------------------------------------------------------------
-- server panel
local server_panel = enet_ui.server_panel({325,250,100,200})
server_panel.window:hide()
local test_log_with_dummy_logs = false
------------------------------------------------------------------------------------------
-- peers panel
local peers_panel = enet_ui.peer_list_panel( )
peers_panel.window:hide()

------------------------------------------------------------------------------------------
-- stats panel
local stats_panel = enet_ui.stats_window({ 325, 475, 100, 200 })
stats_panel.window:hide()

-- signal callbacks
function _on_test_log_button_pressed()
    test_log_with_dummy_logs = not test_log_with_dummy_logs
    if test_log_with_dummy_logs then
        server_panel.button_test_log.label = "test_log (enabled)"
    else
        server_panel.button_test_log.label = "test_log (disabled)"
    end
end


function _on_start_server_button_pressed()

    -- update address from UI
    server.address = server_panel.found_address.label

    if server.host == nil then
        server:start()
        if server.host then
            log_display:log(string.format("[server started at %s]",tostring(server)))
            server_panel.button_start.label = "started"
            server_panel.button_start.style.hilite = {0.1,0.55,0.1,1.0}
            server_panel.button_start.style.focus = {0.4,1.0,0.4,1.0}    
        else
            log_display:log(string.format("[failed to start server at %s]",tostring(server)))
        end
    elseif server.host then

        server:stop()
        if not server.host then
            server_panel.button_start.label = "stopped"
            server_panel.button_start.style.hilite = {1.0,0.2,0.2,1.0}
            server_panel.button_start.style.focus = {1.0,0.4,0.4,1.0}        
            log_display:log(string.format("[stopped server at %s]",tostring(server)))
            peers_panel.update_peers_list( server )
            stats_panel.update_connections( server )
        else
            log_display:log(string.format("[failed to stop server at %s]",tostring(server)))
        end

    end
end


function _on_port_field_changed( new_port_value)
    local old_port_value = server.port
    print(string.format("_on_port_field_changed (%s -> %s)", old_port_value, new_port_value))
    server.port = tonumber(new_port_value)
end

function _on_clear_log_button_pressed(  )
    -- log_display:log_text:clear()
    log_display:clear()
    log_display:log("[log cleared]")
end

server_panel.signals:register("button_start_clicked", _on_start_server_button_pressed)
server_panel.signals:register("button_clear_log_clicked", _on_clear_log_button_pressed)
server_panel.signals:register("button_test_log_clicked", _on_test_log_button_pressed)
server_panel.signals:register("port_field_changed", _on_port_field_changed)


------------------------------------------------------------------------------------------
-- dummy logging
local rng = love.math.newRandomGenerator()
rng:setSeed( os.time() )
local client_names = {"enit", "commosa", "eltuu", "b-aoAR"}
function test_log()
    if test_log_with_dummy_logs then
        local rr = rng:random()
        if rr < 0.1 then
            local new_str = string.format("[%s][command][%s]", os.date("%H:%M:%S", os.time()+30600), client_names[rng:random(#client_names)] )
            log_display:log( new_str )
        end
    end
end


------------------------------------------------------------------------------------------
--- server callbacks
function _on_peer_connected(event)
    log_display:log( string.format("[peer connected] %s (index: %s, id: %s )", event.peer, event.peer:index(), event.peer:connect_id()) )
    print("adding peer to the peers_panel")
    peers_panel.update_peers_list( server )
    stats_panel.update_connections( server )
    
    -- ping back to the connected peer
    local xpos, ypos = 300, 300
    entities.spawn( event.peer:index(), xpos, ypos )
    -- local send_str = string.format("your-id|%s|%s", event.peer, event.peer:connect_id())
    local send_str = string.format("your-id|%s|%s|%s|%s", event.peer, event.peer:index(), xpos, ypos)
    log_display:log(string.format("[send] %s", send_str))
    print("[send] ", send_str)
    event.peer:send(send_str)
    for peer_id, entity in pairs(entities.entities) do
        local send_str = string.format("peer-id|%s|%s|%s|%s", "<noadress>", entity.id, entity.x, entity.y)
        event.peer:send( send_str )
    end

    -- broadcast new connection to all others
    local send_str = string.format("peer-id|%s|%s|%s|%s", event.peer, event.peer:index(), xpos, ypos)
    log_display:log(string.format("[broadcast] %s", send_str))
    print("[broadcast] ", send_str)
    server.host:broadcast( send_str )
end

---comment
---@param event any
---@param disconnect_data Disconnect_Data 
function _on_peer_disconnected( event, disconnect_data )
    log_display:log( string.format("[peer disconnected][%s] %s", disconnect_data.nickname, event.peer) )
    peers_panel.update_peers_list( server )
    stats_panel.update_connections( server )

    entities.despawn( event.peer:index() )

    -- broadcast peer disconnection
    local send_str = string.format("unpeer-id|%s|%s", event.peer, event.peer:index())
    log_display:log(string.format("[broadcast] %s", send_str))
    print("[broadcast] ", send_str)
    server.host:broadcast( send_str )
end


function _on_peer_received( event )
    log_display:log( string.format("[received][%s] '%s'", server.nicknames[event.peer:index()], event.data) )
    local message = tables.split_by_pipe(event.data)
    if message[1] == "my-id" then
       server:set_nickname( event.peer:index(), message[2] )
       peers_panel.update_peers_list( server )
    end
    if message[1] == "move" then
        entities.move(tonumber(message[2]), tonumber(message[3]), tonumber(message[4]))
        
        -- rebroadcast move
        -- TODO: can't be this simple, right?
        server.host:broadcast( event.data )
    end
end

server.signals:register("connected", _on_peer_connected)
server.signals:register("disconnected", _on_peer_disconnected)
server.signals:register("received", _on_peer_received)

------------------------------------------------------------------------------------------
function EnetTest:init()
    --- scene_manager callback
    log_display:log("[log begin]")
    print(string.format("server: %s", server))
    -- bg_image = love.graphics.newImage( "resources/garden.png" )
    -- love.graphics.setDefaultFilter('nearest', 'nearest')
end

function EnetTest:defocus()
    --- scene_manager callback
    print(":defocus()")
    -- hide these GUIs    
    server_panel.window:hide()
    -- log_panel.window:hide()
    stats_panel.window:hide()
    peers_panel.window:hide()
end


function EnetTest:focus()
    --- scene_manager callback
    print(":focus()")
    -- show these GUIs
    -- WARNING: will unhide things that are not meant to be shown
    server_panel.window:show()
    -- log_panel.window:show()
    stats_panel.window:show()
    peers_panel.window:show()
end


function EnetTest:update(dt)
    --- scene_manager callback
    test_log()
    server:update()
end


function EnetTest:draw()
    --- scene_manager callback
    love.graphics.setColor(1,1,1,1)
    love.graphics.clear(0.15,0.15,0.15,1.0)
    -- love.graphics.setColor(1,1,1,0.02)
    -- love.graphics.draw(bg_image)
    love.graphics.print("Enet test")

    love.graphics.setColor(0.4,0.4,0.4,1.0)
    love.graphics.setFont(font_medium)
    local server_text_pos = {x = server_panel.window.pos.x,
        y = server_panel.window.pos.y - font_medium:getHeight() - 4
    }
    if server.host then
        love.graphics.print(string.format("server started %s",tostring(server)), server_text_pos.x , server_text_pos.y)
    else        
        love.graphics.print("server stopped", server_text_pos.x , server_text_pos.y)
    end

    love.graphics.setFont(font_small)
    entities.draw()
    love.graphics.setColor(1,1,1,1)
    for player_id, entity in pairs(entities.entities) do
        if server.nicknames[player_id] then
            love.graphics.print( server.nicknames[player_id], entity.x - 8, entity.y + 8 )
        end
    end

    log_display:draw()
end

------------------------------------------------------------------------------------------

function EnetTest:keypressed(key, code, isrepeat)
	--
end

function EnetTest:textinput(t)
	--
end


function EnetTest:mousepressed (x, y, button)
    --
end


function EnetTest:mousereleased(x, y, button)
	--
end


function EnetTest:wheelmoved(x, y)
    -- 
end


function EnetTest:quit()
    print("cleaning up connections")
    server:stop()
end

------------------------------------------------------------------------------------------
return EnetTest