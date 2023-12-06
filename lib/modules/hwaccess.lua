local devices = {}

function _G.proxy(dev)
    local td = type(dev)
    if td == "string" then
        if devices[dev] then return devices[dev] end
        dev = component.proxy(dev)
        if not dev then
            return nil, "no such device"
        end
    elseif td ~= "table" then
        return nil, "invalid dev specifier type: "..td
    end

    if not devices[dev.address] then
        table.insert(devices, dev)
    end

    return dev
end