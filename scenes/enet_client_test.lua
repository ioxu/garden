local enettest = require "lib.enettest" -- some utils
local net = require "lib.network" -- main networking objects
local gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"

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

function EnetClientTest:init()
    print("EnetClientTest:init")
    print("client", client)
    client:connect("192.168.1.103", 6789)
end


function EnetClientTest:update(dt)
    print("EnetClientTest:update")
    client:update(dt)
end


function EnetClientTest:draw()
    print("EnetClientTest:init")
end

return EnetClientTest