local fs = require("/lib/core/fs")

local file, err = fs.open("/etc/fstab")
if not file then panic("fstab", err) end

local fstab = ""
repeat
    local chunk = file.read(math.huge)
    fstab = fstab..(chunk or "")
until not chunk
file.close()

