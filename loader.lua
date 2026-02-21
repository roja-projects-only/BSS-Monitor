--[[
    BSS Monitor - Loader
    Private server monitoring for Bee Swarm Simulator
    https://github.com/roja-projects-only/BSS-Monitor
    
    =============================================
    LOADSTRING (copy this):
    =============================================
    
    loadstring(game:HttpGet("https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/loader.lua"))()
    
    =============================================
    WITH CUSTOM CONFIG:
    =============================================
    
    _G.BSSMonitorConfig = {
        WEBHOOK_URL = "YOUR_DISCORD_WEBHOOK_URL",
        DRY_RUN = false,  -- Set to false to actually ban
        AUTO_START = true,
        MINIMUM_LEVEL = 17,
        REQUIRED_PERCENT = 0.80,
    }
    loadstring(game:HttpGet("https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/loader.lua"))()
    
]]

local REPO_BASE = "https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/"
local CACHE_BUST = "?v=" .. tostring(os.time())

-- ============================================
-- CLEANUP PREVIOUS SESSION (if re-executed)
-- ============================================
if _G.BSSMonitor then
    -- Silent cleanup of previous session
    
    pcall(function()
        if _G.BSSMonitor.Monitor and _G.BSSMonitor.Monitor.IsRunning then
            _G.BSSMonitor.Monitor.Stop()
        end
    end)
    
    pcall(function()
        -- Destroy GUI and its connections
        if _G.BSSMonitor.GUI then
            if _G.BSSMonitor.GUI.ScreenGui then
                _G.BSSMonitor.GUI.ScreenGui:Destroy()
            end
            for _, conn in ipairs(_G.BSSMonitor.GUI.Connections or {}) do
                pcall(function() conn:Disconnect() end)
            end
        end
    end)
    
    pcall(function()
        -- Disconnect all stored connections (Monitor state + _G level)
        if _G.BSSMonitor.MonitorState and _G.BSSMonitor.MonitorState.Connections then
            for _, conn in ipairs(_G.BSSMonitor.MonitorState.Connections) do
                pcall(function() conn:Disconnect() end)
            end
        elseif _G.BSSMonitor.Monitor and _G.BSSMonitor.Monitor.Connections then
            for _, conn in ipairs(_G.BSSMonitor.Monitor.Connections) do
                pcall(function() conn:Disconnect() end)
            end
        end
        if _G.BSSMonitor._connections then
            for _, conn in pairs(_G.BSSMonitor._connections) do
                if conn and typeof(conn) == "RBXScriptConnection" then
                    conn:Disconnect()
                end
            end
        end
    end)
    
    _G.BSSMonitor = nil
    -- Previous session cleaned up
    task.wait(0.5)
end

-- Check for custom config
local customConfig = _G.BSSMonitorConfig

print("🐝 BSS Monitor - Loading...")

-- Load modules function
local function loadModule(name)
    local url = REPO_BASE .. "modules/" .. name .. ".lua" .. CACHE_BUST
    
    local httpSuccess, code = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not httpSuccess then
        warn("  ✗ " .. name .. ": HTTP failed")
        return nil
    end
    
    local loadSuccess, loadedFunc = pcall(function()
        return loadstring(code, name)
    end)
    
    if not loadSuccess or not loadedFunc then
        warn("  ✗ " .. name .. ": loadstring failed")
        return nil
    end
    
    local runSuccess, result = pcall(loadedFunc)
    
    if runSuccess then
        return result
        return result
    else
        warn("  ✗ " .. name .. ": " .. tostring(result))
        return nil
    end
end

-- Load Logger first (used by all modules)
local Logger = loadModule("logger")

-- Load all modules
local Config = loadModule("config")
local Scanner = loadModule("scanner")
local Chat = loadModule("chat")

-- Load Monitor sub-modules (modular monitor/ folder)
local MonitorState = loadModule("monitor/state")
local MonitorBan = loadModule("monitor/ban")
local MonitorCycle = loadModule("monitor/cycle")
local Monitor = loadModule("monitor/init")

-- Load Webhook sub-modules (modular webhook/ folder)
local WebhookHttp = loadModule("webhook/http")
local WebhookEmbeds = loadModule("webhook/embeds")
local Webhook = loadModule("webhook/init")

-- Load GUI sub-modules (modular gui/ folder)
local GUITheme = loadModule("gui/theme")
local GUIHelpers = loadModule("gui/helpers")
local GUIComponents = loadModule("gui/components")
local GUI = loadModule("gui/init")

-- Validate critical modules (GUI is optional)
if not Config or not Scanner or not Monitor or not MonitorState or not Logger then
    error("❌ BSS Monitor: Critical module load failed!")
    return
end

-- Apply custom config if provided
if customConfig then
    for key, value in pairs(customConfig) do
        Config[key] = value
    end
end

-- Initialize modules
Logger.Init(Config)
_G.BSSMonitorLogger = Logger  -- Expose early for modules that load before full init
if MonitorState then MonitorState.Init(Logger) end
if Chat then Chat.Init(Config) end
if WebhookEmbeds then WebhookEmbeds.Init(WebhookHttp) end
if Webhook then Webhook.Init(WebhookHttp, WebhookEmbeds) end
if GUIHelpers then GUIHelpers.Init(GUITheme) end
if GUIComponents then GUIComponents.Init(GUITheme, GUIHelpers, Config, Monitor, Chat) end
if GUI then GUI.Init(Config, Monitor, Chat, GUITheme, GUIHelpers, GUIComponents) end
Monitor.Init(Config, Scanner, Webhook, Chat, GUI, MonitorState, MonitorBan, MonitorCycle)

-- Create GUI if enabled
if Config.SHOW_GUI and GUI then
    GUI.Create()
end

-- Initial scan after brief delay
task.wait(1)
Monitor.RunCycle()

-- Auto-start if configured
if Config.AUTO_START then
    Monitor.Start()
end

-- Store in _G for access
_G.BSSMonitor = {
    Config = Config,
    Scanner = Scanner,
    Webhook = Webhook,
    Chat = Chat,
    GUI = GUI,
    Monitor = Monitor,
    MonitorState = MonitorState,
    Logger = Logger,
    _connections = {},  -- Store connections for cleanup on re-execution
    
    -- Convenience functions
    start = function() Monitor.Start() end,
    stop = function() Monitor.Stop() end,
    toggle = function() Monitor.Toggle() end,
    scan = function() return Monitor.RunCycle() end,
    status = function() return Monitor.GetStatus() end,
    ban = function(name) return Monitor.ManualBan(name) end,
    whitelist = function(name) return Config.AddToWhitelist(name) end,
    unwhitelist = function(name) return Config.RemoveFromWhitelist(name) end,
    showGui = function() if GUI then GUI.Show() end end,
    hideGui = function() if GUI then GUI.Hide() end end,
    
    -- Test functions
    testChat = function() return Chat.SendTestMessage() end,
    testWebhook = function() return Webhook.Send(Config, { title = "🧪 Test", description = "Webhook test successful!", color = 0x57F287 }) end,
    
    -- Logging controls
    setLogLevel = function(level) Logger.SetLevel(level) end,
    getLogs = function(count) return Logger.GetRecent(count or 20) end,
    clearLogs = function() Logger.Clear() end,
    
    -- Manual cleanup
    cleanup = function()
        -- Silent cleanup
        pcall(function() Monitor.Stop() end)
        pcall(function() if GUI then GUI.ScreenGui:Destroy() end end)
        pcall(function()
            for _, conn in ipairs(GUI and GUI.Connections or {}) do conn:Disconnect() end
        end)
        pcall(function()
            for _, conn in ipairs(_G.BSSMonitor._connections) do conn:Disconnect() end
        end)
        -- Cleaned up
        _G.BSSMonitor = nil
    end,
    
    -- Version
    version = Config.VERSION or "unknown"
}

print("🐝 BSS Monitor v" .. (Config.VERSION or "?") .. " ready | DRY=" .. (Config.DRY_RUN and "ON" or "OFF") .. " LOG=" .. (Config.LOG_LEVEL or "WARN"))

return _G.BSSMonitor
