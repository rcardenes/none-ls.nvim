local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local HOVER = methods.internal.HOVER

return h.make_builtin({
    name = "dictionary",
    method = HOVER,
    filetypes = { "org", "text", "markdown" },
    generator = {
        fn = function(_, done)
            local cword = vim.fn.expand("<cword>")
            local send_definition = function(def)
                done({ cword .. ": " .. def })
            end

            vim.system(
                { "curl", "-s", "https://api.dictionaryapi.dev/api/v2/entries/en/" .. cword },
                {
                    callback = vim.schedule_wrap(function(result)
                        local body = result.stdout
                        if not body or body == "" then
                            send_definition("no definition available")
                            return
                        end

                        local ok, decoded = pcall(vim.json.decode, body)
                        if not ok or not (decoded and decoded[1]) then
                            send_definition("no definition available")
                            return
                        end

                        send_definition(decoded[1].meanings[1].definitions[1].definition)
                    end),
                }
            )
        end,
        async = true,
    },
    meta = {
        url = "https://dictionaryapi.dev/",
        description = "Shows the first available definition for the current word under the cursor.",
        notes = {
            "Depends on having `curl` installed and available on your `$PATH`.",
        },
    },
})
