local Stats = {}


---wrapper for love.graphics.getStats()
---@return string the formatted stats string
function Stats.get_stats_string()
    local stats = love.graphics.getStats()
    return string.format(
    [[drawcalls: %s
canvas switches: %s
texture memory: %.2fMB
images: %s
fonts: %s
shader switches: %s
draw calls batched: %s]],
    stats["drawcalls"],
    stats["canvasswitches"],
    stats["texturememory"] /1024/1024,
    stats["images"],
    stats["fonts"],
    stats["shaderswitches"],
    stats["drawcallsbatched"])
end

return Stats