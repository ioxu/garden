-- tools for the enet_test.lua test server scene
-- server UI
local gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"
local net = require "lib.network"
Enettest = {}

local unit = gspot.style.unit

local font_medium = love.graphics.newFont(28)

------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;221m[enet_test_ui\27[38;5;80m.lib\27[38;5;221m]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end


------------------------------------------------------------------------------------------
local server_panel_table = {}
function Enettest.server_panel( pos )
    local this = server_panel_table
    pos = pos or {25,250,100,200}
    this.window = gspot:group("server", pos)
    this.window.drag = true
    this.signals = signal:new()
    -- this.window.style.bg = {0.42, 0.275, 0.192,1}--{ 1.0,0.5,0.0,1.0 }
    
    this.found_address = gspot:text( "no connection", {x=10, y=0, w=this.window.pos.w-8, h=unit}, this.window )
    local found_IPv4_address = net.get_ip_info()
    if found_IPv4_address then
        print("found_IPv4_address", found_IPv4_address)
        this.found_address.label = found_IPv4_address
    else
        print("could not determine network connection")
    end
    
    this.found_address.style.fg = {0.6,0.6,0.6,1.0}
    this.window:addchild( this.found_address, 'vertical')
    
    this.port = "6789"
    this.port_input = gspot:input("port", {x=32, w=this.window.pos.w -32 -4 ,  h= unit}, this.window, this.port)
    this.port_input.keyrepeat = true
    this.window:addchild( this.port_input, 'vertical' )
    this.port_input.done =  function(this_input)
        print("[server_panel] port changed to: ", this_input.value)
        this.port = this_input.value
        this.signals:emit( "port_field_changed", this.port)
    end
    
    -- start sevrer button
    this.button_start = gspot:button("start", {x=4, y=unit/2, w=this.window.pos.w-8, h=unit}, this.window  )
    this.window:addchild( this.button_start, 'vertical' )
    this.button_start.click = function (this_button, x, y)
        print("button_start clicked")
        this.signals:emit( "button_start_clicked" )
    end
    
    -- clear log button
    -- this.button_clear_log = gspot:button( "clear log", {x=4, y=unit/2, w=this.window.pos.w-8, h=unit}, this.window )
    this.button_clear_log = gspot:button( "clear log", {x=4, y=this.window.pos.h - unit*3 -4, w=this.window.pos.w-8, h=unit}, this.window )
    this.window:addchild( this.button_clear_log, 'vertical' )
    this.button_clear_log.click = function (this_button, x, y)
        print("button_clear_log clicked")
        this.signals:emit( "button_clear_log_clicked" )
    end

    -- test log button
    this.button_test_log = gspot:button( "test log", {x=4, y=this.window.pos.h - unit*2 -4, w=this.window.pos.w-8, h=unit}, this.window )
    this.window:addchild( this.button_test_log, 'vertical' )
    this.button_test_log.click = function (this_button, x, y)
        print("button_test_log_clicked")
        this.signals:emit("button_test_log_clicked")
    end
    
    return this
end


------------------------------------------------------------------------------------------

local peer_list_panel_table = {}


function Enettest.peer_list_panel(pos)
    local this = peer_list_panel_table
    pos = pos or {450, 350, 512, 512}
    this.window = gspot:group("Peers", pos)
    this.window.drag = true
    
    this.peers = {}
    this.peers_list_group = gspot:group( "", {x=4,y=unit +4, w=this.window.pos.w-8, h=this.window.pos.h-unit-8 }, this.window )
    this.peers_list_group.style.bg = {0.2,0.2,0.2,1}

    this.update_peers_list = function( server )
        print(string.format("updating peers list"))
        
        local _clear = {}

        for k,v in pairs( this.peers ) do
            _clear[k] = v
        end
        for k,v in pairs(_clear) do
            this.peers_list_group:remchild(v)
            gspot:rem(v)
            this.peers[k] = nil
        end

        local i = 0
        for k,v in pairs(server.clients) do
            print(string.format("  server.clients[%s]: %s",k, server.clients[k]) )
            -- local button_label =  string.format("%s  %s", server.nicknames[k], tostring(v))
            local button_label =  string.format("%s: %s  id: %s", v:index(), tostring(v), v:connect_id())
            local nickname = server.nicknames[k]
            this.peers[k] = gspot:button( button_label, {x=4, y=4 + (unit*2 + 4)*i , w=this.peers_list_group.pos.w-8, h=unit *2}, this.peers_list_group )
            this.peers[k].style.hilite = {0.4,0.4,0.4,1}
            
            -- custom draw function
            this.peers[k].draw = function( this_button, pos )
                -- draw normal button
                gspot.button.draw(this_button, pos)
                
                -- draw custom things
                if nickname then
                    love.graphics.setFont(font_medium)
                    love.graphics.print( nickname, pos.x +4, pos.y )
                end
                -- orange dot for no reason
                love.graphics.setColor(1.0,0.8,0.5,0.75)
                love.graphics.circle("fill", pos.x + (pos.w-15.0), pos.y+(pos.h/2.0), 10.0)
            end
            
            i = i +1
        end
    end
    
    return this
end


------------------------------------------------------------------------------------------
-- REDUNDANT
local log_panel_table = {}
function Enettest.log_panel(pos)
    local this = log_panel_table
    pos = pos or {150, 250, 512, 512}
    this.window = gspot:group('Log', pos)
    this.window.drag = true
    
    this.log_text = ""
    this.n_lines = 0
    this.autoscroll = true
    this.signals = signal:new()

    this.button_clear = gspot:button( "clear log", {x=2, y=2, w=50,h = gspot.style.unit-4}, this.window )
    this.button_clear.style.hilite = {0.4,0.4,0.4,1.0}
    this.button_clear.click = function(this_button)
        print("clearing log")
        this.log_text = ""
        local children_to_remove = {}
        for k,v in pairs(this.scrollgroup.children) do
            if v.elementtype == "text" then
                table.insert(children_to_remove, v)
            end
        end
        for k,child in pairs(children_to_remove) do
            this.scrollgroup:remchild( child )
            gspot:rem( child )
        end
        this:log("[log cleared]")
    end 

    this.autoscroll_checkbox = gspot:checkbox("autoscroll", {x = 50+2+5, y = 2, r = 6}, this.window)
    this.autoscroll_checkbox.value = true
    this.autoscroll_checkbox.style.fg = {1.0, 0.5, 0.0, 1.0}
    this.autoscroll_checkbox.click = function(this_checkbox)
		gspot[this_checkbox.elementtype].click(this_checkbox) -- calling option's base click() to preserve default functionality, as we're overriding a reserved behaviour
		if this_checkbox.value then this_checkbox.style.fg = {1.0, 0.5, 0.0, 1.0}
		else this_checkbox.style.fg = {1.0, 1.0, 1.0, 1.0} end
        this.autoscroll = not this.autoscroll
        print("\27[38;5;177mthis.autoscroll\27[0m ", this.autoscroll)
    end

    this.scrollgroup = gspot:scrollgroup(nil, {0, gspot.style.unit, 512, 512}, this.window) -- scrollgroup will create its own scrollbar
	this.scrollgroup.style.bg = {0.2,0.2,0.2,1.0}
	this.scrollgroup.scrollh.style.hs = this.scrollgroup.style.unit*2
	this.scrollgroup.scrollv.style.hs = "auto"
    -- this.scrollgroup_logtext = gspot:text("", {w = 512}, this.scrollgroup)
    -- this.scrollgroup:addchild(this.scrollgroup_logtext, 'vertical')

	-- additional scroll controls
	this.button_up = gspot:button('up', {this.window.pos.w, 0}, this.window) -- a small button attached to the scrollgroup's group, because all of a scrollgroup's children scroll
	this.button_up.click = function(this_button)
		local scroll = this.scrollgroup.scrollv
		scroll.values.current = math.max(scroll.values.min, scroll.values.current - scroll.values.step) -- decrement scrollgroup.scrollv.values.current by scrollgroup.scrollv.values.step, and the slider will go up a notch
		-- print("scroll.up ", scroll)
        -- scroll:drop()
	end
	this.button_down = gspot:button('dn', {this.window.pos.w, this.window.pos.h + gspot.style.unit}, this.window)
	this.button_down.click = function(this_button)
		local scroll = this.scrollgroup.scrollv
		scroll.values.current = math.min(scroll.values.max, scroll.values.current + scroll.values.step) -- this one increment's the scrollbar's values.current, moving the slider down a notch
		-- print("scroll.down ", scroll)
        -- scroll:drop()
	end
    -- for some reason this last button ^ would
    -- become nil while removing the text objects from 
    -- the scrollgroup children. So had ot make an extra sacrificial button.
	-- this.button_down_2 = gspot:button('sacrifical', {this.window.pos.w, this.window.pos.h + this.window.style.unit+18}, this.window)
    -- this.button_down_2:hide()

    -- loging
    this.log = function(this_panel, text)
        this_panel.log_text = this_panel.log_text .. text
        this_panel.n_lines = this_panel.n_lines + 1
        this_panel.scrollgroup:addchild(gspot:text(text, {w = 512} ),'vertical')
        
        -- apply autoscroll when a new line is logged
        if this.autoscroll then
            this.scrollgroup.scrollv.values.current = this.scrollgroup.scrollv.values.max
            
        end
    end

    -- love callbacks
    -- this.scrollgroup.update = function( this_scrollg, dt )
    --     -- print("this.scrollgroup.update")
    -- end

    return this
end

local stats_panel_table = {}
function Enettest.stats_window( pos )
    local this = stats_panel_table
    local pos = pos or { 25, 475, 100, 200 }
    this.window = gspot:group("stats", pos)
    this.window.drag = true


    this.fps_label = gspot:text( 'fps', {w = this.window.pos.w}, this.window )
    this.window:addchild(this.fps_label, 'vertical')
    this.fps_label.update = function(this_label, dt)
        local fps = love.timer.getFPS( )
        this_label.label = "fps: " .. tostring(fps)
    end

    this.server_connections_label = gspot:text("server connections", {w = this.window.pos.w}, this.window)
    this.window:addchild( this.server_connections_label, 'vertical' )

    this.update_connections = function( server )
        print("update_connections")
        this.server_connections_label.label = string.format( "connections: %d", #server.clients )
    end

    return this
end




return Enettest