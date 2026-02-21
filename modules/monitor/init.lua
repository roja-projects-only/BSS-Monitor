--[[
    BSS Monitor - Monitor Init
    Orchestrator: initializes sub-modules, sets up player connections,
    and exposes the unified Monitor API
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Monitor = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Sub-modules (set by Init)
local State = nil
local Ban = nil
local Cycle = nil

-- Dependencies
local Config = nil
local Webhook = nil
local GUI = nil

-- Initialize with dependencies and sub-modules
function Monitor.Init(config, scanner, webhook, chat, gui, state, ban, cycle)
    Config = config
    Webhook = webhook
    GUI = gui
    State = state
    Ban = ban
    Cycle = cycle

    -- Hard reset state tables on re-init to avoid carrying over stale data
    State.PlayerJoinTimes = {}
    State.BannedPlayers = {}
    State.KickedTimeouts = {}
    State.CheckedPlayers = {}
    State.LastScanResults = {}
    State.PendingBans = {}
    State.NoHiveDataSince = {}

    -- Clean up existing connections first (in case of re-init)
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}

    -- Initialize sub-modules with their dependencies
    Ban.Init(State, config, scanner, webhook, chat, gui)
    Cycle.Init(State, Ban, config, scanner, webhook, gui, chat)

    -- Track existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            State.PlayerJoinTimes[player.Name] = tick()
        end
    end

    -- Track new players (store connection for cleanup)
    local playerAddedConn = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            State.PlayerJoinTimes[player.Name] = tick()
            State.Log("PlayerJoin", player.Name .. " joined the server")
            if Webhook then
                local playerCount = #Players:GetPlayers()
                Webhook.SendPlayerJoinNotification(Config, player.Name, playerCount, Config.MAX_PLAYERS)
            end

        end
    end)

    -- Clean up when players leave (store connection for cleanup)
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        -- Check if this was a pending ban - mark as verified
        if State.PendingBans[player.Name] then
            State.PendingBans[player.Name].verified = true
            State.PendingBans[player.Name].leftAt = tick()
            State.Log("BanVerified", "✅ " .. player.Name .. " has left the server (ban confirmed)")
        end

        -- Check if this was a banned player (mobile or failed desktop) - mark as verified
        -- Skip if a PendingBan is active (ban coroutine handles verification)
        -- Skip if entry is still pending (set early by CheckPlayer, coroutine not done yet)
        if State.BannedPlayers[player.Name]
            and not State.BannedPlayers[player.Name].verified
            and not State.BannedPlayers[player.Name].pending
            and not State.PendingBans[player.Name] then
            State.BannedPlayers[player.Name].verified = true
            State.Log("BanVerified", "✅ " .. player.Name .. " has left the server (ban confirmed)")
            if Webhook then
                Webhook.SendBanVerifiedNotification(Config, player.Name, "Player left server", State.BannedPlayers[player.Name].attempts or 0)
            end
        end

        -- Check if this was a scan-timeout kick
        if State.KickedTimeouts[player.Name] then
            State.Log("BanVerified", "✅ " .. player.Name .. " has left the server (kick confirmed - scan timeout)")
            if Webhook then
                local kickData = State.KickedTimeouts[player.Name]
                Webhook.SendKickConfirmedNotification(Config, player.Name, kickData.elapsedSeconds)
            end
        end

        -- Send leave webhook only if player was NOT banned/pending ban
        local wasBanned = State.BannedPlayers[player.Name] or State.PendingBans[player.Name] or State.KickedTimeouts[player.Name]

        local joinTime = State.PlayerJoinTimes[player.Name]
        local playtimeSeconds = joinTime and math.floor(tick() - joinTime) or nil

        State.PlayerJoinTimes[player.Name] = nil
        State.CheckedPlayers[player.Name] = nil
        State.KickedTimeouts[player.Name] = nil
        State.NoHiveDataSince[player.Name] = nil
        State.Log("PlayerLeave", player.Name .. " left the server")

        if not wasBanned and Webhook then
            task.wait(0.1)
            local playerCount = #Players:GetPlayers()
            Webhook.SendPlayerLeaveNotification(Config, player.Name, playerCount, Config.MAX_PLAYERS, playtimeSeconds)
        end

        if GUI then
            GUI.UpdateDisplay(State.LastScanResults, State.CheckedPlayers, State.BannedPlayers)
        end
    end)

    -- Store connections for cleanup
    table.insert(State.Connections, playerAddedConn)
    table.insert(State.Connections, playerRemovingConn)

    -- Wire up unified API from sub-modules
    Monitor.IsRunning = State.IsRunning
    Monitor.PlayerJoinTimes = State.PlayerJoinTimes
    Monitor.BannedPlayers = State.BannedPlayers
    Monitor.CheckedPlayers = State.CheckedPlayers
    Monitor.ActionLog = State.GetActionLog()  -- Points to Logger.Buffer
    Monitor.LastScanResults = State.LastScanResults
    Monitor.PendingBans = State.PendingBans
    Monitor.Connections = State.Connections

    Monitor.Log = State.Log
    Monitor.IsPlayerInServer = State.IsPlayerInServer

    Monitor.ExecuteBanWithVerification = Ban.ExecuteWithVerification
    Monitor.CheckPlayer = Ban.CheckPlayer
    Monitor.ManualBan = Ban.ManualBan

    Monitor.RunCycle = Cycle.RunCycle
    Monitor.Start = Cycle.Start
    Monitor.Stop = Cycle.Stop
    Monitor.Toggle = Cycle.Toggle
    Monitor.GetStatus = Cycle.GetStatus

    return Monitor
end

return Monitor
