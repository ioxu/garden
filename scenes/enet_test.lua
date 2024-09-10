local EnetTest ={}
EnetTest.scene_name = "Enet networking components test"
EnetTest.description = "testing ground for the networking components"

local enettest = require "lib.enettest" -- some utils
local net = require "lib.network" -- main networking objects
local gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"

local font_small = love.graphics.newFont(10)


local font_large = love.graphics.newFont(60)

------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;221m[enet_test]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end
------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
-- stats panel
local stats_panel = enettest.stats_window()

------------------------------------------------------------------------------------------
-- log panel
local log_panel = enettest.log_panel({150, 250, 512, 512})

------------------------------------------------------------------------------------------
-- server panel
local server_panel = enettest.server_panel()

-- signal callbacks
function _on_test_log_button_pressed()
    print("_on_test_log_button_pressed")
    test_log_with_dummy_logs = not test_log_with_dummy_logs
    if test_log_with_dummy_logs then
        server_panel.button_test_log.label = "test_log (enabled)"
    else
        server_panel.button_test_log.label = "test_log (disabled)"
    end
end

local server_started_dummy = false

function _on_start_server_button_pressed()
    print("_on_start_server_button_pressed")
    server_started_dummy = not server_started_dummy
    if server_started_dummy then
        server_panel.button_start.label = "started"
        server_panel.button_start.style.hilite = {0.1,0.55,0.1,1.0}
        server_panel.button_start.style.focus = {0.4,1.0,0.4,1.0}
    else
        server_panel.button_start.label = "stopped"
        server_panel.button_start.style.hilite = {1.0,0.2,0.2,1.0}
        server_panel.button_start.style.focus = {1.0,0.4,0.4,1.0}
    end
end

server_panel.signals:register("button_start_clicked", _on_start_server_button_pressed)
server_panel.signals:register("button_test_log_clicked", _on_test_log_button_pressed)

------------------------------------------------------------------------------------------
-- dummy logging
local test_log_with_dummy_logs = false
local rng = love.math.newRandomGenerator()
rng:setSeed( os.time() )
local client_names = {"enit", "commosa", "eltuu", "b-aoAR"}
function test_log()
    if test_log_with_dummy_logs then
        if rng:random() < 0.1 then
            local new_str = string.format("%s:[%s][command][%s]", log_panel.n_lines, os.time(), client_names[rng:random(#client_names)] )
            log_panel:log( new_str )
        end
    end
end

------------------------------------------------------------------------------------------
function EnetTest:init()
    log_panel:log( "[log begin]" )
end


function EnetTest:update(dt)
    test_log()
    gspot:update(dt)
end

function EnetTest:draw()
    love.graphics.setColor(1,1,1,1)
    love.graphics.clear(0.15,0.15,0.15,1.0)
    love.graphics.print("Enet test")

    love.graphics.setColor(0.4,0.4,0.4,1.0)
    love.graphics.setFont(font_large)
    love.graphics.print("server stopped", 32, 32)

    gspot:draw()

    love.graphics.setFont(font_small)
    love.graphics.setColor(1,.3,.3,1)
    -- love.graphics.setFont( font_small )
    love.graphics.print("[  ] put gspot log window components into its own table object\
[  ] update autoscroll _on_add_log events instead of every tick\
[  ] remove cimgui",
                        log_panel.window:getpos().x + log_panel.window:getmaxw() +5,
                        log_panel.window:getpos().y)
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