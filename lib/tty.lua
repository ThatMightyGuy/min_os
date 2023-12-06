function print(...)
    local args = table.pack(...)
    local stdout = io.stdout
    local pre = ""
    for i = 1, args.n do
        stdout:write(pre, (assert(tostring(args[i]), "'tostring' must return a string to 'print'")))
        pre = "\t"
    end
    stdout:write("\n")
    stdout:flush()
end
