
-- https://love2d.org/forums/viewtopic.php?t=92877&sid=6a58e932e8ba60eea54d7632acfcdbe0
-- user pauljessup


------------------------------------------------------------------------------------------
local oldprint = print
local print_header = "\27[38;5;172m[scene_manager]\27[0m "
local function print(...)
    local result = ""
    for i,v in pairs( {...} ) do
        result = result .. tostring(v)
    end
    oldprint( print_header .. result )
end
------------------------------------------------------------------------------------------


return{
    states={},
    descriptions={},
    long_names={},
    focus={},
    action={switch=false, push=false, pop=false, newid=0},
    init=function(self, start_state)
        --gets all the game states from the game states directory
        for i,v in ipairs(love.filesystem.getDirectoryItems("scenes")) do
            if string.find(v, ".lua") then
                print(string.format("[scene_manager] found %s", v))
                local state_name = string.gsub(v, ".lua", "")
              self.states[state_name]=require("scenes." .. string.gsub(v, ".lua", ""))
                if self.states[state_name].description then
                    self.descriptions[state_name] = self.states[state_name].description
                else
                    self.descriptions[state_name] = "--"
                end
                if self.states[state_name].scene_name then
                    self.long_names[state_name] = self.states[state_name].scene_name
                else
                    self.long_names[state_name] = "--"
                end
            end
        end
        if start_state then
            self:push(start_state)
        end
    end,
    push=function(self, state)
        -- print("[scene_manager] .push()", state)
        -- print("[scene_manager] self.currentFocus: ", self:currentFocus())
        self.states[state]:init()
        self.focus[#self.focus+1]=state
        if self.states[state].focus then
            self.states[state]:focus()
        end
    end,
    pop=function(self)
        local cfocus=self:currentFocus()
        if #self.focus>1 then
            if(self.states[cfocus].close~=nil) then
                self.states[cfocus]:close()
            end
            self.focus[#self.focus]=nil 
        end
    end,
    switch=function(self, state)
        -- print("[scene_manager] .switch()", state)
        -- print("[scene_manager] .currentFocus:", self:currentFocus())
        if self.states[self:currentFocus()].defocus then
            self.states[self:currentFocus()]:defocus()
        end
        for i,v in ipairs(self.focus) do
            self.focus[i]=nil
        end
        self.focus={}
        self:push(state)
    end,
    currentFocus=function(self)
        return self.focus[#self.focus]
    end,

    update=function(self, dt)
        self.states[self:currentFocus()]:update(dt)
    end,

    draw=function(self)
        for i,v in pairs(self.focus) do
            self.states[v]:draw()
        end
    end,

    mousepressed=function(self, x, y, button, istouch, presses)
        for i,v in pairs(self.focus) do
            if self.states[v].mousepressed then
                self.states[v]:mousepressed( x, y, button, istouch, presses )
            end
        end
    end,

    mousereleased=function(self, x, y, button, istouch, presses)
        for i,v in pairs(self.focus) do
            if self.states[v].mousereleased then
                self.states[v]:mousereleased( x, y, button, istouch, presses )
            end
        end
    end,

    mousemoved=function(self, x, y, dx, dy, ...)
        for i,v in pairs(self.focus) do
            if self.states[v].mousemoved then
                self.states[v]:mousemoved( x, y, dx, dy, ... )
            end
        end
    end,
    
    wheelmoved=function(self, x, y)
        for i,v in pairs(self.focus) do
            if self.states[v].wheelmoved then
                self.states[v]:wheelmoved( x, y)
            end
        end
    end,

    keypressed=function(self, key, code, isrepeat)
        for i,v in pairs( self.focus) do
            if self.states[v].keypressed then
                self.states[v]:keypressed( key, code, isrepeat )
            end
        end
    end,

    keyreleased=function(self, key, code, isrepeat)
        for i,v in pairs( self.focus) do
            if self.states[v].keyreleased then
                self.states[v]:keyreleased( key, code, isrepeat )
            end
        end
    end,

    textinput=function(self, t)
        for i,v in pairs( self.focus) do
            if self.states[v].textinput then
                self.states[v]:textinput( t )
            end
        end
    end,

    quit=function(self)
        for i,v in pairs( self.states ) do
            if self.states[i].quit then
                self.states[i]:quit()
            end
        end
    end,

    -- TODO: add gamepad events

    gamepadpressed=function(self, joystick, button)
        for i,v in pairs( self.states ) do
            if self.states[i].gamepadpressed then
                self.states[i]:gamepadpressed( joystick, button )
            end
        end
    end,

    gamepadreleased=function(self, joystick, button)
        for i,v in pairs( self.states) do
            if self.states[i].gamepadreleased then
                self.states[i]:gamepadreleased( joystick, button)
            end
        end
    end,

    gamepadaxis=function(self, joystick, axis, value)
        for i,v in pairs( self.states ) do
            if self.states[i].gamepadaxis then
                self.states[i]:gamepadaxis( joystick, axis, value)
            end
        end
    end,

    joystickpressed=function(self, joystick, button)
        for i,v in pairs( self.states ) do
            if self.states[i].joystickpressed then
                self.states[i]:joystickpressed( joystick, button )
            end
        end
    end,

    joystickreleased=function(self, joystick, button)
        for i,v in pairs( self.states ) do
            if self.states[i].joystickreleased then
                self.states[i]:joystickreleased( joystick, button )
            end
        end
    end,

    joystickaxis=function( self, joystick, axis, value )
        for i,v in pairs( self.states ) do
            if self.states[i].joystickaxis then
                self.states[i]:joystickaxis( joystick, axis, value)
            end
        end
    end,

    joystickadded=function( self, joystick)
        for i,v in pairs(self.states) do
            if self.states[i].joystickadded then
                self.states[i]:joystickadded( joystick )
            end
        end
    end,

    joystickremoved=function( self, joystick)
        for i,v in pairs(self.states) do
            if self.states[i].joystickremoved then
                self.states[i]:joystickremoved( joystick )
            end
        end
    end

}
