local M = {}

function M.root(root)
    local f = debug.getinfo(1, "S").source:sub(2)
    return vim.fn.fnamemodify(f, ":p:h:h") .. "/" .. (root or "")
end

---@param plugin string
function M.load(plugin)
    local name = plugin:match(".*/(.*)")
    local package_root = M.root(".tests/site/pack/deps/start/")
    local uv = vim.uv or vim.loop
    if not uv.fs_stat(package_root .. name) then
        print("Installing " .. plugin)
        vim.fn.mkdir(package_root, "p")
        vim.fn.system({
            "git",
            "clone",
            "--depth=1",
            "--filter=blob:none",
            "https://github.com/" .. plugin .. ".git",
            vim.fs.joinpath(package_root, name),
        })
    end
end

function M.setup()
    vim.o.runtimepath = vim.env["VIMRUNTIME"]
    vim.opt.runtimepath:append(M.root())
    vim.opt.runtimepath:append(M.root("test/deps"))
    vim.opt.packpath = { M.root(".tests/site") }
    M.load("jbyuki/one-small-step-for-vimkind")
    vim.env["XDG_CONFIG_HOME"] = M.root(".tests/config")
    vim.env["XDG_DATA_HOME"] = M.root(".tests/data")
    vim.env["XDG_STATE_HOME"] = M.root(".tests/state")
    vim.env["XDG_CACHE_HOME"] = M.root(".tests/cache")
    require("mini.test").setup({ collect = { emulate_busted = false } })
    _G.assert = require("luassert")
    _G.stub = require("luassert.stub")
    _G.mock = require("luassert.mock")
    _G.spy = require("luassert.spy")

    local original_dofile = dofile
    local busted_compat = original_dofile(M.root("test/busted_compat.lua"))
    _G.dofile = function(file)
        if file:find("test/spec/", 1, true) and file:match("_spec%.lua$") then
            return busted_compat.run(original_dofile, file)
        end
        return original_dofile(file)
    end

    require("osv").launch({ port = 8086, blocking = true })
    require("null-ls.config")._set({ log = { enable = false } })
end

vim.o.swapfile = false
vim.o.laststatus = 0
vim.o.ruler = false
vim.treesitter.start = function() end
_G.__TEST = true

M.setup()
