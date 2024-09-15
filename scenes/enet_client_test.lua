local enet_ui = require "lib.enet_test_ui" -- some utils
local net = require "lib.network" -- main networking objects
local gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"
local client_ui = require "lib.enet_client_ui"
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


local EnetClientTest = {}

local client = net.Client:new("Benny")

local main_menu = client_ui.main_menu()

function EnetClientTest:init()
    print("EnetClientTest:init")
    print("client", client)
    client:connect( net.get_ip_info(), 6789)

    print("Scenes:")
    for k,v in pairs(Scenes.states) do
        print(string.format("    %s [%s]",k,v))
    end

    print("finding server adress ..")
    local address = net.get_ip_info()
    if address then
        print(string.format("  .. %s", address))
        main_menu.address.label = address
    else
        print("couldn't infer a connection.")
    end
end


function EnetClientTest:update(dt)
    -- print("EnetClientTest:update")
    -- client:update(dt)
end


function EnetClientTest:draw()
    -- print("EnetClientTest:init")
end

return EnetClientTest