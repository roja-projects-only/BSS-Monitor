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
    print("🐝 BSS Monitor: Previous session detected, cleaning up...")
    
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
        -- Disconnect all stored connections (Monitor + _G level)
        if _G.BSSMonitor.Monitor and _G.BSSMonitor.Monitor.Connections then
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
    print("  ✓ Previous session cleaned up")
    task.wait(0.5)
end

-- Check for custom config
local customConfig = _G.BSSMonitorConfig

print("═══════════════════════════════════════════")
print("       🐝 BSS MONITOR - LOADER")
print("═══════════════════════════════════════════")
print("")

-- Load modules function
local function loadModule(name)
    local url = REPO_BASE .. "modules/" .. name .. ".lua" .. CACHE_BUST
    print("  Loading: " .. name .. " from " .. url)
    
    local httpSuccess, code = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not httpSuccess then
        warn("  ✗ " .. name .. " (HTTP failed): " .. tostring(code))
        return nil
    end
    
    print("    Got " .. #code .. " bytes")
    
    local loadSuccess, loadedFunc = pcall(function()
        return loadstring(code, name)
    end)
    
    if not loadSuccess or not loadedFunc then
        warn("  ✗ " .. name .. " (loadstring failed): " .. tostring(loadedFunc))
        return nil
    end
    
    local runSuccess, result = pcall(loadedFunc)
    
    if runSuccess then
        print("  ✓ " .. name)
        return result
    else
        warn("  ✗ " .. name .. " (runtime error): " .. tostring(result))
        return nil
    end
end

print("Loading modules...")

-- Load all modules
local Config = loadModule("config")
local Scanner = loadModule("scanner")
local Webhook = loadModule("webhook")
local Chat = loadModule("chat")
local GUI = loadModule("gui")
local Monitor = loadModule("monitor")

-- Validate critical modules (GUI is optional)
if not Config or not Scanner or not Monitor then
    error("❌ BSS Monitor: Critical module load failed!")
    return
end

-- Helper to mask webhook URL
local function maskWebhook(url)
    if not url or url == "" then return "Not set" end
    return url:sub(1, 40) .. "..."
end

-- Apply custom config if provided
if customConfig then
    print("")
    print("Applying custom config...")
    for key, value in pairs(customConfig) do
        if Config[key] ~= nil then
            Config[key] = value
            if key == "WEBHOOK_URL" then
                print("  • " .. key .. " = " .. maskWebhook(value))
            else
                print("  • " .. key .. " = " .. tostring(value))
            end
        end
    end
end

print("")

-- Apply MOBILE_MODE override to Chat module
if Chat and Config.MOBILE_MODE ~= nil then
    Chat.MobileOverride = Config.MOBILE_MODE
end

-- Initialize modules
if GUI then GUI.Init(Config, Monitor, Chat) end
Monitor.Init(Config, Scanner, Webhook, Chat, GUI)

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
    
    -- Manual cleanup
    cleanup = function()
        print("🐝 BSS Monitor: Manual cleanup...")
        pcall(function() Monitor.Stop() end)
        pcall(function() if GUI then GUI.ScreenGui:Destroy() end end)
        pcall(function()
            for _, conn in ipairs(GUI and GUI.Connections or {}) do conn:Disconnect() end
        end)
        pcall(function()
            for _, conn in ipairs(_G.BSSMonitor._connections) do conn:Disconnect() end
        end)
        _G.BSSMonitor = nil
        print("  ✓ Cleaned up")
    end,
    
    -- Version
    version = "1.0.0"
}

print("═══════════════════════════════════════════")
print("       🐝 BSS MONITOR READY!")
print("═══════════════════════════════════════════")
print(" DRY_RUN: " .. (Config.DRY_RUN and "ON" or "OFF"))
print(" AUTO_START: " .. (Config.AUTO_START and "ON" or "OFF"))
print("═══════════════════════════════════════════")

return _G.BSSMonitor
