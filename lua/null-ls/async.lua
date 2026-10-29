local M = {}

local leaf_argc = setmetatable({}, { __mode = "k" })

local function tbl_pack(...)
    local t = { ... }
    t.n = select("#", ...)
    return t
end

local function tbl_unpack(t, i, j)
    i = i or 1
    j = j or t.n
    local values = {}
    local n = 0
    for idx = i, j do
        n = n + 1
        values[n] = t[idx]
    end
    return unpack(values, 1, n)
end

local function is_callable(value)
    return type(value) == "function" or (type(value) == "table" and getmetatable(value) ~= nil and getmetatable(value).__call ~= nil)
end

local function rotate(n, value, ...)
    if n == nil or n < 1 then
        return
    end
    if n == 1 then
        return value
    end
    local args = tbl_pack(...)
    local result = {}
    for i = 1, n - 1 do
        result[i] = args[i]
    end
    result[n] = value
    for i = n, args.n do
        result[i + 1] = args[i]
    end
    return tbl_unpack(result, 1, args.n + 1)
end

local function add_leaf_function(func, argc)
    leaf_argc[func] = argc
end

M.is_leaf_function = function(func)
    return leaf_argc[func] ~= nil
end

M.get_leaf_function_argc = function(func)
    return leaf_argc[func]
end

M.wrap = function(func, argc)
    local function leaf(...)
        local nargs = select("#", ...)
        if nargs == argc then
            return func(...)
        end
        return coroutine.yield(func, argc, ...)
    end
    add_leaf_function(leaf, argc)
    return leaf
end

local function callback_or_next(step, thread, callback, ...)
    local stat = select(1, ...)
    if not stat then
        error("The coroutine failed with this message: " .. select(2, ...))
    end

    if coroutine.status(thread) == "dead" then
        if callback then
            callback(select(2, ...))
        end
        return
    end

    local returned_function = select(2, ...)
    local nargs = select(3, ...)
    assert(is_callable(returned_function), "Async function must yield a callable")
    returned_function(rotate(nargs, step, select(4, ...)))
end

local function execute(async_function, callback, ...)
    local thread = coroutine.create(async_function)
    local step
    step = function(...)
        callback_or_next(step, thread, callback, coroutine.resume(thread, ...))
    end
    step(...)
end

M.run = function(async_function, callback)
    if M.is_leaf_function(async_function) then
        async_function(callback)
    else
        execute(async_function, callback)
    end
end

local function oneshot()
    local sent = false
    local value
    local callback

    local function sender(...)
        if callback then
            local cb = callback
            callback = nil
            cb(...)
        else
            sent = true
            value = tbl_pack(...)
        end
    end

    local receiver = M.wrap(function(cb)
        if sent then
            cb(tbl_unpack(value))
        else
            callback = cb
        end
    end, 1)

    return sender, receiver
end

M.util = {}

M.util.scheduler = M.wrap(vim.schedule, 1)

M.util.join = function(async_fns)
    local results = {}
    local total = #async_fns
    if total == 0 then
        return results
    end

    local done = 0
    local tx, rx = oneshot()
    for i, async_fn in ipairs(async_fns) do
        M.run(async_fn, function(...)
            results[i] = tbl_pack(...)
            done = done + 1
            if done == total then
                tx()
            end
        end)
    end
    rx()
    return results
end

M.util.apcall = function(async_fn, ...)
    local nargs = M.get_leaf_function_argc(async_fn)
    if not nargs then
        return pcall(async_fn, ...)
    end

    local tx, rx = oneshot()
    local stat, ret = pcall(async_fn, rotate(nargs, tx, ...))
    if not stat then
        return stat, ret
    end
    return stat, rx()
end

return M
