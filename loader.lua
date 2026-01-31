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

-- Check for custom config
local customConfig = _G.BSSMonitorConfig

print("═══════════════════════════════════════════")
print("       🐝 BSS MONITOR - LOADER")
print("═══════════════════════════════════════════")
print("")

-- Load modules function
local function loadModule(name)
    local url = REPO_BASE .. "modules/" .. name .. ".lua"
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success then
        print("  ✓ " .. name)
        return result
    else
        warn("  ✗ " .. name .. ": " .. tostring(result))
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

-- Validate critical modules
if not Config or not Scanner or not Monitor then
    error("❌ BSS Monitor: Critical module load failed!")
    return
end

-- Apply custom config if provided
if customConfig then
    print("")
    print("Applying custom config...")
    for key, value in pairs(customConfig) do
        if Config[key] ~= nil then
            Config[key] = value
            print("  • " .. key .. " = " .. tostring(value))
        end
    end
end

print("")

-- Initialize modules
GUI.Init(Config, Monitor)
Monitor.Init(Config, Scanner, Webhook, Chat, GUI)

-- Create GUI (always show minimal GUI)
GUI.Create()

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
    
    -- Convenience functions
    start = function() Monitor.Start() end,
    stop = function() Monitor.Stop() end,
    toggle = function() Monitor.Toggle() end,
    scan = function() return Monitor.RunCycle() end,
    status = function() return Monitor.GetStatus() end,
    ban = function(name) return Monitor.ManualBan(name) end,
    whitelist = function(name) return Config.AddToWhitelist(name) end,
    unwhitelist = function(name) return Config.RemoveFromWhitelist(name) end,
    showGui = function() GUI.Show() end,
    hideGui = function() GUI.Hide() end,
    
    -- Test functions
    testChat = function() return Chat.SendTestMessage() end,
    testWebhook = function() return Webhook.Send(Config, "Test", "Webhook test successful!", 3066993, {}) end,
    
    -- Version
    version = "1.0.0"
}

print("═══════════════════════════════════════════")
print("       🐝 BSS MONITOR READY!")
print("═══════════════════════════════════════════")
print("")
print(" Access: _G.BSSMonitor")
print("")
print(" Commands:")
print("   .start()   - Begin monitoring")
print("   .stop()    - Stop monitoring")
print("   .scan()    - Manual scan")
print("   .ban('x')  - Ban player")
print("")
print(" DRY_RUN: " .. (Config.DRY_RUN and "ON" or "OFF"))
print("═══════════════════════════════════════════")

return _G.BSSMonitor
