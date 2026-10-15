-- Every route from app.lua will call a function here.

local dkjson = require("dkjson")
local config = require("config")

local M = {}

-- Log goes to the terminal. The main.lua file change it for a file when the app runs without terminal.
M.exit = io.stdout

-- A log line with hour and date (UTC)
function M.register(fmt, ...)
    local ok = pcall(function(...)
        M.exit:write(os.date("!%Y-%m-%dT%H:%M:%SZ "), string.format(fmt, ...), "\n")
        M.exit:flush()
    end, ...)
    return ok
end

local TEXTOS = {
    [200] = "OK",
    [201] = "Created",
    [204] = "No Content",
    [302] = "Found",
    [400] = "Bad Request",
    [401] = "Unauthorized",
    [403] = "Forbidden",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [409] = "Conflict",
    [411] = "Length Required",
    [413] = "Content Too Large",
    [422] = "Unprocessable Content",
    [429] = "Too Many Requests",
    [500] = "Internal Server Error",
    [503] = "Service Unavailable"
}
-- Four functions in layers:
function M.send(req, ans, status, body, headers)
    ans:statusCode(status, TEXTOS[status] or "Status")
    for k, v in pairs(headers or {}) do ans:addHeader(k, v) end
    ans:write(body or "")
    M.register("%s %s %s %d", req.ip or "-", req:method(), req:path(), status)
    return true
end

function M.json(req, ans, status, data, headers)
    headers = headers or {}
    headers["Content-Type"] = "application/json; charset=utf-8"
    return M.send(req, ans, status, dkjson.encode(data), headers)
end

function M.error(req, ans, status, message, details, headers)
    return M.json(req, ans, status, { error = message, details = details }, headers)
end

function M.vazio(req, ans, status, headers)
    return M.send(req, ans, status or 204, "", headers)
end

-- To get "[]" and not "{}" when the list is empty
function M.like_array(t)
    return setmetatable(t, { __jsontype = "array" })
end

-- Pegasus send query string without decoding, so:
local function decode(s)
    s = s:gsub("%+", " ")
    return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

-- Query string as a table {key = value} already decoded.
-- If there's a repeated parameter, the first value stays.
function M.query(req)
    local q = {}
    for k, v in pairs(req.querystring or {}) do
        if type(v) == "table" then v = v[1] end
        q[decode(k)] = decode(v)
    end
    return q
end

-- Read entire body restricted by Content-Length
function M.ler_corpo(req)
    local headers = req:headers()
    if headers["transfer-encoding"] then
        return nil, 411, "send body with Content-Length"
    end
    local tamanho = tonumber(headers["content-length"] or 0)
    if not tamanho or tamanho < 0 then
        return nil, 400, "invalid Content-Length"
    elseif tamanho > config.max_corpo then
        return nil, 413, "body size not allowed"
    end
    local partes, lidos = {}, 0
    while lidos < tamanho do
        local ok, pedaco = pcall(req.receiveBody, req)
        if not ok or not pedaco or pedaco == "" then break end
        partes[#partes + 1] = pedaco
        lidos = lidos + #pedaco
    end
    if lidos < tamanho then
        return nil, 400, "Requisition body incomplete"
    end
    return table.concat(partes)
end

-- Read and decode body's JSON.
function M.read_json(req)
    local body, status, msg = M.read_body(req)
    if not body then return nil, status, msg end
    if body == "" then
        return nil, 400, "request's body empty"
    end
    local obj, _, err = dkjson.decode(body, 1, nil)
    if err then
        return nil, 400, "Invalid JSON" .. err
    end
    return obj
end

return M
