function love.conf(t)
	print("using love.conf")
	t.console = false
	t.window.msaa = 4
	t.window.fullscreen = true
    t.window.width = 1600
    t.window.height = 900
end