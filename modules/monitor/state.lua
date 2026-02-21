--[[
    BSS Monitor - Monitor State & Logging
    Shared state tables, logging, and utility functions
    https://github.com/roja-projects-only/BSS-Monitor
]]

local State = {}

local Players = game:GetService("Players")

-- State tables
State.IsRunning = false
State.PlayerJoinTimes = {}    -- Track when players joined
State.BannedPlayers = {}      -- Track who we've already banned
State.CheckedPlayers = {}     -- Track who passed checks
State.ActionLog = {}          -- Log of actions taken
State.LastScanResults = {}    -- Last scan results
State.PendingBans = {}        -- Players waiting for ban verification
State.Connections = {}        -- Store RBXScriptConnections for cleanup

-- Logging function
function State.Log(actionType, message)
    local entry = {
        time = os.date("%H:%M:%S"),
        type = actionType,
        message = message
    }
    table.insert(State.ActionLog, 1, entry)

    -- Keep only last 50 entries
    while #State.ActionLog > 50 do
        table.remove(State.ActionLog)
    end

    -- Console log
    local prefix = "[BSS Monitor]"
    if actionType == "Ban" then
        warn(prefix, "🚫", message)
    elseif actionType == "BanVerified" then
        warn(prefix, "✅🚫", message)
    elseif actionType == "BanFailed" then
        warn(prefix, "❌🚫", message)
    elseif actionType == "Pass" then
        print(prefix, "✅", message)
    elseif actionType == "Skip" then
        print(prefix, "⏭️", message)
    elseif actionType == "Error" then
        warn(prefix, "❌", message)
    else
        print(prefix, message)
    end
end

-- Check if a player is in the server
function State.IsPlayerInServer(playerName)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == playerName then
            return true
        end
    end
    return false
end

return State
