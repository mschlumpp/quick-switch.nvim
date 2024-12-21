local function uniquify2(pathlist)
    local buckets = {}
    -- group paths into buckets based on next component
    for idx, path in pairs(pathlist) do
        local rem = path[1]
        local last = rem[#rem]
        if buckets[last] == nil then
            buckets[last] = {}
        end
        table.insert(buckets[last], idx)
    end

    for last, bucket in pairs(buckets) do
        if #bucket > 1 then
            local forward_arr = {}
            for _, idx in ipairs(bucket) do
                local path = pathlist[idx]

                local s
                if #path[2] == 0 then
                    -- Use full name for last path element
                    s = last
                else
                    -- Or shorten path to one 'significant' character
                    s = last:sub(1, 1)
                    if s == '.' then
                        s = last:sub(1, 2)
                    end
                end
                -- use new component and remove old from stack
                table.insert(path[2], s)
                table.remove(path[1])
                if #path[1] ~= 0 then
                    -- only continue process if there are more components to consider
                    table.insert(forward_arr, path)
                else
                    -- mark path as absolute by inserting empty string
                    table.insert(path[2], '')
                end
            end

            uniquify2(forward_arr)
        else
            -- component is already unique => just use it
            local idx = bucket[1]
            local path = pathlist[idx]
            table.insert(path[2], last)
            table.remove(path[1])
        end
    end
end

local function reverse_list(list)
    local len = #list
    local to = math.floor(len / 2)
    for i = 1, to do
        local temp = list[i]
        list[i] = list[len - i + 1]
        list[len - i + 1] = temp
    end
end

-- Generate a short unique representation for each path in pathlist.
-- note: this method will modify the lists in pathlist
local function uniquify(pathlist)
    local results = {}

    -- prepare list for uniquify2
    for _, path in ipairs(pathlist) do
        table.insert(results, { path, {} })
    end

    uniquify2(results)

    -- reverse resulting lists and prepare the final list
    for i, path in ipairs(results) do
        reverse_list(path[2])
        results[i] = path[2]
    end

    return results
end

local function test_uniquify()
    local input = {
        { 'home',   'julia',  'tmp',      'Cargo.toml' },
        { 'home',   'julia',  'tmp',      'src',         'main.rs' },
        { 'home',   'julia',  'Projects', 'hello-world', 'src',       'lib.rs' },
        { 'home',   'julia',  'Projects', 'hello-world', 'src',       'main.rs' },
        { 'home',   'julia',  'Projects', 'hello-world', 'Cargo.toml' },
        { 'home',   'abs.txt' },
        { 'abs.txt' },
    }

    for i, tpath in ipairs(uniquify(input)) do
        print(table.concat(tpath, '/'))
    end
end

return uniquify
