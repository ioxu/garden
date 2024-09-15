-- Server scene
local EnetTest ={}
EnetTest.scene_name = "Enet networking components test"
EnetTest.description = "testing ground for the networking components"

local enet_ui = require "lib.enet_test_ui" -- some utils
local net = require "lib.network" -- main networking objects
-- local gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"

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
-- local inferred_address = net.get_ip_info()
------------------------------------------------------------------------------------------
local font_small = love.graphics.newFont(10)
local font_mono_small = love.graphics.newFont( "resources/fonts/SourceCodePro-Regular.ttf", 10 )
local font_medium = love.graphics.newFont(25)
local font_large = love.graphics.newFont(40)

------------------------------------------------------------------------------------------
-- log panel
-- local log_panel = enet_ui.log_panel({450, 250, 512, 512})
-- ^ log panel is SLOW
-- try a faster log:

local log_display = {}
log_display.log_text = love.graphics.newText( font_mono_small ) -- love.graphics.getFont() )
log_display._line_h = love.graphics.getFont():getHeight()
log_display._nlines = 0


function log_display.log( text )
    log_display.log_text:add( string.format("%05s", log_display._nlines) .. " : " .. text, x, log_display._line_h * log_display._nlines )
    log_display._nlines = log_display._nlines + 1
end


function log_display.draw()
    local diff = 0.0
    if log_display._nlines * log_display._line_h > love.graphics.getHeight() then
        diff = love.graphics.getHeight() - (log_display._nlines * log_display._line_h)
    end
    love.graphics.setColor(1,1,1,0.65)
    love.graphics.push()
    love.graphics.translate(0.0, diff) 
    love.graphics.draw( log_display.log_text )
    love.graphics.pop()
end


------------------------------------------------------------------------------------------
-- server panel
local server_panel = enet_ui.server_panel({325,250,100,200})
server_panel.window:hide()
local test_log_with_dummy_logs = false


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
            -- log_panel:log(string.format("[server started at %s]",tostring(server)))
            log_display.log(string.format("[server started at %s]",tostring(server)))
            server_panel.button_start.label = "started"
            server_panel.button_start.style.hilite = {0.1,0.55,0.1,1.0}
            server_panel.button_start.style.focus = {0.4,1.0,0.4,1.0}    
        else
            -- log_panel:log(string.format("[failed to start server at %s]",tostring(server)))
            log_display.log(string.format("[failed to start server at %s]",tostring(server)))
        end
    elseif server.host then
        if server.host then
            server:stop()
            if not server.host then
                server_panel.button_start.label = "stopped"
                server_panel.button_start.style.hilite = {1.0,0.2,0.2,1.0}
                server_panel.button_start.style.focus = {1.0,0.4,0.4,1.0}        
                -- log_panel:log(string.format("[stoppped server at %s]",tostring(server)))
                log_display.log(string.format("[stopped server at %s]",tostring(server)))
            else
                -- log_panel:log(string.format("[failed to stop server at %s]",tostring(server)))
                log_display.log(string.format("[failed to stop server at %s]",tostring(server)))
            end
        end
    end
end


function _on_port_field_changed( new_port_value)
    local old_port_value = server.port
    print(string.format("_on_port_field_changed (%s -> %s)", old_port_value, new_port_value))
    server.port = tonumber(new_port_value)
end

function _on_clear_log_button_pressed(  )
    log_display.log_text:clear()
    log_display.log("[log cleared]")
end

server_panel.signals:register("button_start_clicked", _on_start_server_button_pressed)
server_panel.signals:register("button_clear_log_clicked", _on_clear_log_button_pressed)
server_panel.signals:register("button_test_log_clicked", _on_test_log_button_pressed)
server_panel.signals:register("port_field_changed", _on_port_field_changed)

------------------------------------------------------------------------------------------
-- peers panel
local peers_panel = enet_ui.peer_list_panel( )
peers_panel.window:hide()

------------------------------------------------------------------------------------------
-- stats panel
local stats_panel = enet_ui.stats_window({ 325, 475, 100, 200 })
stats_panel.window:hide()

------------------------------------------------------------------------------------------
-- dummy logging
local rng = love.math.newRandomGenerator()
rng:setSeed( os.time() )
local client_names = {"enit", "commosa", "eltuu", "b-aoAR"}
function test_log()
    if test_log_with_dummy_logs then
        local rr = rng:random()
        if rr < 0.1 then
            -- local new_str = string.format("%s:[%s][command][%s]", log_panel.n_lines, os.time(), client_names[rng:random(#client_names)] )
            local new_str = string.format("%s:[%s][command][%s]", log_display._n_lines, os.time(), client_names[rng:random(#client_names)] )
            -- log_panel:log( new_str )
            -- print(new_str)
            log_display.log( new_str )
        end
    end
end


------------------------------------------------------------------------------------------
--- server callbacks
function _on_peer_connected(peer)
    -- log_panel:log( string.format("[peer connected] %s (index: %s, id: %s )", peer, peer:index(), peer:connect_id()) )
    log_display.log( string.format("[peer connected] %s (index: %s, id: %s )", peer, peer:index(), peer:connect_id()) )
    print("adding peer to the peers_panel")
    peers_panel.update_peers_list( server )
    stats_panel.update_connections( server )
end

function _on_peer_disconnected( peer )
    -- log_panel:log( string.format("[peer disconnected] %s", peer) )
    log_display.log( string.format("[peer disconnected] %s", peer) )
    peers_panel.update_peers_list( server )
    stats_panel.update_connections( server )
end

function _on_peer_received( message, peer )
    -- log_panel:log( string.format("[received] %s '%s'", peer, message) )
    log_display.log( string.format("[received] %s '%s'", peer, message) )
end

server.signals:register("connected", _on_peer_connected)
server.signals:register("disconnected", _on_peer_disconnected)
server.signals:register("received", _on_peer_received)

------------------------------------------------------------------------------------------
function EnetTest:init()
    --- scene_manager callback
    -- log_panel:log( "[log begin]" )
    log_display.log("[log begin]")
    print(string.format("server: %s", server))
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
    
    log_display.draw()
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