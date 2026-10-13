local source = debug.getinfo(1, "S").source:sub(2)
local folder_app = source:match("^(.*)[\\/][^\\/]+$") or "."
package.path = folder_app .. "/?.lua;" .. folder_app .. "/?/init.lua;" .. package.path

local lfs = require("lfs")
local config = require("config")
config.folder_app = folder_app
local paths = require("paths")
local web = require("web")

-- Messages for a user in the terminal
local function warn(fmt, ...)
    print(string.format(fmt, ...))
end

-- If there is no terminal, try a desktop notification

local function notify_failure()
    if paths.windows then return end
    local msg = ("It was not possible to start. Details in %s"):format(config.log_file)
    os.execute("notify-send 'Bookshelf' '" .. msg:gsub("'", "'\\''") .. "' >/dev/null 2>&1")
end

local function start()
    -- Data and log folder
    assert(paths.create_folder(config.data_folder))
    if config.log_in_file then
        -- Just keep recent log. Restart at 1mb.
        local size = lfs.attributes(config.log_file, "size") or 0
        local f = io.open(config.log_file, size > 1048576 and "w" or "a")
        if f then web.out = f end
    end
    web.register("Bookshelf %s starting (%s), database %s",
        config.version, config.enviroment, config.db_path)

    -- Database: Update or create
    local db = require("db")
    db.migrate()

    -- Port

    local server = require("server")
    local s, port, reason = server.choose_port(config.host, config.port, config.extra_ports)
    if not s and reason == "already_open" then
        warn("Bookshelf is already running. Opening your browser...")
        if config.open_browser then
            server.open_browser(("http://127.0.0.1:%d"):format(port))
        end
        return
    elseif not s then
        error(("no port available between %d and %d"):format(
            config.port, config.port + config.extra_ports), 0)
    end
    config.port = port
    local url = ("http://127.0.0.1:%d/"):format(port)
    warn("")
    warn(" Bookshelf %s open in %s", config.versao, url)
    warn(" Your data is stored in %s", config.data_folder)
    warn("")
    warn(" To quit, use the \"Quit\" button in the app%s.",
        paths.windows and " or close this window" or " or press Crtl+C")
    web.register("listening in %s", url)

    if config.open_browser then server.open_browser(url) end

    local app = require("app")
    server.run(s, app.plugins(), app.not_found, config.timeout, port)
    web.register("terminated by user")
    warn("Bookshelf terminated")
end

local ok, err = xpcall(start, debug.traceback)
if not ok then
    web.register("failed to start: %s", tostring(err))
    notify_failure()
    -- Send the error for who called and exits with code 1;
    error("Failed to start Bookshelf:\n" .. tostring(err), 0)
end
