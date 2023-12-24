local iface = {}

function iface.new(tbl)
    error("not implemented")
end

function iface.implements(obj, interface)
    for k, _ in pairs(interface) do
        if not obj[k] then return false end
    end
    return true
end

return iface