-- Defines Windows or Linux;
-- Keep data from each person;
-- Also create folders

local lfs = require("lfs") -- Useful C library. Allo us to check file size, create folders and whatnot

local M = {}

-- Defining by folders: "\" for Windows, "/" for the rest
M.windows = package.config:sub(1, 1) == "\\"
M.sep = M.windows and "\\" or "/"

-- Stack pieces of a path

function M.stack(...)
    return table.concat({ ... }, M.sep)
end

-- Users folders by default:
-- Linux: $XDG_DATA_HOME/biblioteca (usually ~/.local/share/biblioteca)
-- Windows: %APPDATA%\Bookshelf     (usually C:\Users\<name>\AppData\Roaming\Bookshelf)
-- BOOKSHELF_DATA overwrittes both (useful for tests)
function M.data_folder()
    local forced = os.getenv("BOOKSHELF_DATA")
    if forced and forced ~= "" then return forced end -- The double test here covers 3 situations. If os.getenv returns nil, it might cause problems later down the road.
    if M.windows then
        local appdata = os.getenv("APPDATA") or os.getenv("USERPROFILE") or "."
        return M.stack(appdata, "Bookshelf")
    end
    local xdg = os.getenv("XDG_DATA_HOME")
    if xdg and xdg ~= "" then return xdg .. "/bookshelf" end -- Same here
    return (os.getenv("HOME") or ".") .. "/.local/share/bookshelf"
end

-- Create folders along the way
local prefix
local leftover
function M.create_folder(path)
    if lfs.attributes(path, "mode") == "directory" then return true end
    prefix, leftover = path:match("^(%a:[\\/])(.*)$")
    if not prefix then prefix, leftover = path:match("^([\\/]?)(.*)$") end
    local current = prefix
    for part in leftover:gmatch("[^\\/]+") do
        current = (current == prefix) and (prefix .. part) or (current .. M.sep .. part)
        if lfs.attributes(current, "mode") ~= "directory" then
            local ok, err = lfs.mkdir(current)
            if not ok and lfs.attributes(current, "mode") ~= "directory" then
                return nil, "couldn't create " .. current .. ": " .. tostring(err)
            end
        end
    end
    return true
end

function M.folder_of(file)
    return file:match("^(.*)[\\/][^\\/]+$")
end

return M
