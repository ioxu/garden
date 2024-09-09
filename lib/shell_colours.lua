-- https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
ShellColours = {}


function ShellColours:test()
    -- \27 nut sure why \033 doesn't work (27 is decimal for octal's 033' )
    -----------------------
    -- VSCode debug console
    -----------------------
    -- flashing red
    print("\27[31;5;193mlog_window.config\27[0m.autoscroll")

end


return ShellColours