local stream = {}

function stream.new(write, read, seek, close)
    return {write=write, read=read, seek=seek, close=close}
end

return stream