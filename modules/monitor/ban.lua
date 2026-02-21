--[[
    BSS Monitor - Ban Module
    Ban execution, verification, player checking, and manual bans
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Ban = {}

-- Dependencies (set by Init)
local State = nil
local Config = nil
local Scanner = nil
local Webhook = nil
local Chat = nil
local GUI = nil

function Ban.Init(state, config, scanner, webhook, chat, gui)
    State = state
    Config = config
    Scanner = scanner
    Webhook = webhook
    Chat = chat
    GUI = gui
end

-- Execute ban with verification (waits to confirm player left)
-- Both platforms try VirtualInputManager first.
-- Mobile fallback: if VIM doesn't work, sends Discord webhook with @mention + tap-to-copy /ban command.
function Ban.ExecuteWithVerification(playerName, reason, maxRetries, timeout)
    maxRetries = maxRetries or 3
    timeout = timeout or 10 -- seconds to wait for player to leave

    -- Check if player is even in server
    if not State.IsPlayerInServer(playerName) then
        State.Log("Ban", playerName .. " is not in server (already left or doesn't exist)")
        return true, "Not in server"
    end

    -- Determine if we're on mobile (Chat.IsMobile() already respects Config.MOBILE_MODE override)
    local isMobile = Chat.IsMobile()

    -- Mobile uses shorter initial timeout (3s) before falling back to webhook
    local initialTimeout = isMobile and 3 or timeout

    -- Mark as pending ban
    State.PendingBans[playerName] = {
        startTime = tick(),
        reason = reason,
        attempts = 0,
        verified = false
    }

    -- ATTEMPT 1: Try VirtualInputManager (works on both platforms now)
    for attempt = 1, maxRetries do
        State.PendingBans[playerName].attempts = attempt

        -- Send kick/ban command
        local success, method
        if Config.USE_KICK then
            success, method = Chat.SendKickCommand(playerName)
        else
            success, method = Chat.SendBanCommand(playerName)
        end

        local cmdType = Config.USE_KICK and "Kick" or "Ban"
        if success then
            State.Log("Ban", string.format("%s command sent for %s (attempt %d/%d) via %s",
                cmdType, playerName, attempt, maxRetries, method))
        else
            State.Log("Error", "Failed to send " .. cmdType:lower() .. " command: " .. tostring(method))
            -- On mobile, if VIM send fails on first attempt, skip straight to webhook fallback
            if isMobile and attempt == 1 then
                break
            end
        end

        -- Wait and check if player left
        local waitTimeout = (attempt == 1 and isMobile) and initialTimeout or timeout
        local waitStart = tick()
        while tick() - waitStart < waitTimeout do
            if State.PendingBans[playerName] and State.PendingBans[playerName].verified then
                State.BannedPlayers[playerName] = {
                    time = tick(),
                    reason = reason,
                    verified = true,
                    attempts = attempt
                }
                State.PendingBans[playerName] = nil
                return true, "Verified (player left)"
            end

            if not State.IsPlayerInServer(playerName) then
                State.BannedPlayers[playerName] = {
                    time = tick(),
                    reason = reason,
                    verified = true,
                    attempts = attempt
                }
                State.PendingBans[playerName] = nil
                State.Log("BanVerified", "✅ " .. playerName .. " is no longer in server (ban successful)")
                return true, "Verified (not in server)"
            end

            task.wait(0.5)
        end

        -- On mobile, after first attempt + short wait, fall back to webhook instead of retrying VIM
        if isMobile then
            break
        end

        if attempt < maxRetries then
            State.Log("BanFailed", string.format("%s still in server after attempt %d, retrying...",
                playerName, attempt))
        end
    end

    -- MOBILE FALLBACK: VIM didn't work, send webhook notification with @mention + tap-to-copy
    if isMobile then
        State.Log("Mobile", "📱 VIM ban didn't work for " .. playerName .. ", sending webhook notification")

        State.BannedPlayers[playerName] = {
            time = tick(),
            reason = reason,
            mobileMode = true,
            webhookNotified = true,
            lastNotifyTime = tick()
        }
        State.PendingBans[playerName] = nil

        -- Send mobile webhook with @mention + tap-to-copy /ban command
        local hiveData = State.LastScanResults[playerName]
        if hiveData and Webhook then
            local checkResult = Scanner.CheckRequirements(hiveData, Config)
            Webhook.SendMobileBanNotification(Config, playerName, hiveData, checkResult)
        end

        return false, "Mobile fallback (webhook notified)"
    end

    -- DESKTOP: All retries exhausted, player still in server
    State.Log("BanFailed", string.format("❌ Failed to ban %s after %d attempts - player still in server!",
        playerName, maxRetries))

    State.BannedPlayers[playerName] = {
        time = tick(),
        reason = reason,
        verified = false,
        attempts = maxRetries,
        failed = true
    }
    State.PendingBans[playerName] = nil

    if Webhook then
        Webhook.SendBanFailedNotification(Config, playerName, reason, maxRetries)
    end

    return false, "Player still in server after " .. maxRetries .. " attempts"
end

-- Check a single player
function Ban.CheckPlayer(playerName, hiveData)
    -- Skip if whitelisted
    if Config.IsWhitelisted(playerName) then
        State.Log("Skip", playerName .. " is whitelisted")
        State.CheckedPlayers[playerName] = { passed = true, reason = "Whitelisted" }
        return true, "Whitelisted"
    end

    -- Skip if already banned
    if State.BannedPlayers[playerName] then
        return false, "Already banned"
    end

    -- Skip if in grace period
    local joinTime = State.PlayerJoinTimes[playerName]
    if joinTime then
        local timeSinceJoin = tick() - joinTime
        if timeSinceJoin < Config.GRACE_PERIOD then
            local remaining = math.ceil(Config.GRACE_PERIOD - timeSinceJoin)
            State.Log("Skip", playerName .. " in grace period (" .. remaining .. "s remaining)")
            return true, "Grace period"
        end
    end

    -- Check requirements
    local checkResult = Scanner.CheckRequirements(hiveData, Config)

    if checkResult.details and checkResult.details.skipped then
        State.Log("Skip", playerName .. ": " .. checkResult.reason)
        State.CheckedPlayers[playerName] = { passed = true, reason = checkResult.reason }
        return true, checkResult.reason
    end

    if checkResult.passes then
        State.Log("Pass", playerName .. ": " .. checkResult.reason)
        State.CheckedPlayers[playerName] = {
            passed = true,
            reason = checkResult.reason,
            details = checkResult.details
        }

        return true, checkResult.reason
    else
        -- Player fails requirements - BAN
        State.Log("Ban", playerName .. ": " .. checkResult.reason)

        -- Execute ban with verification (unless dry run)
        if not Config.DRY_RUN then
            local hiveDataRef = hiveData
            local checkResultRef = checkResult

            -- Run verification in a separate coroutine so it doesn't block
            coroutine.wrap(function()
                local success, verifyResult = Ban.ExecuteWithVerification(
                    playerName,
                    checkResult.reason,
                    3,  -- max retries
                    10  -- timeout seconds
                )

                if success then
                    State.Log("BanVerified", playerName .. ": " .. verifyResult)
                    if Webhook then
                        Webhook.SendBanNotification(Config, playerName, hiveDataRef, checkResultRef)
                    end
                else
                    State.Log("BanFailed", playerName .. ": " .. verifyResult)
                end

                if GUI then
                    GUI.UpdateDisplay(State.LastScanResults, State.CheckedPlayers, State.BannedPlayers)
                end
            end)()
        else
            local cmd = Config.USE_KICK and "/kick" or "/ban"
            State.Log("Ban", "[DRY RUN] Would send: " .. cmd .. " " .. playerName)
            State.BannedPlayers[playerName] = {
                time = tick(),
                reason = checkResult.reason,
                details = checkResult.details,
                dryRun = true
            }
        end

        return false, checkResult.reason
    end
end

-- Manual ban command
function Ban.ManualBan(playerName)
    if Config.IsWhitelisted(playerName) then
        State.Log("Error", "Cannot ban whitelisted player: " .. playerName)
        return false, "Player is whitelisted"
    end

    State.Log("Ban", "Manual ban initiated: " .. playerName)

    if not Config.DRY_RUN then
        coroutine.wrap(function()
            local success, verifyResult = Ban.ExecuteWithVerification(
                playerName,
                "Manual ban",
                3,  -- max retries
                10  -- timeout seconds
            )

            if success then
                State.Log("BanVerified", "Manual ban successful: " .. playerName .. " - " .. verifyResult)
            else
                State.Log("BanFailed", "Manual ban failed: " .. playerName .. " - " .. verifyResult)
            end

            if GUI then
                GUI.UpdateDisplay(State.LastScanResults, State.CheckedPlayers, State.BannedPlayers)
            end
        end)()

        return true, "Ban initiated (verifying...)"
    else
        local cmd = Config.USE_KICK and "/kick" or "/ban"
        State.Log("Ban", "[DRY RUN] Would send: " .. cmd .. " " .. playerName)
        State.BannedPlayers[playerName] = {
            time = tick(),
            reason = "Manual ban",
            dryRun = true
        }
        return true, "DRY RUN"
    end
end

return Ban
