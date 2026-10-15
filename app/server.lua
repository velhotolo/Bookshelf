-- Same of Pegasus:start() but more concise.
-- Key differences:
-- open port before, so we know if it's free to open the browser;
-- recognize when the port is from another instance of Bookshelf;
-- Pegasus' Handler still processes the requests.
local socket = require("socket")
local http = require("socket.http")
local Handler = require("pegasus.handler")
local paths = require("paths")
local web = require("web")

local M = {}
local stop = false

function M.ask_stop()
    stop = true
end

function M.open_port(host, port)
    local s, err
    if host:find(":", 1, true) then s, err = socket.tcp6() else s, err = socket.tcp4() end
    if not s then return nil, err end
    if not paths.windows then assert(s:setoption("reuseaddr", true)) end -- on Linux accelerates port reuse; on Windows allow 2 instances of the app at the same time,
    local ok                                                             -- which is dangerous.
    ok, err = s:bind(host, port)
    if ok then ok, err = s:listen(64) end
    if not ok then
        s:close()
        return nil, err
    end
    return s
end

function M.is_it_bookshelf(host, port)
    http.TIMEOUT = 2
    local body, code = http.request(string.format("http://%s:%d/health", host, port))
    return code == 200 and type(body) == "string"
        and body:find('"app":"bookshelf"', 1, true) ~= nil
end

function M.choose_port(host, initial, extras)
    for port = initial, initial + extras do
        local s = M.open_port(host, port)
        if s then return s, port end
        if M.is_it_bookshelf(host, port) then return nil, port, "already_open" end
    end
    return nil, nil, "no_port"
end

function M.open_browser(url)
    assert(url:match("^http://[%w%.%[%]:]+/?$"), "unexpected URL")
    if paths.windows then
        os.execute('start "" "' .. url .. '"')
    else
        os.execute('xdg-open "' .. url .. '" >/dev/null 2>&1 &')
    end
end

function M.run(s, plugins, callback, timeout, port)
    local handler = Handler:new(callback, nil, plugins)
    s:settimeout(0.5)
    stop = false
    while not stop do
        local client = s:accept()
        if client then
            client:settimeout(timeout, "b")
            local ok, err = pcall(handler.processRequest, handler, port, client, s)
            if not ok then
                web.register("ERROR while processing request: %s", tostring(err))
                pcall(client.close, client)
            end
        end
    end
    s:close()
end

return M

