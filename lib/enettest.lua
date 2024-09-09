-- tools for the enet_test.lua test scene
local gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"
Enettest = {}

local unit = gspot.style.unit

function Enettest.server_panel()
    local window = gspot:group("server", {25,250,100,200})
    window.drag = true
    window.signals = signal:new()
    window.style.bg = {0.42, 0.275, 0.192,1}--{ 1.0,0.5,0.0,1.0 }
    local start_button = gspot:button("start", {x=4, y=unit/2, w=window.pos.w-8, h=unit}, window  )
    window:addchild( start_button, 'vertical' )
    start_button.click = function (this, x, y)
        print("start_button clicked")
        window.signals:emit( "start_button_clicked" )
    end
    
    
    local test_log_button = gspot:button( "test log", {x=4, y=16, w=window.pos.w-8, h=unit}, window )
    window:addchild( test_log_button, 'vertical' )
    test_log_button.click = function (this, x, y)
        print("test_log_button_clicked")
        window.signals:emit("test_log_button_clicked")
    end

    return window
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