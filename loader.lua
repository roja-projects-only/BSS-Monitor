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
        MINIMUM_LEVEL = 17,
        REQUIRED_PERCENT = 0.80,
    }
    loadstring(game:HttpGet("https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/loader.lua"))()
    
]]

local REPO_BASE = _G.BSSMonitorDev or "https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/"
_G.BSSMonitorDev = nil  -- clear immediately so no module can read the dev URL
-- Dev/local URLs get cache bust so changes apply; production reuses cache for faster reloads
local CACHE_BUST = (REPO_BASE:find("dev") or REPO_BASE:find("localhost") or _G.BSSMonitorNoCache) and ("?v=" .. tostring(os.time())) or ""

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
        -- Destroy config panel first (overlay, dropdowns, refs)
        if _G.BSSMonitor.ConfigPanel and _G.BSSMonitor.ConfigPanel.Cleanup then
            _G.BSSMonitor.ConfigPanel.Cleanup()
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

local loadStart = tick()
print("🐝 BSS Monitor - Loading...")

local function loadModule(name)
    local url = REPO_BASE .. "modules/" .. name .. ".lua" .. CACHE_BUST
    local httpOk, code = pcall(function() return game:HttpGet(url) end)
    if not httpOk or not code then
        warn("  ✗ " .. name .. ": HTTP failed")
        return nil
    end
    local loadOk, fn = pcall(loadstring, code, name)
    if not loadOk or not fn then
        warn("  ✗ " .. name .. ": loadstring failed")
        return nil
    end
    local runOk, result = pcall(fn)
    if runOk then return result end
    warn("  ✗ " .. name .. ": " .. tostring(result))
    return nil
end

local Logger = loadModule("logger")
local Config = loadModule("config")
local Persist = loadModule("persist")
local Scanner = loadModule("scanner")
local Chat = loadModule("chat")

local MonitorState = loadModule("monitor/state")
local MonitorBan = loadModule("monitor/ban")
local MonitorCycle = loadModule("monitor/cycle")
local Monitor = loadModule("monitor/init")

local WebhookHttp = loadModule("webhook/http")
local WebhookEmbeds = loadModule("webhook/embeds")
local Webhook = loadModule("webhook/init")

local GUITheme = loadModule("gui/theme")
local GUIHelpers = loadModule("gui/helpers")
local GUIComponents = loadModule("gui/components")
local ConfigPanel = loadModule("gui/configpanel")
local GUI = loadModule("gui/init")

-- Validate critical modules (GUI is optional)
if not Config or not Scanner or not Monitor or not MonitorState or not Logger then
    error("❌ BSS Monitor: Critical module load failed!")
    return
end

-- Apply script config first (defaults + _G.BSSMonitorConfig)
if customConfig then
    for key, value in pairs(customConfig) do
        Config[key] = value
    end
end

-- Then apply persisted config from BSS-Monitor/config.json (overrides script config when file exists)
local hadPersistedConfig = false
if Persist and Persist.Load then
    local content, loadErr = Persist.Load()
    if content and #content > 0 then
        local HttpService = game:GetService("HttpService")
        local ok, decoded = pcall(function() return HttpService:JSONDecode(content) end)
        if ok and decoded and type(decoded) == "table" and Config.ApplyFromTable then
            Config.ApplyFromTable(decoded)
            hadPersistedConfig = true
        end
    end
end

-- First run: no config.json → save current config (script/defaults) so next run loads from file
if not hadPersistedConfig and Persist and Persist.Save and Config.ExportToTable then
    local HttpService = game:GetService("HttpService")
    local exportTable = Config.ExportToTable()
    local jsonStr = HttpService:JSONEncode(exportTable)
    local ok, err = Persist.Save(jsonStr)
    if ok then
        print("[BSS Monitor] First run: config saved to BSS-Monitor/config.json")
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
if ConfigPanel then ConfigPanel.Init(GUITheme, GUIHelpers, Config) end
if GUI then GUI.Init(Config, Monitor, Chat, GUITheme, GUIHelpers, GUIComponents, ConfigPanel) end
Monitor.Init(Config, Scanner, Webhook, Chat, GUI, MonitorState, MonitorBan, MonitorCycle)

-- Create GUI if enabled
if Config.SHOW_GUI and GUI then
    GUI.Create()
end

-- Initial scan after brief delay
task.wait(1)
Monitor.RunCycle()

-- Always start monitoring on load
Monitor.Start()

-- Store in _G for access
_G.BSSMonitor = {
    Config = Config,
    Persist = Persist,
    ConfigPanel = ConfigPanel,
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
    testWebhook = function()
        if not Config.IsWebhookConfigured() then
            print("[BSS Monitor] Webhook not configured. Set Webhook URL and enable Notifications in Settings.")
            return false, "Not configured"
        end
        return Webhook.Send(Config, { title = "🧪 Test", description = "Webhook test successful!", color = 0x57F287 })
    end,
    
    -- Logging controls
    setLogLevel = function(level) Logger.SetLevel(level) end,
    getLogs = function(count) return Logger.GetRecent(count or 20) end,
    clearLogs = function() Logger.Clear() end,
    
    -- Manual cleanup
    cleanup = function()
        -- Silent cleanup (safe to re-execute after)
        pcall(function() Monitor.Stop() end)
        pcall(function() if ConfigPanel and ConfigPanel.Cleanup then ConfigPanel.Cleanup() end end)
        pcall(function() if GUI then GUI.ScreenGui:Destroy() end end)
        pcall(function()
            for _, conn in ipairs(GUI and GUI.Connections or {}) do conn:Disconnect() end
        end)
        pcall(function()
            for _, conn in ipairs(_G.BSSMonitor._connections) do conn:Disconnect() end
        end)
        _G.BSSMonitor = nil
    end,
    
    -- Version
    version = Config.VERSION or "unknown"
}

local loadTime = string.format("%.2f", tick() - loadStart)
print("🐝 BSS Monitor v" .. (Config.VERSION or "?") .. " ready in " .. loadTime .. "s | DRY=" .. (Config.DRY_RUN and "ON" or "OFF") .. " LOG=" .. (Config.LOG_LEVEL or "WARN"))

return _G.BSSMonitor
