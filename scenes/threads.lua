Threads = {}
Threads.scene_name = "testing love.thread"
Threads.description = "This is a long description of the scene"

local navigation_camera = require "lib.navigation_camera"
local signal = require "lib.signal"
local handles = require "lib.handles"

local thread_code = [[
math = require "love.math"

local ch_name = ...

local res = 0
-- local r_length = 300000000 
local r_length = math.random(100) * (100000000/6.0)

-- print("start thread_code for ".. ch_name..":"..tostring(r_length))

local in_thread_channel = love.thread.getChannel("in_"..ch_name)
local out_thread_channel = love.thread.getChannel("out_"..ch_name)


for i = 1, r_length do
    if i%1000000 == 0 then
        -- print(ch_name.. " checking channel "..i)
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
]]

local tc, error_message = load( thread_code )
print("thread_code check: ", tc, " ", error_message)


------------------------------------------------------------------------------------------
--- @alias job_state
--- | '"UNSTARTED"'
--- | '"RUNNING"'
--- | '"FINISHED"'
--- | '"STOPPED"'

--- @class Job
--- @field name string
--- @field width number
--- @field height number
--- @field state job_state
--- @field thread love.Thread
--- @field in_channel love.Channel
--- @field out_channel love.Channel
--- @field signals Signal
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
    self.in_channel = love.thread.getChannel( "in_"..self.name )
    self.out_channel = love.thread.getChannel( "out_"..self.name )
    self.signals = signal:new()
    return self
end

function Job:start( jobname )
    self.thread:start( jobname )
    if self.thread:isRunning() then
        print("job started:", self.name)
        self.signals:emit("started", self)
        self.state = "RUNNING"
        return true
    else
        return false
    end
end

function Job:stop( jobname )
    -- if self.thread:isRunning() then
    --     print("stopping job: "..self.name)
    --     self.channel:push( "stop_thread" )
    --     -- self.signals:emit("stopped", self)
    --     -- self.state = "STOPPED"
    --     return true
    -- else        
    --     return false
    -- end
    print("stopping job: "..self.name)
    self.in_channel:push( "stop_thread" )
end

function Job:update(dt)
    local msg = self.out_channel:pop()
    if msg then
        if msg:find("^complete") then
            print("COMPLETE:"..self.name..":"..msg)
            if self.state == "RUNNING" then
                self.state = "FINISHED"
                self.signals:emit("finished", self)
            end
        elseif msg:find("^stopped") then
            print("STOPPED:"..self.name..":"..msg)
            self.state = "STOPPED"
            self.signals:emit("stopped", self)
        end
    end
end


function Job:draw( x_off, y_off )
    if self.state == "UNSTARTED" then
        -- love.graphics.setLineWidth(1)
        love.graphics.setColor(1,1,1,0.25)
    elseif self.state == "RUNNING" then
        love.graphics.setColor(0,1,0,0.75)
        love.graphics.setLineWidth(1.2)
        -- love.graphics.setLineWidth(1)
        -- love.graphics.setColor(1,0.65,0,1.0)
    elseif self.state == "FINISHED" then
        love.graphics.setLineWidth(1.2)
        love.graphics.setColor(0.25,0.6,1.0,0.5)
        -- love.graphics.setColor(0.9,0.2,1.0,0.15)
    elseif self.state == "STOPPED" then
        -- love.graphics.setLineWidth(3.0)
        love.graphics.setColor(0.75,0.65,0.2,1.0)
        -- love.graphics.setColor(0.9,0.2,1.0,0.15)
    end
    love.graphics.rectangle("line", x_off, y_off, self.width, self.height)
    love.graphics.print(self.name, x_off+1, y_off+1, 0, 0.25, 0.25)
end

------------------------------------------------------------------------------------------
-- jobs scheduler ("jobs" is probably a bad name for a scheduler)
local jobs = {}
jobs.running = false
jobs.max_concurrent_jobs = 12
jobs.jobs = {}
jobs.running_jobs = {}


jobs.on_job_finished = function( job )
    print("jobs.on_job_finished ", job.name)
    local idx = nil
    for k,v in pairs(jobs.running_jobs) do
        if v == job then
            idx = k
        end
    end
    if idx then 
        table.remove( jobs.running_jobs, idx )
    end
    
    while #jobs.running_jobs < jobs.max_concurrent_jobs and jobs.running do
        local res = jobs.find_job_to_start()
        if res == false then
            return
        end
    end
end


jobs.start = function()
    print("starting jobs")

    ---------------------------------------
    -- start all over again, reset all jobs
    for i =1, #jobs.jobs do
        local this_job = jobs.jobs[i]
        this_job.state = "UNSTARTED"
    end
    --------------------------------------

    for i=1,jobs.max_concurrent_jobs do
    -- for i=1,3 do
        local this_job = jobs.jobs[i]
        local res = this_job:start( this_job.name )
        if res then
            table.insert(jobs.running_jobs, this_job)
        end
    end
end

jobs.stop = function()
    print("stopping jobs")
    -- stop jobs
    -- for i=1, #jobs.jobs do
    for i=1,#jobs.running_jobs do
        -- local this_job = jobs.jobs[i]
        local this_job = jobs.running_jobs[i]
        print("this_job:stop("..this_job.name..")")
        local res = this_job:stop( this_job.name )
        -- -- also set their state to "UNSTARTED"
        -- this_job.state = "UNSTARTED"
    end
    -- jobs.running_jobs = {}
end


jobs.find_job_to_start = function()
    -- just naively start from the start of the jobs table each times
    if #jobs.running_jobs < jobs.max_concurrent_jobs then
        for k,v in pairs(jobs.jobs) do
            local this_job_state = jobs.jobs[k].state
            if (this_job_state == "UNSTARTED" or this_job_state == "STOPPED") then
                local this_job = jobs.jobs[k]
                local res = this_job:start( this_job.name )
                if res then
                    table.insert(jobs.running_jobs, jobs.jobs[k])
                    return true
                end
            end
            
            if k == #jobs.jobs then
                -- we're at the end of the list of jobs
                return false
            end
        end
    end
end


------------------------------------------------------------------------------------------
local job_display = {}
job_display.width = 32--16
job_display.height = 16--8
job_display.box_width = 16
job_display.box_height = 32
job_display.margin = 5
job_display.origin = {150, 150}

job_display.draw = function ()
    local self = job_display
    love.graphics.setColor(1,1,1,0.25)
    local job_index = 1
    for y = 0, job_display.height -1 do
        for x = 0, job_display.width -1 do
            local this_job = jobs.jobs[job_index]
            love.graphics.setLineWidth(0.1)
            this_job:draw(self.origin[1] + (x * (this_job.width + self.margin)),
                self.origin[2] + (y * (this_job.height + self.margin))
            )

            job_index = job_index + 1
        end
    end
end


------------------------------------------------------------------------------------------
-- ui
local start_button = handles.CircleHandle:new("start_button", 200.0, 200.0, 10)
start_button.label = "start.stop"
start_button.dragable = false


local function _on_start_button_pressed()
    jobs.running = not jobs.running
    if jobs.running then
        start_button.colour = {0.2, 0.95, 0.2, 1.0}
        jobs.start()
        print("jobs started")
    else
        start_button.colour = {0.3, 0.3, 0.3, 1.0}
        jobs.stop()
        print("jobs stopped")
    end
end

start_button.signals:register("pressed", _on_start_button_pressed)

------------------------------------------------------------------------------------------
function Threads:init()
    navigation_camera.camera:lookAt(
        job_display.origin[1] + ((job_display.width * (job_display.box_width + job_display.margin) ))/2.0,
        job_display.origin[2] + ((job_display.height * (job_display.box_height + job_display.margin) ))/2.0
    )

    -- fill jobs.jobs with Jobs
    for j=1,(job_display.width * job_display.height) do
        local job = Job:new("job_"..tostring(j))
        job.width = job_display.box_width
        job.height = job_display.box_height
        job.thread = love.thread.newThread( thread_code )
        job.signals:register( "finished", jobs.on_job_finished )
        job.signals:register( "stopped", jobs.on_job_finished )
        table.insert(jobs.jobs, job )
    end

    -- jobs.start()
end

function Threads:focus()
end

function Threads:defocus()
end

function Threads:update(dt)
    navigation_camera.update(dt)

    for k,v in pairs(jobs.running_jobs) do
        jobs.running_jobs[k]:update(dt)
    end
end


function Threads:draw()
    navigation_camera.camera:attach()
    job_display.draw()
    navigation_camera.camera:detach()

    start_button:draw()

    for k,v in pairs(jobs.running_jobs) do
        love.graphics.print(v.name, 100, 200 + (k*10))
    end

end

function Threads:keypressed(key, code, isrepeat)
end

function Threads:keyreleased(key, code, isrepeat)
end

function Threads:mousepressed(x,y,button,istouch,presses)
    start_button:mousepressed(x,y,button,istouch,presses)
    navigation_camera.mousepressed( x, y, button )
end

function Threads:mousereleased(x,y,button,istouch,presses)
    start_button:mousereleased(x,y,button,istouch,presses)
    navigation_camera.mousereleased( x, y, button )
end

function Threads:mousemoved( x, y, dx, dy )
    start_button:mousemoved( x, y, dx, dy )
end

function Threads:wheelmoved(x,y)
    navigation_camera.wheelmoved(x,y)
end


return Threads