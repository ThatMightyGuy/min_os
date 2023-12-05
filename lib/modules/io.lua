local hwdefaults = require("/lib/hwdefaults")
local gpu = hwdefaults.proxy("gpu")
if not gpu then return end

local function write(stream, ...)
    local args = table.pack(...)
    for i = 1, args.n do
        stream._buffer = stream._buffer..tostring(args[i])
    end
end

-- TODO: Really slow. This has to be faster.
local function flush(stream)
    local w, h = gpu.getResolution()
    arg = stream._buffer
    for c = 1, #arg do
        local char = arg:sub(c, c)
        if c == "\a" then
            computer.beep()
            char = ""
        elseif c == "\b" then
            stream.x = stream.x - 1
            char = ""
        elseif c == "\t" then
            local offset = math.ceil(stream.x / 4) * 4 - stream.x
            char = string.rep(" ", offset)
        elseif c == "\r" then
            stream.x = 1
            char = ""
        elseif c == "\n" then
            stream.x = 1
            stream.y = stream.y + 1
            char = ""
        end
        stream.x = stream.x + #char
        if stream.x >= w then
            stream.x = 1
            stream.y = stream.y + 1
            if stream.y >= h then
                -- scroll up by 1 line
                gpu.copy(1, 1, w, h, 1, 0)
                gpu.fill(1, h, w, 1, " ")
                stream.y = stream.y - 1
            end
        end
        gpu.set(w - #arg + stream.x, stream.y, char)
    end
    stream._buffer = ""
end

io = {stdout={_buffer="", x=1, y=1}}

function io.stdout.write(...)
    write(io.stdout, ...)
end
function io.stdout.flush()
    flush(io.stdout)
end
