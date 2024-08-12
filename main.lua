print(string.format("LOVE2D v%i.%i.%i %s", love.getVersion()) )

-- cimgui, dearimgui generated for LOVE2D ------------------------------------------------
-- from here: https://love2d.org/wiki/cimgui-love
-- here: https://codeberg.org/apicici/cimgui-love/releases
-- and here: https://codeberg.org/apicici/cimgui-love
local lib_path = love.filesystem.getSource() .. "/cimgui"
-- local extension = jit.os == "Windows" and "dll" or jit.os == "Linux" and "so" or jit.os == "OSX" and "dylib"
package.cpath = string.format("%s;%s/?.%s", package.cpath, lib_path, "dll")
print(package.cpath)
local imgui = require "cimgui"
------------------------------------------------------------------------------------------

-- local quadtree_main = require"quadtree_main"


io.stdout:setvbuf("no")

function love.load()
    imgui.love.Init()
end


function love.draw()
    -- example window
    imgui.ShowDemoWindow()
    
    -- code to render imgui
    imgui.Render()
    imgui.love.RenderDrawLists()
end


function love.update(dt)
    imgui.love.Update(dt)
    imgui.NewFrame()
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
        -- your code here 
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
    if imgui.love.GetWantCaptureKeyboard() then
        -- your code here 
    end
end

love.quit = function()
    return imgui.love.Shutdown()
end

function love.keypressed(key, code, isrepeat)
    imgui.love.KeyPressed(key)

    print(key)
    if key == "escape" then
        love.event.quit()
    end
end