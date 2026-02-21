--[[
    BSS Monitor - Monitor State
    Shared state tables and utility functions.
    Logging is delegated to the Logger module.
    https://github.com/roja-projects-only/BSS-Monitor
]]

local State = {}

local Players = game:GetService("Players")

-- State tables
State.IsRunning = false
State.PlayerJoinTimes = {}    -- Track when players joined
State.BannedPlayers = {}      -- Track who we've already banned
State.KickedTimeouts = {}     -- Track scan-timeout kicks (not shown in GUI banned list)
State.CheckedPlayers = {}     -- Track who passed checks
State.LastScanResults = {}    -- Last scan results
State.PendingBans = {}        -- Players waiting for ban verification
State.Connections = {}        -- Store RBXScriptConnections for cleanup

-- Logger reference (set by Init)
local Logger = nil

function State.Init(logger)
    Logger = logger
end

-- Logging function (delegates to Logger)
function State.Log(actionType, message)
    if Logger then
        Logger.Log(actionType, message)
    end
end

-- Convenience: get action log from Logger buffer
function State.GetActionLog()
    if Logger then
        return Logger.Buffer
    end
    return {}
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
