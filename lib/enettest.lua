-- tools for the enet_test.lua test scene
local gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"
Enettest = {}

local unit = gspot.style.unit

------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;221m[enet_test\27[38;5;80m.lib\27[38;5;221m]\27[0m "
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

    -- start evrer button
    this.button_start = gspot:button("start", {x=4, y=unit/2, w=this.window.pos.w-8, h=unit}, this.window  )
    this.window:addchild( this.button_start, 'vertical' )
    this.button_start.click = function (this_button, x, y)
        print("button_start clicked")
        this.signals:emit( "button_start_clicked" )
    end
    
    -- test log button
    this.button_test_log = gspot:button( "test log", {x=4, y=16, w=this.window.pos.w-8, h=unit}, this.window )
    this.window:addchild( this.button_test_log, 'vertical' )
    this.button_test_log.click = function (this_button, x, y)
        print("button_test_log_clicked")
        this.signals:emit("button_test_log_clicked")
    end

    return this
end


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
		scroll:drop()
	end
	this.button_down = gspot:button('dn', {this.window.pos.w, this.window.pos.h + gspot.style.unit}, this.window)
	this.button_down.click = function(this_button)
		local scroll = this.scrollgroup.scrollv
		scroll.values.current = math.min(scroll.values.max, scroll.values.current + scroll.values.step) -- this one increment's the scrollbar's values.current, moving the slider down a notch
		scroll:drop()
	end
    -- for some reason this last button ^ would
    -- become nil while removing the text objects from 
    -- the scrollgroup children. So had ot make an extra sacrificial button.
	this.button_down_2 = gspot:button('sacrifical', {this.window.pos.w, this.window.pos.h + this.window.style.unit+18}, this.window)
    this.button_down_2:hide()

    -- loging
    this.log = function(this_panel, text)
        this_panel.log_text = this_panel.log_text .. text
        this_panel.n_lines = this_panel.n_lines + 1
        this_panel.scrollgroup:addchild(gspot:text(text, {w = 512} ),'vertical')
    end

    -- love callbacks
    this.scrollgroup.update = function( this_scrollg, dt )
        -- print("this.scrollgroup.update")
        if this.autoscroll then
            this_scrollg.scrollv.values.current = this_scrollg.scrollv.values.max
        end
    end

    return this
end


function Enettest.stats_window()
    local window = gspot:group("stats", {700,300,100,200})
    window.drag = true

    -- scrollgroup = gspot:scrollgroup("scrollgroup", {})

    local fps_label = gspot:text( 'fps', {w = window.pos.w}, window )
    window:addchild(fps_label, 'vertical')

    window.update = function(this, dt)
        local fps = love.timer.getFPS( )
        fps_label.label = "fps: " .. tostring(fps)
    end
    return window
end




return Enettest