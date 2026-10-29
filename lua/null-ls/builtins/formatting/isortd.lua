local h = require("null-ls.helpers")
local u = require("null-ls.utils")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "isortd",
    meta = {
        url = "https://github.com/urm8/isortd",
        description = "isortd is a small HTTP server that exposes isort’s functionality over a simple protocol. The main benefit of using it is to avoid the cost of starting up a new isort process every time you want to format a file.",
        config = {
            {
                key = "hostname",
                type = "string",
                description = "Address that the isortd server listens on. Defaults to localhost.",
            },
            {
                key = "port",
                type = "string",
                description = "Port that the isortd server listens on. Defaults to 47393.",
            },
        },
    },
    method = FORMATTING,
    filetypes = { "python" },
    generator = {
        async = true,
        fn = function(params, done)
            local config = params:get_config()
            local hostname = config.hostname or "localhost"
            local port = config.port or 47393
            local root = u.get_root()
            local filepath = vim.api.nvim_buf_get_name(params.bufnr)

            local body = table.concat(params.content, "\n")
            vim.system(
                {
                    "curl",
                    "-s",
                    "-X",
                    "POST",
                    "-H",
                    "XX-SRC: " .. root,
                    "-H",
                    "XX-PATH: " .. filepath,
                    "-d",
                    body,
                    "-w",
                    "\n%{http_code}",
                    "http://" .. hostname .. ":" .. port,
                },
                {
                    callback = function(result)
                        local log = require("null-ls.logger")
                        if result.code ~= 0 then
                            log:error(string.format("error formatting with isortd: %s", result.stderr or result.stdout or "unknown error"))
                            return done()
                        end

                        local raw = result.stdout or ""
                        local status_idx = raw:find("\n%d+$")
                        local response_body = status_idx and raw:sub(1, status_idx - 1) or raw
                        local status = status_idx and tonumber(raw:sub(status_idx + 1)) or nil

                        if status == 200 then
                            return done({ { text = response_body } })
                        end

                        log:error(string.format("error formatting with isortd %s %s", tostring(status), response_body))
                        return done()
                    end,
                }
            )
        end,
    },
})
