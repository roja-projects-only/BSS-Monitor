--[[
    BSS Monitor - GUI (Init / Orchestrator)
    State management, Create(), and Update*() functions
    Delegates UI building to gui/components
    https://github.com/roja-projects-only/BSS-Monitor
]]

local GUI = {}

-- Public state (referenced by Monitor and other modules)
GUI.ScreenGui = nil
GUI.PlayerCountLabel = nil
GUI.StatusLabel = nil
GUI.StatusDot = nil
GUI.PlayerList = nil
GUI.BannedList = nil
GUI.MainFrame = nil
GUI.Content = nil
GUI.Footer = nil
GUI.ToggleButton = nil
GUI.ToggleIcon = nil
GUI.CollapseButton = nil
GUI.TitleCountLabel = nil
GUI.TitleFix = nil
GUI.AccentLine = nil
GUI.LastScanResults = {}
GUI.CheckedPlayers = {}
GUI.IsCollapsed = false
GUI.IsHidden = false
GUI.Connections = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Dependencies (set by Init)
local Config = nil
local Monitor = nil
local Chat = nil
local Theme = nil
local H = nil       -- Helpers
local Comp = nil    -- Components

function GUI.Init(config, monitor, chat, theme, helpers, components)
    Config = config
    Monitor = monitor
    Chat = chat
    Theme = theme
    H = helpers
    Comp = components
    return GUI
end

-- ============================================
-- Create the full GUI
-- ============================================
function GUI.Create()
    local C = Theme.C
    local PANEL_WIDTH = Theme.PANEL_WIDTH
    local EXPANDED_HEIGHT = Theme.EXPANDED_HEIGHT
    local COLLAPSED_HEIGHT = Theme.COLLAPSED_HEIGHT
    local PADDING = Theme.PADDING

    -- Clean up previous GUI instance
    pcall(function()
        if GUI.ScreenGui then GUI.ScreenGui:Destroy() end
    end)
    for _, conn in ipairs(GUI.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    GUI.Connections = {}

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BSSMonitorGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Toggle button
    local toggleBtn, toggleIcon = Comp.CreateToggleButton(screenGui)
    GUI.ToggleButton = toggleBtn
    GUI.ToggleIcon = toggleIcon

    -- Main panel
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, PANEL_WIDTH, 0, EXPANDED_HEIGHT)
    panel.Position = UDim2.new(0, 14, 0.5, -EXPANDED_HEIGHT / 2)
    panel.BackgroundColor3 = C.bg
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.ClipsDescendants = true
    panel.Parent = screenGui
    H.addCorner(panel, 12)
    H.addStroke(panel, C.accent, 1.5)
    H.addShadow(panel)
    GUI.MainFrame = panel

    -- Title bar
    local titleParts = Comp.CreateTitleBar(panel)
    GUI.TitleFix = titleParts.TitleFix
    GUI.AccentLine = titleParts.AccentLine
    GUI.StatusDot = titleParts.StatusDot
    GUI.TitleCountLabel = titleParts.TitleCountLabel
    GUI.CollapseButton = titleParts.CollapseButton

    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -PADDING * 2, 1, -(COLLAPSED_HEIGHT + PADDING + 26))
    content.Position = UDim2.new(0, PADDING, 0, COLLAPSED_HEIGHT + 6)
    content.BackgroundTransparency = 1
    content.Parent = panel
    GUI.Content = content

    -- Stats row
    local statsParts = Comp.CreateStatsRow(content)
    GUI.PlayerCountLabel = statsParts.PlayerCountLabel
    GUI.StatusLabel = statsParts.StatusLabel

    -- Player list section
    local playersY = 56
    GUI.PlayerList = Comp.CreatePlayerListSection(content, playersY)

    -- Banned list section
    local bannedY = playersY + 18 + 112 + 6
    GUI.BannedList = Comp.CreateBannedListSection(content, bannedY)

    -- Footer
    GUI.Footer = Comp.CreateFooter(panel, statsParts.isMobile)

    GUI.ScreenGui = screenGui

    -- Toggle button click handler
    toggleBtn.MouseButton1Click:Connect(function()
        GUI.IsHidden = not GUI.IsHidden
        panel.Visible = not GUI.IsHidden
        toggleIcon.Text = GUI.IsHidden and "\xF0\x9F\x90\x9D" or "X"
        toggleIcon.Font = GUI.IsHidden and Enum.Font.SourceSans or Enum.Font.GothamBold
        toggleIcon.TextSize = GUI.IsHidden and 22 or 18
        toggleIcon.TextColor3 = GUI.IsHidden and C.text or C.red
        local borderColor = GUI.IsHidden and C.accent or C.red
        local s = toggleBtn:FindFirstChildOfClass("UIStroke")
        if s then s.Color = borderColor end
    end)

    -- Collapse button click handler
    GUI.CollapseButton.MouseButton1Click:Connect(function()
        GUI.ToggleCollapse()
    end)

    -- Parent to appropriate container
    local parented = false
    pcall(function()
        if gethui then screenGui.Parent = gethui() parented = true end
    end)
    if not parented then
        pcall(function() screenGui.Parent = game:GetService("CoreGui") parented = true end)
    end
    if not parented then
        screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    GUI.UpdatePlayerCount()
    GUI.UpdatePlayerList()

    -- Live refresh timer (1s) for grace period countdown
    local refreshConn
    refreshConn = game:GetService("RunService").Heartbeat:Connect(function()
        if not GUI._lastRefresh then GUI._lastRefresh = 0 end
        if tick() - GUI._lastRefresh < 1 then return end
        GUI._lastRefresh = tick()

        if Monitor and Monitor.PlayerJoinTimes then
            local gracePeriod = Config and Config.GRACE_PERIOD or 20
            local scanTimeout = Config and Config.SCAN_TIMEOUT or 90
            local totalTimeout = gracePeriod + scanTimeout
            for name, joinTime in pairs(Monitor.PlayerJoinTimes) do
                local elapsed = tick() - joinTime
                -- Refresh during grace countdown OR scan-timeout countdown (no hive data)
                if elapsed < gracePeriod + 2 then
                    GUI.UpdatePlayerList()
                    break
                elseif elapsed < totalTimeout + 2 and not (GUI.LastScanResults and GUI.LastScanResults[name]) then
                    GUI.UpdatePlayerList()
                    break
                end
            end
        end
    end)
    table.insert(GUI.Connections, refreshConn)

    table.insert(GUI.Connections, Players.PlayerAdded:Connect(function() GUI.UpdatePlayerCount() GUI.UpdatePlayerList() end))
    table.insert(GUI.Connections, Players.PlayerRemoving:Connect(function() task.wait(0.1) GUI.UpdatePlayerCount() GUI.UpdatePlayerList() end))

    return screenGui
end

-- ============================================
-- Toggle collapse with animation
-- ============================================
function GUI.ToggleCollapse()
    GUI.IsCollapsed = not GUI.IsCollapsed

    local targetHeight = GUI.IsCollapsed and Theme.COLLAPSED_HEIGHT or Theme.EXPANDED_HEIGHT

    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(GUI.MainFrame, tweenInfo, {
        Size = UDim2.new(0, Theme.PANEL_WIDTH, 0, targetHeight)
    })
    tween:Play()

    if GUI.CollapseButton then
        GUI.CollapseButton.Text = GUI.IsCollapsed and ">" or "v"
        GUI.CollapseButton.TextSize = GUI.IsCollapsed and 14 or 12
    end

    if GUI.Content then GUI.Content.Visible = not GUI.IsCollapsed end
    if GUI.Footer then GUI.Footer.Visible = not GUI.IsCollapsed end
    if GUI.TitleFix then GUI.TitleFix.Visible = not GUI.IsCollapsed end
    if GUI.AccentLine then GUI.AccentLine.Visible = not GUI.IsCollapsed end
end

-- ============================================
-- Update functions
-- ============================================
function GUI.UpdatePlayerCount()
    pcall(function()
        local count = #Players:GetPlayers()
        local max = Config and Config.MAX_PLAYERS or 6
        local text = count .. "/" .. max
        if GUI.PlayerCountLabel then GUI.PlayerCountLabel.Text = text end
        if GUI.TitleCountLabel then GUI.TitleCountLabel.Text = text end
    end)
end

function GUI.UpdatePlayerList()
    pcall(function()
        if not GUI.PlayerList then return end
        for _, child in ipairs(GUI.PlayerList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end

        local localPlayer = Players.LocalPlayer
        local entryCount = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                local hiveData = GUI.LastScanResults and GUI.LastScanResults[player.Name]
                local checkedData = GUI.CheckedPlayers and GUI.CheckedPlayers[player.Name]
                local entry = Comp.CreatePlayerEntry(player.Name, hiveData, checkedData)
                entry.Parent = GUI.PlayerList
                entryCount = entryCount + 1
            end
        end

        if entryCount == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Name = "_Empty"
            emptyLabel.Size = UDim2.new(1, 0, 0, Theme.ENTRY_HEIGHT)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "No other players"
            emptyLabel.TextColor3 = Theme.C.textDim
            emptyLabel.TextSize = 11
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.Parent = GUI.PlayerList
            entryCount = 1
        end

        GUI.PlayerList.CanvasSize = UDim2.new(0, 0, 0, entryCount * Theme.ENTRY_HEIGHT + math.max(0, entryCount - 1) * Theme.ENTRY_GAP)
    end)
end

function GUI.UpdateBannedList(bannedPlayers)
    pcall(function()
        if not GUI.BannedList then return end
        for _, child in ipairs(GUI.BannedList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end

        local bannedCount = 0
        if bannedPlayers then
            for playerName, banData in pairs(bannedPlayers) do
                local entry = Comp.CreateBannedEntry(playerName, banData)
                entry.Parent = GUI.BannedList
                bannedCount = bannedCount + 1
            end
        end

        if bannedCount == 0 then
            local noneLabel = Instance.new("TextLabel")
            noneLabel.Name = "_None"
            noneLabel.Size = UDim2.new(1, 0, 0, Theme.BANNED_ENTRY_HEIGHT)
            noneLabel.BackgroundTransparency = 1
            noneLabel.Text = "None"
            noneLabel.TextColor3 = Theme.C.textDim
            noneLabel.TextSize = 10
            noneLabel.Font = Enum.Font.Gotham
            noneLabel.TextXAlignment = Enum.TextXAlignment.Center
            noneLabel.Parent = GUI.BannedList
            bannedCount = 1
        end

        GUI.BannedList.CanvasSize = UDim2.new(0, 0, 0, bannedCount * Theme.BANNED_ENTRY_HEIGHT + math.max(0, bannedCount - 1) * Theme.ENTRY_GAP)
    end)
end

function GUI.UpdateStatus(isRunning)
    pcall(function()
        if GUI.StatusLabel then
            if isRunning then
                GUI.StatusLabel.Text = "ACTIVE"
                GUI.StatusLabel.TextColor3 = Theme.C.green
            else
                GUI.StatusLabel.Text = "PAUSED"
                GUI.StatusLabel.TextColor3 = Theme.C.red
            end
        end
        if GUI.StatusDot then
            GUI.StatusDot.BackgroundColor3 = isRunning and Theme.C.green or Theme.C.red
        end
    end)
end

function GUI.UpdateDisplay(scanResults, checkedPlayers, bannedPlayers)
    GUI.LastScanResults = scanResults or {}
    GUI.CheckedPlayers = checkedPlayers or {}
    GUI.UpdatePlayerList()
    GUI.UpdateBannedList(bannedPlayers)
end

function GUI.UpdateLog() end
function GUI.Show() pcall(function() if GUI.ScreenGui then GUI.ScreenGui.Enabled = true end end) end
function GUI.Hide() pcall(function() if GUI.ScreenGui then GUI.ScreenGui.Enabled = false end end) end
function GUI.Toggle() pcall(function() if GUI.ScreenGui then GUI.ScreenGui.Enabled = not GUI.ScreenGui.Enabled end end) end

return GUI
