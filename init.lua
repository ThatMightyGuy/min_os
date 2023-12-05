-- This is a fairly advanced CUI bootloader for OS selection
do
    local bootable = {}

    local function readAll(path, dev)
        local file = dev.open(path)
        local f = ""
        repeat
            local s = dev.read(file, math.huge)
            f = f..(s or "")
        until not s
        dev.close(file)
        return f
    end

    -- find bootable devices
    local fs = component.list("filesystem")
    for f in fs do
        local dev = component.proxy(f)
        if dev.exists("/init.lua") then
            table.insert(bootable, dev)
        end
    end

    local cd
    -- get current drive address
    for _, dev in ipairs(bootable) do
        if dev.address == computer.getBootAddress() then cd = dev break end
    end

    local file = readAll("/boot/minbl.cfg", cd)

    local config, err = load("return "..file)
    if not config then
        error("Unable to load minbl config: "..err)
    end
    config = config()

    local function boot(dev, path, args)
        if type(dev) == "string" then dev = component.proxy(dev) end
        path = path or "/init.lua"
        local fh = readAll(path, dev)
        local f, ferr = load(fh)
        if not f then
            error("Unable to boot: "..ferr)
        end
        f(table.unpack(args))
    end

    local function gpu_text(self, text, x, y, align, invert, width)
        x = x or 1
        y = y or 1
        align = align or -1
        invert = invert or false
        width = width or #text
        local oldbg, oldfg = self.getBackground(), self.getForeground()
        if invert then
            self.setBackground(oldfg)
            self.setForeground(oldbg)
        end
        if align == 0 then
            self.fill(x, y, width / 2, 1, " ")
            self.set(width / 2 + x - #text / 2, y, text)
            self.fill(width / 2 + x + #text / 2, y, width / 2, 1, " ")
        elseif align == -1 then
            self.set(x, y, text)
        else
            self.set(width - #text + x, y, text)
        end
        self.setBackground(oldbg)
        self.setForeground(oldfg)
    end

    local function bootDefault()
        local entry = config.bootEntries[config.default or 1]
        boot(entry.address or computer.getBootAddress(), entry.path, entry.args)
    end

    local gpu = component.proxy(component.list("gpu")())

    local function draw()
        gpu.text = gpu_text
        local sw, sh = gpu.maxResolution()
        gpu.setResolution(sw, sh)
        gpu.fill(1, 1, sw, sh, " ")
        gpu.fill(1, 1, sw, 1, " ")
        gpu:text("select boot entry", 1, 1, 0, true, sw)
        gpu:text("min_bl ver 1.0", 1, 1, nil, true)
        local event, data = computer.pullSignal("key_down", config.timeout)
        while true do
            
        end
    end
    bootDefault()
    
    -- if config.mode ~= 2 and config.mode ~= 3 and gpu then
    --     if config.mode == 0 then
    --         draw()
    --     elseif config.mode == 1 then
    --         if computer.pullSignal("key_down", config.timeout) then draw() else bootDefault() end
    --     end
    -- end

    while true do
        computer.pullSignal()
    end
end