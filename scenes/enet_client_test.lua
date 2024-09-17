local enet_ui = require "lib.enet_test_ui" -- some utils
local net = require "lib.network" -- main networking objects
local gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"
local client_ui = require "lib.enet_client_ui"
local log_ui = require "lib.log_ui"
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
local log_panel = log_ui:new("client log panel")

------------------------------------------------------------------------------------------

local EnetClientTest = {}
local client = net.Client:new("Benny")

function _on_connected( event )
    log_panel:log(string.format("connect event: %s", event))
end

function _on_received( event )
    log_panel:log(string.format("received: '%s'", event.data))
end

function _on_disconnected( event )
    log_panel:log(string.format("disconnected: '%s'", event.data))
end


client.signals:register("connected", _on_connected)
client.signals:register("received", _on_received)
client.signals:register("disconnected", _on_disconnected)

local main_menu = client_ui.main_menu()
main_menu.window:hide()

local function _on_connect_attempted()
    print("attempting connecion")
    log_panel:log( "attempting connecion" )
    print(string.format( "%s:%s", main_menu.address.label, main_menu.port ) )
    client:connect( main_menu.address.label, main_menu.port )
    -- client:connect( "192.168.1.106", 6789)
    EnetClientTest.connected = true
    main_menu.announce_connected()
end

main_menu.signals:register("connect_attempted", _on_connect_attempted)


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
        main_menu.address.label = address
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
    -- print("EnetClientTest:update")
    if EnetClientTest.connected then
        client:update(dt)
    end
end


function EnetClientTest:draw()
    -- print("EnetClientTest:init")
    log_panel:draw()
end


function EnetClientTest:quit()
    client:disconnect()
end

return EnetClientTest