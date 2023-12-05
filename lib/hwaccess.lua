local hw = {}

function hw.proxy(addr)
    return component.proxy(addr) or nil, "No such device"
end

return hw