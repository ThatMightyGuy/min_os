local tty = {}

function tty.new(init, clear, write, read, color, position, size, scroll)
    return {
        init=init,
        clear=clear,
        write=write,
        read=read,
        color=color,
        position=position,
        size=size,
        scroll=scroll
    }
end

return tty