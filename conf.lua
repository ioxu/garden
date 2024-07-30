function love.conf(t)
	print("using love.conf")
	t.console = false
	t.window.msaa = 16
	t.window.fullscreen = true
end