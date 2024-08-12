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


-- cimgui, dearimgui generated for LOVE2D ------------------------------------------------
-- from here: https://love2d.org/wiki/cimgui-love
-- here: https://codeberg.org/apicici/cimgui-love/releases
-- and here: https://codeberg.org/apicici/cimgui-love
-- I have put the .dll in the ./cimgui directory and ignored ./cimgui from git.
local lib_path = love.filesystem.getSource() .. "/cimgui"
-- local extension = jit.os == "Windows" and "dll" or jit.os == "Linux" and "so" or jit.os == "OSX" and "dylib"
package.cpath = string.format("%s;%s/?.%s", package.cpath, lib_path, "dll")
print(package.cpath)
local imgui = require "cimgui"
------------------------------------------------------------------------------------------

io.stdout:setvbuf("no")
------------------------------------------------------------------------------------------

local quadtree_main = require"quadtree_main"

local gloabl_time = 0

function love.load()
    imgui.love.Init()
    quadtree_main.load()
end


function love.draw()
    quadtree_main.draw()
    love.graphics.setColor(1,1,1,1)

    -- example window
    imgui.ShowDemoWindow()
    
    -- code to render imgui
    imgui.Render()
    imgui.love.RenderDrawLists()
end


function love.update(dt)
    gloabl_time = gloabl_time + dt
    quadtree_main.update(dt)
    imgui.love.Update(dt)
    imgui.NewFrame()


    -- if gloabl_time > 3 then
    --     print("breaking")
    -- end
end


love.mousemoved = function(x, y, ...)
    imgui.love.MouseMoved(x, y)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here
    end
end

love.mousepressed = function(x, y, button, ...)
    imgui.love.MousePressed(button)
    if not imgui.love.GetWantCaptureMouse() then
        quadtree_main.mousepressed(x,y,button, ...)
    end
end

love.mousereleased = function(x, y, button, ...)
    imgui.love.MouseReleased(button)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here 
    end
end

love.wheelmoved = function(x, y)
    imgui.love.WheelMoved(x, y)
    if not imgui.love.GetWantCaptureMouse() then
        -- your code here 
    end
end

-- function love.keypressed(key, ...)
--     print(key)
--     -- imgui.love.KeyPressed(key)
--     -- if not imgui.love.GetWantCaptureKeyboard() then
--     --     -- your code here 
--     -- end
-- end

love.keyreleased = function(key, ...)
    imgui.love.KeyReleased(key)
    if not imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
    end
end

love.textinput = function(t)
    imgui.love.TextInput(t)
    if not imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
    end
end

love.quit = function()
    return imgui.love.Shutdown()
end

function love.keypressed(key, code, isrepeat)
    imgui.love.KeyPressed(key)

    if not imgui.love.GetWantCaptureKeyboard() then
        quadtree_main.keypressed(key, code, isrepeat)
    end

    if key == "escape" then
        love.event.quit()
    end
end