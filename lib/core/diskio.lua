local hwaccess = require("/lib/hwaccess")

local diskio = {}

local handlepaths = {}

function handlepaths.set(dev, handle, path)
    if not handlepaths[dev] then
        handlepaths[dev] = {}
    end
    handlepaths[dev][handle] = path
end

function diskio.getdisk(dev)
    local err
    dev, err = hwaccess.proxy(dev)
    if not dev then
        return nil, err
    elseif dev.type ~= "filesystem" then
        return nil, "device is not a filesystem"
    end
    return dev
end

function diskio.open(dev, path, mode)
    local err
    dev, err = getdisk(dev)
    if not dev then return nil, err end
    local fh = dev.open(path, mode)
    if fh == 0 then return nil, "no such file" end
    handlepaths.set(dev, fh, path)
    return fh
end

function diskio.write(dev, handle, data)
    checkArg(1, dev, "table")
    computer.pushSignal("kern.disk_write", dev.addr, handlepaths[dev][handle])
    return dev.write(handle, data)
end

function diskio.close(dev, handle)
    checkArg(1, dev, "table")
    computer.pushSignal("kern.disk_close", dev.addr, handlepaths[dev][handle])
    table.remove(handlepaths[dev], handle)
    return dev.close(handle)
end

function diskio.mkdir(dev, path)
    checkArg(1, dev, "table")
    computer.pushSignal("kern.disk_newdir", dev.addr, path)
    return dev.makeDirectory(path)
end

function diskio.remove(dev, path)
    checkArg(1, dev, "table")
    computer.pushSignal("kern.disk_remove", dev.addr, path)
    return dev.remove(path)
end

function diskio.rename(dev, oldpath, newpath)
    checkArg(1, dev, "table")
    computer.pushSignal("kern.disk_move", dev.addr, oldpath, newpath)
    return dev.rename(oldpath, newpath)
end

return diskio
