--[[
    BSS Monitor - Cycle & Control
    Scan cycle, start/stop/toggle, status reporting
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Cycle = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Dependencies (set by Init)
local State = nil
local Ban = nil
local Config = nil
local Scanner = nil
local Webhook = nil
local GUI = nil
local Chat = nil

function Cycle.Init(state, ban, config, scanner, webhook, gui, chat)
    State = state
    Ban = ban
    Config = config
    Scanner = scanner
    Webhook = webhook
    GUI = gui
    Chat = chat
end

-- Run a single scan cycle
function Cycle.RunCycle()
    State.LastScanResults = Scanner.ScanAllHives(Config)

    local checkedCount = 0
    local passedCount = 0
    local failedCount = 0

    for playerName, hiveData in pairs(State.LastScanResults) do
        if playerName ~= LocalPlayer.Name then
            checkedCount = checkedCount + 1
            local passed, reason = Ban.CheckPlayer(playerName, hiveData)
            if passed then
                passedCount = passedCount + 1
            else
                failedCount = failedCount + 1
            end
        end
    end

    -- Mobile ban verification: re-check if mobile-banned players have left or need re-notification
    for playerName, banData in pairs(State.BannedPlayers) do
        if banData.mobileMode and not banData.verified then
            if not State.IsPlayerInServer(playerName) then
                -- Player left on their own
                banData.verified = true
                State.Log("BanVerified", "✅ " .. playerName .. " has left the server")
                if Webhook then
                    Webhook.SendBanVerifiedNotification(Config, playerName, "Player left server", 0)
                end
            elseif banData.webhookNotified then
                -- Player still in server, re-send webhook if enough time has passed
                local timeSinceNotify = tick() - (banData.lastNotifyTime or banData.time)
                local renotifyInterval = Config.MOBILE_RENOTIFY_INTERVAL or 300
                if timeSinceNotify >= renotifyInterval then
                    local hiveData = State.LastScanResults[playerName]
                    if hiveData then
                        local checkResult = Scanner.CheckRequirements(hiveData, Config)
                        Webhook.SendMobileBanNotification(Config, playerName, hiveData, checkResult)
                        banData.lastNotifyTime = tick()
                        State.Log("Mobile", "📱 Re-sent webhook notification for: " .. playerName .. " (still in server)")
                    end
                end
            end
        end
    end

    -- Scan timeout: kick players with no hive data after SCAN_TIMEOUT past grace period
    local scanTimeout = Config.SCAN_TIMEOUT or 90
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local playerName = player.Name
            if not Config.IsWhitelisted(playerName) and not State.BannedPlayers[playerName] then
                local joinTime = State.PlayerJoinTimes[playerName]
                if joinTime then
                    local elapsed = tick() - joinTime
                    if elapsed > Config.GRACE_PERIOD + scanTimeout then
                        if not State.LastScanResults[playerName] then
                            State.Log("Ban", string.format("⏰ %s: no hive data after %ds - kicking (scan timeout)", playerName, math.floor(elapsed)))
                            if not Config.DRY_RUN then
                                coroutine.wrap(function()
                                    local success, err = Chat.SendKickCommand(playerName)
                                    if success then
                                        State.Log("BanVerified", "Kick command sent for " .. playerName .. " (scan timeout)")
                                    else
                                        State.Log("BanFailed", "Failed to kick " .. playerName .. ": " .. tostring(err))
                                    end
                                    if GUI then
                                        GUI.UpdateDisplay(State.LastScanResults, State.CheckedPlayers, State.BannedPlayers)
                                    end
                                end)()
                            else
                                State.Log("Ban", "[DRY RUN] Would kick " .. playerName .. " for scan timeout")
                            end
                            State.BannedPlayers[playerName] = {
                                time = tick(),
                                reason = "No hive data (scan timeout)",
                                scanTimeout = true,
                                dryRun = Config.DRY_RUN
                            }
                            if Webhook then
                                Webhook.Send(Config, {
                                    title = "\xE2\x8F\xB0  Scan Timeout \xE2\x80\x94 Player Kicked",
                                    color = 0xE67E22,
                                    description = string.format("**%s** was kicked for having no hive data after %d seconds.", playerName, math.floor(elapsed)),
                                })
                            end
                        end
                    end
                end
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
function Cycle.Start()
    if State.IsRunning then
        State.Log("Info", "Monitor already running")
        return false
    end

    State.IsRunning = true
    State.Log("Start", "Monitoring started")

    -- Send webhook
    Webhook.SendStartNotification(Config)

    -- Update GUI
    if GUI then
        GUI.UpdateStatus(true)
    end

    -- Start loop in coroutine
    coroutine.wrap(function()
        while State.IsRunning do
            local results = Cycle.RunCycle()
            State.Log("Scan", string.format("Scanned %d players: %d passed, %d failed",
                results.checked, results.passed, results.failed))

            if GUI then
                GUI.UpdateDisplay(State.LastScanResults, State.CheckedPlayers, State.BannedPlayers)
                GUI.UpdateLog()
            end

            -- Wait for next cycle
            for i = 1, Config.CHECK_INTERVAL do
                if not State.IsRunning then break end
                wait(1)
            end
        end
    end)()

    return true
end

-- Stop monitoring
function Cycle.Stop()
    if not State.IsRunning then
        State.Log("Info", "Monitor not running")
        return false
    end

    State.IsRunning = false
    State.Log("Stop", "Monitoring stopped")

    -- Send webhook
    Webhook.SendStopNotification(Config)

    -- Update GUI
    if GUI then
        GUI.UpdateStatus(false)
    end

    return true
end

-- Toggle monitoring
function Cycle.Toggle()
    if State.IsRunning then
        return Cycle.Stop()
    else
        return Cycle.Start()
    end
end

-- Get status
function Cycle.GetStatus()
    return {
        running = State.IsRunning,
        playersInGrace = (function()
            local count = 0
            for name, joinTime in pairs(State.PlayerJoinTimes) do
                if tick() - joinTime < Config.GRACE_PERIOD then
                    count = count + 1
                end
            end
            return count
        end)(),
        playersBanned = (function()
            local count = 0
            for _ in pairs(State.BannedPlayers) do count = count + 1 end
            return count
        end)(),
        playersPassed = (function()
            local count = 0
            for _ in pairs(State.CheckedPlayers) do count = count + 1 end
            return count
        end)(),
        lastScan = State.LastScanResults
    }
end

return Cycle
