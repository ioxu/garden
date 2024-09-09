
-- https://love2d.org/forums/viewtopic.php?t=92877&sid=6a58e932e8ba60eea54d7632acfcdbe0
-- user pauljessup

return{
    states={},
    descriptions={},
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
            end
        end
        if start_state then
            self:push(start_state)
        end
    end,
    push=function(self, state)
        self.states[state]:init()
        self.focus[#self.focus+1]=state
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
    end
}
