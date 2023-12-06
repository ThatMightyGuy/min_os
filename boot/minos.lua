do
    local bootfs = component.proxy(computer.getBootAddress())

    local state = "status"

    local modules = {...}

    function _G.panic(source, data)
        error("panic ["..source.."]: "..data)
    end

    -- Only exact paths. Only current filesystem.
    

    function loadfile(filename, ...)
        local handle, open_reason = bootfs.open(filename)
        if not handle then
            return nil, open_reason
        end
        local buffer = {}

        repeat
            local data = bootfs.read(handle, math.huge)
            table.insert(buffer, data or "")
        until not data
        bootfs.close(handle)

        return load(table.concat(buffer), "=" .. filename, ...)
    end

    function _G.dofile(filename)
        local program, reason = loadfile(filename)
        if not program then
            return error(reason .. ':' .. filename, 0)
        end
        return program()
    end

    function _G.status(...)
        if state == "status" and print then
            print(...)
        end
    end

    local loaded_mods = {}
    function _G.modprobe(mod)
        for _, v in ipairs(loaded_mods) do
            if v == mod then return true end
        end
        return false
    end

    function _G.modload(mod)
        computer.pushSignal("module_load", mod)
        loadfile("/lib/modules/"..mod..".lua")()
        table.insert(loaded_mods, mod)
    end

    for i = 1, #modules do
        local mod = modules[i]
        modload(mod)
    end

    while true do computer.pullSignal() end
end

local kernel = {}
do
    --syscalls
    function kernel.fork()
    
    end
    
end

