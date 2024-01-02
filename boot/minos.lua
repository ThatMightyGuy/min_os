do
    local bootfs = component.proxy(computer.getBootAddress())

    local modules = {...}
    local loaded_mods = {}

    local environ = {runlevel=0}

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
            environ.runlevel = rl
            computer.pushSignal("kern.runlevel_change")
        end
        return environ.runlevel
    end

    local function modprobe(mod)
        for _, v in ipairs(loaded_mods) do
            if v == mod then return true end
        end
        return false
    end

    local function modload(mod)
        if modprobe(mod) then panic("modloader", "module already loaded: "..mod) end
        computer.pushSignal("kern.module_load", mod)
        loadfile("/lib/modules/"..mod..".lua")()
        table.insert(loaded_mods, mod)
    end

    local function load_modules()
        for i = 1, #modules do
            local mod = modules[i]
            modload(mod)
        end
    end

    load_modules()

    -- Cooperative multitasking
    local scheduler = {}
    do
        scheduler.processes = {}
        scheduler.queue = {}

        local function get_proc_index(pid)
            for i, v in ipairs(scheduler.processes) do
                if v.pid == pid then
                    return i
                end
            end
            return nil
        end

        local function pid_new()
            local pid
            repeat
                pid = math.random(math.huge)
            until get_proc_index(pid)
            return pid
        end

        function scheduler.unload(index)
            table.remove(scheduler.processes, index)
            -- shift queue process pointers left by 1
            for i = 0, #scheduler.queue do
                if scheduler.queue[i] > index then
                    scheduler.queue[i] = scheduler.queue[i] - 1
                end
            end
        end

        function scheduler.enqueue(proc, pos)
            pos = pos or #scheduler.queue + 1
            table.insert(scheduler.queue, pos, get_proc_index(proc.pid))
        end

        function scheduler.dequeue(proc, unload)
            local index = get_proc_index(proc.pid)
            if not index then return nil, "no such process" end
            for i, v in ipairs(scheduler.queue) do
                if v == index then
                    table.remove(scheduler.queue, i)
                end
            end
            if unload then
                scheduler.unload(index)
            end
            return true
        end

        local function proc_new(ppid, path, env)
            local err

            local proc = {
                pid=pid_new(),
                ppid=ppid or 0,
                path=path,
                env=env or environ,
                state="r",
                toc=computer.uptime(),
            }
            proc.__resumetimestamp = proc.toc
            proc.__callback, err = loadfile(path)
            if not proc.__callback then return nil, err end
            proc.__co = coroutine.create(proc.__callback)

            function proc:exec()
                self.state = "R"
                if coroutine.status(self.__co) == "dead" then
                    self.state = "D"
                    return
                end
                scheduler.enqueue(self)
                self.state = "Q"
            end

            return proc
        end

        function scheduler.next()
            if #scheduler.processes == 0 then panic("scheduler", "no processes to execute") end
            local proc = scheduler.processes[scheduler.queue[1]]
            if proc.state == "S" then
                if proc.__resumetimestamp <= computer.uptime() then
                    proc.state = "Q"
                else
                    table.remove(scheduler.queue, 1)
                    scheduler.enqueue(proc, 2)
                end
            else
                proc:exec()
                table.remove(scheduler.queue, 1)
                if proc.state == "D" then
                    scheduler.dequeue(proc, true)
                end
            end
        end

        local function timed_sleep(proc, sec)
            proc.__resumetimestamp = computer.uptime() + math.abs(sec or 0)
            proc.state = "S"
        end

        function scheduler.create(path, parent, env, pos)
            local proc = proc_new(parent, path, env)
            table.insert(scheduler.processes, proc)
            scheduler.enqueue(proc, pos)
        end
    end

    while true do computer.pullSignal() end
end
