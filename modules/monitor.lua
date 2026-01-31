--[[
    BSS Monitor - Monitor Module
    Main monitoring loop and player tracking
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Monitor = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- State
Monitor.IsRunning = false
Monitor.PlayerJoinTimes = {}    -- Track when players joined
Monitor.BannedPlayers = {}      -- Track who we've already banned
Monitor.CheckedPlayers = {}     -- Track who passed checks
Monitor.ActionLog = {}          -- Log of actions taken
Monitor.LastScanResults = {}    -- Last scan results
Monitor.PendingBans = {}        -- Players waiting for ban verification

-- Dependencies (set by Init)
local Config = nil
local Scanner = nil
local Webhook = nil
local Chat = nil
local GUI = nil

-- Initialize with dependencies
function Monitor.Init(config, scanner, webhook, chat, gui)
    Config = config
    Scanner = scanner
    Webhook = webhook
    Chat = chat
    GUI = gui
    
    -- Track existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            Monitor.PlayerJoinTimes[player.Name] = tick()
        end
    end
    
    -- Track new players (store connection for cleanup)
    local playerAddedConn = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            Monitor.PlayerJoinTimes[player.Name] = tick()
            Monitor.Log("PlayerJoin", player.Name .. " joined the server")
            if GUI then
                GUI.UpdateLog()
            end
        end
    end)
    
    -- Clean up when players leave (store connection for cleanup)
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        -- Check if this was a pending ban - mark as verified
        if Monitor.PendingBans[player.Name] then
            Monitor.PendingBans[player.Name].verified = true
            Monitor.PendingBans[player.Name].leftAt = tick()
            Monitor.Log("BanVerified", "✅ " .. player.Name .. " has left the server (ban confirmed)")
        end
        
        Monitor.PlayerJoinTimes[player.Name] = nil
        Monitor.CheckedPlayers[player.Name] = nil
        Monitor.Log("PlayerLeave", player.Name .. " left the server")
        if GUI then
            GUI.UpdateLog()
        end
    end)
    
    -- Store connections in _G for cleanup on re-execution
    if _G.BSSMonitor and _G.BSSMonitor._connections then
        table.insert(_G.BSSMonitor._connections, playerAddedConn)
        table.insert(_G.BSSMonitor._connections, playerRemovingConn)
    end
    
    return Monitor
end

-- Logging function
function Monitor.Log(actionType, message)
    local entry = {
        time = os.date("%H:%M:%S"),
        type = actionType,
        message = message
    }
    table.insert(Monitor.ActionLog, 1, entry)
    
    -- Keep only last 50 entries
    while #Monitor.ActionLog > 50 do
        table.remove(Monitor.ActionLog)
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
function Monitor.IsPlayerInServer(playerName)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == playerName then
            return true
        end
    end
    return false
end

-- Execute ban with verification (waits to confirm player left)
function Monitor.ExecuteBanWithVerification(playerName, reason, maxRetries, timeout)
    maxRetries = maxRetries or 3
    timeout = timeout or 10 -- seconds to wait for player to leave
    
    -- Check if player is even in server
    if not Monitor.IsPlayerInServer(playerName) then
        Monitor.Log("Ban", playerName .. " is not in server (already left or doesn't exist)")
        return true, "Not in server"
    end
    
    -- Mark as pending ban
    Monitor.PendingBans[playerName] = {
        startTime = tick(),
        reason = reason,
        attempts = 0,
        verified = false
    }
    
    for attempt = 1, maxRetries do
        Monitor.PendingBans[playerName].attempts = attempt
        
        -- Send ban command
        local success, method = Chat.SendBanCommand(playerName)
        if success then
            Monitor.Log("Ban", string.format("Ban command sent for %s (attempt %d/%d) via %s", 
                playerName, attempt, maxRetries, method))
        else
            Monitor.Log("Error", "Failed to send ban command: " .. tostring(method))
        end
        
        -- Wait and check if player left
        local waitStart = tick()
        while tick() - waitStart < timeout do
            -- Check if verified via PlayerRemoving event
            if Monitor.PendingBans[playerName] and Monitor.PendingBans[playerName].verified then
                Monitor.BannedPlayers[playerName] = {
                    time = tick(),
                    reason = reason,
                    verified = true,
                    attempts = attempt
                }
                Monitor.PendingBans[playerName] = nil
                return true, "Verified (player left)"
            end
            
            -- Also directly check if player is still in server
            if not Monitor.IsPlayerInServer(playerName) then
                Monitor.BannedPlayers[playerName] = {
                    time = tick(),
                    reason = reason,
                    verified = true,
                    attempts = attempt
                }
                Monitor.PendingBans[playerName] = nil
                Monitor.Log("BanVerified", "✅ " .. playerName .. " is no longer in server (ban successful)")
                return true, "Verified (not in server)"
            end
            
            task.wait(0.5)
        end
        
        -- Player still in server after timeout
        if attempt < maxRetries then
            Monitor.Log("BanFailed", string.format("%s still in server after attempt %d, retrying...", 
                playerName, attempt))
        end
    end
    
    -- All retries exhausted, player still in server
    Monitor.Log("BanFailed", string.format("❌ Failed to ban %s after %d attempts - player still in server!", 
        playerName, maxRetries))
    
    -- Mark as failed ban
    Monitor.BannedPlayers[playerName] = {
        time = tick(),
        reason = reason,
        verified = false,
        attempts = maxRetries,
        failed = true
    }
    Monitor.PendingBans[playerName] = nil
    
    -- Send failure webhook
    if Webhook then
        Webhook.SendBanFailedNotification(Config, playerName, reason, maxRetries)
    end
    
    return false, "Player still in server after " .. maxRetries .. " attempts"
end

-- Check a single player
function Monitor.CheckPlayer(playerName, hiveData)
    -- Skip if whitelisted
    if Config.IsWhitelisted(playerName) then
        Monitor.Log("Skip", playerName .. " is whitelisted")
        Monitor.CheckedPlayers[playerName] = { passed = true, reason = "Whitelisted" }
        return true, "Whitelisted"
    end
    
    -- Skip if already banned
    if Monitor.BannedPlayers[playerName] then
        return false, "Already banned"
    end
    
    -- Skip if in grace period
    local joinTime = Monitor.PlayerJoinTimes[playerName]
    if joinTime then
        local timeSinceJoin = tick() - joinTime
        if timeSinceJoin < Config.GRACE_PERIOD then
            local remaining = math.ceil(Config.GRACE_PERIOD - timeSinceJoin)
            Monitor.Log("Skip", playerName .. " in grace period (" .. remaining .. "s remaining)")
            return true, "Grace period"
        end
    end
    
    -- Check requirements
    local checkResult = Scanner.CheckRequirements(hiveData, Config)
    
    if checkResult.details and checkResult.details.skipped then
        Monitor.Log("Skip", playerName .. ": " .. checkResult.reason)
        Monitor.CheckedPlayers[playerName] = { passed = true, reason = checkResult.reason }
        return true, checkResult.reason
    end
    
    if checkResult.passes then
        Monitor.Log("Pass", playerName .. ": " .. checkResult.reason)
        Monitor.CheckedPlayers[playerName] = { 
            passed = true, 
            reason = checkResult.reason,
            details = checkResult.details
        }
        
        -- Webhook notification (optional, can be noisy)
        -- Webhook.SendPlayerPassedNotification(Config, playerName, hiveData, checkResult)
        
        return true, checkResult.reason
    else
        -- Player fails requirements - BAN
        Monitor.Log("Ban", playerName .. ": " .. checkResult.reason)
        
        -- Send webhook first
        Webhook.SendBanNotification(Config, playerName, hiveData, checkResult)
        
        -- Execute ban with verification (unless dry run)
        if not Config.DRY_RUN then
            -- Run verification in a separate coroutine so it doesn't block
            coroutine.wrap(function()
                local success, verifyResult = Monitor.ExecuteBanWithVerification(
                    playerName, 
                    checkResult.reason, 
                    3,  -- max retries
                    10  -- timeout seconds
                )
                
                if success then
                    Monitor.Log("BanVerified", playerName .. ": " .. verifyResult)
                else
                    Monitor.Log("BanFailed", playerName .. ": " .. verifyResult)
                end
                
                if GUI then
                    GUI.UpdateDisplay(Monitor.LastScanResults, Monitor.CheckedPlayers, Monitor.BannedPlayers)
                end
            end)()
        else
            Monitor.Log("Ban", "[DRY RUN] Would send: /ban " .. playerName)
            Monitor.BannedPlayers[playerName] = {
                time = tick(),
                reason = checkResult.reason,
                details = checkResult.details,
                dryRun = true
            }
        end
        
        return false, checkResult.reason
    end
end

-- Run a single scan cycle
function Monitor.RunCycle()
    Monitor.LastScanResults = Scanner.ScanAllHives(Config)
    
    local checkedCount = 0
    local passedCount = 0
    local failedCount = 0
    
    for playerName, hiveData in pairs(Monitor.LastScanResults) do
        if playerName ~= LocalPlayer.Name then
            checkedCount = checkedCount + 1
            local passed, reason = Monitor.CheckPlayer(playerName, hiveData)
            if passed then
                passedCount = passedCount + 1
            else
                failedCount = failedCount + 1
            end
        end
    end
    
    return {
        checked = checkedCount,
        passed = passedCount,
        failed = failedCount
    }
end

-- Start monitoring loop
function Monitor.Start()
    if Monitor.IsRunning then
        Monitor.Log("Info", "Monitor already running")
        return false
    end
    
    Monitor.IsRunning = true
    Monitor.Log("Start", "Monitoring started")
    
    -- Send webhook
    Webhook.SendStartNotification(Config)
    
    -- Update GUI
    if GUI then
        GUI.UpdateStatus(true)
    end
    
    -- Start loop in coroutine
    coroutine.wrap(function()
        while Monitor.IsRunning do
            local results = Monitor.RunCycle()
            Monitor.Log("Scan", string.format("Scanned %d players: %d passed, %d failed", 
                results.checked, results.passed, results.failed))
            
            if GUI then
                GUI.UpdateDisplay(Monitor.LastScanResults, Monitor.CheckedPlayers, Monitor.BannedPlayers)
                GUI.UpdateLog()
            end
            
            -- Wait for next cycle
            for i = 1, Config.CHECK_INTERVAL do
                if not Monitor.IsRunning then break end
                wait(1)
            end
        end
    end)()
    
    return true
end

-- Stop monitoring
function Monitor.Stop()
    if not Monitor.IsRunning then
        Monitor.Log("Info", "Monitor not running")
        return false
    end
    
    Monitor.IsRunning = false
    Monitor.Log("Stop", "Monitoring stopped")
    
    -- Send webhook
    Webhook.SendStopNotification(Config)
    
    -- Update GUI
    if GUI then
        GUI.UpdateStatus(false)
    end
    
    return true
end

-- Toggle monitoring
function Monitor.Toggle()
    if Monitor.IsRunning then
        return Monitor.Stop()
    else
        return Monitor.Start()
    end
end

-- Get status
function Monitor.GetStatus()
    return {
        running = Monitor.IsRunning,
        playersInGrace = (function()
            local count = 0
            for name, joinTime in pairs(Monitor.PlayerJoinTimes) do
                if tick() - joinTime < Config.GRACE_PERIOD then
                    count = count + 1
                end
            end
            return count
        end)(),
        playersBanned = (function()
            local count = 0
            for _ in pairs(Monitor.BannedPlayers) do count = count + 1 end
            return count
        end)(),
        playersPassed = (function()
            local count = 0
            for _ in pairs(Monitor.CheckedPlayers) do count = count + 1 end
            return count
        end)(),
        lastScan = Monitor.LastScanResults
    }
end

-- Manual ban command
function Monitor.ManualBan(playerName)
    if Config.IsWhitelisted(playerName) then
        Monitor.Log("Error", "Cannot ban whitelisted player: " .. playerName)
        return false, "Player is whitelisted"
    end
    
    Monitor.Log("Ban", "Manual ban initiated: " .. playerName)
    
    if not Config.DRY_RUN then
        -- Run verification in a separate coroutine
        coroutine.wrap(function()
            local success, verifyResult = Monitor.ExecuteBanWithVerification(
                playerName, 
                "Manual ban", 
                3,  -- max retries
                10  -- timeout seconds
            )
            
            if success then
                Monitor.Log("BanVerified", "Manual ban successful: " .. playerName .. " - " .. verifyResult)
            else
                Monitor.Log("BanFailed", "Manual ban failed: " .. playerName .. " - " .. verifyResult)
            end
            
            if GUI then
                GUI.UpdateDisplay(Monitor.LastScanResults, Monitor.CheckedPlayers, Monitor.BannedPlayers)
            end
        end)()
        
        return true, "Ban initiated (verifying...)"
    else
        Monitor.Log("Ban", "[DRY RUN] Would send: /ban " .. playerName)
        Monitor.BannedPlayers[playerName] = {
            time = tick(),
            reason = "Manual ban",
            dryRun = true
        }
        return true, "DRY RUN"
    end
end

return Monitor
