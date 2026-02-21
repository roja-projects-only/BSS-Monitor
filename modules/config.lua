--[[
    BSS Monitor - Configuration Module
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Config = {}

-- =============================================
-- VERSION (auto-bumped by CI — do not edit manually)
-- =============================================
Config.VERSION = "1.6.1"

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
Config.AUTO_START = true            -- If true, starts monitoring immediately on load
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

return Config
