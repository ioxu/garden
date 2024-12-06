-- codingtrain palette
Palette = {
    {11, 106, 136},
    {45, 197, 244},
    {112, 50, 126},
    {146, 83, 161},
    {164, 41, 99},
    {236, 1, 90},
    {240, 99, 164},
    {241, 97, 100},
    {248, 158, 79},
    {252, 238, 33},
}

-- convert 8bit to 0..1 colours
for i,v in ipairs(Palette) do
    local cc = Palette[i]
    Palette[i][1], Palette[i][2], Palette[i][3] = love.math.colorFromBytes( cc[1], cc[2], cc[3] )
end

return Palette
