local stream = require("/lib/stream")

local filesystem = {}

local mtab = {}     -- mountpoints
local fstab = nil   -- mountpoint hierarchy

local fp = {}       -- open file pointers per mountpoint

-- returns fstab node which the path lies on
local function getnode(segments, node, indices)
    if #segments == 0 then return nil end
    node = node or fstab
    indices = indices or {}

    local seg = segments[1]
    for i, v in ipairs(node.children) do
        if v.name == seg then
            table.remove(segments, 1)
            table.insert(indices, i)
            return getnode(segments, v, indices)
        end
    end

    return node, indices
end

local function addchildnode(segments, node)
    local n, indices = getnode(segments)
    if not n then return nil, "no such path" end
    local function ins(tbl, i, val)
        local index = table.remove(i, 1)
        if #i == 0 then
            table.insert(tbl, val)
            return
        end
        ins(tbl[index], i, val)
    end
    ins(fstab, indices, node)
    return true
end

local function localizepath(path, node)
    for _, v in ipairs(mtab) do
        if v.device.address == node.device.address then
            return "/"..path:sub(#v.name + 1)
        end
    end
    return nil, "no such mountpoint"
end

function filesystem.parent(path)
    path = path:gsub("/[^/]+$", "")
    if path == "" then path = "/" end
    return path
end

function filesystem.segments(path)
    local seg = {}
    for v in path:gmatch("[^/]+") do
        table.insert(seg, v)
    end
    return seg
end

function filesystem.mtab() return mtab end

function filesystem.mountpoint(path)
    return mtab[path]
end

function filesystem.mount(path, fs)
    local mp = filesystem.mountpoint(path)
    if mp then return false, "mountpoint taken" end
    mp = filesystem.segments(path)
    local node = getnode(mp)
    local entry = {name=path, device=fs, children={}}
    if not node then
        fstab = entry
        node = entry
    else
        addchildnode(mp, entry)
    end
    mtab[path] = fs
    fp[node.device.address] = {}
end

function filesystem.unmount(fs)
    if #fp[fs.address] > 0 then return nil, "mountpoint busy" end
    for k, v in pairs(mtab) do
        if v.address == fs.address then
            
        end
    end
end

function filesystem.open(path, mode)
    local node = getnode(filesystem.segments(path))
    if not node then return nil, "no such mountpoint or directory" end
    local fh = node.device.open(localizepath(path, node), mode)
    if fh <= 0 then return nil, "file not found" end
    table.insert(fp[node.device.address], fh)

    local function read(count)
        count = count or math.huge
        return node.device.read(fh, count)
    end
    local function write(str)
        computer.pushSignal("fs_write", path)
        return node.device.write(fh, str)
    end
    local function seek(whence, offset)
        return node.device.seek(fh, whence, offset)
    end
    local function close()
        for i, v in ipairs(fp[node.device.address]) do
            if v == fh then
                table.remove(fp[node.device.address], i)
                break
            end
        end
        node.device.close(fh)
        computer.pushSignal("fs_close", path)
    end
    return stream.new(write, read, seek, close)
end