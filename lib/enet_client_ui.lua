local net = require "lib.network" -- main networking objects
local gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"
local unit = gspot.style.unit
------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;221m[enet_client_ui\27[38;5;80m.lib\27[38;5;221m]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end

------------------------------------------------------------------------------------------
local client_ui = {}

local main_menu = {}
function client_ui.main_menu()
    this = main_menu
    this.signals = signal:new()

    this.STATUS_READY_TO_CONNECT = 1
    this.STATUS_NOT_READY_TO_CONNECT = 2
    this.status = this.STATUS_NOT_READY_TO_CONNECT
    
    this.window = gspot:group("main menu",{x=500,y=500, w=256,h=128})

    this.nickname = gspot:input("nickname",{x=64,y=4, w = this.window.pos.w -64 -4, h = unit}, this.window)
    this.nickname.keyrepeat = true
    this.window:addchild( this.nickname )
    this.nickname.done = function( this_input )
        print(string.format("nickname set: %s", this.nickname.value))
        this.signals:emit("nickname_changed", this.nickname.value)
        this_input.Gspot:unfocus()
        this.evaluate_ready_to_connect()
    end
    
    this.address = gspot:text("<address>", {x=64,y=4,w=this.window.pos.w -4, h= unit}, this.window)
    this.window:addchild(this.address, 'vertical')
    
    this.port = "6789"
    this.port_input = gspot:input("port",{x=64,y=4,w= this.window.pos.w -64 -4, h=unit}, this.window)
    this.port_input.value = this.port
    this.window:addchild(this.port_input, 'vertical')
    this.port_input.done = function( this_port )
        print(string.format("port set: %s", this.port_input.value))
        this.port = this.port_input.value
        this.signals:emit("port_changed", this.port)
        this_port.Gspot:unfocus()
    end

    this.button_connect = gspot:button("connect", {x=4,y=this.window.pos.h - (unit*4) -4, w=this.window.pos.w -8, h = unit*2 }, this.window)
    this.window:addchild(this.button_connect, 'vertical')
    this.button_connect.click = function(this_button)
        if this.status == this.STATUS_READY_TO_CONNECT then
            print("CONNECTING")
            this.signals:emit("connect_attempted")
        else
            print("cannot connect, check settings")
        end
    end

    -- check ready
    this.evaluate_ready_to_connect = function()
        this.status = this.STATUS_NOT_READY_TO_CONNECT
        this.button_connect.style.hilite = {0.65,0.2,0.2,1.0}
        this.button_connect.style.focus = {0.75,0.3,0.3,1.0}
        if this.nickname.value ~= "" and
        this.address.lable ~= "<address>"
        then
            this.status = this.STATUS_READY_TO_CONNECT
            this.button_connect.style.hilite = {0.2,0.65,0.2,1.0}
            this.button_connect.style.focus = {0.3,0.75,0.3,1.0}
        end
    end

    print('this.nickname.value ~= ""', (this.nickname.value ~= "") )
    this.evaluate_ready_to_connect()
    return this
end


return client_ui