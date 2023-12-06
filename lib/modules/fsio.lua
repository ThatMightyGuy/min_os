local hwaccess = require("/lib/hwaccess")

local handlepaths = {}

function handlepaths.set(dev, handle, path)
    if not handlepaths[dev] then
        handlepaths[dev] = {}
    end
    handlepaths[dev][handle] = path
end

function getfs(dev)
    local err
    dev, err = hwaccess.proxy(dev)
    if not dev then
        return nil, err
    elseif dev.type ~= "filesystem" then
        return nil, "device is not a filesystem"
    end
    return dev
end

function open(dev, path, mode)
    local err
    dev, err = getfs(dev)
    if not dev then return nil, err end
    local fh = dev.open(path, mode)
    if fh == 0 then return nil, "no such file" end
    handlepaths.set(dev, fh, path)
    return fh
end

function write(dev, handle, data)
    checkArg(1, dev, "table")
    computer.pushSignal("kern.fs_write", dev.addr, handlepaths[dev][handle])
    return dev.write(handle, data)
end

function read(dev, handle, count)
    checkArg(1, dev, "table")
    return dev.read(handle, count)
end

function seek(dev, handle, whence, offset)
    checkArg(1, dev, "table")
    return dev.seek(handle, whence, offset)
end

function close(dev, handle)
    checkArg(1, dev, "table")
    computer.pushSignal("kern.fs_close", dev.addr, handlepaths[dev][handle])
    table.remove(handlepaths[dev], handle)
    return dev.close(handle)
end

function mkdir(dev, path)
    checkArg(1, dev, "table")
    computer.pushSignal("kern.fs_newdir", dev.addr, path)
    return dev.makeDirectory(path)
end

function remove(dev, path)
    checkArg(1, dev, "table")
    computer.pushSignal("kern.fs_remove", dev.addr, path)
    return dev.remove(path)
end

function rename(dev, oldpath, newpath)
    checkArg(1, dev, "table")
    computer.pushSignal("kern.fs_move", dev.addr, oldpath, newpath)
    return dev.rename(oldpath, newpath)
end

