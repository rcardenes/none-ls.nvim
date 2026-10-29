local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "blackd",
    meta = {
        url = "https://github.com/psf/black",
        description = "blackd is a small HTTP server that exposes Black’s functionality over a simple protocol. The main benefit of using it is to avoid the cost of starting up a new Black process every time you want to blacken a file. The only way to configure the formatter is by using the provided config options, it will not pick up on config files.",

        config = {
            {
                key = "hostname",
                type = "string",
                description = "Address to bind the server to. Defaults to localhost.",
            },
            { key = "port", type = "string", description = "Port to listen on. Defaults to 45484." },
            {
                key = "line_length",
                type = "number",
                description = "Set how many characters per line to allow. Defaults to 88.",
            },
            {
                key = "skip_source_first_line",
                type = "boolean",
                description = "If set to true, the first line of the source code will be ignored. Defaults to false.",
            },
            {
                key = "skip_string_normalization",
                type = "boolean",
                description = "If set to true, no string normalization will be performed. Defaults to false.",
            },
            {
                key = "skip_magic_trailing_comma",
                type = "boolean",
                description = "If set to true, trailing commas will not be used as a reason to split lines. Defaults to false.",
            },
            {
                key = "preview",
                type = "boolean",
                description = "If set to true, experimental and potentially disruptive style changes will be used. Defaults to false.",
            },
            {
                key = "fast",
                type = "boolean",
                description = "If set to true, Black will not perform an AST safety check after formatting. Defaults to false.",
            },
            {
                key = "python_variant",
                type = "string",
                description = "If set to pyi, Black will format all input files like typing stubs regardless of the file extension. Otherwise, its value must correspond to a Python version or a set of comma-separated Python versions, optionally prefixed with py. (e.g. py3.5,py3.6). Defaults to empty string.",
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
            local port = config.port or 45484
            local body = table.concat(params.content, "\n")
            local headers = {
                { "X-Line-Length", tostring(config.line_length or 88) },
                { "X-Skip-Source-First-Line", config.skip_source_first_line and "true" or nil },
                { "X-Skip-String-Normalization", config.skip_string_normalization and "true" or nil },
                { "X-Skip-Magic-Trailing-Comma", config.skip_magic_trailing_comma and "true" or nil },
                { "X-Preview", config.preview and "true" or nil },
                { "X-Fast-Or-Safe", config.fast == "fast" and "fast" or nil },
                { "X-Python-Variant", config.python_variant or "" },
            }

            local args = { "curl", "-s", "-X", "POST" }
            for _, header in ipairs(headers) do
                if header[2] ~= nil then
                    table.insert(args, "-H")
                    table.insert(args, header[1] .. ": " .. header[2])
                end
            end
            table.insert(args, "-d")
            table.insert(args, body)
            table.insert(args, "-w")
            table.insert(args, "\n%{http_code}")
            table.insert(args, "http://" .. hostname .. ":" .. port)

            vim.system(args, {
                callback = function(result)
                    if result.code ~= 0 then
                        return done()
                    end

                    local raw = result.stdout or ""
                    local status_idx = raw:find("\n%d+$")
                    local response_body = status_idx and raw:sub(1, status_idx - 1) or raw
                    local status = status_idx and tonumber(raw:sub(status_idx + 1)) or nil

                    if status == 200 then
                        return done({ { text = response_body } })
                    end
                    return done()
                end,
            })
        end,
    },
})
