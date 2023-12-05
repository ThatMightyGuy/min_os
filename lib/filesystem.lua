local mtab = {name="", children={}, links={}}

local fs = {
    lfs=require("/lib/modules/hwdefaults").filesystem
}

local function segments(path)
    local parts = {}
    for part in path:gmatch("[^\\/]+") do
        local current, up = part:find("^%.?%.$")
        if current then
            if up == 2 then
                table.remove(parts)
            end
        else
            table.insert(parts, part)
        end
    end
    return parts
end

function fs.proxy(filter, options)
    checkArg(1, filter, "string")
    if not component.list("filesystem")[filter] or next(options or {}) then
        return nil, "No such directory"
    end
    return component.proxy(filter)
end

function fs.isDirectory(path)

end

function fs.exists(path)
    return fs.isDirectory ~= nil
end

function fs.list(dir)

end
  
function fs.canonical(path)
    local result = table.concat(segments(path), "/")
    if path:sub(1, 1) == "/" then
        return "/" .. result
    else
        return result
    end
end

function fs.mount(where, what)
    if type(where) == "string" then
        where = fs.proxy(fs)
    end
end

return fs