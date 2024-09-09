-- set the code page to UTF-8 to render non-ASCII characters correctly (e.g. Ö)
os.execute("chcp 65001 > NUL")

print(string.format("LÖVE2D v%i.%i.%i\n%s", love.getVersion()) )

--https://patorjk.com/software/taag font: tmplr, and https://asciiflow.com/#/ for therectangle
print([[
    
    ┌─────────────────┐
    │         ┓       │
    │  ┏┓┏┓┏┓┏┫┏┓┏┓   │
    │  ┗┫┗┻┛ ┗┻┗ ┛┗   │
    │   ┛             │
    └─────────────────┘ 
]])


-- cmdline -------------------------------------------------------------------------------
print("-----------------------------------\ncli")
-- lua-local-debugger for VSCode: https://github.com/tomblind/local-lua-debugger-vscode
lldebugger = nil
local DEBUG_MODE = false
for k,v in pairs(arg) do
    if v == "debug" then
        if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
            DEBUG_MODE = true
            lldebugger = require("lldebugger")
            lldebugger.start()
        else
            print("lldebugger unavailable")
        end
    end
end

print("DEBUG_MODE ", DEBUG_MODE)


-- local imgui_mode = "cimgui" -- "cimgui"

-- if imgui_mode == "cimgui" then
    -- cimgui, dearimgui generated for LOVE2D ------------------------------------------------
    -- from here: https://love2d.org/wiki/cimgui-love
    -- here: https://codeberg.org/apicici/cimgui-love/releases
    -- and here: https://codeberg.org/apicici/cimgui-love
    -- I have put the .dll in the ./cimgui directory and ignored ./cimgui from git.
------------------------------------------------------------------------------------------
-- https://github.com/ocornut/imgui/blob/master/imgui_demo.cpp
-- line 80605, ShowExampleAppLog()
-- https://github.com/ocornut/imgui/blob/a2366f902249107f1533a85d3d1f93ec193f52f0/imgui_demo.cpp#L8605C39-L8605C58

-- some LuaJIT-ImGui examples
-- https://github.com/sonoro1234/LuaJIT-ImGui/tree/docking_inter/examples

-- need to use ffi types when passing a reference
------------------------------------------------------------------------------------------
print("-----------------------------------\ncimgui")
print("based on version 1.90.8 (docking branch) of Dear ImGui and LÖVE 11.5")
local lib_path = love.filesystem.getSource() .. "/lib/cimgui"
-- local extension = jit.os == "Windows" and "dll" or jit.os == "Linux" and "so" or jit.os == "OSX" and "dylib"
package.cpath = string.format("%s;%s/?.%s", package.cpath, lib_path, "dll")
print("package.cpath: ", package.cpath)
imgui = require "lib.cimgui" -- note: global.
print("-----------------------------------")
-- elseif imgui_mode == "imgui" then
--     -- https://github.com/slages/love-imgui
--     print("-----------------------------------\nlove-imgui")
--     local lib_path = love.filesystem.getSource() .. "/lib/imgui"
--     package.cpath = string.format("%s;%s/?.%s", package.cpath, lib_path, "dll")
--     print("package.cpath: ", package.cpath)
--     imgui = require"imgui"
--     print("imgui ", imgui)
--     print("-----------------------------------")
-- end
------------------------------------------------------------------------------------------
love.window.setTitle("garden")
io.stdout:setvbuf("no")

local font_medium = love.graphics.newFont(20)
local font_small = love.graphics.newFont(10)

------------------------------------------------------------------------------------------
-- scenes
-- Scenes = {}
-- Scenes["quadtree_main"] = require"quadtree_main"
Scenes = require("lib.scene_manager")



------------------------------------------------------------------------------------------
local gloabl_time = 0

function love.load()
    imgui.love.Init()
    love.mouse.setVisible( false )
    
    -- Scenes:init("circles_around_circles")--"enet_test") --"circles_around_circles")--"quadtree_main" )
    Scenes:init("enet_test")

    -- graphics
    love.graphics.setLineStyle("rough")
end


function love.draw()
    
    Scenes:draw()
    
    love.graphics.setColor(1,1,1,1)
    
    -- example window
    -- imgui.ShowDemoWindow()
    
    Show_scenes_selector()
    -- imgui.ShowDemoWindow()
    -- code to render imgui
    imgui.Render()
    imgui.love.RenderDrawLists()
    
    -- TODO: need some better way of coercing the mouse cursor
    -- if not imgui.love.GetWantCaptureMouse() then

    if not imgui.love.GetWantCaptureMouse() then
    -- if not imgui.GetWantCaptureMouse() then
        love.mouse.setVisible( false )
    else
        love.mouse.setVisible( true )
    end
   
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

end


function love.update(dt)
    gloabl_time = gloabl_time + dt

    Scenes:update(dt)
    
    imgui.love.Update(dt)
    imgui.NewFrame()
    
    -- breakpoint ------------------------------------------------------------------------
    if love.keyboard.isDown('lctrl') and love.keyboard.isDown('f4') then
        if DEBUG_MODE then
            print("BREAK")
            lldebugger.requestBreak()
        end
    end
end


------------------------------------------------------------------------------------------
function Show_scenes_selector()
    imgui.Begin("Scenes", nil, imgui.ImGuiWindowFlags_AlwaysAutoResize)
    for k,v in pairs(Scenes.states) do
        if imgui.Button(k) then
            print(string.format('Scenes selector button "%s" pressed', k))
            Scenes:switch(k)
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip(Scenes.descriptions[k])
        end
    end
    
    imgui.End()
end


------------------------------------------------------------------------------------------
love.mousemoved = function(x, y, ...)
    imgui.love.MouseMoved(x,y)
    -- imgui.MouseMoved(x,y)
    -- if not imgui.love.GetWantCaptureMouse() then
    if not imgui.love.GetWantCaptureMouse() then
    -- if not imgui.GetWantCaptureMouse() then
        Scenes:mousemoved( x,y, ... )
    end
end


love.mousepressed = function(x, y, button, ...)
    imgui.love.MousePressed(button)
    -- imgui.MousePressed(button)
    if not imgui.love.GetWantCaptureMouse() then
    -- if not imgui.GetWantCaptureMouse() then
        Scenes:mousepressed( x, y, button, ... )
    end
end


love.mousereleased = function(x, y, button, ...)
    imgui.love.MouseReleased(button)
    -- imgui.MouseReleased(button)
    if not imgui.love.GetWantCaptureMouse() then
    -- if not imgui.GetWantCaptureMouse() then
        Scenes:mousereleased( x,y,button, ... )
    end
end


love.wheelmoved = function(x, y)
    imgui.love.WheelMoved(x, y)
    -- imgui.WheelMoved(x, y)
    if not imgui.love.GetWantCaptureMouse() then
    -- if not imgui.GetWantCaptureMouse() then
        Scenes:wheelmoved(x,y)
    end
end


love.keyreleased = function(key, ...)
    imgui.love.KeyReleased(key)
    -- imgui.KeyReleased(key)
    if not imgui.love.GetWantCaptureKeyboard() then
    -- if not imgui.GetWantCaptureKeyboard() then
        Scenes:keyreleased( key, ... )
    end
end


love.textinput = function(t)
    imgui.love.TextInput(t)
    -- imgui.TextInput(t)
    if not imgui.love.GetWantCaptureKeyboard() then
    -- if not imgui.GetWantCaptureKeyboard() then
        Scenes:textinput( t )
    end
end


love.quit = function()
    return imgui.love.Shutdown()
    -- return imgui.ShutDown()
end


function love.keypressed(key, code, isrepeat)
    imgui.love.KeyPressed(key)
    -- imgui.KeyPressed(key)
    if not imgui.love.GetWantCaptureKeyboard() then
    -- if not imgui.GetWantCaptureKeyboard() then
        if key == "escape" then
            love.event.quit()
        end
        Scenes:keypressed( key, code, isrepeat )
    end
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