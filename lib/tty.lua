local gpu = nil

local tty = {}

function tty.isavailable()
    return gpu ~= nil
end

local buffer = ""
local x, y = 1, 1
local w, h = 80, 25

function tty.clear()
    gpu.fill(1, 1, w, h, " ")
end

function tty.init(writer)
    gpu = writer
    if not tty.isavailable() then return false end
    tty.clear()
    buffer = ""
    x, y = 1, 1
    w, h = gpu.getResolution()
end

function tty.color(fg, bg)
    local _fg = gpu.getForeground()
    local _bg = gpu.getBackground()

    if fg then
        gpu.setForeground(fg)
    end
    if bg then
        gpu.setBackground(fg)
    end
    return _fg, _bg
end







