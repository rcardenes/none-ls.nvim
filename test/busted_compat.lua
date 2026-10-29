local M = {}

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

local function is_post_hook(name)
    return name == "post_case" or name == "post_once"
end

local function run_test(fn, ...)
    local test_args = tbl_pack(...)
    local co = coroutine.create(function()
        fn(tbl_unpack(test_args))
    end)

    local original_resume = coroutine.resume
    local test_error = nil
    coroutine.resume = function(target, ...)
        local results = tbl_pack(original_resume(target, ...))
        if target == co and results[1] == false and test_error == nil then
            test_error = results[2]
        end
        return tbl_unpack(results)
    end

    local ok, err = original_resume(co)
    if coroutine.status(co) ~= "dead" then
        local completed = vim.wait(10000, function()
            return coroutine.status(co) == "dead"
        end, 1)
        if not completed then
            coroutine.resume = original_resume
            error("Test coroutine did not complete in time")
        end
    end

    coroutine.resume = original_resume

    if test_error then
        error(test_error)
    end
    if not ok then
        error(err)
    end
end

local function add_hook(set, name, hook)
    local opts = getmetatable(set).opts
    opts.hooks = opts.hooks or {}
    local existing = opts.hooks[name]
    if not existing then
        opts.hooks[name] = hook
        return
    end
    if is_post_hook(name) then
        opts.hooks[name] = function()
            hook()
            existing()
        end
    else
        opts.hooks[name] = function()
            existing()
            hook()
        end
    end
end

M.run = function(original_dofile, path)
    local state = require("luassert.state")
    local baseline = state.snapshot()
    local root_set = MiniTest.new_set()
    local current_snapshot = nil

    add_hook(root_set, "pre_case", function()
        current_snapshot = state.snapshot()
    end)
    add_hook(root_set, "post_case", function()
        if current_snapshot then
            state.revert(current_snapshot)
            current_snapshot = nil
        end
    end)
    add_hook(root_set, "post_once", function()
        state.revert(baseline)
    end)

    local current_set = root_set

    _G.describe = function(name, fn)
        local parent = current_set
        local child = MiniTest.new_set()
        parent[name] = child
        current_set = child
        fn()
        current_set = parent
    end

    _G.it = function(name, fn)
        current_set[name] = function(...)
            run_test(fn, ...)
        end
    end

    _G.before_each = function(hook)
        add_hook(current_set, "pre_case", hook)
    end

    _G.after_each = function(hook)
        add_hook(current_set, "post_case", hook)
    end

    _G.setup = function(hook)
        add_hook(current_set, "pre_once", hook)
    end

    _G.teardown = function(hook)
        add_hook(current_set, "post_once", hook)
    end

    original_dofile(path)

    _G.describe = nil
    _G.it = nil
    _G.before_each = nil
    _G.after_each = nil
    _G.setup = nil
    _G.teardown = nil

    return root_set
end

return M
