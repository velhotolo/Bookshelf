-- This file set values for the app. It runs with paths since the latter determines the OS used.

local paths = require("paths")

local common = {
    version = "1.0.0",
    host = "127.0.0.1", -- Never online; only the machine
    port = 47823,
    extra_ports = 9,
    pbkdf2_iter = 600000, -- Password hash costs
    token_ttl = 86400,    -- Access token for 24 hours
    timeout = 2,
    max_body = 1048576,   -- 1mb: above this, 413
    auth_limit = { per_minute = 30, beam = 10 },
    open_browser = true,
    log_file = true, -- Without visible terminal, log goes to a file
}

local environments = { -- Different environment setups (produciton, development, tests)
    production = {},
    development = {
        data_folder = "data",
        auth_limit = { per_minute = 600, beam = 100 },
        log_file = false,
    },
    test = {
        port = 8081,
        extra_ports = 0,
        data_folder = "data",
        database_file = "test.db",
        pbkdf2_iter = 1000,
        auth_limit = { per_minute = 100000, beam = 100000 },
        open_browser = false,
        log_file = false,
    },
}

local name = os.getenv("APP_ENV") or "production"
local extra = environments[name] or error("APP_ENV unknown: " .. name)

local config = { environment = name }
for k, v in pairs(common) do config[k] = v end
for k, v in pairs(extra) do config[k] = v end

config.data_folder = config.data_folder or paths.data_folder()
config.db_path = os.getenv("DB_PATH") or paths.stack(config.data_folder, config.database_file or "bookshelf.db")
config.log_file = paths.stack(config.data_folder, "bookshelf.log")
config.port = tonumber(os.getenv("PORT")) or config.port
config.host = os.getenv("HOST") or config.host
if os.getenv("BOOKSHELF_WITHOUT_BROWSER") == "1" then config.open_browser = false end

return config
