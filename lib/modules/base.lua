-- Makeshift convenience/compatibility functions. Will be replaced at a later boot stage

local bootfs = proxy(computer.getBootAddress())

local libs = {}

if not bootfs then return panic("base", "no boot fs found") end

local function getname(path)
    return path:gsub("%.[^.]*$", "")
end

local function parentpath(path)
    return path:gsub("/[^/]+$", "")
end

function require(path)
    if libs[path] then return libs[path] end
    path = getname(path)
    local dir = parentpath(path)
    local list = bootfs.list(dir)
    for _, v in ipairs(list) do
        local p = dir.."/"..getname(v)
        if p == path then
            path = p
            break
        end
    end
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
    lib = load(lib)()
    libs[path] = lib
    return lib
end

function _G.dofile(filename)
    local program, reason = loadfile(filename)
    if not program then
        return error(reason .. ':' .. filename, 0)
    end
    return program()
end
