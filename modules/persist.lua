--[[
    BSS Monitor - Persistence Module
    Saves/loads config to BSS-Monitor/config.json using executor global file APIs.
    Uses global makefolder, writefile, readfile, isfile (no executor-specific namespaces).
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Persist = {}

local FOLDER = "BSS-Monitor"
local CONFIG_FILE = "BSS-Monitor/config.json"

-- ============================================
-- Global file API (executor-provided)
-- ============================================
local function doMakefolder(name)
    local fn = makefolder or _G.makefolder
    if type(fn) == "function" then
        return pcall(fn, name)
    end
    return false, "makefolder not available"
end

local function doWritefile(path, content)
    local fn = writefile or _G.writefile
    if type(fn) == "function" then
        return pcall(fn, path, content)
    end
    return false, "writefile not available"
end

local function doReadfile(path)
    local fn = readfile or _G.readfile
    if type(fn) == "function" then
        return pcall(fn, path)
    end
    return false, "readfile not available"
end

local function doIsfile(path)
    local fn = isfile or _G.isfile
    if type(fn) == "function" then
        return pcall(fn, path)
    end
    return false, false
end

-- ============================================
-- Public API
-- ============================================

--- Check if persistence is available (any file API works). Does not overwrite existing config.
function Persist.IsAvailable()
    Persist.EnsureFolder()
    local content, _ = Persist.Load()
    local toWrite = (content and #content > 0) and content or "{}"
    local ok = doWritefile(CONFIG_FILE, toWrite)
    return ok
end

--- Ensure folder exists. Call before first writefile if executor requires it.
function Persist.EnsureFolder()
    local ok = doMakefolder(FOLDER)
    return ok
end

--- Save string content to BSS-Monitor/config.json. Returns success, errorMessage.
function Persist.Save(content)
    if type(content) ~= "string" then
        return false, "content must be string"
    end
    Persist.EnsureFolder()
    local ok, err = doWritefile(CONFIG_FILE, content)
    if not ok then
        return false, tostring(err)
    end
    return true
end

--- Load content from BSS-Monitor/config.json. Returns content or nil, errorMessage.
function Persist.Load()
    local existsOk, exists = doIsfile(CONFIG_FILE)
    if not existsOk or not exists then
        return nil, "file not found"
    end
    local ok, content = doReadfile(CONFIG_FILE)
    if not ok then
        return nil, tostring(content)
    end
    if type(content) ~= "string" then
        return nil, "invalid read"
    end
    return content, nil
end

--- Returns true if config file exists and can be read.
function Persist.HasSavedConfig()
    local existsOk, exists = doIsfile(CONFIG_FILE)
    return existsOk and exists
end

return Persist
