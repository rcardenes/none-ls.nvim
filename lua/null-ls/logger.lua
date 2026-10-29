local c = require("null-ls.config")
local u = require("null-ls.utils")

local default_notify_opts = {
    title = "null-ls",
}

local level_weights = {
    trace = 1,
    debug = 2,
    info = 3,
    warn = 4,
    error = 5,
}

local log = {}

--- Adds a log entry to the null-ls log file
---@param msg any
---@param level string [same as vim.log.log_levels]
function log:add_entry(msg, level)
    local cfg = c.get()

    if not self.__notify_fmt then
        self.__notify_fmt = function(m)
            return string.format(cfg.notify_format, m)
        end
    end

    if cfg.log_level == "off" then
        return
    end

    local effective_level = cfg.debug and "trace" or (cfg.log_level or "warn")
    if (level_weights[level] or 0) < (level_weights[effective_level] or 0) then
        return
    end

    local path = self:get_path()
    vim.fn.mkdir(vim.fn.stdpath("log"), "p")
    local file = io.open(path, "a")
    if not file then
        return
    end

    file:write(string.format("[%s] [%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), level:upper(), tostring(msg)))
    file:close()
end

--- Retrieves the path of the logfile
---@return string path path of the logfile
function log:get_path()
    return u.path.join(vim.fn.stdpath("log") --[[@as string]], "null-ls.log")
end

---Add a log entry at TRACE level
---@param msg any
function log:trace(msg)
    self:add_entry(msg, "trace")
end

---Add a log entry at DEBUG level
---@param msg any
function log:debug(msg)
    self:add_entry(msg, "debug")
end

---Add a log entry at INFO level
---@param msg any
function log:info(msg)
    self:add_entry(msg, "info")
end

---Add a log entry at WARN level
---@param msg any
function log:warn(msg)
    self:add_entry(msg, "warn")
    vim.schedule(function()
        vim.notify(self.__notify_fmt(msg), vim.log.levels.WARN, default_notify_opts)
    end)
end

---Add a log entry at ERROR level
---@param msg any
function log:error(msg)
    self:add_entry(msg, "error")
    vim.schedule(function()
        vim.notify(self.__notify_fmt(msg), vim.log.levels.ERROR, default_notify_opts)
    end)
end

setmetatable({}, log)
return log
