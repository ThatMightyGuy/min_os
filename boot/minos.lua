do
    local bootfs = component.proxy(computer.getBootAddress())

    local modules = {...}
    local loaded_mods = {}

    local runlevel = 0

    local function panic(source, data)
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

    local function runlevel(rl)
        if rl then
            runlevel = rl
            computer.pushSignal("kern.runlevel_change")
        end
        return runlevel
    end

    local function modprobe(mod)
        for _, v in ipairs(loaded_mods) do
            if v == mod then return true end
        end
        return false
    end

    local function modload(mod)
        computer.pushSignal("kern.module_load", mod)
        loadfile("/lib/modules/"..mod..".lua")()
        table.insert(loaded_mods, mod)
    end

    for i = 1, #modules do
        local mod = modules[i]
        modload(mod)
    end

    while true do computer.pullSignal() end
end
