do
    local bootfs = component.proxy(computer.getBootAddress())

    local state = "status"

    local modules = {...}

    local function endswith(str, suffix)
        return str:sub(-#suffix) == suffix
    end

    -- Only exact paths. Only current filesystem.
    function require(path)
        if not endswith(path, ".lua") then path = path..".lua" end
        local file, err = bootfs.open(path)
        if err then
            return error("No such file: `"..path.."`")
        end
        local lib = ""
        repeat
            local s = bootfs.read(file, math.huge)
            lib = lib..(s or "")
        until not s
        bootfs.close(file)
        return load(lib)()
    end

    function loadfile(filename, ...)
        if filename:sub(1,1) ~= "/" then
            filename = (os.getenv("PWD") or "/") .. "/" .. filename
        end
        local handle, open_reason = bootfs.open(filename)
        if not handle then
            return nil, open_reason
        end
        local buffer = {}
        while true do
            local data, reason = bootfs.read(handle, 1024)
            if not data then
                bootfs.close(handle)
                if reason then
                return nil, reason
                end
                break
            end
            buffer[#buffer + 1] = data
        end
        return load(table.concat(buffer), "=" .. filename, ...)
    end

    function dofile(filename)
        local program, reason = loadfile(filename)
        if not program then
            return error(reason .. ':' .. filename, 0)
        end
        return program()
    end

    function status(...)
        if state == "status" and print then
            print(...)
        end
    end

    for i = 1, #modules do
        local mod = modules[i]
        status("Loading module "..mod)
        dofile("/lib/modules/"..mod..".lua")
    end

    while true do computer.pullSignal() end
end

local kernel = {}
do
    --syscalls
    function kernel.fork()
    
    end
    
end

