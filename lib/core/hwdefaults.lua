local hwaccess = require("/lib/core/hwaccess")
local hwdefaults = {
    filesystem=computer.getBootAddress()
}

function hwdefaults.proxy(name)
    if hwdefaults[name] == nil then
        hwdefaults[name] = hwaccess.proxy(component.list(name)())
    elseif type(hwdefaults[name] ~= "table") then
        return nil, "Invalid component type"
    end
    return hwdefaults[name]
end

return hwdefaults