--[[
    BSS Monitor - Persistence Module
    Saves/loads config to BSS-Monitor/config.json using executor file APIs.
    Fallback chain: syn.*, fluxus.*, global writefile/readfile/makefolder.
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Persist = {}

local FOLDER = "BSS-Monitor"
local CONFIG_FILE = "BSS-Monitor/config.json"

-- ============================================
-- Executor file API fallback chain
-- ============================================
local function doMakefolder(name)
    if syn and syn.makefolder then
        return pcall(syn.makefolder, name)
    end
    if fluxus and fluxus.makefolder then
        return pcall(fluxus.makefolder, name)
    end
    if _G.makefolder and type(_G.makefolder) == "function" then
        return pcall(_G.makefolder, name)
    end
    return false, "makefolder not available"
end

local function doWritefile(path, content)
    if syn and syn.writefile then
        return pcall(syn.writefile, path, content)
    end
    if fluxus and fluxus.writefile then
        return pcall(fluxus.writefile, path, content)
    end
    if _G.writefile and type(_G.writefile) == "function" then
        return pcall(_G.writefile, path, content)
    end
    return false, "writefile not available"
end

local function doReadfile(path)
    if syn and syn.readfile then
        return pcall(syn.readfile, path)
    end
    if fluxus and fluxus.readfile then
        return pcall(fluxus.readfile, path)
    end
    if _G.readfile and type(_G.readfile) == "function" then
        return pcall(_G.readfile, path)
    end
    return false, "readfile not available"
end

local function doIsfile(path)
    if syn and syn.isfile then
        return pcall(syn.isfile, path)
    end
    if fluxus and fluxus.isfile then
        return pcall(fluxus.isfile, path)
    end
    if _G.isfile and type(_G.isfile) == "function" then
        return pcall(_G.isfile, path)
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
