local EnetTest ={}
EnetTest.scene_name = "Enet networking components test"
EnetTest.description = "testing ground for the networking components"

-- local ffi = require"ffi"

-- local Slab = require "Slab"
local gspot = require "lib.gspot.Gspot"


local font_small = love.graphics.newFont(10)



log_window = {}
log_window.log_text = "" --{}
log_window.config = {}
log_window.config.autoscroll = true
log_window.n_lines = 0 -- update manually


function log_window:log( text )
    self.log_text = self.log_text .. text
    self.n_lines = self.n_lines + 1
end

function log_window:draw()

end

local server_start_button = false

------------------------------------------------------------------------------------------
local rng = love.math.newRandomGenerator()
rng:setSeed( os.time() )

local client_names = {"enit", "commosa", "eltuu", "b-aoAR"}

------------------------------------------------------------------------------------------
function EnetTest:init()
    log_window:log( "[log begin]" )
    -- Slab.Initialize()


	log_group = gspot:group('Log', {150, 250, 512, 512})
	log_group.drag = true
	-- log_group.tip = 'main log window'

    button_clear = gspot:button( "clear log", {x=2, y=2, w=50,h = gspot.style.unit-4}, log_group )
    button_clear.style.hilite = {0.4,0.4,0.4,1.0}
    button_clear.click = function(this)
        print("clearing log")
        log_window.log_text = ""
        local children_to_remove = {}
        for k,v in pairs(scrollgroup.children) do
            if v.elementtype == "text" then
                table.insert(children_to_remove, v)
            end
        end
        for k,child in pairs(children_to_remove) do
            scrollgroup:remchild( child )
            gspot:rem( child )
        end
        log_window:log("[log cleared]")
        scrollgroup:addchild(gspot:text(log_window.log_text, {w = 512} ),'vertical')
    end

    local autoscroll_checkbox = gspot:checkbox("autoscroll", {x = 50+2+5, y = 2, r = 6}, log_group)
    autoscroll_checkbox.value = true
    autoscroll_checkbox.style.fg = {1.0, 0.5, 0.0, 1.0}

    autoscroll_checkbox.click = function(this)
		gspot[this.elementtype].click(this) -- calling option's base click() to preserve default functionality, as we're overriding a reserved behaviour
		if this.value then this.style.fg = {1.0, 0.5, 0.0, 1.0}
		else this.style.fg = {1.0, 1.0, 1.0, 1.0} end
        log_window.config.autoscroll = not log_window.config.autoscroll
        print("log_window.config.autoscroll ", log_window.config.autoscroll)
    end

    -- scrollgroup's children, excepting its scrollbar, will scroll
	scrollgroup = gspot:scrollgroup(nil, {0, gspot.style.unit, 512, 512}, log_group) -- scrollgroup will create its own scrollbar
	scrollgroup.style.bg = {0.2,0.2,0.2,1.0}
    -- scrollgroup.scrollh.tip = 'Scroll (mouse or wheel)' -- scrollgroup.scrollh is the horizontal scrollbar
	scrollgroup.scrollh.style.hs = scrollgroup.style.unit*2
	-- scrollgroup.scrollv.tip = scrollgroup.scrollh.tip -- scrollgroup.scrollv is the vertical scrollbar
	-- scrollgroup.scroller:setshape('circle') -- to set a round handle
	scrollgroup.scrollh.drop = function(this) gspot:feedback('Scrolled to : '..this.values.current..' / '..this.values.min..' - '..this.values.max) end
	scrollgroup.scrollv.drop = scrollgroup.scrollh.drop
	scrollgroup.scrollv.style.hs = "auto"

    -- scrollgroup:addchild(gspot:text(log_window.log_text, {w = 128}), 'grid')
    scrollgroup_logtext = gspot:text(log_window.log_text, {w = 512}, scrollgroup)
    
    -- scrollgroup:addchild(gspot:text(log_window.log_text, {w = 512}), 'vertical')
    scrollgroup:addchild(scrollgroup_logtext, 'vertical')

	-- additional scroll controls
	button_up = gspot:button('up', {log_group.pos.w, 0}, log_group) -- a small button attached to the scrollgroup's group, because all of a scrollgroup's children scroll
	button_up.click = function(this)
		local scroll = scrollgroup.scrollv
		scroll.values.current = math.max(scroll.values.min, scroll.values.current - scroll.values.step) -- decrement scrollgroup.scrollv.values.current by scrollgroup.scrollv.values.step, and the slider will go up a notch
		scroll:drop()
	end
	button_down = gspot:button('dn', {log_group.pos.w, log_group.pos.h + gspot.style.unit}, log_group)
	button_down.click = function(this)
		local scroll = scrollgroup.scrollv
		scroll.values.current = math.min(scroll.values.max, scroll.values.current + scroll.values.step) -- this one increment's the scrollbar's values.current, moving the slider down a notch
		scroll:drop()
	end
    -- for some reason this last button ^ would
    -- become nil while removing the text objects from 
    -- the scrollgroup children. So had ot make an extra sacrificial button.
	button_down_2 = gspot:button('sacrifical', {log_group.pos.w, log_group.pos.h + gspot.style.unit+18}, log_group)
    button_down_2:hide()

end


function EnetTest:update(dt)
    -- Slab.Update(dt)
    -- Slab.BeginWindow("server", {Title = "server", X = 25, Y = 200, NoSavedSettings = true } ) 
    -- if Slab.Button("start") then
    --     server_start_button = true
    -- end
    -- Slab.EndWindow()

    if rng:random() < 0.1 then
        -- can't seem to work out how to add text to the tex control without adding a whole new gspot:text instance each line.
        local new_str = string.format("%s:[%s][command][%s]", log_window.n_lines, os.time(), client_names[rng:random(#client_names)] )
        log_window:log( new_str  )
        scrollgroup:addchild(gspot:text(new_str, {w = 512} ),'vertical')
        -- scrollgroup_logtext.label = log_window.log_text
    end

    --------------------------------------------------------------------------------------
    -- autoscroll (move to _on_log event)
    --scrollgroup.scrollv:drag(0.0, scrollgroup.scrollv.values.max - 1 ) -- scrollgroup.scrollv.values.max)
    if log_window.config.autoscroll then
        scrollgroup.scrollv.values.current = scrollgroup.scrollv.values.max
        scrollgroup.scrollv:drop()
    end
    --------------------------------------------------------------------------------------
    gspot:update(dt)
end

function EnetTest:draw()
    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Enet test")

    -- Slab.Draw()

    gspot:draw()

    love.graphics.setColor(1,.3,.3,1)
    -- love.graphics.setFont( font_small )
    love.graphics.print("[  ] put gspot log window components into its own table object\
[  ] update autoscroll _on_add_log events instead of every tick\
[  ] remove cimgui\
[  ] remove Slab",
                        log_group:getpos().x + log_group:getmaxw() +5,
                        log_group:getpos().y)
end

------------------------------------------------------------------------------------------

function EnetTest:keypressed(key, code, isrepeat)
	if gspot.focus then
		gspot:keypress(key) -- only sending input to the gui if we're not using it for something else
	else
		gspot:feedback(key) -- why not
	end
end

function EnetTest.textinput(key)
	if gspot.focus then
		gspot:textinput(key) -- only sending input to the gui if we're not using it for something else
	end
end


function EnetTest:mousepressed (x, y, button)
	gspot:mousepress(x, y, button) -- pretty sure you want to register mouse events
end


function EnetTest:mousereleased(x, y, button)
	gspot:mouserelease(x, y, button)
end


function EnetTest:wheelmoved(x, y)
	gspot:mousewheel(x, y)
end

------------------------------------------------------------------------------------------
return EnetTest