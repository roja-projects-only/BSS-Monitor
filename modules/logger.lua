--[[
    BSS Monitor - Logger Module
    Centralized logging with level-based console filtering.
    All logs are stored in-memory for GUI/debug access regardless of console level.
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Logger = {}

-- =============================================
-- LOG LEVELS (lower = more verbose)
-- =============================================
Logger.LEVELS = {
    DEBUG    = 1,  -- Verbose: scan details, state changes
    INFO     = 2,  -- General: player joins, passes, skips, start/stop
    WARN     = 3,  -- Important: ban attempts, mobile fallback
    ERROR    = 4,  -- Failures: ban failed, errors
    CRITICAL = 5,  -- Fatal only
    NONE     = 6,  -- No console output at all
}

-- Reverse lookup for display
local LEVEL_NAMES = {}
for name, num in pairs(Logger.LEVELS) do
    LEVEL_NAMES[num] = name
end

-- =============================================
-- ACTION TYPE → LOG LEVEL MAPPING
-- =============================================
local ACTION_LEVEL = {
    -- DEBUG level
    Scan        = 1,

    -- INFO level
    Start       = 2,
    Stop        = 2,
    Info        = 2,
    Pass        = 2,
    Skip        = 2,
    PlayerJoin  = 2,
    PlayerLeave = 2,

    -- WARN level
    Ban         = 3,
    BanVerified = 3,
    Mobile      = 3,

    -- ERROR level
    BanFailed   = 4,
    Error       = 4,
}

-- =============================================
-- STATE
-- =============================================
Logger.ConsoleLevel = Logger.LEVELS.WARN  -- Default: only WARN+ to console
Logger.Buffer = {}                         -- In-memory log buffer (all levels)
Logger.MaxBuffer = 100                     -- Max entries kept in buffer
Logger.Listeners = {}                      -- Callbacks notified on new log entry

-- Dependencies
local Config = nil

-- =============================================
-- INIT
-- =============================================
function Logger.Init(config)
    Config = config

    -- Apply config-level override if set
    if Config and Config.LOG_LEVEL then
        local level = Logger.LEVELS[Config.LOG_LEVEL:upper()]
        if level then
            Logger.ConsoleLevel = level
        end
    end
end

-- =============================================
-- SET LEVEL AT RUNTIME
-- =============================================
function Logger.SetLevel(levelNameOrNum)
    if type(levelNameOrNum) == "string" then
        local level = Logger.LEVELS[levelNameOrNum:upper()]
        if level then
            Logger.ConsoleLevel = level
        end
    elseif type(levelNameOrNum) == "number" then
        Logger.ConsoleLevel = levelNameOrNum
    end
end

-- =============================================
-- REGISTER LISTENER (e.g. GUI update callback)
-- =============================================
function Logger.OnLog(callback)
    table.insert(Logger.Listeners, callback)
end

-- =============================================
-- CORE LOG FUNCTION
-- =============================================
function Logger.Log(actionType, message)
    local level = ACTION_LEVEL[actionType] or Logger.LEVELS.INFO

    -- Build entry (always stored)
    local entry = {
        time = os.date("%H:%M:%S"),
        type = actionType,
        level = level,
        levelName = LEVEL_NAMES[level] or "INFO",
        message = message,
    }

    -- Store in buffer
    table.insert(Logger.Buffer, 1, entry)
    while #Logger.Buffer > Logger.MaxBuffer do
        table.remove(Logger.Buffer)
    end

    -- Console output (only if level meets threshold)
    if level >= Logger.ConsoleLevel then
        local prefix = "[BSS Monitor]"
        if level >= Logger.LEVELS.ERROR then
            warn(prefix, "❌", message)
        elseif level >= Logger.LEVELS.WARN then
            warn(prefix, message)
        else
            print(prefix, message)
        end
    end

    -- Notify listeners
    for _, callback in ipairs(Logger.Listeners) do
        pcall(callback, entry)
    end
end

-- =============================================
-- CONVENIENCE SHORTCUTS
-- =============================================
function Logger.Debug(message)   Logger.Log("Scan", message)      end
function Logger.Info(message)    Logger.Log("Info", message)       end
function Logger.Warn(message)    Logger.Log("Ban", message)        end
function Logger.Error(message)   Logger.Log("Error", message)      end

-- =============================================
-- QUERY BUFFER
-- =============================================

-- Get all buffer entries (newest first)
function Logger.GetAll()
    return Logger.Buffer
end

-- Get entries filtered by minimum level
function Logger.GetByLevel(minLevel)
    if type(minLevel) == "string" then
        minLevel = Logger.LEVELS[minLevel:upper()] or 1
    end
    local filtered = {}
    for _, entry in ipairs(Logger.Buffer) do
        if entry.level >= minLevel then
            table.insert(filtered, entry)
        end
    end
    return filtered
end

-- Get last N entries
function Logger.GetRecent(count)
    count = math.min(count or 20, #Logger.Buffer)
    local recent = {}
    for i = 1, count do
        recent[i] = Logger.Buffer[i]
    end
    return recent
end

-- Clear buffer
function Logger.Clear()
    Logger.Buffer = {}
end

return Logger
