-- set the code page to UTF-8 to render non-ASCII characters correctly (e.g. Ö)
gspot = require "lib.gspot.Gspot"
local signal = require "lib.signal"


os.execute("chcp 65001 > NUL")

print(string.format("LÖVE2D v%i.%i.%i\n%s", love.getVersion()) )

--https://patorjk.com/software/taag font: tmplr, and https://asciiflow.com/#/ for therectangle
local garden_logo = [[
    ┌─────────────────┐ 
    │         ┓       │ 
    │  ┏┓┏┓┏┓┏┫┏┓┏┓   │ 
    │  ┗┫┗┻┛ ┗┻┗ ┛┗   │ 
    │   ┛             │ 
    └─────────────────┘ 
]]
print("\n")
print("\27[38;5;84m" .. garden_logo .. "\27[0m")

print("-----------------------------------\ncli:")
-- lua-local-debugger for VSCode: https://github.com/tomblind/local-lua-debugger-vscode
lldebugger = nil
local DEBUG_MODE = false
local PROFILE = false
local CLIENT_MODE = false
for k,v in pairs(arg) do
    print(v)
    if v == "debug" then
        if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
            DEBUG_MODE = true
            lldebugger = require("lldebugger")
            lldebugger.start()
        else
            print("lldebugger unavailable")
        end
    end
    if v == "client" then
        -- stry to switch scenes straight into the client interface
        CLIENT_MODE = true
    end
end

print("DEBUG_MODE ", DEBUG_MODE)

------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;118m[main]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end
------------------------------------------------------------------------------------------

-- scenes and scene selector
Scenes = require("lib.scene_manager")
-- gspot scene selector
local scene_selector_ui = {}
function new_scene_selector()
    local this = scene_selector_ui
    local w = 150
    local h = 200
    this.window = gspot:group("scene selector", {x = love.graphics.getWidth() - w - 16, y = 16, w= w, h = h })
    this.window.drag = true
    this.signals =  signal:new()
    
    this.buttons = {}
    local i = 0
    for k,v in pairs(Scenes.states) do
        -- buttons
        this.buttons[k] = gspot:button( k, {x=4, y=gspot.style.unit + i*20, w=this.window.pos.w-8, h = gspot.style.unit }, this.window )
        this.buttons[k].tip = Scenes.long_names[k] .. "\n--\n" .. Scenes.descriptions[k]
        this.window:addchild( this.buttons[k], 'vertical' )
        this.buttons[k].click = function(this_button, x, y)
            print(string.format('Scenes selector button "%s" pressed', k))
            Scenes:switch(k)
        end
        i = i +1
    end
    return this
end

local scene_selector = nil

------------------------------------------------------------------------------------------
love.window.setTitle("garden")
io.stdout:setvbuf("no")

local font_medium = love.graphics.newFont(20)
local font_small = love.graphics.newFont(10)

------------------------------------------------------------------------------------------
local global_time = 0
local global_frame = 0

function love.load()
    -- imgui.love.Init()
    love.mouse.setVisible( false )
    
    if CLIENT_MODE then
        Scenes:init("enet_client_test")
    else
        Scenes:init("enet_test")
    end
    scene_selector = new_scene_selector()
    if CLIENT_MODE then
        scene_selector.window:hide()
    end

    -- graphics
    love.graphics.setLineStyle("rough")

    if PROFILE then
        love.profiler = require('lib.profile.profile') 
        love.profiler.start()
    end
end


function love.draw()
    Scenes:draw()
    love.graphics.setColor(1,1,1,1)
    gspot:draw()
   
    love.graphics.setColor(1.0,1.0,1.0,0.5)
    love.graphics.circle("fill", love.mouse.getX(), love.mouse.getY(), 3.25)
    local fps = love.timer.getFPS()
    love.graphics.setFont(font_medium)
    love.graphics.print(string.format("%i",fps), 10, 10)
    -- 
    if DEBUG_MODE then
        love.graphics.setColor( 1.0, 0.2, 0.2, 0.5)
        love.graphics.setFont(font_medium)
        love.graphics.print( "DEBUG", love.graphics.getWidth() /2 - 35, 20 )
        love.graphics.setFont(font_small)
        love.graphics.print( "(ctrl-F4 to breakpoint)", love.graphics.getWidth() /2 - 53, 44 )        
    end
    if PROFILE then
        print(love.report)
    end
end


function love.update(dt)
    global_time = global_time + dt
    global_frame = global_frame + 1


    if PROFILE and global_frame%100 == 0 then
        love.report = love.profiler.report(20)
        love.profiler.reset()
    end

    Scenes:update(dt)
    gspot:update(dt)
    -- print("gspot.mousein: ", gspot.mousein)
    -- print("gspot.focus: ", gspot.focus)

    -- breakpoint ------------------------------------------------------------------------
    if love.keyboard.isDown('lctrl') and love.keyboard.isDown('f4') then
        if DEBUG_MODE then
            print("BREAK")
            lldebugger.requestBreak()
        end
    end
end


------------------------------------------------------------------------------------------
love.mousemoved = function(x, y, ...)
    Scenes:mousemoved( x,y, ... )
end


love.mousepressed = function(x, y, button, ...)
    gspot:mousepress(x, y, button)
    if gspot.mousein == false then
        Scenes:mousepressed( x, y, button, ... )
    end
end


love.mousereleased = function(x, y, button, ...)
    Scenes:mousereleased( x,y,button, ... )
    gspot:mouserelease(x, y, button)
end


love.wheelmoved = function(x, y)
    Scenes:wheelmoved(x,y)
    gspot:mousewheel(x, y)
end


love.keyreleased = function(key, ...)
    Scenes:keyreleased( key, ... )
end


love.textinput = function(t)
    if gspot.focus then
        gspot:textinput(t) -- only sending input to the gui if we're not using it for something else
    else
        Scenes:textinput( t )
    end
end


function love.keypressed(key, code, isrepeat)
    if key == "escape" then
        love.event.quit()
    end
    Scenes:keypressed( key, code, isrepeat )
    if gspot.focus then
        gspot:keypress(key) -- only sending input to the gui if we're not using it for something else
    else
        gspot:feedback(key) -- why not
    end
end


love.quit = function()
    --
end


-- debug ---------------------------------------------------------------------------------
local love_errorhandler = love.errorhandler

function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    else
        return love_errorhandler(msg)
    end
end