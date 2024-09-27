local enet_ui = require "lib.enet_test_ui" -- some utils
local net = require "lib.network" -- main networking objects
local gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"
local client_ui = require "lib.enet_client_ui"
local entities = require "lib.entities"
local log_ui = require "lib.log_ui"
local tables = require "lib.tables"
local joystick_diagram = require "lib.joystick_diagram"
local shaping = require "lib.shaping"
local vector = require "lib.vector"
------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;42m[enet_client_test\27[38;5;80m.scene\27[38;5;221m]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end
------------------------------------------------------------------------------------------
local font_small = love.graphics.newFont(10)
------------------------------------------------------------------------------------------
local joysticks = love.joystick.getJoysticks()
local joystick = joysticks[1]

local log_panel = log_ui:new("client log panel")

------------------------------------------------------------------------------------------

-- this player
local this_player = {}
this_player.nickname = nil
this_player.id = nil
this_player.x = 0.0
this_player.y = 0.0
this_player.move_speed = 300
------------------------------------------------------------------------------------------

local EnetClientTest = {}
local client = net.Client:new("Benny")

local main_menu = client_ui.main_menu()
main_menu.window:hide()


function _on_connected( event )
    log_panel:log(string.format("connect event: %s", event))
end

function _on_received( event )
    log_panel:log(string.format("[received] '%s'", event.data))

    local split = tables.split_by_pipe(event.data)  --split_by_pipe(event.data)
    -- print(string.format("split[0] %s", split[1]))
    if split[1] == "your-id" then
        main_menu:set_local_address( split[2] )
        main_menu:set_connect_id( split[3] )
        entities.player_id = tonumber(split[3])
        this_player.id = tonumber(split[3])
        this_player.x = tonumber(split[4])
        this_player.y = tonumber(split[5])

        entities.spawn( entities.player_id, this_player.x, this_player.y )

        local send_str = string.format("my-id|%s", main_menu.nickname.value)
        log_panel:log("[send] '".. send_str .."'")
        event.peer:send(send_str)
    elseif split[1] == "peer-id" then
        -- spawn a peer entity
        local peer_id = tonumber( split[3] )
        if peer_id ~= this_player.id then
            print("SPAWN A PEER ", peer_id)
            entities.spawn( peer_id, tonumber(split[4]), tonumber(split[5]) )
        end
    elseif split[1] == "move" then
        local peer_id = tonumber( split[2] )
        if peer_id ~= this_player.id then
            entities.move( peer_id, tonumber(split[3]), tonumber(split[4]) )
        end
    end
end


function _on_disconnected( event )
    log_panel:log(string.format("disconnected: '%s'", event.data))
    main_menu.announce_disconnected()
end

client.signals:register("connected", _on_connected)
client.signals:register("received", _on_received)
client.signals:register("disconnected", _on_disconnected)


local function _on_connect_attempted()
    print("attempting connection")
    log_panel:log( "attempting connection" )
    -- print(string.format( "%s:%s", main_menu.address.label, main_menu.port ) )
    print(string.format( "%s:%s", main_menu.address.value, main_menu.port ) )
    -- client:connect( main_menu.address.label, main_menu.port )
    client:connect( main_menu.address.value, main_menu.port )
    -- client:connect( "192.168.1.106", 6789)
    EnetClientTest.connected = true
    main_menu.announce_connected()
end


local function _on_disconnect_attempted()
    print("attempting disconnection")
    log_panel:log("attempting disconnection")
    client:disconnect()
    main_menu.announce_disconnected()
end


local function _on_nickname_changed( nickname )
    this_player.nickname = nickname
end

main_menu.signals:register("nickname_changed", _on_nickname_changed)
main_menu.signals:register("connect_attempted", _on_connect_attempted)
main_menu.signals:register("disconnect_attempted", _on_disconnect_attempted)


------------------------------------------------------------------------------------------
function EnetClientTest:init()
    main_menu.window:show()
    print("EnetClientTest:init")
    print("client ", client)
    log_panel:log(string.format("client: %s", client))
    print("finding server adress ..")
    
    EnetClientTest.connected = false

    local address = net.get_ip_info()
    if address then
        print(string.format("  .. %s", address))
        -- main_menu.address.label = address
        main_menu.address.value = address
    else
        print("couldn't infer a connection.")
    end

end

function EnetClientTest:focus()
    main_menu.window:show()
end


function EnetClientTest:defocus()
    main_menu.window:hide()
end

function EnetClientTest:update(dt)

    -- pump network
    if EnetClientTest.connected then
        client:update(dt)
    end

    -- move
    local old_x, old_y = this_player.x, this_player.y

    -- joy axes
    local js_lx = joystick:getGamepadAxis( "leftx" )
    local js_ly = joystick:getGamepadAxis( "lefty" )
    
    -- deadzones
    if math.abs(js_lx) < 0.085 then
        js_lx = 0.0
    end
    if math.abs(js_ly) < 0.085 then
        js_ly = 0.0
    end

    if client:is_connected() and js_lx ~= 0.0 or js_ly ~= 0.0 then
        local n_lstick_dir_x, n_lstick_dir_y = vector.normalise( js_lx, js_ly )
        local lsktick_mag = shaping.clamp(vector.length( js_lx, js_ly ), 0.0, 1.0)

        this_player.x = this_player.x + n_lstick_dir_x * lsktick_mag * this_player.move_speed * dt
        this_player.y = this_player.y + n_lstick_dir_y * lsktick_mag * this_player.move_speed * dt
        entities.move( this_player.id, this_player.x, this_player.y )

        if old_x ~= this_player.x or old_y ~= this_player.y then
            local send_str = string.format("move|%s|%0.2f|%0.2f", this_player.id, this_player.x, this_player.y)
            log_panel:log(send_str)
            client.server:send(send_str)
        end
    end
end


function EnetClientTest:draw()
    -- print("EnetClientTest:init")
    love.graphics.setFont(font_small)
    entities.draw()
    love.graphics.setColor(1,1,1,1)
    for player_id, entity in pairs(entities.entities) do
        -- TODO: find a way to get nicknames from server to clients
        -- local nick = client.server.nicknames[player_id]
        -- print("nick ",nick)
        -- nick = nick or "-"
        -- print("nick ",nick)
        -- love.graphics.print( client.server.nicknames[player_id], entity.x -8 , entity.y + 8 )
        love.graphics.print( this_player.nickname, entity.x -8 , entity.y + 8 )
    end

    log_panel:draw()
    joystick_diagram.draw_PS4Controller_diagram( joystick , 1300, 825)
end


function EnetClientTest:quit()
    client:disconnect()
end

return EnetClientTest