--[[
    BSS Monitor - Main Entry Point
    Private server monitoring for Bee Swarm Simulator
    https://github.com/roja-projects-only/BSS-Monitor
    
    Usage:
        loadstring(game:HttpGet("https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/loader.lua"))()
]]

local REPO_BASE = "https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/"

-- ============================================
-- CLEANUP PREVIOUS SESSION (if re-executed)
-- ============================================
if _G.BSSMonitor then
    print("🐝 BSS Monitor: Previous session detected, cleaning up...")
    
    pcall(function()
        -- Stop monitoring
        if _G.BSSMonitor.Monitor and _G.BSSMonitor.Monitor.IsRunning then
            _G.BSSMonitor.Monitor.Stop()
        end
    end)
    
    pcall(function()
        -- Destroy GUI
        if _G.BSSMonitor.GUI and _G.BSSMonitor.GUI.ScreenGui then
            _G.BSSMonitor.GUI.ScreenGui:Destroy()
        end
    end)
    
    pcall(function()
        -- Disconnect all connections if stored
        if _G.BSSMonitor._connections then
            for _, conn in pairs(_G.BSSMonitor._connections) do
                if conn and typeof(conn) == "RBXScriptConnection" then
                    conn:Disconnect()
                end
            end
        end
    end)
    
    -- Clear old reference
    _G.BSSMonitor = nil
    
    print("  ✓ Previous session cleaned up")
    task.wait(0.5)
end

print("🐝 BSS Monitor Loading...")

-- Load modules from GitHub
local function loadModule(name)
    local url = REPO_BASE .. "modules/" .. name .. ".lua"
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success then
        print("  ✓ Loaded: " .. name)
        return result
    else
        warn("  ✗ Failed: " .. name .. " - " .. tostring(result))
        return nil
    end
end

-- Load all modules
local Config = loadModule("config")
local Scanner = loadModule("scanner")
local Webhook = loadModule("webhook")
local Chat = loadModule("chat")
local GUI = loadModule("gui")
local Bridge = loadModule("bridge")
local Monitor = loadModule("monitor")

-- Validate critical modules
if not Config or not Scanner or not Monitor then
    error("🐝 BSS Monitor: Failed to load critical modules!")
    return
end

-- Initialize modules
Bridge.Init(Config)
GUI.Init(Config, Monitor)
Monitor.Init(Config, Scanner, Webhook, Chat, GUI, Bridge)

-- Create GUI (always show minimal)
GUI.Create()

-- Initial scan
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
    Bridge = Bridge,
    Monitor = Monitor,
    _connections = {}, -- Store connections for cleanup
    
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
    testChat = function() return Chat.SendTestMessage() end,
    testWebhook = function() return Webhook.Send(Config, "Test", "Webhook test", 3066993, {}) end,
    testBridge = function() return Bridge.TestConnection() end,
    
    -- Manual cleanup function
    cleanup = function()
        print("🐝 BSS Monitor: Manual cleanup...")
        pcall(function() Monitor.Stop() end)
        pcall(function() GUI.ScreenGui:Destroy() end)
        _G.BSSMonitor = nil
        print("  ✓ Cleaned up")
    end
}

print("🐝 BSS Monitor Loaded!")
print("Access: _G.BSSMonitor")
print("DRY_RUN: " .. (Config.DRY_RUN and "ON" or "OFF"))
print("Re-execute to reload, or use _G.BSSMonitor.cleanup()")

return _G.BSSMonitor
