--[[
    BSS Monitor - Configuration Module
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Config = {}

-- =============================================
-- VERSION (auto-bumped by CI — do not edit manually)
-- =============================================
Config.VERSION = "1.9.3"

-- =============================================
-- MONITORING REQUIREMENTS
-- =============================================
Config.MINIMUM_LEVEL = 17           -- Minimum bee level to count as "meeting requirement"
Config.REQUIRED_PERCENT = 0.80      -- 80% of bees must be at or above MINIMUM_LEVEL
Config.MIN_BEES_REQUIRED = 45       -- Minimum bees to have (ignore if less, might be new player)

-- =============================================
-- TIMING SETTINGS
-- =============================================
Config.CHECK_INTERVAL = 30          -- Seconds between scans
Config.GRACE_PERIOD = 20            -- Seconds after join before checking (let hive load)
Config.SCAN_TIMEOUT = 100            -- Seconds after grace period before kicking (no hive data found)
Config.BAN_COOLDOWN = 5             -- Seconds between ban commands (avoid spam)

-- =============================================
-- SERVER SETTINGS
-- =============================================
Config.MAX_PLAYERS = 6              -- Max players in private server

-- =============================================
-- WHITELIST (these players will NEVER be banned)
-- =============================================
Config.WHITELIST = {
    "a210w",
    "a21_0w",                        -- Owner
    -- Add more usernames here:
    -- "FriendName1",
    -- "FriendName2",
}

-- =============================================
-- DISCORD WEBHOOK
-- =============================================
Config.WEBHOOK_ENABLED = true
Config.WEBHOOK_URL = ""             -- Set your Discord webhook URL here

-- =============================================
-- BEHAVIOR SETTINGS
-- =============================================
Config.DRY_RUN = false               -- If true, logs but doesn't actually ban (for testing)
Config.SHOW_GUI = true             -- If false, runs without GUI (headless mode)
Config.USE_KICK = true              -- If true, uses /kick instead of /ban (some servers only support kick)

-- =============================================
-- MOBILE SETTINGS (auto-detected, but can override)
-- =============================================
Config.MOBILE_MODE = nil           -- nil = auto-detect, true = force mobile, false = force desktop

-- =============================================
-- LOGGING SETTINGS
-- =============================================
Config.LOG_LEVEL = "WARN"          -- Console output level: DEBUG, INFO, WARN, ERROR, CRITICAL, NONE
                                    -- All levels are always stored in-memory for GUI/debug access
                                    -- Use "NONE" to completely silence console output

-- =============================================
-- DISCORD NOTIFICATION SETTINGS
-- =============================================
Config.DISCORD_USER_ID = ""         -- Discord user ID for @mention in ban notifications (e.g., "123456789012345678")
Config.MOBILE_RENOTIFY_INTERVAL = 300  -- Seconds between re-sending webhook if player is still in server (default 5 min)
-- =============================================
-- HIVE GRID CONSTANTS
-- =============================================
Config.HIVE_SIZE_X = 5
Config.HIVE_SIZE_Y = 10
Config.MAX_SLOTS = Config.HIVE_SIZE_X * Config.HIVE_SIZE_Y  -- 50

-- =============================================
-- HELPER FUNCTIONS
-- =============================================
function Config.IsWhitelisted(username)
    for _, name in ipairs(Config.WHITELIST) do
        if name:lower() == username:lower() then
            return true
        end
    end
    return false
end

function Config.AddToWhitelist(username)
    if not Config.IsWhitelisted(username) then
        table.insert(Config.WHITELIST, username)
        return true
    end
    return false
end

function Config.RemoveFromWhitelist(username)
    for i, name in ipairs(Config.WHITELIST) do
        if name:lower() == username:lower() then
            table.remove(Config.WHITELIST, i)
            return true
        end
    end
    return false
end

--- True when notifications are enabled and webhook URL is set (trimmed non-empty).
--- Use this before sending webhooks or logging Discord-related messages.
function Config.IsWebhookConfigured()
    if not Config.WEBHOOK_ENABLED then return false end
    local url = type(Config.WEBHOOK_URL) == "string" and Config.WEBHOOK_URL:gsub("^%s*(.-)%s*$", "%1") or ""
    return url ~= ""
end

-- =============================================
-- PERSISTENCE (export/apply for config.json)
-- =============================================
-- Keys saved to file (excludes VERSION, MAX_SLOTS, and functions)
Config.PERSIST_KEYS = {
    "MINIMUM_LEVEL", "REQUIRED_PERCENT", "MIN_BEES_REQUIRED",
    "CHECK_INTERVAL", "GRACE_PERIOD", "SCAN_TIMEOUT", "BAN_COOLDOWN",
    "MAX_PLAYERS", "WHITELIST",
    "WEBHOOK_ENABLED", "WEBHOOK_URL",
    "DRY_RUN", "SHOW_GUI", "USE_KICK",
    "MOBILE_MODE", "LOG_LEVEL",
    "DISCORD_USER_ID", "MOBILE_RENOTIFY_INTERVAL",
}

--- Export current config to a plain table for JSON encode. Copies whitelist by value.
function Config.ExportToTable()
    local t = {}
    for _, key in ipairs(Config.PERSIST_KEYS) do
        local v = Config[key]
        if key == "WHITELIST" then
            t[key] = {}
            for _, name in ipairs(v or {}) do
                table.insert(t[key], name)
            end
        else
            t[key] = v
        end
    end
    return t
end

--- Apply a table (e.g. from JSON decode) onto Config. Ignores unknown keys and invalid types.
function Config.ApplyFromTable(tbl)
    if type(tbl) ~= "table" then return end
    for _, key in ipairs(Config.PERSIST_KEYS) do
        local v = tbl[key]
        if v == nil then continue end
        if key == "WHITELIST" then
            if type(v) == "table" then
                Config.WHITELIST = {}
                for _, name in ipairs(v) do
                    if type(name) == "string" and #name > 0 then
                        table.insert(Config.WHITELIST, name)
                    end
                end
            end
        elseif key == "MOBILE_MODE" then
            if v == true or v == false then
                Config.MOBILE_MODE = v
            elseif v == nil then
                Config.MOBILE_MODE = nil
            end
        elseif key == "MINIMUM_LEVEL" then
            local n = tonumber(v)
            if n then Config[key] = math.max(1, math.min(23, math.floor(n))) end
        elseif key == "MIN_BEES_REQUIRED" or key == "MAX_PLAYERS" then
            local n = tonumber(v)
            if n and n >= 0 then Config[key] = math.floor(n) end
        elseif key == "REQUIRED_PERCENT" then
            local n = tonumber(v)
            if n and n >= 0 and n <= 1 then Config[key] = n end
        elseif key == "CHECK_INTERVAL" or key == "GRACE_PERIOD" or key == "SCAN_TIMEOUT" or key == "BAN_COOLDOWN" or key == "MOBILE_RENOTIFY_INTERVAL" then
            local n = tonumber(v)
            if n and n >= 0 then Config[key] = math.floor(n) end
        elseif key == "WEBHOOK_ENABLED" or key == "DRY_RUN" or key == "SHOW_GUI" or key == "USE_KICK" then
            if type(v) == "boolean" then Config[key] = v end
        elseif key == "WEBHOOK_URL" or key == "DISCORD_USER_ID" then
            if type(v) == "string" then
                local trimmed = v:gsub("^%s*(.-)%s*$", "%1")
                Config[key] = trimmed
            end
        elseif key == "LOG_LEVEL" then
            if type(v) == "string" then
                local valid = { DEBUG = true, INFO = true, WARN = true, ERROR = true, CRITICAL = true, NONE = true }
                if valid[v] then Config[key] = v end
            end
        end
    end
    Config.MAX_SLOTS = Config.HIVE_SIZE_X * Config.HIVE_SIZE_Y
end

return Config
