Isolines = {}
Isolines.scene_name = "Isolines and maps"
Isolines.description = "test for algorithms for generating toplogical isolines from heightfields, for making geographics map type graphics."
------------------------------------------------------------------------------------------
local shaping = require "lib.shaping"
local Camera = require "lib.camera"
-- local ms = require "lib.marching_squares"
local ms = require "lib.luams.luams"
-- ms.setVerbose(true)
------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;114m[isolines]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end
------------------------------------------------------------------------------------------
local navigation = {}
navigation.is_panning = false
navigation.pan_last_x = 0.0
navigation.pan_dx = 0.0
navigation.pan_last_y = 0.0
navigation.pan_dy = 0.0
navigation.zoom = 1.0
navigation._zoom_damped = shaping.float_damped( 10.5, 1.0 )
navigation._target_zoom = 1.0
navigation.camera = Camera( 0.0, 0.0 )

navigation.update = function(dt)
    -- panning
    if navigation.is_panning then
        local mx, my = navigation.camera:mousePosition( )

        navigation.pan_dx = mx - navigation.pan_last_x
        navigation.pan_dy = my - navigation.pan_last_y
        navigation.camera:move( -navigation.pan_dx, -navigation.pan_dy )

        local cx,cy = navigation.camera:mousePosition( )
        navigation.pan_last_x = cx
        navigation.pan_last_y = cy
    end
    -- zoom
    navigation.zoom = navigation._zoom_damped( navigation._target_zoom )
    navigation.camera:zoomTo( navigation.zoom )
end


navigation.mousepressed = function( x, y, button )
    if button == 3 then -- middle
        navigation.is_panning = true
        local cx,cy = navigation.camera:mousePosition( )
        navigation.pan_last_x = cx
        navigation.pan_last_y = cy
    end    
end


navigation.mousereleased = function( x, y, button )
    if button == 3 then -- middle
        navigation.is_panning = false
    end
end


navigation.wheelmoved = function( x,y )
    navigation._target_zoom = navigation._target_zoom * ( 1 + (y *0.1))
    navigation._target_zoom = shaping.clamp( navigation._target_zoom, 0.1, 500.0 )
end


------------------------------------------------------------------------------------------
local function genImage( width, height, map_func )
    local image_data = love.image.newImageData(width, height, "r16")
    image_data:mapPixel( map_func )
    local image = love.graphics.newImage( image_data )
    image:setFilter("linear", "nearest")
    return image, image_data
end


local fractal_noise_parameters = {
    ["octaves"] = 7,
    ["lacunarity"] = 1.95,
    ["gain"] = 0.45,
    ["scale"] = 0.005,--0.006,
    ["offset"] = {24000, 1700.775}
}


local fractal_noise = function(x,y,r,g,b,a)
    local octaves = fractal_noise_parameters["octaves"]
    local lacunarity = fractal_noise_parameters["lacunarity"]
    local gain = fractal_noise_parameters["gain"]
    local scale = fractal_noise_parameters["scale"]
    local offset = fractal_noise_parameters["offset"]

    local total = 0
    local frequency = 1
    local amplitude = 1
    local maxAmplitude = 0

    for i = 1, octaves do
        local noiseValue = love.math.noise((x + offset[1]) * scale * frequency , (y+ offset[2]) * scale * frequency )
         total = total + noiseValue * amplitude

        frequency = frequency * lacunarity
        amplitude = amplitude * gain
        maxAmplitude = maxAmplitude + amplitude
    end
    local t = (total / maxAmplitude) * gain
    return t,t,t,1.0
end

------------------------------------------------------------------------------------------
---comment
---@param image_data love.ImageData
---@param levels table
local function genIsolines( image_data, levels )
    local data = {}
    for y = image_data:getHeight(),1,-1 do
        -- print("y ",y)
        local row = {}
        for ix = image_data:getWidth(),1,-1 do
            local pv = image_data:getPixel( ix-1, y-1 )
            -- print("ix ",ix, " ", pv )
            table.insert(row, pv )
        end
        table.insert( data, row )
    end
    
    local layers = ms.getContour( data, levels )
    return layers
end

------------------------------------------------------------------------------------------
local image_width = 512
local image_height = 512

--- @type love.Image
local current_image
--- @type love.ImageData
local current_image_data

--- @type table
local isolines = {}
local isoline_levels = {} -- {0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9}--{0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9}--{0.25,0.5,0.75,}
for i=1,25 do
    table.insert(isoline_levels, i/25)
end

-- for k,v in pairs(isoline_levels) do
--     print(v)
-- end

------------------------------------------------------------------------------------------
function Isolines:init()
    print("generating Image .. ")
    current_image, current_image_data = genImage( image_width, image_height, fractal_noise )
    isolines = genIsolines(current_image_data, isoline_levels)
    print(".. done")
    -- love.window.setMode( love.graphics.getWidth(), love.graphics.getHeight(), {["msaa"]=16} )
end


function Isolines:focus()
end


function Isolines:defocus()
end


function Isolines:update(dt)
    navigation.update(dt)
end


function Isolines:draw()
    navigation.camera:attach()

    -- local tx = current_image:getWidth()/-2.0
    -- local ty = current_image:getHeight()/-2.0
    local tx = current_image:getWidth()
    local ty = current_image:getHeight()
    
    love.graphics.translate( tx/-2.0, ty/-2.0 )

    -- image
    love.graphics.setColor( 1.0, 1.0, 1.0, 0.5 )
    love.graphics.draw( current_image, 0.0, 0.0 )
    
    -- pixel grid
    if navigation.camera.scale > 8.0 then
        local _a = shaping.remapc( navigation.camera.scale, 4.0, 17.0, 0.0, 0.35 )
        love.graphics.setColor( 0.2, 1.0, 0.1, _a )
        for x=1,tx do
            love.graphics.line( x, 0.0, x, ty )
        end
        for y=1,ty do
            love.graphics.line( 0.0, y, tx, y )
        end
    end

    -- isolines
    love.graphics.setLineWidth( 0.25 )
    love.graphics.setColor( 1.0, 0.875, 0.05, 1.0 )
    
    love.graphics.scale(-1.0, -1.0)
    love.graphics.translate(-tx, -ty)
    for l=1, #isolines do
        if (l%4==0) then
            love.graphics.setLineWidth( 1.0/navigation.camera.scale )
        else
            love.graphics.setLineWidth( 0.25/navigation.camera.scale ) --0.05 )
        end

        for p=1, #isolines[l] do
            if (#isolines[l][p] > 2) then
                love.graphics.line(isolines[l][p])
            end
        end
    end
    
    -- love.graphics.translate(0.0, 0.0)
    navigation.camera:detach()

    love.graphics.print("keys:\nr: regenerate image\nl: regenerate isolines", 100, 100)
    love.graphics.print(string.format("zoom: %0.2f", navigation.camera.scale), 100, 200)
end


function Isolines:keypressed(key, code, isrepeat)
    if code == "r" then
        print("regenerating image ..")
        local rxo = (love.math.random() - 0.5) * 10000
        local ryo = (love.math.random() - 0.5) * 10000
        fractal_noise_parameters["offset"] = { rxo, ryo }
        current_image, current_image_data = genImage( image_width, image_height, fractal_noise )

        print("generating isolines .. ")
        isolines = genIsolines(current_image_data, isoline_levels)
        print(".. done")
    end

    if code == "l" then
        print("generating isolines .. ")
        local lines = genIsolines(current_image_data, isoline_levels)
        print(".. done")
    end
end


function Isolines:mousepressed( x, y, button )
    navigation.mousepressed( x, y, button )
end


function Isolines:mousereleased(x,y,button)
    navigation.mousereleased( x, y, button )
end


function Isolines:wheelmoved(x,y)
    navigation.wheelmoved(x,y)
end


return Isolines