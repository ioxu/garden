-- networking objects
-- mainly using enet
local enet = require "enet"
local signal = require "lib.signal"

------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;37m[network]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end

------------------------------------------------------------------------------------------
Network = {}

--- @class Network.Server
--- @field name string
--- @field address string
--- @field port integer
--- @field host table
--- @field peer table
--- @field received_data boolean
--- @field clients table
--- @field signals Signal
Network.Server = {}

--- Base server type
--- @param name string arbitrary name
--- @param address string IPv4 address
--- @param port integer port number
function Network.Server:new( name, address, port )
    Network.Server.__index = Network.Server
    local self = setmetatable({}, Network.Server)
    self.name = name or "server"
    self.address = address or "127.0.0.1"
    self.port = port or 5678
    self.host = nil
    self.peer = nil
    self.received_data = false
    self.clients = {}
    self.signals = signal:new()
    return self
end


--- @return string address the address and port concatenated
function Network.Server:full_address()
    return string.format("%s:%s", self.address, self.port)
end

--- @return ENetHost? host 
function Network.Server:start()
    print("Server:start() trying ", self:full_address() )
    self.host = enet.host_create( self:full_address() )
    if self.host then
        print(string.format("started server at %s", self))
    else
        print(string.format("failed to start server at %s", self))
    end
    return self.host
end


function Network.Server:stop()
    print(string.format("%s stopping", self))
    ----------------------------
    --- TDO need to loop through all peers?
    ----------------------------
    if self.peer then
        print(string.format("  disconnect peer %s", peer))
        self.peer:disconnect_now()
        self.peer = nil
    end
    self.host = nil
    self.received_data = false
end


function Network.Server:update( dt )
    if not self.host then return end
    
    local _nc = self:nclients()
    -- print("#server.clients", _nc)
    if _nc == 0 then
        self.received_data = false
    end

    local received_message = nil

    local event = self.host:service()
    if event then
        self.received_data = true
        self.peer = event.peer
        print("----")
        for k, v in pairs(event) do
            print(string.format("%s %s", k, v))
            if v=="disconnect" then
                print(string.format("peer %s disconnected!", self.peer))
                self.clients[self.peer:index()] = nil
                self.signals:emit("disconnected", event.peer)
            end
        end
        if event.type == "receive" then
            received_message = split_by_pipe(event.data)[2]
            event.peer:send( string.format("recieved message '%s'", received_message ))
            self.signals:emit("received", received_message, event.peer)
        end

        if event.type == "connect" then
            self.clients[self.peer:index()] = self.peer
            event.peer:send(string.format("your-id|%s|%s", self.peer, self.peer:connect_id()))
            self.signals:emit("connected", event.peer)
        end
    end
end


function Network.Server:nclients(  )
    local i = 0 
    for k,v in pairs(self.clients) do
        i = i+1
    end
    return i
end


function Network.Server:is_connected()
    return self.received_data
end


function Network.Server.__tostring( self )
    return string.format("%s@%s:%s", self.name, self.address, tostring(self.port))
end

------------------------------------
function split_by_pipe(input)
    local result = {}
    for part in string.gmatch(input, "([^|]+)") do
        table.insert(result, part)
    end
    return result
end

------------------------------------
return Network