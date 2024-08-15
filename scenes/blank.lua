local color = require"color"

local Blank = {}
Blank.description = "dummy scene state"

local global_time = 0 
local font_huge = love.graphics.newFont(400)

function Blank:init()
    print("[blank] init")
    global_time = 0
end

function Blank:update(dt)
    -- print("[blank] update")
    global_time = global_time + dt
end

function Blank:draw(dt)
    -- print("[blank] draw")
    local new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1, 1.0 ), 0.85, 0.3)
    -- print(new_r, new_g, new_b)
    love.graphics.clear( new_r, new_g, new_b )
    fx = font_huge:getWidth("BLANK")
    fy = font_huge:getHeight("BLANK")
    love.graphics.setFont(font_huge)
    
    new_r, new_g, new_b = color.hslToRgb(math.fmod( global_time * 0.1 - 0.05, 1.0 ), 0.85, 0.3)
    love.graphics.setColor( new_r, new_g, new_b )
    love.graphics.print("BLANK", love.graphics.getWidth()/2 - fx/2, love.graphics.getHeight()/2 - fy/2)

end

function Blank:mousepressed(x,y,button,istouch,presses)
    print("mouse pressed ", global_time)
end

return Blank