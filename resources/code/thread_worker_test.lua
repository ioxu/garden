math = require "love.math"

local ch_name = ...

local res = 0
-- local r_length = 300000000 
local r_length = math.random(100) * (100000000/6.0)

-- print("start thread_code for ".. ch_name..":"..tostring(r_length))

local in_thread_channel = love.thread.getChannel("in_"..ch_name)
local out_thread_channel = love.thread.getChannel("out_"..ch_name)


local perc_progress = 0.0

for i = 1, r_length do
    if i%1000000 == 0 then
        local msg = in_thread_channel:pop()
        if msg and msg:find("^stop_thread") then
            print("STOP THREAD: "..tostring(msg).." "..ch_name)
            out_thread_channel:push( "stopped" )
            return
        end

    end

    res = i*i
end

out_thread_channel:push( "complete "..tostring(res) )
