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
--- @field port number
--- @field host table
--- @field peer table
--- @field received_data boolean
--- @field clients table
--- @field nicknames table table of string nicknames for each client (submitted by each client in the 'my-id' pragma)
--- @field signals Signal
Network.Server = {}

--- Base server type
--- @param name? string arbitrary name
--- @param address? string IPv4 address
--- @param port? number port number
function Network.Server:new( name, address, port )
    Network.Server.__index = Network.Server
    local self = setmetatable({}, Network.Server)
    self.name = name or "server"
    self.address = address or "127.0.0.1"
    self.port = port or 6789
    self.host = nil
    self.peer = nil
    self.received_data = false
    self.clients = {}
    self.nicknames = {}
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
        print(string.format("\27[31;5;193mfailed to start server at %s\27[0m", self))
    end
    return self.host
end


function Network.Server:stop()
    print(string.format("%s stopping", self))
    if self.peer then
        print(string.format("  disconnect peer %s", peer))
        self.peer:disconnect_now()
        self.peer = nil
    end
    -- to be sure
    for client_index,client in pairs(self.clients) do
        client:disconnect_now()
    end
    -- scrub list
    self.clients = {}

    self.host = nil
    self.received_data = false
end


function Network.Server:update( dt )
    if not self.host then return end
    
    local _nc = self:nclients()
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
                self.nicknames[self.peer:index()] = nil
                self.signals:emit("disconnected", event)
            end
        end
        if event.type == "receive" then
            self.signals:emit("received", event)
        end

        if event.type == "connect" then
            self.clients[self.peer:index()] = self.peer
            event.peer:send(string.format("your-id|%s|%s", self.peer, self.peer:connect_id()))
            self.signals:emit("connected", event)
        end
    end
end

--- Sets a nickname for an index matching the client index
--- @param index number nickname index to set
--- @param nickname string nickname to set
function Network.Server:set_nickname( index, nickname )
    self.nicknames[index] = nickname
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
    return string.format("'%s'@%s:%s", self.name, self.address, tostring(self.port))
end

------------------------------------
Network.Client = {}

function Network.Client:new(name)
    Network.Client.__index = Network.Client
    local self = setmetatable({}, Network.Client)
    self.name = name or "client"
    self.host = enet.host_create()
    self.peer = nil
    self.received_data = nil
    self.signals = signal:new()
    return self
end


function Network.Client:connect(address, port)
    self.host:connect(string.format('%s:%s', address, port))
end


function Network.Client:is_connected()
    return self.received_data
end


function Network.Client:update(dt)
    if self.host then
        local event = self.host:service()
        if event then
            self.received_data = true
            self.peer = event.peer
            print("----")
            for k, v in pairs(event) do
                print(string.format("%s %s",k,v) )
            end

            if event.type == "connect" then
                self.signals:emit("connected", event)
            elseif event.type == "receive" then
                self.signals:emit("received", event)
            elseif event.type == "disconnect" then
                self.signals:emit("disconnected", event)
            end
        end
    end
end


function Network.Client:disconnect()
    print("client disconnecting ..")
    if self.peer then
        print(string.format("  disconnect peer %s", self.peer))
        self.peer:disconnect_now()
        self.peer = nil
    end
    -- self.host = nil
    self.received_data = false
end


------------------------------------
function Network.get_ip_info()
    print("[get_ip_info] io.popen('ipconfig') :")
    local IPv4_address  = nil
    local res = io.popen("ipconfig")
    for line in res:lines() do
        if line.find(line, "IPv4") then
            print("[get_ip_info] ", line)
            local colon_index = line.find(line, ":")
            local address = line.sub(line, colon_index+1)
            IPv4_address = string.gsub(address, "%s+", "")
            print(string.format("[address] '%s'", IPv4_address))
        end
    end
    return IPv4_address
end


function split_by_pipe(input)
    local result = {}
    for part in string.gmatch(input, "([^|]+)") do
        table.insert(result, part)
    end
    return result
end

------------------------------------
return Network