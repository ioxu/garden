Threads = {}
Threads.scene_name = "testing love.thread"
Threads.description = "This is a long description of the scene"

local navigation_camera = require "lib.navigation_camera"

local thread_code = [[

math = require "love.math"

local ch_name = ...

local res = 0
local r_length = math.random(100) *100000000
print(r_length)
for i = 1, r_length do
    res = i*i
end

local thread_channel = love.thread.getChannel(ch_name)
thread_channel:push( "complete "..tostring(res) )
]]

local tc, error_message = load( thread_code )
print("thread_code check: ", tc, " ", error_message)

print()

--- @alias job_state
--- | '"UNSTARTED"'
--- | '"RUNNING"'
--- | '"FINISHED"'

--- @class Job
--- @field name string
--- @field width number
--- @field height number
--- @field state job_state
--- @field thread love.Thread
--- @field channel love.Channel
local Job = {}

---comment
---@param name any
---@return Job job
function Job:new( name )
    Job.__index = Job
    local self = setmetatable( {}, Job )
    self.name = name or "job"
    self.width = 8
    self.height = 8
    self.state = "UNSTARTED"
    self.thread = nil-- love.thread.newThread()
    self.channel = love.thread.getChannel( self.name )
    return self
end


function Job:draw( x_off, y_off )
    love.graphics.rectangle("line", x_off, y_off, self.width, self.height)
    if self.state == "UNSTARTED" then
        love.graphics.setColor(1,1,1,0.25)
    elseif self.state == "RUNNING" then
        love.graphics.setColor(0,1,0,0.75)
    elseif self.state == "FINISHED" then
        love.graphics.setColor(0.25,0.25,1.0,0.5)
    end
end


local jobs = {}
jobs.max_concurrent_jobs = 10
jobs.jobs = {}


local job_display = {}
job_display.width = 64
job_display.height = 16
job_display.box_width = 16
job_display.box_height = 32
job_display.margin = 5
job_display.origin = {150, 150}

-- fill jobs.jobs with Jobs
for j=1,(job_display.width * job_display.height) do
    local job = Job:new("job_"..tostring(j))
    job.width = job_display.box_width
    job.height = job_display.box_height
    job.thread = love.thread.newThread( thread_code )
    table.insert(jobs.jobs, job )
end

job_display.draw = function ()
    local self = job_display
    love.graphics.setLineWidth(0.5)
    love.graphics.setColor(1,1,1,0.25)
    local job_index = 1
    for x = 1, job_display.width do
        for y = 1, job_display.height do

            local this_job = jobs.jobs[job_index]
            this_job:draw(self.origin[1] + (x * (this_job.width + self.margin)),
                self.origin[2] + (y * (this_job.height + self.margin))
            )

            job_index = job_index + 1
        end
    end
end


function Threads:init()
    navigation_camera.camera:lookAt(
        job_display.origin[1] + ((job_display.width * (job_display.box_width + job_display.margin) ))/2.0,
        job_display.origin[2] + ((job_display.height * (job_display.box_height + job_display.margin) ))/2.0
    )

    for i = 1,10 do
        local this_job = jobs.jobs[i]
        this_job.thread:start( this_job.name )
    end
end

function Threads:focus()
end

function Threads:defocus()
end

function Threads:update(dt)
    navigation_camera.update(dt)

    for i = 1,10 do
        local this_job = jobs.jobs[i]
        local msg = this_job.channel:pop()
        if msg then
            print(this_job.name, ":", msg)
        end
    end

end

function Threads:draw()
    navigation_camera.camera:attach()
    job_display.draw()
    navigation_camera.camera:detach()
end

function Threads:keypressed(key, code, isrepeat)
end

function Threads:keyreleased(key, code, isrepeat)
end

function Threads:mousepressed(x,y,button)
    navigation_camera.mousepressed( x, y, button )
end

function Threads:mousereleased(x,y,button)
    navigation_camera.mousereleased( x, y, button )
end

function Threads:wheelmoved(x,y)
    navigation_camera.wheelmoved(x,y)
end


return Threads